import 'package:jmap_cli/jmap_cli.dart';
import 'package:jmap_cli/src/commands/base_command.dart';

class IdentityCommand extends BaseCommand {
  @override
  final name = 'identity';

  @override
  final description = 'Manage JMAP Identity';

  IdentityCommand() {
    addSubcommand(GetIdentityCommand());
  }

  @override
  Future<int> run() async {
    print('Usage: jmap-cli Identity <command> [options]');
    print('');
    print('Available commands:');
    print('  get        Get Identity');
    return 1;
  }
}
