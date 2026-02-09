import 'dart:convert';
import 'package:jmap_cli/src/commands/base_command.dart';
import 'package:jmap_cli/src/common/jmap_util.dart';
import 'package:jmap_dart_client/jmap/account_id.dart';
import 'package:jmap_dart_client/jmap/core/id.dart';
import 'package:jmap_dart_client/jmap/core/state.dart';
import 'package:jmap_dart_client/util/contact_util.dart';

class ChangesContactCommand extends BaseCommand {
  @override
  final name = 'changes';

  @override
  List<String> get aliases => ['contact.changes'];

  @override
  final description = 'Get change information of contacts as json';

  ChangesContactCommand() {
    argParser.addOption(
      'apiVersion',
      help: 'Select contacts API version: ietf (default), cyrus',
      allowed: ['ietf', 'cyrus'],
      defaultsTo: 'ietf',
    );
    argParser.addOption(
      'state',
      help: 'Previous state. If omitted, current state is fetched first.',
    );
  }

  @override
  Future<int> run() async {
    try {
      if (argResults == null) return 1;

      final apiVersionStr = argResults!['apiVersion'] ?? 'ietf';
      if (apiVersionStr == 'jscontact') {
        print('jscontact is not supported for changesCard');
        return 1;
      }

      final apiVersion = JmapUtils.parseApiVersion(apiVersionStr);
      final live = await buildClientAndAccount(argResults!, 'GET');

      final client = live.httpClient;
      final accountId = AccountId(
        Id(argResults!['accountId'] ?? live.accountId.id.value),
      );

      State fromState;
      final stateArg = argResults!['state'];

      if (stateArg != null && stateArg.trim().isNotEmpty) {
        fromState = State(stateArg.trim());
      } else {
        final getResp = await ContactUtil.getContacts(
          client: client,
          accountId: accountId,
          apiVersion: apiVersion,
        );
        fromState = getResp.state;
      }

      final changes = await ContactUtil.changesContacts(
        client: client,
        accountId: accountId,
        sinceState: fromState,
        apiVersion: apiVersion,
      );

      print(jsonEncode(changes));
      return 0;
    } catch (e) {
      print('Error: $e');
      return 1;
    }
  }
}
