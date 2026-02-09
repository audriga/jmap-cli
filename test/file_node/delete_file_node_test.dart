import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:jmap_cli/src/common/jmap_util.dart';

void main() {
  group('CLI FileNode tests: rm', () {
    test('fileNodes rm deletes a file', () async {
      final auth = await jsonDecode(
        await File('test/data/credentials/auth_ietf.json').readAsString(),
      );

      final localFile = File('rm_test_file.txt');
      await localFile.writeAsString('delete me');

      final remoteFile =
          JmapUtils().uniqueFileName('rm_test_file.txt');
      final remotePath =
          'jmap:UploadTestFolder/$remoteFile';

      await Process.start('dart', [
        'bin/jmap_cli.dart',
        'fileNodes',
        'cp',
        localFile.path,
        remotePath,
        '--url',
        auth['url'],
        '-u',
        auth['username'],
        '-p',
        auth['password'],
      ]).then((p) async => p.exitCode);

      final process = await Process.start('dart', [
        'bin/jmap_cli.dart',
        'fileNodes',
        'rm',
        remotePath,
        '--url',
        auth['url'],
        '-u',
        auth['username'],
        '-p',
        auth['password'],
      ]);

      final stderrData =
          await process.stderr.transform(utf8.decoder).join();
      final exitCode = await process.exitCode;

      expect(exitCode, 0, reason: stderrData);

      await localFile.delete();
    }, timeout: const Timeout(Duration(seconds: 300)));

    test('fileNodes rm fails on non-empty directory without -r', () async {
      final auth = await jsonDecode(
        await File('test/data/credentials/auth_ietf.json').readAsString(),
      );

      final base =
          'rm_dir_${DateTime.now().millisecondsSinceEpoch}';
      final remoteDir = 'jmap:UploadTestFolder/$base';

      await Process.start('dart', [
        'bin/jmap_cli.dart',
        'fileNodes',
        'mkdir',
        remoteDir,
        '--url',
        auth['url'],
        '-u',
        auth['username'],
        '-p',
        auth['password'],
      ]).then((p) async => p.exitCode);

      final localFile = File('rm_dir_file.txt');
      await localFile.writeAsString('inside dir');

      await Process.start('dart', [
        'bin/jmap_cli.dart',
        'fileNodes',
        'cp',
        localFile.path,
        '$remoteDir/file.txt',
        '--url',
        auth['url'],
        '-u',
        auth['username'],
        '-p',
        auth['password'],
      ]).then((p) async => p.exitCode);

      final process = await Process.start('dart', [
        'bin/jmap_cli.dart',
        'fileNodes',
        'rm',
        remoteDir,
        '--url',
        auth['url'],
        '-u',
        auth['username'],
        '-p',
        auth['password'],
      ]);

      final exitCode = await process.exitCode;
      expect(exitCode, isNot(0));

      await localFile.delete();
    }, timeout: const Timeout(Duration(seconds: 300)));

    test('fileNodes rm -r deletes directory recursively', () async {
      final auth = await jsonDecode(
        await File('test/data/credentials/auth_ietf.json').readAsString(),
      );

      final base =
          'rm_recursive_${DateTime.now().millisecondsSinceEpoch}';
      final remoteDir = 'jmap:UploadTestFolder/$base';

      await Process.start('dart', [
        'bin/jmap_cli.dart',
        'fileNodes',
        'mkdir',
        '$remoteDir/a/b',
        '--url',
        auth['url'],
        '-u',
        auth['username'],
        '-p',
        auth['password'],
      ]).then((p) async => p.exitCode);

      final localFile = File('rm_recursive.txt');
      await localFile.writeAsString('recursive');

      await Process.start('dart', [
        'bin/jmap_cli.dart',
        'fileNodes',
        'cp',
        localFile.path,
        '$remoteDir/a/b/file.txt',
        '--url',
        auth['url'],
        '-u',
        auth['username'],
        '-p',
        auth['password'],
      ]).then((p) async => p.exitCode);

      final process = await Process.start('dart', [
        'bin/jmap_cli.dart',
        'fileNodes',
        'rm',
        '-r',
        remoteDir,
        '--url',
        auth['url'],
        '-u',
        auth['username'],
        '-p',
        auth['password'],
      ]);

      final stderrData =
          await process.stderr.transform(utf8.decoder).join();
      final exitCode = await process.exitCode;

      expect(exitCode, 0, reason: stderrData);

      await localFile.delete();
    }, timeout: const Timeout(Duration(seconds: 300)));
  });
}
