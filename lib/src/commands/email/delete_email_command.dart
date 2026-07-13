import 'package:jmap_cli/src/commands/base_command.dart';
import 'package:jmap_dart_client/jmap/account_id.dart';
import 'package:jmap_dart_client/jmap/core/id.dart';
import 'package:jmap_dart_client/util/email_util.dart';

class DeleteEmailCommand extends BaseCommand {
  @override
  final name = 'delete';

  @override
  List<String> get aliases => ['email.delete'];

  @override
  final description = 'Delete an email by id';

  @override
  Future<int> run() async {
    try {
      if (argResults == null) return 1;

      final idArg = argResults!['id'];
      if (idArg == null || idArg.toString().trim().isEmpty) {
        print('Error: --id is required');
        return 1;
      }

      final live = await buildClientAndAccount(argResults!, 'POST');
      final accountId = AccountId(Id(argResults!['accountId'] ?? live.accountId.id.value));

      final resp = await EmailUtil.deleteEmail(
        client: live.httpClient,
        accountId: accountId,
        id: Id(idArg),
      );

      if (resp.destroyed != null && resp.destroyed!.isNotEmpty) {
        print('Email successfully deleted!');
        return 0;
      }

      print('Email could not be deleted!');
      return 1;
    } catch (e) {
      print('Error: $e');
      return 1;
    }
  }
}
