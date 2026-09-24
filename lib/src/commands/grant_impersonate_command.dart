import 'package:jmap_cli/src/commands/base_command.dart';
import 'package:jmap_cli/src/commands/session/get_session_command.dart';
import 'package:jmap_dart_client/util/session_util.dart';

/// Grants an account the ability to impersonate others, by finding a role
/// with the "impersonate" permission and adding it to that account's roles,
/// without dropping whatever roles it already had (dropping them would also
/// remove baseline login rights, a real failure mode found while building
/// this: an account with only the impersonate role and nothing else could no
/// longer even authenticate).
///
/// This wraps Stalwart's JMAP management methods (x:Role/query, x:Role/get,
/// Principal/query, x:Account/get, x:Account/set), it is Stalwart-specific,
/// not part of the core JMAP spec.
class GrantImpersonateCommand extends BaseCommand {
  @override
  final name = 'grant-impersonate';

  @override
  final description =
      'Grant an account impersonation rights (Stalwart-specific, requires admin credentials)';

  GrantImpersonateCommand() {
    argParser.addOption('email', help: 'Email of the account to grant impersonation rights to', mandatory: true);
  }

  @override
  Future<int> run() async {
    try {
      final args = argResults;
      if (args == null) return 1;

      final targetEmail = args['email'] as String;
      final live = await GetSessionCommand().getLiveClient(args, 'POST');

      // 1. Find a role that grants "impersonate".
      final roleId = await _findRoleWithPermission(live, 'impersonate');
      if (roleId == null) {
        print('Error: no role with the "impersonate" permission exists on this server. '
            'Create one first (e.g. via the admin UI) before granting it.');
        return 1;
      }

      // 2. Resolve the target account's principal id.
      final principalId = await _findPrincipalId(live, targetEmail);
      if (principalId == null) {
        print('Error: no account found for email: $targetEmail');
        return 1;
      }

      // 3. Read its current roles, so granting impersonate does not drop them.
      final currentRoleIds = await _getCurrentRoleIds(live, principalId);
      final newRoleIds = {...currentRoleIds, roleId: true};

      // 4. Apply the merged role set.
      final setBody = {
        'using': ['urn:ietf:params:jmap:core', 'urn:stalwart:jmap'],
        'methodCalls': [
          [
            'x:Account/set',
            {
              'accountId': live.accountId.id.value,
              'update': {
                principalId: {
                  'roles': {'@type': 'Custom', 'roleIds': newRoleIds},
                }
              },
            },
            'c0',
          ],
        ],
      };

      final response = await live.httpClient.post('', data: setBody);
      final methodResponses = response['methodResponses'] as List;
      final result = methodResponses[0][1] as Map<String, dynamic>;

      if (result['notUpdated'] != null && (result['notUpdated'] as Map).isNotEmpty) {
        print('Error: grant failed: ${result['notUpdated']}');
        return 1;
      }

      print('Granted impersonation rights to $targetEmail (role $roleId, kept existing roles $currentRoleIds).');
      return 0;
    } catch (e) {
      print('Error: $e');
      return 1;
    }
  }

  Future<String?> _findRoleWithPermission(JmapLiveClient live, String permission) async {
    final queryBody = {
      'using': ['urn:ietf:params:jmap:core', 'urn:stalwart:jmap'],
      'methodCalls': [
        [
          'x:Role/query',
          {'accountId': live.accountId.id.value},
          'c0',
        ],
        [
          'x:Role/get',
          {
            'accountId': live.accountId.id.value,
            '#ids': {'resultOf': 'c0', 'name': 'x:Role/query', 'path': '/ids'},
            'properties': ['enabledPermissions'],
          },
          'c1',
        ],
      ],
    };

    final response = await live.httpClient.post('', data: queryBody);
    final methodResponses = response['methodResponses'] as List;
    final getResult = methodResponses[1][1] as Map<String, dynamic>;
    final list = (getResult['list'] as List?) ?? [];

    for (final role in list.cast<Map<String, dynamic>>()) {
      final enabled = role['enabledPermissions'] as Map<String, dynamic>?;
      if (enabled?[permission] == true) {
        return role['id'] as String;
      }
    }
    return null;
  }

  Future<String?> _findPrincipalId(JmapLiveClient live, String email) async {
    final body = {
      'using': ['urn:ietf:params:jmap:core', 'urn:ietf:params:jmap:principals'],
      'methodCalls': [
        [
          'Principal/query',
          {
            'accountId': live.accountId.id.value,
            'filter': {'email': email},
          },
          'c0',
        ],
      ],
    };

    final response = await live.httpClient.post('', data: body);
    final methodResponses = response['methodResponses'] as List;
    final result = methodResponses[0][1] as Map<String, dynamic>;
    final ids = (result['ids'] as List?) ?? [];
    return ids.isEmpty ? null : ids.first as String;
  }

  Future<Map<String, bool>> _getCurrentRoleIds(JmapLiveClient live, String principalId) async {
    final body = {
      'using': ['urn:ietf:params:jmap:core', 'urn:stalwart:jmap'],
      'methodCalls': [
        [
          'x:Account/get',
          {
            'accountId': live.accountId.id.value,
            'ids': [principalId],
            'properties': ['roles'],
          },
          'c0',
        ],
      ],
    };

    final response = await live.httpClient.post('', data: body);
    final methodResponses = response['methodResponses'] as List;
    final result = methodResponses[0][1] as Map<String, dynamic>;
    final list = (result['list'] as List?) ?? [];
    if (list.isEmpty) return {};

    final roles = (list.first as Map<String, dynamic>)['roles'] as Map<String, dynamic>?;
    if (roles == null) return {};

    if (roles['@type'] == 'Custom') {
      final roleIds = roles['roleIds'] as Map<String, dynamic>?;
      return roleIds?.map((k, v) => MapEntry(k, v == true)) ?? {};
    }

    // Shortcut form (e.g. {"@type": "User"}): look up the matching built-in
    // role id by description so it is preserved instead of dropped.
    final shortcutType = roles['@type'] as String?;
    if (shortcutType == null) return {};
    final matchedId = await _findRoleWithDescription(live, shortcutType);
    return matchedId == null ? {} : {matchedId: true};
  }

  Future<String?> _findRoleWithDescription(JmapLiveClient live, String description) async {
    final body = {
      'using': ['urn:ietf:params:jmap:core', 'urn:stalwart:jmap'],
      'methodCalls': [
        [
          'x:Role/query',
          {'accountId': live.accountId.id.value},
          'c0',
        ],
        [
          'x:Role/get',
          {
            'accountId': live.accountId.id.value,
            '#ids': {'resultOf': 'c0', 'name': 'x:Role/query', 'path': '/ids'},
            'properties': ['description'],
          },
          'c1',
        ],
      ],
    };

    final response = await live.httpClient.post('', data: body);
    final methodResponses = response['methodResponses'] as List;
    final getResult = methodResponses[1][1] as Map<String, dynamic>;
    final list = (getResult['list'] as List?) ?? [];

    for (final role in list.cast<Map<String, dynamic>>()) {
      if (role['description'] == description) {
        return role['id'] as String;
      }
    }
    return null;
  }
}
