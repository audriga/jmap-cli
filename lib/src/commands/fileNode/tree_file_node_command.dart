import 'package:jmap_cli/src/commands/base_command.dart';
import 'package:jmap_dart_client/jmap/file_node/file_node.dart';
import 'package:jmap_dart_client/jmap/file_node/path_resolver.dart';
import 'package:jmap_dart_client/util/file_node_util.dart';

class FileNodesTreeCommand extends BaseCommand {
  @override
  final name = 'tree';

  @override
  final description =
      'Recursively list FileNodes in a tree-like structure';

  FileNodesTreeCommand() {
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

      final client = live.httpClient;
      final accountId = live.accountId;
      final path = argResults!['path'] as String? ?? '/';

      final resp = await FileNodeUtil.getFileNodes(
        client: client,
        accountId: accountId,
      );

      final resolver = FileNodePathResolver(resp.list);

      final root = path == '/' ? null : resolver.resolve(path);

      if (path != '/' && root == null) {
        print('Path not found: $path');
        return 1;
      }

      _printTree(
        resolver: resolver,
        node: root,
        prefix: '',
        isLast: true,
      );

      return 0;
    } catch (e) {
      print('Error: $e');
      return 1;
    }
  }

  void _printTree({
    required FileNodePathResolver resolver,
    FileNode? node,
    required String prefix,
    required bool isLast,
  }) {
    final children =
        resolver.listChildren(node?.id?.value).toList();

    for (var i = 0; i < children.length; i++) {
      final child = children[i];
      final last = i == children.length - 1;

      final connector = last ? '└── ' : '├── ';
      final nextPrefix = prefix + (last ? '    ' : '│   ');

      final name =
          child.blobId == null ? '${child.name}/' : child.name;

      print('$prefix$connector$name');

      if (child.blobId == null) {
        _printTree(
          resolver: resolver,
          node: child,
          prefix: nextPrefix,
          isLast: last,
        );
      }
    }
  }
}
