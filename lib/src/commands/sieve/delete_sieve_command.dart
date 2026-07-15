import 'package:jmap_cli/src/commands/base_command.dart';
import 'package:jmap_dart_client/jmap/account_id.dart';
import 'package:jmap_dart_client/jmap/core/id.dart';
import 'package:jmap_dart_client/util/sieve_util.dart';

class DeleteSieveCommand extends BaseCommand {
  @override
  final name = 'delete';

  @override
  List<String> get aliases => ['sieve.delete'];

  @override
  final description = 'Delete a sieve script by id';

  @override
  Future<int> run() async {
    try {
      final args = argResults;
      if (args == null) return 1;

      final idArg = args['id'];
      if (idArg == null || idArg.toString().trim().isEmpty) {
        print('Error: --id is required');
        return 1;
      }

      final live = await buildClientAndAccount(args, 'POST');
      final accountId = AccountId(Id(args['accountId'] ?? live.accountId.id.value));

      final resp = await SieveUtil.deleteSieveScript(
        client: live.httpClient,
        accountId: accountId,
        id: idArg,
      );

      if (resp.destroyed != null && resp.destroyed!.isNotEmpty) {
        print('Sieve script successfully deleted!');
        return 0;
      }

      print('Sieve script could not be deleted!');
      return 1;
    } catch (e) {
      print('Error: $e');
      return 1;
    }
  }
}
