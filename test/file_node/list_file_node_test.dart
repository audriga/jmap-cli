import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
void main() {
  group('CLI FileNode tests – real API', () {
    test('Command: list root folder using path', () async {
      final auth = await jsonDecode(await File('test/data/credentials/auth_ietf.json').readAsString());

      final process = await Process.start('dart', ['bin/jmap_cli.dart',
        'fileNodes',
        'list',
        '--path',
        '/',
        '--url',
        auth['url'],
        '-u',
        auth['username'],
        '-p',
        auth['password'],
      ]);

      final stdoutData = await process.stdout.transform(utf8.decoder).join();
      final stderrData = await process.stderr.transform(utf8.decoder).join();
      final exitCode = await process.exitCode;

      expect(exitCode, 0, reason: stderrData);
      expect(stdoutData.trim().isNotEmpty, true);
    }, timeout: Timeout(Duration(seconds: 300)));

    test('Command: list inside a folder if it exists', () async {
      final auth = await jsonDecode(await File('test/data/credentials/auth_ietf.json').readAsString());

      final process = await Process.start('dart', ['bin/jmap_cli.dart',
        'fileNodes',
        'list',
        '--path',
        'NewTestFolder',
        '--url',
        auth['url'],
        '-u',
        auth['username'],
        '-p',
        auth['password'],
      ]);

      final stdoutData = await process.stdout.transform(utf8.decoder).join();
      final exitCode = await process.exitCode;

      expect(exitCode, 0);
      expect(stdoutData, isNotNull);
    }, timeout: Timeout(Duration(seconds: 300)));

    test('Command: list nested folder (if exists)', () async {
      final auth = await jsonDecode(await File('test/data/credentials/auth_ietf.json').readAsString());

      final process = await Process.start('dart', ['bin/jmap_cli.dart',
        'fileNodes',
        'list',
        '--path',
        'NewTestFolder/Docs',
        '--url',
        auth['url'],
        '-u',
        auth['username'],
        '-p',
        auth['password'],
      ]);

      final stdoutData = await process.stdout.transform(utf8.decoder).join();
      final exitCode = await process.exitCode;

      expect(exitCode, 0);
      expect(stdoutData, isNotNull);
    }, timeout: Timeout(Duration(seconds: 300)));
  });
}
