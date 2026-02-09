import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CLI FileNode tests: mkdir', () {
    test('fileNodes mkdir creates remote directory', () async {
      final auth = await jsonDecode(
        await File('test/data/credentials/auth_ietf.json').readAsString(),
      );

      final dirName =
          'test_mkdir_${DateTime.now().millisecondsSinceEpoch}';
      final remotePath = 'jmap:UploadTestFolder/$dirName';

      final process = await Process.start('dart', [
        'bin/jmap_cli.dart',
        'fileNodes',
        'mkdir',
        remotePath,
        '--url',
        auth['url'],
        '-u',
        auth['username'],
        '-p',
        auth['password'],
      ]);
      final stdoutData =
          await process.stdout.transform(utf8.decoder).join();
      print(stdoutData);
      final stderrData =
          await process.stderr.transform(utf8.decoder).join();
      final exitCode = await process.exitCode;

      expect(exitCode, 0, reason: stderrData);
    }, timeout: const Timeout(Duration(seconds: 300)));

    test('fileNodes mkdir creates nested directories', () async {
      final auth = await jsonDecode(
        await File('test/data/credentials/auth_ietf.json').readAsString(),
      );

      final base =
          'nested_${DateTime.now().millisecondsSinceEpoch}';
      final remotePath = 'jmap:UploadTestFolder/$base/a/b/c';

      final process = await Process.start('dart', [
        'bin/jmap_cli.dart',
        'fileNodes',
        'mkdir',
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
    }, timeout: const Timeout(Duration(seconds: 300)));
  });
}
