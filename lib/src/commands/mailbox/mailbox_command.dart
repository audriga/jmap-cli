import 'package:jmap_cli/jmap_cli.dart';
import 'package:jmap_cli/src/commands/base_command.dart';

class MailboxCommand extends BaseCommand {
  @override
  final name = 'mailbox';

  @override
  final description = 'Manage JMAP mailboxes';

  MailboxCommand() {
    addSubcommand(GetMailboxCommand());
    addSubcommand(CreateMailboxCommand());
    addSubcommand(DeleteMailboxCommand());
    addSubcommand(ChangesMailboxCommand());
  }

  @override
  Future<int> run() async {
    print('Usage: jmap-cli mailbox <command> [options]');
    print('');
    print('Available commands:');
    print('  get        Get mailboxes or a single mailbox by id');
    print('  create     Create a mailbox');
    print('  delete     Delete a mailbox');
    print('  changes    Show mailbox changes since a given state');
    return 1;
  }
}
