import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CLI tests for get command', () {
    test('Command to getIdentity data', () async {
      final authFile = File('test/data/credentials/auth_ietf.json');
      final authContent = await authFile.readAsString();
      final auth = jsonDecode(authContent);

      final process = await Process.start(
        'dart',
        [
          'bin/jmap_cli.dart',
          'identity',
          'get',
          '--url',
          auth['url'].toString(),
          '-u',
          auth['username'].toString(),
          '-p',
          auth['password'].toString(),
        ],
      );

      final output = await process.stdout.transform(utf8.decoder).join();
      print(output);

      final exitCode = await process.exitCode;
      expect(exitCode, equals(0));
    }, timeout: Timeout(Duration(seconds: 300)));
  });
}
