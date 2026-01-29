import 'package:jmap_cli/jmap_cli.dart';
import 'package:jmap_cli/src/commands/base_command.dart';

class AddressBookCommand extends BaseCommand {
  @override
  final name = 'addressBook';

  @override
  final description = 'Manage JMAP AddressBook';

  AddressBookCommand() {
    addSubcommand(GetAddressBookCommand());
    addSubcommand(CreateAddressBookCommand());
    addSubcommand(ChangesAddressBookCommand());
    addSubcommand(DeleteAddressBookCommand());
  }

  @override
  Future<int> run() async {
    print('Usage: jmap-cli AddressBook <command> [options]');
    print('');
    print('Available commands:');
    print('  get        Get AddressBook or a single AddressBook by id');
    print('  create     Create a AddressBook event');
    print('  delete     Delete a AddressBook event');
    print('  changes    Show AddressBook event changes');
    return 1;
  }
}
