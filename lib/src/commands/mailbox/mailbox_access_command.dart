import 'dart:convert';
import 'package:jmap_cli/src/commands/base_command.dart';
import 'package:jmap_dart_client/jmap/account_id.dart';
import 'package:jmap_dart_client/jmap/core/id.dart';
import 'package:jmap_dart_client/util/mailbox_util.dart';

class MailboxAccessCommand extends BaseCommand {
  @override
  final name = 'access';

  @override
  List<String> get aliases => ['mailbox.access'];

  @override
  final description = 'Show who has been given access to one of your mailboxes';

  MailboxAccessCommand() {
    argParser.addFlag('json', help: 'Print raw JSON instead of a formatted summary.', negatable: false);
  }

  @override
  Future<int> run() async {
    try {
      final args = argResults;
      if (args == null) return 1;

      final mailboxId = args['id'] as String?;
      if (mailboxId == null || mailboxId.trim().isEmpty) {
        print('Error: --id is required (the mailbox to check)');
        return 1;
      }

      final live = await buildClientAndAccount(args, 'GET');
      final accountId = AccountId(Id(args['accountId'] ?? live.accountId.id.value));

      final mailbox = await MailboxUtil.getMailboxById(
        client: live.httpClient,
        accountId: accountId,
        id: mailboxId,
        properties: {'id', 'name', 'shareWith'},
      );

      if (mailbox == null) {
        print('Mailbox not found');
        return 1;
      }

      final shareWith = mailbox.shareWith;

      if (args['json'] == true) {
        print(jsonEncode(shareWith ?? {}));
        return 0;
      }

      print('Mailbox: ${mailbox.name?.name ?? mailboxId} ($mailboxId)');
      print('');

      if (shareWith == null || shareWith.isEmpty) {
        print('Not shared with anyone.');
        return 0;
      }

      print('Shared with:');
      for (final entry in shareWith.entries) {
        final rights = entry.value;
        final granted = <String>[
          if (rights.mayReadItems) 'read',
          if (rights.mayAddItems) 'add',
          if (rights.mayRemoveItems) 'remove',
          if (rights.maySetSeen) 'setSeen',
          if (rights.maySetKeywords) 'setKeywords',
          if (rights.mayCreateChild) 'createChild',
          if (rights.mayRename) 'rename',
          if (rights.mayDelete) 'delete',
          if (rights.maySubmit) 'submit',
          if (rights.mayShare == true) 'share',
        ];
        print('  - ${entry.key}: ${granted.isEmpty ? '(no rights)' : granted.join(', ')}');
      }
      return 0;
    } catch (e) {
      print('Error: $e');
      return 1;
    }
  }
}
