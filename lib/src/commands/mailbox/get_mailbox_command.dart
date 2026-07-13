import 'dart:convert';
import 'package:jmap_cli/src/commands/base_command.dart';
import 'package:jmap_dart_client/jmap/account_id.dart';
import 'package:jmap_dart_client/jmap/core/id.dart';
import 'package:jmap_dart_client/util/mailbox_util.dart';

class GetMailboxCommand extends BaseCommand {
  @override
  final name = 'get';

  @override
  List<String> get aliases => ['mailbox.get'];

  @override
  final description = 'Get mailboxes or a single mailbox by id';

  GetMailboxCommand() {
    argParser.addFlag('all', help: 'Fetch all mailboxes using paged queries (for large accounts).');
  }

  @override
  Future<int> run() async {
    try {
      final args = argResults;
      if (args == null) return 1;

      final live = await buildClientAndAccount(args, 'GET');
      final accountId = AccountId(Id(args['accountId'] ?? live.accountId.id.value));
      final id = args['id'];

      if (id != null && id is String && id.isNotEmpty) {
        final mailbox = await MailboxUtil.getMailboxById(
          client: live.httpClient,
          accountId: accountId,
          id: id,
        );

        if (mailbox == null) {
          print('Mailbox not found');
          return 1;
        }

        print(jsonEncode(mailbox));
        return 0;
      }

      if (args['all'] == true) {
        final mailboxes = await MailboxUtil.getAllMailboxes(
          client: live.httpClient,
          accountId: accountId,
        );
        print(jsonEncode(mailboxes));
        return 0;
      }

      final resp = await MailboxUtil.getMailboxes(
        client: live.httpClient,
        accountId: accountId,
      );

      print(jsonEncode(resp));
      return 0;
    } catch (e) {
      print('Error: $e');
      return 1;
    }
  }
}
