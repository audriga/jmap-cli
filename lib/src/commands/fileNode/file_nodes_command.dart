import 'package:jmap_cli/jmap_cli.dart';
import 'package:jmap_cli/src/commands/base_command.dart';

class FileNodesCommand extends BaseCommand {
  @override
  final name = 'fileNodes';

  @override
  final description = 'Manage JMAP FileNodes';

  FileNodesCommand() {
    addSubcommand(ListFileNodesCommand());
    addSubcommand(CopyFileNodesCommand());
    addSubcommand(FileNodesMkdirCommand());
    addSubcommand(FileNodesRmCommand());
    addSubcommand(FileNodesTreeCommand());
  }

  @override
  Future<int> run() async {
    print('Usage: jmap-cli fileNodes <command> [options]');
    print('');
    print('Available commands:');
    print('  list     List files and folders');
    print('  cp       Copy files between local and server');
    print('  mkdir    Create a directory on the server');
    print('  rm       Delete a file or directory');
    print('  tree     Show files and folders recursively');
    return 1;
  }
}
