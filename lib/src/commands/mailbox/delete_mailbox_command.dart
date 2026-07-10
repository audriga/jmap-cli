import 'package:jmap_cli/src/commands/base_command.dart';
import 'package:jmap_dart_client/jmap/account_id.dart';
import 'package:jmap_dart_client/jmap/core/id.dart';
import 'package:jmap_dart_client/util/mailbox_util.dart';

class DeleteMailboxCommand extends BaseCommand {
  @override
  final name = 'delete';

  @override
  List<String> get aliases => ['mailbox.delete'];

  @override
  final description = 'Delete a mailbox by id';

  DeleteMailboxCommand() {
    argParser.addFlag(
      'removeEmails',
      help: 'Also delete all emails within the mailbox.',
      defaultsTo: false,
    );
  }

  @override
  Future<int> run() async {
    try {
      if (argResults == null) return 1;

      final idArg = argResults!['id'];
      if (idArg == null || idArg.toString().trim().isEmpty) {
        print('Error: --id is required');
        return 1;
      }

      final removeEmails = argResults!['removeEmails'] as bool? ?? false;

      final live = await buildClientAndAccount(argResults!, 'POST');
      final accountId = AccountId(Id(argResults!['accountId'] ?? live.accountId.id.value));

      final resp = await MailboxUtil.deleteMailbox(
        client: live.httpClient,
        accountId: accountId,
        id: Id(idArg),
        removeEmails: removeEmails,
      );

      if (resp.destroyed != null && resp.destroyed!.isNotEmpty) {
        print('Mailbox successfully deleted!');
        return 0;
      }

      print('Mailbox could not be deleted!');
      return 1;
    } catch (e) {
      print('Error: $e');
      return 1;
    }
  }
}
