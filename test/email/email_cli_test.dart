import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CLI tests for email commands (IETF / Stalwart)', () {
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

    test('email get returns valid JSON with list', () async {
      final process = await Process.start('dart', [
        'bin/jmap_cli.dart', 'email', 'get', ...baseArgs,
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

    test('email create with args, get by id, then delete', () async {
      final mailboxId = await _getInboxId(auth);

      // Create
      var process = await Process.start('dart', [
        'bin/jmap_cli.dart', 'email', 'create', ...baseArgs,
        '--subject', 'CLI test email (args)',
        '--mailboxId', mailboxId,
      ]);
      final createOutput = await process.stdout.transform(utf8.decoder).join();
      final createExit = await process.exitCode;

      print('Created id: $createOutput');
      expect(createExit, equals(0));
      expect(createOutput.trim(), isNotEmpty);

      final emailId = createOutput.trim();

      // Get by id
      process = await Process.start('dart', [
        'bin/jmap_cli.dart', 'email', 'get', ...baseArgs,
        '--id', emailId,
      ]);
      final getOutput = await process.stdout.transform(utf8.decoder).join();
      final getExit = await process.exitCode;

      print(getOutput);
      expect(getExit, equals(0));
      expect(isJSON(getOutput), true);
      expect(jsonDecode(getOutput)['subject'], equals('CLI test email (args)'));

      // Delete
      process = await Process.start('dart', [
        'bin/jmap_cli.dart', 'email', 'delete', ...baseArgs,
        '--id', emailId,
      ]);
      final deleteOutput = await process.stdout.transform(utf8.decoder).join();
      final deleteExit = await process.exitCode;

      print(deleteOutput);
      expect(deleteExit, equals(0));
    }, timeout: Timeout(Duration(seconds: 300)));

    test('email create from JSON file then delete', () async {
      final mailboxId = await _getInboxId(auth);

      var process = await Process.start('dart', [
        'bin/jmap_cli.dart', 'email', 'create', ...baseArgs,
        '--mailboxId', mailboxId,
        '-f', 'test/data/email/email_ietf.json',
      ]);
      final output = await process.stdout.transform(utf8.decoder).join();
      final createExit = await process.exitCode;

      print('Created id: $output');
      expect(createExit, equals(0));
      expect(output.trim(), isNotEmpty);

      process = await Process.start('dart', [
        'bin/jmap_cli.dart', 'email', 'delete', ...baseArgs,
        '--id', output.trim(),
      ]);
      final deleteOutput = await process.stdout.transform(utf8.decoder).join();
      final deleteExit = await process.exitCode;

      print(deleteOutput);
      expect(deleteExit, equals(0));
    }, timeout: Timeout(Duration(seconds: 300)));

    test('email create from .eml file (MIME import) then delete', () async {
      final mailboxId = await _getInboxId(auth);

      // Import .eml
      var process = await Process.start('dart', [
        'bin/jmap_cli.dart', 'email', 'create', ...baseArgs,
        '-f', 'test/data/email/sample.eml',
        '--mailboxId', mailboxId,
      ]);
      final createOutput = await process.stdout.transform(utf8.decoder).join();
      final createExit = await process.exitCode;

      print('Imported id: $createOutput');
      expect(createExit, equals(0));
      expect(createOutput.trim(), isNotEmpty);

      final emailId = createOutput.trim();

      // Verify it exists with correct subject
      process = await Process.start('dart', [
        'bin/jmap_cli.dart', 'email', 'get', ...baseArgs,
        '--id', emailId,
      ]);
      final getOutput = await process.stdout.transform(utf8.decoder).join();
      final getExit = await process.exitCode;

      expect(getExit, equals(0));
      expect(isJSON(getOutput), true);
      expect(jsonDecode(getOutput)['subject'], equals('Sample JMAP CLI test email'));

      // Delete
      process = await Process.start('dart', [
        'bin/jmap_cli.dart', 'email', 'delete', ...baseArgs,
        '--id', emailId,
      ]);
      expect(await process.exitCode, equals(0));
    }, timeout: Timeout(Duration(seconds: 300)));

    test('email get --all returns list of all emails', () async {
      final mailboxId = await _getInboxId(auth);

      final process = await Process.start('dart', [
        'bin/jmap_cli.dart', 'email', 'get', ...baseArgs,
        '--all', '--mailboxId', mailboxId,
      ]);

      final output = await process.stdout.transform(utf8.decoder).join();
      final exitCode = await process.exitCode;

      print('Total emails: ${(jsonDecode(output) as List).length}');
      expect(exitCode, equals(0));
      expect(isJSON(output), true);
      expect(jsonDecode(output), isList);
    }, timeout: Timeout(Duration(seconds: 300)));

    test('email get --id with -o out.eml downloads raw MIME', () async {
      final mailboxId = await _getInboxId(auth);

      // Create an email to download
      var process = await Process.start('dart', [
        'bin/jmap_cli.dart', 'email', 'create', ...baseArgs,
        '--subject', 'MIME download test',
        '--mailboxId', mailboxId,
      ]);
      final createOutput = await process.stdout.transform(utf8.decoder).join();
      await process.exitCode;
      final emailId = createOutput.trim();

      // Download as MIME
      final outPath = '/tmp/jmap_cli_mime_test_${DateTime.now().millisecondsSinceEpoch}.eml';
      process = await Process.start('dart', [
        'bin/jmap_cli.dart', 'email', 'get', ...baseArgs,
        '--id', emailId,
        '-o', outPath,
      ]);
      final downloadOutput = await process.stdout.transform(utf8.decoder).join();
      final downloadExit = await process.exitCode;

      print(downloadOutput);
      expect(downloadExit, equals(0));

      final outFile = File(outPath);
      expect(outFile.existsSync(), isTrue);
      final content = await outFile.readAsString();
      expect(content, contains('Subject:'));

      // Cleanup
      outFile.deleteSync();
      await Process.run('dart', [
        'bin/jmap_cli.dart', 'email', 'delete', ...baseArgs,
        '--id', emailId,
      ]);
    }, timeout: Timeout(Duration(seconds: 300)));

    test('email query returns valid JSON with ids list', () async {
      final process = await Process.start('dart', [
        'bin/jmap_cli.dart', 'email', 'query', ...baseArgs,
      ]);

      final output = await process.stdout.transform(utf8.decoder).join();
      final exitCode = await process.exitCode;

      print(output);
      expect(exitCode, equals(0));
      expect(isJSON(output), true);

      final json = jsonDecode(output);
      expect(json['accountId'], isNotNull);
      expect(json['ids'], isList);
    }, timeout: Timeout(Duration(seconds: 300)));

    test('email query with --limit and --position returns paged results', () async {
      final mailboxId = await _getInboxId(auth);

      // Page 1
      var process = await Process.start('dart', [
        'bin/jmap_cli.dart', 'email', 'query', ...baseArgs,
        '--mailboxId', mailboxId, '--limit', '2', '--position', '0',
      ]);
      final page1Output = await process.stdout.transform(utf8.decoder).join();
      final page1Exit = await process.exitCode;

      expect(page1Exit, equals(0));
      expect(isJSON(page1Output), true);
      final page1 = jsonDecode(page1Output);
      expect(page1['ids'], isList);
      expect((page1['ids'] as List).length, lessThanOrEqualTo(2));

      // Page 2
      process = await Process.start('dart', [
        'bin/jmap_cli.dart', 'email', 'query', ...baseArgs,
        '--mailboxId', mailboxId, '--limit', '2', '--position', '2',
      ]);
      final page2Output = await process.stdout.transform(utf8.decoder).join();
      final page2Exit = await process.exitCode;

      expect(page2Exit, equals(0));
      expect(isJSON(page2Output), true);
      expect(jsonDecode(page2Output)['ids'], isList);
    }, timeout: Timeout(Duration(seconds: 300)));

    test('email changes returns valid JSON', () async {
      final process = await Process.start('dart', [
        'bin/jmap_cli.dart', 'email', 'changes', ...baseArgs,
      ]);

      final output = await process.stdout.transform(utf8.decoder).join();
      final exitCode = await process.exitCode;

      print(output);
      expect(exitCode, equals(0));
      expect(isJSON(output), true);

      final json = jsonDecode(output);
      expect(json['accountId'], isNotNull);
      expect(json['newState'], isNotNull);
    }, timeout: Timeout(Duration(seconds: 300)));

    test('email changes with explicit state returns valid JSON', () async {
      // First get the current state
      var process = await Process.start('dart', [
        'bin/jmap_cli.dart', 'email', 'get', ...baseArgs,
      ]);
      final getOutput = await process.stdout.transform(utf8.decoder).join();
      await process.exitCode;
      final state = jsonDecode(getOutput)['state'] as String;

      // Then changes from that state
      process = await Process.start('dart', [
        'bin/jmap_cli.dart', 'email', 'changes', ...baseArgs,
        '--state', state,
      ]);

      final output = await process.stdout.transform(utf8.decoder).join();
      final exitCode = await process.exitCode;

      print(output);
      expect(exitCode, equals(0));
      expect(isJSON(output), true);
    }, timeout: Timeout(Duration(seconds: 300)));
  });
}

/// Returns the id of the inbox mailbox (role = inbox).
Future<String> _getInboxId(Map<String, dynamic> auth) async {
  final process = await Process.start('dart', [
    'bin/jmap_cli.dart', 'mailbox', 'get',
    '--url', auth['url'].toString(),
    '-u', auth['username'].toString(),
    '-p', auth['password'].toString(),
  ]);
  final output = await process.stdout.transform(utf8.decoder).join();
  await process.exitCode;
  final list = jsonDecode(output)['list'] as List;
  final inbox = list.firstWhere(
    (m) => m['role'] == 'inbox',
    orElse: () => list.first,
  );
  return inbox['id'] as String;
}

bool isJSON(String str) {
  try {
    jsonDecode(str);
    return true;
  } catch (_) {
    return false;
  }
}
