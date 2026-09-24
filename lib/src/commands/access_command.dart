import 'dart:convert';
import 'package:jmap_cli/src/commands/base_command.dart';
import 'package:jmap_cli/src/commands/session/get_session_command.dart';
import 'package:jmap_dart_client/util/session_util.dart';
import 'package:jmap_dart_client/util/mailbox_util.dart';
import 'package:jmap_dart_client/util/file_node_util.dart';

class AccessCommand extends BaseCommand {
  @override
  final name = 'access';

  @override
  final description =
      'Show who you are logged in as, which accounts are already shared with you, and which other accounts exist that you might be able to reach with --impersonate';

  AccessCommand() {
    argParser.addFlag('json', help: 'Print raw JSON instead of a formatted summary.', negatable: false);
  }

  @override
  Future<int> run() async {
    try {
      final args = argResults;
      if (args == null) return 1;

      // Always resolves the session directly, since --accountId (if given)
      // would otherwise skip the lookup this command exists to show.
      final live = await GetSessionCommand().getLiveClient(args, 'GET');
      final session = live.session;

      // Best-effort: not every server supports/allows listing principals, and
      // being listed here does not guarantee --impersonate will actually
      // succeed against it, the server still enforces that separately.
      final otherPrincipals = await _listOtherPrincipals(live);

      // What the current account has shared out with others, across every
      // resource type that supports sharing. Only includes resources with a
      // non-empty shareWith, not everything owned.
      final sharedMailboxes = await _listSharedMailboxes(live);
      final sharedFileNodes = await _listSharedFileNodes(live);

      if (args['json'] == true) {
        final accounts = session.accounts.map((id, account) => MapEntry(
              id.id.value,
              {
                'name': account.name.value,
                'isPersonal': account.isPersonal,
                'isReadOnly': account.isReadOnly,
                'capabilities': account.accountCapabilities.keys
                    .map((c) => c.value.toString())
                    .toList(),
              },
            ));
        print(jsonEncode({
          'username': session.username.value,
          'primaryAccountId': live.accountId.id.value,
          'accounts': accounts,
          'otherPrincipalsSeen': otherPrincipals,
          'sharedByMe': {
            'mailboxes': sharedMailboxes.map((r) => r.toJson()).toList(),
            'fileNodes': sharedFileNodes.map((r) => r.toJson()).toList(),
          },
        }));
        return 0;
      }

      print('Logged in as   : ${session.username.value}');
      print('Primary account: ${live.accountId.id.value}');
      print('');
      print('Accounts you can access:');
      for (final entry in session.accounts.entries) {
        final id = entry.key.id.value;
        final account = entry.value;
        final kind = account.isPersonal ? 'personal' : 'shared/delegated';
        final access = account.isReadOnly ? 'read-only' : 'read-write';
        print('  - $id  (${account.name.value})  [$kind, $access]');
      }

      if (otherPrincipals.isNotEmpty) {
        print('');
        print('Other accounts that exist on this server (not confirmed accessible,');
        print('try --impersonate <email> on a command to check):');
        for (final email in otherPrincipals) {
          print('  - $email');
        }
      }

      if (sharedMailboxes.isNotEmpty || sharedFileNodes.isNotEmpty) {
        print('');
        print('Things you have shared with others:');
        for (final entry in sharedMailboxes) {
          print('  - mailbox "${entry.name}" (${entry.id}) shared with: ${entry.sharedWithIds.join(', ')}');
        }
        for (final entry in sharedFileNodes) {
          print('  - file "${entry.name}" (${entry.id}) shared with: ${entry.sharedWithIds.join(', ')}');
        }
      }
      return 0;
    } catch (e) {
      print('Error: $e');
      return 1;
    }
  }

  /// Lists other principals visible via Principal/query, excluding accounts
  /// already listed in the session's own accounts map. Returns an empty list
  /// (rather than throwing) if the server doesn't support/allow this, since
  /// this is a supplementary hint, not core to the command.
  Future<List<String>> _listOtherPrincipals(JmapLiveClient live) async {
    try {
      final ownIds = live.session.accounts.keys.map((id) => id.id.value).toSet();

      final body = {
        'using': ['urn:ietf:params:jmap:core', 'urn:ietf:params:jmap:principals'],
        'methodCalls': [
          [
            'Principal/query',
            {'accountId': live.accountId.id.value},
            'c0',
          ],
          [
            'Principal/get',
            {
              'accountId': live.accountId.id.value,
              '#ids': {
                'resultOf': 'c0',
                'name': 'Principal/query',
                'path': '/ids',
              },
              'properties': ['email'],
            },
            'c1',
          ],
        ],
      };

      final response = await live.httpClient.post('', data: body);
      final methodResponses = response['methodResponses'] as List;
      final getResult = methodResponses[1][1] as Map<String, dynamic>;
      final list = getResult['list'] as List? ?? [];

      return list
          .cast<Map<String, dynamic>>()
          .where((principal) => !ownIds.contains(principal['id']))
          .map((principal) => principal['email'] as String)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<_SharedResource>> _listSharedMailboxes(JmapLiveClient live) async {
    try {
      final resp = await MailboxUtil.getMailboxes(
        client: live.httpClient,
        accountId: live.accountId,
        properties: {'id', 'name', 'shareWith'},
      );

      return resp.list
          .where((mailbox) => mailbox.shareWith != null && mailbox.shareWith!.isNotEmpty)
          .map((mailbox) => _SharedResource(
                id: mailbox.id?.id.value ?? '?',
                name: mailbox.name?.name ?? '(unnamed)',
                sharedWithIds: mailbox.shareWith!.keys.toList(),
              ))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<_SharedResource>> _listSharedFileNodes(JmapLiveClient live) async {
    try {
      final resp = await FileNodeUtil.getFileNodes(
        client: live.httpClient,
        accountId: live.accountId,
      );

      return resp.list
          .where((node) => node.shareWith != null && node.shareWith!.isNotEmpty)
          .map((node) => _SharedResource(
                id: node.id?.value ?? '?',
                name: node.name ?? '(unnamed)',
                sharedWithIds: node.shareWith!.keys.toList(),
              ))
          .toList();
    } catch (_) {
      return [];
    }
  }
}

class _SharedResource {
  final String id;
  final String name;
  final List<String> sharedWithIds;

  _SharedResource({required this.id, required this.name, required this.sharedWithIds});

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'sharedWithIds': sharedWithIds};
}
