import 'dart:convert';
import 'package:jmap_cli/src/commands/base_command.dart';
import 'package:jmap_dart_client/jmap/account_id.dart';
import 'package:jmap_dart_client/jmap/core/error/method/error_method_response.dart';
import 'package:jmap_dart_client/jmap/core/error/method/exception/error_method_response_exception.dart';
import 'package:jmap_dart_client/jmap/core/id.dart';
import 'package:jmap_dart_client/jmap/core/state.dart';
import 'package:jmap_dart_client/util/sieve_util.dart';

class ChangesSieveCommand extends BaseCommand {
  @override
  final name = 'changes';

  @override
  List<String> get aliases => ['sieve.changes'];

  @override
  final description = 'Get change information for sieve scripts as JSON';

  ChangesSieveCommand() {
    argParser.addOption(
      'state',
      help: 'The previous state to check changes from. If omitted, fetches current state first.',
    );
  }

  @override
  Future<int> run() async {
    try {
      final args = argResults;
      if (args == null) return 1;

      final live = await buildClientAndAccount(args, 'GET');
      final accountId = AccountId(Id(args['accountId'] ?? live.accountId.id.value));

      State fromState;
      final stateArg = args['state'];

      if (stateArg != null && stateArg.trim().isNotEmpty) {
        fromState = State(stateArg.trim());
      } else {
        final getResp = await SieveUtil.getSieveScripts(
          client: live.httpClient,
          accountId: accountId,
        );
        fromState = getResp.state;
      }

      final changes = await SieveUtil.changesSieveScripts(
        client: live.httpClient,
        accountId: accountId,
        sinceState: fromState,
      );

      print(jsonEncode({
        'accountId': changes.accountId.id.value,
        'oldState': changes.oldState.value,
        'newState': changes.newState.value,
        'hasMoreChanges': changes.hasMoreChanges,
        'created': changes.created.map((id) => id.value).toList(),
        'updated': changes.updated.map((id) => id.value).toList(),
        'destroyed': changes.destroyed.map((id) => id.value).toList(),
      }));
      return 0;
    } on ErrorMethodResponseException catch (e) {
      final errorResponse = e.errorResponse;
      if (errorResponse is ErrorMethodResponse &&
          errorResponse.type == ErrorMethodResponse.unknownMethod) {
        print('Error: this server does not support SieveScript/changes.');
        return 1;
      }
      print('Error: $e');
      return 1;
    } catch (e) {
      print('Error: $e');
      return 1;
    }
  }
}
