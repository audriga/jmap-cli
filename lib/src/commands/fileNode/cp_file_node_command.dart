import 'dart:io';
import 'package:jmap_cli/src/commands/base_command.dart';
import 'package:jmap_dart_client/http/http_client.dart';
import 'package:jmap_dart_client/jmap/account_id.dart';
import 'package:jmap_dart_client/jmap/file_node/file_node.dart';
import 'package:jmap_dart_client/jmap/file_node/path_resolver.dart';
import 'package:jmap_dart_client/util/file_node_util.dart';

/// CLI command to copy files between local filesystem and JMAP FileNodes.
/// Supports single file copy and recursive folder copy when -r is used.
class CopyFileNodesCommand extends BaseCommand {
  @override
  final name = 'cp';

  @override
  List<String> get aliases => ['fileNodes.cp'];

  @override
  final description =
    'Copy files between the local filesystem and JMAP FileNodes. '
    'Use the jmap: prefix to read from or write to the server.';
  CopyFileNodesCommand() {
    argParser
      .addFlag(
        'recursive',
        abbr: 'r',
        negatable: false,
        help: 'Copy a folder and everything inside it.',
      );
  }

  @override
  Future<int> run() async {
    String? src;
    String? dest;

    final rest = argResults!.rest;
    if (rest.length == 2) {
      src = rest[0];
      dest = rest[1];
    } else {
      print('Error! Usage: jmap-cli cp <source> <destination>');
    }

    if (src == null || dest == null) {
      print('Error! Usage: jmap-cli cp <source> <destination>');
      return 1;
    }

    final recursive = argResults!['recursive'] == true;
    final srcIsJmap = src.startsWith('jmap:');
    final destIsJmap = dest.startsWith('jmap:');

    // Exactly one side must be a JMAP path
    if (srcIsJmap == destIsJmap) {
      print('Error: exactly one side must be jmap:');
      return 1;
    }

    final live = await buildClientAndAccount(argResults!, 'POST');

    // Remote to local copy
    if (srcIsJmap) {
      return _copyRemoteToLocal(
        live.httpClient,
        live.accountId,
        src.substring(5),
        dest,
        recursive,
      );
    }

    // Local to remote copy
    return _copyLocalToRemote(
      live.httpClient,
      live.accountId,
      src,
      dest.substring(5),
      recursive,
    );
  }

  /// Copies a local file or folder to a remote JMAP destination.
  /// Uploading a folder copies all of its contents and requires the recursive flag.
  Future<int> _copyLocalToRemote(
    HttpClient client,
    AccountId accountId,
    String localPath,
    String jmapDest,
    bool recursive,
  ) async {
    final type = FileSystemEntity.typeSync(localPath);

    // Handle directory upload
    if (type == FileSystemEntityType.directory) {
      if (!recursive) {
        print('folder upload is not supported without -r');
        return 1;
      }

      final root = Directory(localPath);
      final destRoot = jmapDest.replaceFirst(RegExp('^/+'), '');

      await _uploadDirectoryRecursively(
        client,
        accountId,
        root,
        destRoot,
      );

      print('Folder uploaded successfully');
      return 0;
    }

    if (type == FileSystemEntityType.notFound) {
      print('Error: local path not found');
      return 1;
    }

    // Handle single file upload
    final file = File(localPath);
    final dest = jmapDest.replaceFirst(RegExp(r'^/+'), '');

    final isRootDest = dest.isEmpty;
    final isFolder = dest.endsWith('/');

    final filename = isRootDest || isFolder
        ? file.uri.pathSegments.last
        : dest.split('/').last;


    final folderPath = isFolder
        ? dest.substring(0, dest.length - 1)
        : dest.contains('/')
            ? dest.substring(0, dest.lastIndexOf('/'))
            : '';

    final folder = folderPath.isNotEmpty
        ? await FileNodeUtil.ensureFolderPath(
            client: client,
            accountId: accountId,
            folderPath: folderPath,
          )
        : null;

    await FileNodeUtil.uploadFile(
      client: client,
      accountId: accountId,
      name: filename,
      content: await file.readAsBytes(),
      parentId: folder?.id,
    );

    print('File uploaded successfully');
    return 0;
  }

  // Recursively uploads all files from the local [root] directory
  /// to the remote JMAP destination [destRoot].
  Future<void> _uploadDirectoryRecursively(
    HttpClient client,
    AccountId accountId,
    Directory root,
    String destRoot,
  ) async {
    // Walk through all files in the directory tree
    await for (final entity in root.list(recursive: true)) {

      //handle directories so empty folders are created
      if (entity is Directory) {
        final rel = entity.path.substring(root.path.length + 1);
        if (rel.isEmpty) continue;

        final folderPath = ('$destRoot/$rel')
            .replaceAll(RegExp(r'/+$'), ''); //final remote folder path with extra slashes removed

        // Ensure remote folder exists even if it is empty
        await FileNodeUtil.ensureFolderPath(
          client: client,
          accountId: accountId,
          folderPath: folderPath,
        );
        continue;
      }

      if (entity is! File) continue;

      final rel = entity.path.substring(root.path.length + 1); //file path relative to the local root folder
      final filename = rel.split('/').last; //name of the file
      final relDir = rel.substring(0, rel.length - filename.length); //relative directory containing the file
      final combinedPath = '$destRoot/$relDir';
      final folderPath = combinedPath.replaceAll(RegExp(r'/+$'), ''); //final remote folder path with extra slashes removed

      // Ensure remote folder structure exists
      final folder = folderPath.isNotEmpty
          ? await FileNodeUtil.ensureFolderPath(
              client: client,
              accountId: accountId,
              folderPath: folderPath,
            )
          : null;

      // Upload the file
      await FileNodeUtil.uploadFile(
        client: client,
        accountId: accountId,
        name: filename,
        content: await entity.readAsBytes(),
        parentId: folder?.id,
      );
    }
  }


  /// Copies a remote JMAP file or folder to the local filesystem.
  /// Folder download requires the recursive flag.
  Future<int> _copyRemoteToLocal(
    HttpClient client,
    AccountId accountId,
    String jmapPath,
    String localPath,
    bool recursive,
  ) async {
    final all = await FileNodeUtil.getFileNodes(
      client: client,
      accountId: accountId,
    );

    final resolver = FileNodePathResolver(all.list);
    final node = resolver.resolve(jmapPath);

    if (node == null) {
      print('Error: file not found');
      return 1;
    }

    // Handle single file download
    if (node.blobId != null) {
      final data = await FileNodeUtil.downloadFile(
        client: client,
        accountId: accountId,
        jmapPath: jmapPath,
      );

      await FileNodeUtil.writeDownloadedData(
        data: data,
        localPath: localPath,
      );

      print('File downloaded successfully');
      return 0;
    }

    if (!recursive) {
      print('folder download is not supported without -r');
      return 1;
    }

    // Handle recursive folder download
    await _downloadDirectoryRecursively(
      client,
      accountId,
      resolver,
      node,
      jmapPath,
      localPath,
    );

    print('Folder downloaded successfully');
    return 0;
  }
  /// Downloads all files from a remote folder and its subfolders
  // into the given local directory.
  Future<void> _downloadDirectoryRecursively(
    HttpClient client,
    AccountId accountId,
    FileNodePathResolver resolver,
    FileNode rootNode,
    String jmapPath,
    String localPath,
  ) async {
    final baseDir = Directory(localPath);
    baseDir.createSync(recursive: true);

    for (final entry in _collectRemoteFileNodes(resolver, rootNode, '')) {
      final fileNode = entry.node;
      final relPath = entry.relativePath;

      // Skip folders, only download files
      if (fileNode.blobId == null) continue;

      final outFile = File('${baseDir.path}/$relPath');
      outFile.parent.createSync(recursive: true);

      final data = await FileNodeUtil.downloadFile(
        client: client,
        accountId: accountId,
        jmapPath: '$jmapPath/$relPath',
      );

      await FileNodeUtil.writeDownloadedData(
        data: data,
        localPath: outFile.path,
      );
    }
  }

  /// Goes through the remote folder and its subfolders.
  /// Returns each file and folder with its path.
  Iterable<_RemoteEntry> _collectRemoteFileNodes(
    FileNodePathResolver resolver,
    FileNode node,
    String prefix,
  ) sync* {
    for (final child in resolver.listChildren(node.id!.value)) {
      final childPath =
          prefix.isEmpty ? child.name! : '$prefix/${child.name}';

      yield _RemoteEntry(child, childPath);

      // If this is a folder, go inside it
      if (child.blobId == null) {
        yield* _collectRemoteFileNodes(resolver, child, childPath);
      }
    }
  }
}

/// Holds a FileNode and its relative path during traversal.
class _RemoteEntry {
  final FileNode node;
  final String relativePath;

  _RemoteEntry(this.node, this.relativePath);
}
