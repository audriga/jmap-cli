import 'package:jmap_cli/src/commands/base_command.dart';
import 'package:jmap_dart_client/util/file_node_util.dart';

class ListFileNodesCommand extends BaseCommand {
  @override
  final name = 'list';

  @override
  List<String> get aliases => ['fileNodes.list'];

  @override
  final description = 'List FileNodes inside a given path (non-recursive).';

  ListFileNodesCommand() {
    argParser.addOption(
      'path',
      help: 'Path to list (e.g. "/", "docs", "work/projects")',
      defaultsTo: '/',
    );
  }

  @override
  Future<int> run() async {
    try {
      final live = await buildClientAndAccount(argResults!, 'GET');

      final httpClient = live.httpClient;
      final accountId = live.accountId;

      final path = argResults!['path'] as String? ?? '/';

      final children = await FileNodeUtil.listFolder(
        client: httpClient,
        accountId: accountId,
        path: path,
      );

      if (children.isEmpty) {
        print('(empty)');
        return 0;
      }

      for (final node in children) {
        if (node.blobId == null) {
          print('${node.name}/');
        } else {
          print(node.name);
        }
      }

      return 0;
    } catch (e, st) {
      print('Error: $e');
      print(st);
      return 1;
    }
  }
}
