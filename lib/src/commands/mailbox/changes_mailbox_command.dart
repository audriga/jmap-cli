import 'dart:convert';
import 'package:jmap_cli/src/commands/base_command.dart';
import 'package:jmap_dart_client/jmap/account_id.dart';
import 'package:jmap_dart_client/jmap/core/id.dart';
import 'package:jmap_dart_client/jmap/core/state.dart';
import 'package:jmap_dart_client/util/mailbox_util.dart';

class ChangesMailboxCommand extends BaseCommand {
  @override
  final name = 'changes';

  @override
  List<String> get aliases => ['mailbox.changes'];

  @override
  final description = 'Get change information for mailboxes as JSON';

  ChangesMailboxCommand() {
    argParser.addOption(
      'state',
      help: 'The previous state to check changes from. If omitted, fetches current state first.',
    );
  }

  @override
  Future<int> run() async {
    try {
      if (argResults == null) return 1;

      final live = await buildClientAndAccount(argResults!, 'GET');
      final accountId = AccountId(Id(argResults!['accountId'] ?? live.accountId.id.value));

      State fromState;
      final stateArg = argResults!['state'];

      if (stateArg != null && stateArg.trim().isNotEmpty) {
        fromState = State(stateArg.trim());
      } else {
        final getResp = await MailboxUtil.getMailboxes(
          client: live.httpClient,
          accountId: accountId,
        );
        fromState = getResp.state;
      }

      final changes = await MailboxUtil.changesMailboxes(
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
    } catch (e) {
      print('Error: $e');
      return 1;
    }
  }
}
