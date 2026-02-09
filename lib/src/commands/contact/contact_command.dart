import 'package:jmap_cli/jmap_cli.dart';
import 'package:jmap_cli/src/commands/base_command.dart';

class ContactCommand extends BaseCommand {
  @override
  final name = 'contact';

  @override
  final description = 'Manage JMAP contacts';

  ContactCommand() {
    addSubcommand(GetContactCommand());
    addSubcommand(CreateContactCommand());
    addSubcommand(DeletecontactCommand());
    addSubcommand(ChangesContactCommand());
  }

  @override
  Future<int> run() async {
    print('Usage: jmap-cli contacts <command> [options]');
    print('');
    print('Available commands:');
    print('  get        Get contacts or a single contact by id');
    print('  create     Create a contact');
    print('  delete     Delete a contact');
    print('  changes    Show contact changes');
    return 1;
  }
}
