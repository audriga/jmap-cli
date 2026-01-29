import 'package:jmap_cli/src/commands/base_command.dart';
import 'package:jmap_dart_client/jmap/account_id.dart';
import 'package:jmap_dart_client/jmap/core/id.dart';
import 'package:jmap_dart_client/util/address_book_util.dart';

class DeleteAddressBookCommand extends BaseCommand {
  @override
  final name = 'delete';

  @override
  List<String> get aliases => ['addressBook.delete'];

  @override
  final description = 'Delete a addressBook by id';

  DeleteAddressBookCommand();

  @override
  Future<int> run() async {
    try {
      if (argResults == null) {
        print('Error: No arguments provided.');
        return 1;
      }

      final idArg = argResults!['id'];
      if (idArg == null || idArg.toString().trim().isEmpty) {
        print('Error: --id is required');
        return 1;
      }

      final live = await buildClientAndAccount(argResults!, 'POST');
      final httpClient = live.httpClient;

      final accountId =
          argResults!['accountId'] ?? live.accountId.id.value;

      final resp = await AddressBookUtil.deleteAddressBook(
        client: httpClient,
        accountId: AccountId(Id(accountId)),
        id: Id(idArg),
      );

      if (resp.destroyed != null && resp.destroyed!.isNotEmpty) {
        print('AddressBook successfully deleted!');
        return 0;
      }

      print('AddressBook could not be deleted!');
      return 1;
    } catch (e) {
      print('Error: $e');
      return 1;
    }
  }
}
