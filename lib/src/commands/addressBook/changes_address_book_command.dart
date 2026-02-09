import 'dart:convert';
import 'package:jmap_cli/src/commands/base_command.dart';
import 'package:jmap_dart_client/jmap/account_id.dart';
import 'package:jmap_dart_client/jmap/core/id.dart';
import 'package:jmap_dart_client/jmap/core/state.dart';
import 'package:jmap_dart_client/util/address_book_util.dart';

class ChangesAddressBookCommand extends BaseCommand {
  @override
  final name = 'changes';

  @override
  List<String> get aliases => ['addressBook.changes'];

  @override
  final description = 'Get change information of addressBook as JSON';

  ChangesAddressBookCommand() {
    argParser.addOption(
      'state',
      help:
          'The previous state to check changes from. If omitted, the current state will be fetched first.',
    );
  }

  @override
  Future<int> run() async {
    try {
      if (argResults == null) {
        print('Error: No arguments provided.');
        return 1;
      }

      final live = await buildClientAndAccount(argResults!, 'GET');
      final httpClient = live.httpClient;

      String accountId =
          argResults!['accountId'] ?? live.accountId.id.value;

      State fromState;
      final stateArg = argResults!['state'];

      if (stateArg != null && stateArg.trim().isNotEmpty) {
        fromState = State(stateArg.trim());
      } else {
        final getResp = await AddressBookUtil.getAddressBooks(
          client: httpClient,
          accountId: AccountId(Id(accountId)),
        );
        fromState = getResp.state;
      }

      final changes = await AddressBookUtil.changesAddressBooks(
        client: httpClient,
        accountId: AccountId(Id(accountId)),
        sinceState: fromState,
      );

      print(jsonEncode(changes));
      return 0;
    } catch (e) {
      print('Error: $e');
      return 1;
    }
  }
}
