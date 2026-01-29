import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CLI Calendar tests', () {
    test('calendar create', () async {
      final auth = jsonDecode(
        await File('test/data/credentials/auth_ietf.json').readAsString(),
      );

      final name = 'CLI Calendar ${DateTime.now().millisecondsSinceEpoch}';

      final process = await Process.start('dart', [
        'bin/jmap_cli.dart',
        'calendar',
        'create',
        '--name',
        name,
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

      expect(exitCode, 0, reason: stdoutData + stderrData);
      expect(stdoutData.trim().isNotEmpty, true);
    }, timeout: const Timeout(Duration(seconds: 300)));

    test('calendar get list', () async {
      final auth = jsonDecode(
        await File('test/data/credentials/auth_ietf.json').readAsString(),
      );

      final process = await Process.start('dart', [
        'bin/jmap_cli.dart',
        'calendar',
        'get',
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

      expect(exitCode, 0, reason: stdoutData + stderrData);

      final decoded = jsonDecode(stdoutData);
      expect(decoded, isNotNull);
    }, timeout: const Timeout(Duration(seconds: 300)));

    test('calendar changes', () async {
      final auth = jsonDecode(
        await File('test/data/credentials/auth_ietf.json').readAsString(),
      );

      final process = await Process.start('dart', [
        'bin/jmap_cli.dart',
        'calendar',
        'changes',
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

      expect(exitCode, 0, reason: stdoutData + stderrData);

      final decoded = jsonDecode(stdoutData);
      expect(decoded, isNotNull);
    }, timeout: const Timeout(Duration(seconds: 300)));

    test('calendar delete', () async {
      final auth = jsonDecode(
        await File('test/data/credentials/auth_ietf.json').readAsString(),
      );

      final name = 'CLI Calendar ${DateTime.now().millisecondsSinceEpoch}';

      final createProcess = await Process.start('dart', [
        'bin/jmap_cli.dart',
        'calendar',
        'create',
        '--name',
        name,
        '--url',
        auth['url'],
        '-u',
        auth['username'],
        '-p',
        auth['password'],
      ]);

      final createOut = await createProcess.stdout.transform(utf8.decoder).join();
      final createErr = await createProcess.stderr.transform(utf8.decoder).join();
      final createExit = await createProcess.exitCode;

      expect(createExit, 0, reason: createOut + createErr);

      final createdId = createOut.trim();
      expect(createdId.isNotEmpty, true);

      final deleteProcess = await Process.start('dart', [
        'bin/jmap_cli.dart',
        'calendar',
        'delete',
        '--id',
        createdId,
        '--url',
        auth['url'],
        '-u',
        auth['username'],
        '-p',
        auth['password'],
      ]);

      final deleteOut = await deleteProcess.stdout.transform(utf8.decoder).join();
      final deleteErr = await deleteProcess.stderr.transform(utf8.decoder).join();
      final deleteExit = await deleteProcess.exitCode;

      expect(deleteExit, 0, reason: deleteOut + deleteErr);
    }, timeout: const Timeout(Duration(seconds: 300)));
  });
}
