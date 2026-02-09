import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

/// Ensure to use your own credentials for testing the functionality before deployment.
void main() {
  group('CLI tests for ietf', () {
    test('Command to getContact data', () async {
      var authFile = File('test/data/credentials/auth_ietf.json');

      var authContent = await authFile.readAsString();
      var auth = jsonDecode(authContent);

      var process = await Process.start('dart', [
      'bin/jmap_cli.dart',
      'contact',
      'get',
      '--url',
      auth['url'].toString(),
      '-u',
      auth['username'].toString(),
      '-p',
      auth['password'].toString(),
      '--apiVersion',
      'ietf',
    ]);

    var stdoutData = process.stdout.transform(utf8.decoder).join();
    var output = await stdoutData;  
    print(output);
    var exitCode = await process.exitCode;
    expect(exitCode, equals(0));
    expect(isJSON(output), true);
    }, timeout: Timeout(Duration(seconds: 300)));

    test('Command to Changes data', () async {
      var authFile = File('test/data/credentials/auth_ietf.json');

      var authContent = await authFile.readAsString();
      var auth = jsonDecode(authContent);

      var process = await Process.start('dart', [
      'bin/jmap_cli.dart',
      'contact',
      'changes',
      '--url',
      auth['url'].toString(),
      '-u',
      auth['username'].toString(),
      '-p',
      auth['password'].toString(),
      '--apiVersion',
      'ietf',
    ]);

      var stdoutData = process.stdout.transform(utf8.decoder).join();
      var output = await stdoutData;  
      print(output);
      var exitCode = await process.exitCode;

      expect(exitCode, equals(0));
      expect(isJSON(output), true);
    }, timeout: Timeout(Duration(seconds: 300)));

    test('Command to Changes data with explicit state', () async {
      var authFile = File('test/data/credentials/auth_ietf.json');

      var authContent = await authFile.readAsString();
      var auth = jsonDecode(authContent);

      var process = await Process.start('dart', [
        'bin/jmap_cli.dart',
        'contact',
        'changes',
        '--url',
        auth['url'].toString(),
        '-u',
        auth['username'].toString(),
        '-p',
        auth['password'].toString(),
        '--apiVersion',
        'ietf',
        '--state',
        'suuba'
      ]);

      var stdoutData = process.stdout.transform(utf8.decoder).join();
      var output = await stdoutData;
      print(output);

      var exitCode = await process.exitCode;

      expect(exitCode, equals(0));
      expect(isJSON(output), true);
    }, timeout: Timeout(Duration(seconds: 300)));

    test('Command to createContact using json file and deleteContact data with json', () async {
      var authFile = File('test/data/credentials/auth_ietf.json');
      var authContent = await authFile.readAsString();
      var auth = jsonDecode(authContent);
  
      final processCreate = await Process.start('dart', [
        'bin/jmap_cli.dart',
        'contact',
        'create',
        '--url',
        auth['url'].toString(),
        '-u',
        auth['username'].toString(),
        '-p',
        auth['password'].toString(),
        '-f',
        'test/data/contact/contact_ietf.json',
      ]);

      var stdoutData = await processCreate.stdout.transform(utf8.decoder).join();
      print(stdoutData);
      final processDelete = await Process.start('dart', [
        'bin/jmap_cli.dart',
        'contact',
        'delete',
        '--url',
        auth['url'].toString(),
        '-u',
        auth['username'].toString(),
        '-p',
        auth['password'].toString(),
        '--id',
        stdoutData.trim(),
      ]);
      print(stdoutData);
      final stdoutDeleteData = await processDelete.stdout.transform(utf8.decoder).join();
      print(stdoutDeleteData);
      final deleteCode = await processDelete.exitCode;

      expect(deleteCode, equals(0));
      expect(stdoutDeleteData, isNotNull);

    }, timeout: Timeout(Duration(seconds: 300)));
  });
  test('Command to createContact using json file and deleteContact data with fullName (ietf)', () async {
    final authFile = File('test/data/credentials/auth_ietf.json');
    final authContent = await authFile.readAsString();
    final auth = jsonDecode(authContent);

    final processCreate = await Process.start('dart', [
        'bin/jmap_cli.dart',
        'contact',
        'create',
        '--url',
        auth['url'].toString(),
        '-u',
        auth['username'].toString(),
        '-p',
        auth['password'].toString(),
        '--fullName',
        'Caroline Samatha Heavens',
        '--addressBookIds',
        'b'
    ]);

    final createOut = await processCreate.stdout.transform(utf8.decoder).join();
    final createCode = await processCreate.exitCode;
    expect(createCode, equals(0), reason: 'createContact failed');

    final processDelete = await Process.start('dart', [
        'bin/jmap_cli.dart',
        'contact',
        'delete',
        '--url',
        auth['url'].toString(),
        '-u',
        auth['username'].toString(),
        '-p',
        auth['password'].toString(),
        '--id',
        createOut.trim(),
    ]);
    final deleteCode = await processDelete.exitCode;

    expect(deleteCode, equals(0), reason: 'deleteContact failed');
  }, timeout: Timeout(Duration(seconds: 300)));

  group('CLI tests for cyrus', () {
    test('Command to createContact using json file and deleteContact data with json', () async {
      var authFile = File('test/data/credentials/auth_cyrus.json');
      var authContent = await authFile.readAsString();
      var auth = jsonDecode(authContent);
      final processCreate = await Process.start('dart', [
        'bin/jmap_cli.dart',
        'contact',
        'create',
        '--url',
        auth['url'].toString(),
        '-u',
        auth['username'].toString(),
        '-p',
        auth['password'].toString(),
        '-f',
        'test/data/contact/contact_cyrus.json',
        '--apiVersion', 'cyrus'
      ]);

      final stdoutData = await processCreate.stdout.transform(utf8.decoder).join();
      print(stdoutData);

      final exitCode = await processCreate.exitCode;

      expect(exitCode, equals(0));

      final processDelete = await Process.start('dart', [
        'bin/jmap_cli.dart',
        'contact',
        'delete',
        '--url',
        auth['url'].toString(),
        '-u',
        auth['username'].toString(),
        '-p',
        auth['password'].toString(),
        '--id',
        stdoutData.trim(),
      ]);
      final stdoutDeleteData = await processDelete.stdout.transform(utf8.decoder).join();

      expect(exitCode, equals(0));
      expect(stdoutDeleteData, isNotNull);

    }, timeout: Timeout(Duration(seconds: 300)));
  

    test('Command to Changes data', () async {
      var authFile = File('test/data/credentials/auth_cyrus.json');

      var authContent = await authFile.readAsString();
      var auth = jsonDecode(authContent);

      var process = await Process.start('dart', [
      'bin/jmap_cli.dart',
      'contact',
      'changes',
      '--url',
      auth['url'].toString(),
      '-u',
      auth['username'].toString(),
      '-p',
      auth['password'].toString(),
      '--apiVersion',
      'cyrus',
    ]);

      var stdoutData = process.stdout.transform(utf8.decoder).join();
      var output = await stdoutData;  
      print(output);
      var exitCode = await process.exitCode;

      expect(exitCode, equals(0));
      expect(isJSON(output), true);
   }, timeout: Timeout(Duration(seconds: 300)));
    test('Command to createContact using json file and deleteContact data with fullName', () async {
      final authFile = File('test/data/credentials/auth_cyrus.json');
      final authContent = await authFile.readAsString();
      final auth = jsonDecode(authContent);

      final processCreate = await Process.start('dart', [
        'bin/jmap_cli.dart',
        'contact',
        'create',
        '--url',
        auth['url'].toString(),
        '-u',
        auth['username'].toString(),
        '-p',
        auth['password'].toString(),
        '--fullName',
        'user 123',
        '--apiVersion',
        'cyrus',
      ]);

      final createOut = await processCreate.stdout.transform(utf8.decoder).join();
      print(createOut); 
      final createCode = await processCreate.exitCode;

      expect(createCode, equals(0), reason: 'createContact failed');

      final processDelete = await Process.start('dart', [
        'bin/jmap_cli.dart',
        'contact',
        'delete',
        '--url',
        auth['url'].toString(),
        '-u',
        auth['username'].toString(),
        '-p',
        auth['password'].toString(),
        '--id',
        createOut.toString().trim(),
      ]);
      final deleteCode = await processDelete.exitCode;

      expect(deleteCode, equals(0), reason: 'deleteContact failed');
    }, timeout: Timeout(Duration(seconds: 300)));
  });
  group('CLI tests for jsContact', () {
    test('Command to createContact using json file', () async {
      var authFile = File('test/data/credentials/auth_jscontact.json');
      var authContent = await authFile.readAsString();
      var auth = jsonDecode(authContent);
      final processCreate = await Process.start('dart', [
        'bin/jmap_cli.dart',
        'contact',
        'create',
        '--url',
        auth['url'].toString(),
        '-u',
        auth['username'].toString(),
        '-p',
        auth['password'].toString(),
        '-f',
        'test/data/contact/contact_jscontact.json',
        '--apiVersion',
        'jscontact',
      ]);
      final createCode = await processCreate.exitCode;

      expect(createCode, equals(0), reason: 'createContact failed');

    }, timeout: Timeout(Duration(seconds: 300)));
  
  test('Command to createContact using json file and deleteContact data with fullName information', () async {
      final authFile = File('test/data/credentials/auth_jscontact.json');
      final authContent = await authFile.readAsString();
      final auth = jsonDecode(authContent);

      final processCreate = await Process.start('dart', [
        'bin/jmap_cli.dart',
        'contact',
        'create',
        '--url',
        auth['url'].toString(),
        '-u',
        auth['username'].toString(),
        '-p',
        auth['password'].toString(),
        '--fullName',
        'user 1',
        '--apiVersion',
        'jscontact',
        '--accountId',
        'normaluser'
      ]);

      final createOut = await processCreate.stdout.transform(utf8.decoder).join();
      final createCode = await processCreate.exitCode;
      expect(createCode, equals(0), reason: 'createContact failed');

      final processDelete = await Process.start('dart', [
        'bin/jmap_cli.dart',
        'contact',
        'delete',
        '--url',
        auth['url'].toString(),
        '-u',
        auth['username'].toString(),
        '-p',
        auth['password'].toString(),
        '--id',
        createOut.trim(),
        '--apiVersion', 'jscontact'
      ]);
      final deleteOut = await processDelete.stdout.transform(utf8.decoder).join();
      print(deleteOut);
      final deleteCode = await processDelete.exitCode;
      expect(deleteCode, equals(0));
      expect(processDelete, isNotNull);
    }, timeout: Timeout(Duration(seconds: 300)));
  });
}

// Function to check if a string is valid JSON
bool isJSON(String str) {
  try {
    jsonDecode(str);
    return true;
  } catch (e) {
    return false;
  }
}
