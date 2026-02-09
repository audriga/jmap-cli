import 'package:jmap_cli/src/commands/base_command.dart';
import 'package:jmap_dart_client/jmap/core/id.dart';
import 'package:jmap_dart_client/jmap/file_node/path_resolver.dart';
import 'package:jmap_dart_client/util/file_node_util.dart';

class FileNodesRmCommand extends BaseCommand {
  @override
  final name = 'rm';

  @override
  final description = 'Delete file or directory';

  FileNodesRmCommand() {
    argParser.addFlag(
      'recursive',
      abbr: 'r',
      negatable: false,
      help: 'Delete a folder and everything inside it.',
    );
  }

  @override
  Future<int> run() async {
    try {
      if (argResults == null || argResults!.rest.isEmpty) {
        print('Missing path');
        return 1;
      }

      final recursive = argResults!['recursive'] == true;
      final rawPath = argResults!.rest.first;
      final normalized =
          rawPath.replaceFirst('jmap:', '').replaceAll(RegExp('^/+'), '');

      if (normalized.isEmpty) {
        print('Invalid path');
        return 1;
      }

      final live = await buildClientAndAccount(argResults!, 'POST');

      final resp = await FileNodeUtil.getFileNodes(
        client: live.httpClient,
        accountId: live.accountId,
      );

      final resolver = FileNodePathResolver(resp.list);
      final node = resolver.resolve(normalized);

      if (node == null || node.id == null) {
        print('Path not found: $rawPath');
        return 1;
      }

      final idsToDelete = <Id>{};

      if (node.blobId == null) {
        final children = resolver.listChildren(node.id!.value);

        if (children.isNotEmpty && !recursive) {
          print('Directory not empty. Use -r to delete recursively.');
          return 1;
        }

        if (recursive) {
          for (final child in _collectRecursive(resolver, node)) {
            if (child.id != null) {
              idsToDelete.add(child.id!);
            }
          }
        }
      }

      idsToDelete.add(node.id!);

      await FileNodeUtil.setFileNodes(
        client: live.httpClient,
        accountId: live.accountId,
        destroy: idsToDelete,
      );

      print('Deleted: $rawPath');
      return 0;
    } catch (e) {
      print('Error: $e');
      return 1;
    }
  }
  /// Recursively collects all files and folders under the given node.
  Iterable<dynamic> _collectRecursive(
    FileNodePathResolver resolver,
    dynamic node,
  ) sync* {
    final children = resolver.listChildren(node.id!.value);
    for (final child in children) {
      if (child.blobId == null) {
        yield* _collectRecursive(resolver, child);
      }
      yield child;
    }
  }
}
