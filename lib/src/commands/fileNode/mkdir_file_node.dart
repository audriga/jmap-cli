import 'package:jmap_cli/src/commands/base_command.dart';
import 'package:jmap_dart_client/jmap/core/id.dart';
import 'package:jmap_dart_client/jmap/file_node/path_resolver.dart';
import 'package:jmap_dart_client/util/file_node_util.dart';

class FileNodesMkdirCommand extends BaseCommand {
  @override
  final name = 'mkdir';

  @override
  final description = 'Create directory on server';

  FileNodesMkdirCommand();

  @override
  Future<int> run() async {
    try {
      if (argResults == null || argResults!.rest.isEmpty) {
        print('Missing directory path');
        return 1;
      }

      final rawPath = argResults!.rest.first;
      final normalized =
          rawPath.replaceFirst('jmap:', '').replaceAll(RegExp('^/+'), '');

      if (normalized.isEmpty) {
        print('Invalid directory path');
        return 1;
      }

      final live = await buildClientAndAccount(argResults!, 'POST');

      final parts = normalized.split('/').where((p) => p.isNotEmpty).toList();

      final all = await FileNodeUtil.getFileNodes(
        client: live.httpClient,
        accountId: live.accountId,
      );

      final resolver = FileNodePathResolver(all.list);

      Id? parentId;
      String currentPath = '';

      for (final part in parts) {
        currentPath = currentPath.isEmpty ? part : '$currentPath/$part';

        final existing = resolver.resolve(currentPath);
        if (existing != null && existing.blobId == null) {
          parentId = existing.id;
          continue;
        }

        final newId = await FileNodeUtil.createFolder(
          client: live.httpClient,
          accountId: live.accountId,
          name: part,
          parentId: parentId,
        );

        if (newId == null) {
          throw Exception('Failed to create folder: $currentPath');
        }

        parentId = Id(newId);
      }

      print('Directory created: $rawPath');
      return 0;
    } catch (e) {
      print('Error: $e');
      return 1;
    }
  }
}
