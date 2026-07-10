import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CLI tests for mailbox commands', () {
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

    test('mailbox get returns valid JSON with list', () async {
      final process = await Process.start('dart', [
        'bin/jmap_cli.dart', 'mailbox', 'get', ...baseArgs,
      ]);

      final output = await process.stdout.transform(utf8.decoder).join();
      final exitCode = await process.exitCode;

      print(output);
      expect(exitCode, equals(0));
      expect(isJSON(output), true);

      final json = jsonDecode(output);
      expect(json['accountId'], isNotNull);
      expect(json['list'], isList);
      expect((json['list'] as List), isNotEmpty);
    }, timeout: Timeout(Duration(seconds: 300)));

    test('mailbox get by id returns single mailbox JSON', () async {
      // Get all mailboxes first to obtain a valid id
      var process = await Process.start('dart', [
        'bin/jmap_cli.dart', 'mailbox', 'get', ...baseArgs,
      ]);
      final allOutput = await process.stdout.transform(utf8.decoder).join();
      await process.exitCode;

      final firstId = (jsonDecode(allOutput)['list'] as List).first['id'] as String;

      process = await Process.start('dart', [
        'bin/jmap_cli.dart', 'mailbox', 'get', ...baseArgs,
        '--id', firstId,
      ]);
      final output = await process.stdout.transform(utf8.decoder).join();
      final exitCode = await process.exitCode;

      print(output);
      expect(exitCode, equals(0));
      expect(isJSON(output), true);
      expect(jsonDecode(output)['id'], equals(firstId));
    }, timeout: Timeout(Duration(seconds: 300)));

    test('mailbox create then delete', () async {
      var process = await Process.start('dart', [
        'bin/jmap_cli.dart', 'mailbox', 'create', ...baseArgs,
        '--name', 'CLITestMailbox',
      ]);
      final createOutput = await process.stdout.transform(utf8.decoder).join();
      final createExit = await process.exitCode;

      print('Created mailbox id: $createOutput');
      expect(createExit, equals(0));
      expect(createOutput.trim(), isNotEmpty);

      final mailboxId = createOutput.trim();

      process = await Process.start('dart', [
        'bin/jmap_cli.dart', 'mailbox', 'delete', ...baseArgs,
        '--id', mailboxId,
      ]);
      final deleteOutput = await process.stdout.transform(utf8.decoder).join();
      final deleteExit = await process.exitCode;

      print(deleteOutput);
      expect(deleteExit, equals(0));
      expect(deleteOutput.trim(), contains('deleted'));
    }, timeout: Timeout(Duration(seconds: 300)));

    test('mailbox create nested under parent then delete both', () async {
      // Create parent
      var process = await Process.start('dart', [
        'bin/jmap_cli.dart', 'mailbox', 'create', ...baseArgs,
        '--name', 'CLIParentMailbox',
      ]);
      final parentOutput = await process.stdout.transform(utf8.decoder).join();
      final parentExit = await process.exitCode;
      expect(parentExit, equals(0));
      final parentId = parentOutput.trim();

      // Create child
      process = await Process.start('dart', [
        'bin/jmap_cli.dart', 'mailbox', 'create', ...baseArgs,
        '--name', 'CLIChildMailbox',
        '--parentId', parentId,
      ]);
      final childOutput = await process.stdout.transform(utf8.decoder).join();
      final childExit = await process.exitCode;

      print('Child id: $childOutput');
      expect(childExit, equals(0));
      expect(childOutput.trim(), isNotEmpty);
      final childId = childOutput.trim();

      // Delete child first, then parent
      process = await Process.start('dart', [
        'bin/jmap_cli.dart', 'mailbox', 'delete', ...baseArgs,
        '--id', childId,
      ]);
      expect(await process.exitCode, equals(0));

      process = await Process.start('dart', [
        'bin/jmap_cli.dart', 'mailbox', 'delete', ...baseArgs,
        '--id', parentId,
      ]);
      expect(await process.exitCode, equals(0));
    }, timeout: Timeout(Duration(seconds: 300)));

    test('mailbox get --all returns list of all mailboxes', () async {
      final process = await Process.start('dart', [
        'bin/jmap_cli.dart', 'mailbox', 'get', ...baseArgs,
        '--all',
      ]);

      final output = await process.stdout.transform(utf8.decoder).join();
      final exitCode = await process.exitCode;

      print('Total mailboxes: ${(jsonDecode(output) as List).length}');
      expect(exitCode, equals(0));
      expect(isJSON(output), true);
      expect(jsonDecode(output), isList);
      expect((jsonDecode(output) as List), isNotEmpty);
    }, timeout: Timeout(Duration(seconds: 300)));

    test('mailbox changes returns valid JSON', () async {
      final process = await Process.start('dart', [
        'bin/jmap_cli.dart', 'mailbox', 'changes', ...baseArgs,
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

    test('mailbox changes with explicit state returns valid JSON', () async {
      // Get current state first
      var process = await Process.start('dart', [
        'bin/jmap_cli.dart', 'mailbox', 'get', ...baseArgs,
      ]);
      final getOutput = await process.stdout.transform(utf8.decoder).join();
      await process.exitCode;
      final state = jsonDecode(getOutput)['state'] as String;

      // Changes from that state
      process = await Process.start('dart', [
        'bin/jmap_cli.dart', 'mailbox', 'changes', ...baseArgs,
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

bool isJSON(String str) {
  try {
    jsonDecode(str);
    return true;
  } catch (_) {
    return false;
  }
}
