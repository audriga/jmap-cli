import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CLI FileNode tests: tree', () {
    test('fileNodes tree lists directory structure recursively', () async {
      final auth = await jsonDecode(
        await File('test/data/credentials/auth_ietf.json').readAsString(),
      );

      final base =
          'tree_test_${DateTime.now().millisecondsSinceEpoch}';
      final rootPath = 'jmap:UploadTestFolder/$base';

      await Process.start('dart', [
        'bin/jmap_cli.dart',
        'fileNodes',
        'mkdir',
        '$rootPath/a/b',
        '--url',
        auth['url'],
        '-u',
        auth['username'],
        '-p',
        auth['password'],
      ]).then((p) async => p.exitCode);

      final localFile = File('tree_test.txt');
      await localFile.writeAsString('tree');

      await Process.start('dart', [
        'bin/jmap_cli.dart',
        'fileNodes',
        'cp',
        localFile.path,
        '$rootPath/a/file.txt',
        '--url',
        auth['url'],
        '-u',
        auth['username'],
        '-p',
        auth['password'],
      ]).then((p) async => p.exitCode);

      await Process.start('dart', [
        'bin/jmap_cli.dart',
        'fileNodes',
        'cp',
        localFile.path,
        '$rootPath/a/b/file2.txt',
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
        'tree',
        '--path',
        'UploadTestFolder/$base',
        '--url',
        auth['url'],
        '-u',
        auth['username'],
        '-p',
        auth['password'],
      ]);

      final stdoutData =
          await process.stdout.transform(utf8.decoder).join();
      final stderrData =
          await process.stderr.transform(utf8.decoder).join();
      final exitCode = await process.exitCode;
      print(stdoutData);
      expect(exitCode, 0, reason: stderrData);
      expect(stdoutData.contains('a/'), true);
      expect(stdoutData.contains('file.txt'), true);
      expect(stdoutData.contains('b/'), true);
      expect(stdoutData.contains('file2.txt'), true);

      await localFile.delete();
    }, timeout: const Timeout(Duration(seconds: 300)));
  });

  group('CLI FileNode tests: tree (all filenodes)', () {
    test('fileNodes tree lists all filenodes from root', () async {
      final auth = await jsonDecode(
        await File('test/data/credentials/auth_ietf.json').readAsString(),
      );

      final process = await Process.start('dart', [
        'bin/jmap_cli.dart',
        'fileNodes',
        'tree',
        '--path',
        '/',
        '--url',
        auth['url'],
        '-u',
        auth['username'],
        '-p',
        auth['password'],
      ]);

      final stdoutData =
          await process.stdout.transform(utf8.decoder).join();
      final stderrData =
          await process.stderr.transform(utf8.decoder).join();
      final exitCode = await process.exitCode;
      print(stdoutData);
      expect(exitCode, 0, reason: stderrData);
      expect(stdoutData.trim().isNotEmpty, true);
    }, timeout: const Timeout(Duration(seconds: 300)));
  });
}
