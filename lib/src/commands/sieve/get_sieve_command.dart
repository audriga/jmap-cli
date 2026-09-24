import 'dart:convert';
import 'package:jmap_cli/src/commands/base_command.dart';
import 'package:jmap_dart_client/jmap/account_id.dart';
import 'package:jmap_dart_client/jmap/core/id.dart';
import 'package:jmap_dart_client/util/sieve_util.dart';

class GetSieveCommand extends BaseCommand {
  @override
  final name = 'get';

  @override
  List<String> get aliases => ['sieve.get'];

  @override
  final description = 'Get sieve scripts or a single script by id';

  @override
  Future<int> run() async {
    try {
      final args = argResults;
      if (args == null) return 1;

      final live = await buildClientAndAccount(args, 'GET');
      final accountId = AccountId(Id(args['accountId'] ?? live.accountId.id.value));
      final id = args['id'];

      if (id != null && id is String && id.isNotEmpty) {
        final script = await SieveUtil.getSieveScriptById(
          client: live.httpClient,
          accountId: accountId,
          id: id,
        );

        if (script == null) {
          print('Sieve script not found');
          return 1;
        }

        print(jsonEncode(script));
        return 0;
      }

      final resp = await SieveUtil.getSieveScripts(
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
