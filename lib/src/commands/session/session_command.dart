import 'package:jmap_cli/jmap_cli.dart';
import 'package:jmap_cli/src/commands/base_command.dart';

class SessionCommand extends BaseCommand {
  @override
  final name = 'session';

  @override
  final description = 'Manage JMAP Sessions';

  SessionCommand() {
    addSubcommand(GetSessionCommand());
  }

  @override
  Future<int> run() async {
    print('Usage: jmap-cli Sessions <command> [options]');
    print('');
    print('Available commands:');
    print('  get        Get Sessions');
    return 1;
  }
}
