import 'package:jmap_cli/src/commands/base_command.dart';
import 'package:jmap_cli/src/commands/session/get_session_command.dart';
import 'package:jmap_dart_client/util/session_util.dart';

/// Checks whether a given account currently holds the "impersonate"
/// permission (Stalwart-specific), the same permission granted by
/// grant-impersonate. Requires admin credentials, since a normal user cannot
/// even read their own permissions (confirmed: x:Account/get on yourself is
/// forbidden for a non-admin account).
class CheckImpersonateCommand extends BaseCommand {
  @override
  final name = 'check-impersonate';

  @override
  final description =
      'Check whether an account currently holds impersonation rights (Stalwart-specific, requires admin credentials)';

  CheckImpersonateCommand() {
    argParser.addOption('email', help: 'Email of the account to check', mandatory: true);
  }

  @override
  Future<int> run() async {
    try {
      final args = argResults;
      if (args == null) return 1;

      final targetEmail = args['email'] as String;
      final live = await GetSessionCommand().getLiveClient(args, 'POST');

      final roleId = await _findRoleWithPermission(live, 'impersonate');
      if (roleId == null) {
        print('No role with the "impersonate" permission exists on this server.');
        return 0;
      }

      final principalId = await _findPrincipalId(live, targetEmail);
      if (principalId == null) {
        print('Error: no account found for email: $targetEmail');
        return 1;
      }

      final currentRoleIds = await _getCurrentRoleIds(live, principalId);
      final hasIt = currentRoleIds.containsKey(roleId);

      if (hasIt) {
        print('$targetEmail HAS impersonation rights (via role $roleId). '
            'Note: this permission is not scoped to specific accounts, it can act as anyone.');
      } else {
        print('$targetEmail does NOT have impersonation rights.');
      }
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

    return {};
  }
}
