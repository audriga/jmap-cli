import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CLI tests for sieve commands', () {
    late Map<String, dynamic> auth;
    late List<String> baseArgs;

    setUpAll(() async {
      final authFile = File('test/data/credentials/auth_ietf.json');
      auth = jsonDecode(await authFile.readAsString());
      baseArgs = [
        '--url', auth['url'].toString(),
        '-u', auth['username'].toString(),
        '-p', auth['password'].toString(),
      ];
    });

    test('sieve get returns valid JSON with list', () async {
      final process = await Process.start('dart', [
        'bin/jmap_cli.dart', 'sieve', 'get', ...baseArgs,
      ]);

      final output = await process.stdout.transform(utf8.decoder).join();
      final exitCode = await process.exitCode;

      print(output);
      expect(exitCode, equals(0));
      expect(isJSON(output), true);

      final json = jsonDecode(output);
      expect(json['accountId'], isNotNull);
      expect(json['list'], isList);
    }, timeout: Timeout(Duration(seconds: 300)));

    test('sieve create then get by id then delete', () async {
      var process = await Process.start('dart', [
        'bin/jmap_cli.dart', 'sieve', 'create', ...baseArgs,
        '--name', 'CLITestScript',
        '--content', 'require ["fileinto"];\nkeep;\n',
      ]);
      final createOutput = await process.stdout.transform(utf8.decoder).join();
      final createExit = await process.exitCode;

      print('Created sieve script id: $createOutput');
      expect(createExit, equals(0));
      expect(createOutput.trim(), isNotEmpty);

      final scriptId = createOutput.trim();

      process = await Process.start('dart', [
        'bin/jmap_cli.dart', 'sieve', 'get', ...baseArgs,
        '--id', scriptId,
      ]);
      final getOutput = await process.stdout.transform(utf8.decoder).join();
      final getExit = await process.exitCode;

      print(getOutput);
      expect(getExit, equals(0));
      expect(isJSON(getOutput), true);
      final getJson = jsonDecode(getOutput);
      expect(getJson['id'], equals(scriptId));
      expect(getJson['name'], equals('CLITestScript'));
      expect(getJson['isActive'], equals(false));

      process = await Process.start('dart', [
        'bin/jmap_cli.dart', 'sieve', 'delete', ...baseArgs,
        '--id', scriptId,
      ]);
      final deleteOutput = await process.stdout.transform(utf8.decoder).join();
      final deleteExit = await process.exitCode;

      print(deleteOutput);
      expect(deleteExit, equals(0));
      expect(deleteOutput.trim(), contains('deleted'));
    }, timeout: Timeout(Duration(seconds: 300)));

    test('sieve activate then deactivate a script', () async {
      var process = await Process.start('dart', [
        'bin/jmap_cli.dart', 'sieve', 'create', ...baseArgs,
        '--name', 'CLIActivateTestScript',
        '--content', 'require ["fileinto"];\nkeep;\n',
      ]);
      final createOutput = await process.stdout.transform(utf8.decoder).join();
      expect(await process.exitCode, equals(0));
      final scriptId = createOutput.trim();

      process = await Process.start('dart', [
        'bin/jmap_cli.dart', 'sieve', 'activate', ...baseArgs,
        '--id', scriptId,
      ]);
      final activateOutput = await process.stdout.transform(utf8.decoder).join();
      expect(await process.exitCode, equals(0));
      expect(activateOutput.trim(), contains('activated'));

      process = await Process.start('dart', [
        'bin/jmap_cli.dart', 'sieve', 'get', ...baseArgs,
        '--id', scriptId,
      ]);
      final afterActivateOutput = await process.stdout.transform(utf8.decoder).join();
      expect(await process.exitCode, equals(0));
      expect(jsonDecode(afterActivateOutput)['isActive'], equals(true));

      process = await Process.start('dart', [
        'bin/jmap_cli.dart', 'sieve', 'deactivate', ...baseArgs,
      ]);
      final deactivateOutput = await process.stdout.transform(utf8.decoder).join();
      expect(await process.exitCode, equals(0));
      expect(deactivateOutput.trim(), contains('deactivated'));

      process = await Process.start('dart', [
        'bin/jmap_cli.dart', 'sieve', 'get', ...baseArgs,
        '--id', scriptId,
      ]);
      final afterDeactivateOutput = await process.stdout.transform(utf8.decoder).join();
      expect(await process.exitCode, equals(0));
      expect(jsonDecode(afterDeactivateOutput)['isActive'], equals(false));

      process = await Process.start('dart', [
        'bin/jmap_cli.dart', 'sieve', 'delete', ...baseArgs,
        '--id', scriptId,
      ]);
      expect(await process.exitCode, equals(0));
    }, timeout: Timeout(Duration(seconds: 300)));
  });
}

bool isJSON(String str) {
  try {
    jsonDecode(str);
    return true;
  } catch (_) {
    return false;
  }
}
