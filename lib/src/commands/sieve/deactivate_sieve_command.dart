import 'package:jmap_cli/src/commands/base_command.dart';
import 'package:jmap_dart_client/jmap/account_id.dart';
import 'package:jmap_dart_client/jmap/core/id.dart';
import 'package:jmap_dart_client/util/sieve_util.dart';

class DeactivateSieveCommand extends BaseCommand {
  @override
  final name = 'deactivate';

  @override
  List<String> get aliases => ['sieve.deactivate'];

  @override
  final description = 'Deactivate the currently active sieve script';

  @override
  Future<int> run() async {
    try {
      final args = argResults;
      if (args == null) return 1;

      final live = await buildClientAndAccount(args, 'POST');
      final accountId = AccountId(Id(args['accountId'] ?? live.accountId.id.value));

      await SieveUtil.deactivateActiveSieveScript(
        client: live.httpClient,
        accountId: accountId,
      );

      print('Sieve script deactivated!');
      return 0;
    } catch (e) {
      print('Error: $e');
      return 1;
    }
  }
}
