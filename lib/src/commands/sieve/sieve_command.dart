import 'package:jmap_cli/jmap_cli.dart';
import 'package:jmap_cli/src/commands/base_command.dart';

class SieveCommand extends BaseCommand {
  @override
  final name = 'sieve';

  @override
  final description = 'Manage JMAP Sieve scripts';

  SieveCommand() {
    addSubcommand(GetSieveCommand());
    addSubcommand(CreateSieveCommand());
    addSubcommand(DeleteSieveCommand());
    addSubcommand(ChangesSieveCommand());
    addSubcommand(ActivateSieveCommand());
    addSubcommand(DeactivateSieveCommand());
  }

  @override
  Future<int> run() async {
    print('Usage: jmap-cli sieve <command> [options]');
    print('');
    print('Available commands:');
    print('  get          Get sieve scripts or a single script by id');
    print('  create       Create a sieve script');
    print('  delete       Delete a sieve script');
    print('  changes      Show sieve script changes since a given state');
    print('  activate     Activate a sieve script');
    print('  deactivate   Deactivate the currently active sieve script');
    return 1;
  }
}
