import 'package:jmap_cli/src/commands/base_command.dart';
import 'package:jmap_dart_client/jmap/account_id.dart';
import 'package:jmap_dart_client/jmap/core/id.dart';
import 'package:jmap_dart_client/util/sieve_util.dart';

class ActivateSieveCommand extends BaseCommand {
  @override
  final name = 'activate';

  @override
  List<String> get aliases => ['sieve.activate'];

  @override
  final description = 'Activate a sieve script by id';

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

      await SieveUtil.activateSieveScript(
        client: live.httpClient,
        accountId: accountId,
        id: idArg,
      );

      print('Sieve script activated!');
      return 0;
    } catch (e) {
      print('Error: $e');
      return 1;
    }
  }
}
