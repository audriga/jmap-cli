import 'package:jmap_cli/src/commands/base_command.dart';
import 'package:jmap_dart_client/jmap/account_id.dart';
import 'package:jmap_dart_client/jmap/core/id.dart';
import 'package:jmap_dart_client/jmap/mail/mailbox/mailbox.dart';
import 'package:jmap_dart_client/util/mailbox_util.dart';

class CreateMailboxCommand extends BaseCommand {
  @override
  final name = 'create';

  @override
  List<String> get aliases => ['mailbox.create'];

  @override
  final description = 'Create a mailbox';

  CreateMailboxCommand() {
    argParser
      ..addOption('name', abbr: 'n', help: 'Name of the mailbox.', mandatory: true)
      ..addOption('parentId', help: 'Parent mailbox id (for nested mailboxes).');
  }

  @override
  Future<int> run() async {
    try {
      if (argResults == null) return 1;

      final nameArg = argResults!['name'];
      if (nameArg == null || nameArg.toString().trim().isEmpty) {
        print('Error: --name is required');
        return 1;
      }

      final parentIdArg = argResults!['parentId'];

      final live = await buildClientAndAccount(argResults!, 'POST');
      final accountId = AccountId(Id(argResults!['accountId'] ?? live.accountId.id.value));

      final mailbox = Mailbox(
        name: MailboxName(nameArg),
        parentId: parentIdArg != null ? MailboxId(Id(parentIdArg)) : null,
      );

      final resp = await MailboxUtil.createMailbox(
        client: live.httpClient,
        accountId: accountId,
        mailbox: mailbox,
      );

      final created = resp.created?.values.first;
      final id = created?.id?.id.value;

      if (id != null) {
        print(id);
        return 0;
      }

      print('Mailbox could not be created!');
      return 1;
    } catch (e) {
      print('Error: $e');
      return 1;
    }
  }
}
