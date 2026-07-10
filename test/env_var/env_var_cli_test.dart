import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CLI tests for environment variable support', () {
    late Map<String, dynamic> auth;

    setUpAll(() async {
      final authFile = File('test/data/credentials/auth_ietf.json');
      auth = jsonDecode(await authFile.readAsString());
    });

    test('mailbox get works with env vars instead of flags', () async {
      final process = await Process.start(
        'dart',
        ['bin/jmap_cli.dart', 'mailbox', 'get'],
        environment: {
          ...Platform.environment,
          'JMAP_URL': auth['url'].toString(),
          'JMAP_USERNAME': auth['username'].toString(),
          'JMAP_PASSWORD': auth['password'].toString(),
        },
      );

      final output = await process.stdout.transform(utf8.decoder).join();
      final exitCode = await process.exitCode;

      print(output);
      expect(exitCode, equals(0));
      expect(isJSON(output), true);
      expect(jsonDecode(output)['list'], isList);
    }, timeout: Timeout(Duration(seconds: 300)));

    test('email get works with env vars instead of flags', () async {
      final process = await Process.start(
        'dart',
        ['bin/jmap_cli.dart', 'email', 'get'],
        environment: {
          ...Platform.environment,
          'JMAP_URL': auth['url'].toString(),
          'JMAP_USERNAME': auth['username'].toString(),
          'JMAP_PASSWORD': auth['password'].toString(),
        },
      );

      final output = await process.stdout.transform(utf8.decoder).join();
      final exitCode = await process.exitCode;

      print(output);
      expect(exitCode, equals(0));
      expect(isJSON(output), true);
      expect(jsonDecode(output)['list'], isList);
    }, timeout: Timeout(Duration(seconds: 300)));

    test('CLI flag takes precedence over env var', () async {
      final process = await Process.start(
        'dart',
        [
          'bin/jmap_cli.dart', 'mailbox', 'get',
          '--url', auth['url'].toString(),
          '-u', auth['username'].toString(),
          '-p', auth['password'].toString(),
        ],
        environment: {
          ...Platform.environment,
          'JMAP_URL': 'http://invalid-env-url/jmap',
          'JMAP_USERNAME': 'wrong_user',
          'JMAP_PASSWORD': 'wrong_pass',
        },
      );

      final output = await process.stdout.transform(utf8.decoder).join();
      final exitCode = await process.exitCode;

      print(output);
      expect(exitCode, equals(0));
      expect(isJSON(output), true);
      expect(jsonDecode(output)['list'], isList);
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
