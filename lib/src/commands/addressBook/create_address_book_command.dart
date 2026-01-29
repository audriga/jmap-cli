import 'package:jmap_cli/src/commands/base_command.dart';
import 'package:jmap_dart_client/jmap/account_id.dart';
import 'package:jmap_dart_client/jmap/address_book/address_book.dart';
import 'package:jmap_dart_client/jmap/core/id.dart';
import 'package:jmap_dart_client/util/address_book_util.dart';

class CreateAddressBookCommand extends BaseCommand {
  @override
  final name = 'create';

  @override
  List<String> get aliases => ['addressBook.create'];

  @override
  final description = 'Create a addressBook (only name)';

  CreateAddressBookCommand() {
    argParser.addOption(
      'name',
      abbr: 'n',
      help: 'AddressBook name',
    );
  }

  @override
  Future<int> run() async {
    try {
      if (argResults == null) return 1;

      final addressBookName = (argResults!['name'] as String?)?.trim();
      if (addressBookName == null || addressBookName.isEmpty) {
        print('Error: missing --name');
        return 1;
      }

      final live = await buildClientAndAccount(argResults!, 'POST');
      final accountId = AccountId(Id(argResults!['accountId'] ?? live.accountId.id.value));

      final resp = await AddressBookUtil.createAddressBook(
        client: live.httpClient,
        accountId: accountId,
        addressBook: AddressBook(name: addressBookName),
        );

      final created = resp.created?.values.first;
      final id = created?.id?.value;

      if (id != null && id.isNotEmpty) {
        print(id);
      } else {
        print('Error: AddressBook id not returned');
        return 1;
      }

      return 0;
    } catch (e) {
      print('Error: $e');
      return 1;
    }
  }
}
