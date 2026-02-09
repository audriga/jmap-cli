import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CLI tests for IETF get command', () {
    test('Command to getCalendarEvent data', () async {
      final authFile = File('test/data/credentials/auth_ietf.json');
      final authContent = await authFile.readAsString();
      final auth = jsonDecode(authContent);

      final process = await Process.start('dart', [
        'bin/jmap_cli.dart',
        'calendarEvent',
        'get',
        '--url',
        auth['url'].toString(),
        '-u',
        auth['username'].toString(),
        '-p',
        auth['password'].toString(),
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

    test(
        'Command to createCalendarEvent using json file and deleteCalendarEvent using json file',
        () async {
      final authFile = File('test/data/credentials/auth_ietf.json');
      final authContent = await authFile.readAsString();
      final auth = jsonDecode(authContent);

      var process = await Process.start('dart', [
        'bin/jmap_cli.dart',
        'calendarEvent',
        'create',
        '--url',
        auth['url'].toString(),
        '-u',
        auth['username'].toString(),
        '-p',
        auth['password'].toString(),
        '-f',
        'test/data/calendarEvent/calendar_event_ietf.json'
      ]);

      var output = await process.stdout.transform(utf8.decoder).join();

      print(output);
      process = await Process.start('dart', [
        'bin/jmap_cli.dart',
        'calendarEvent',
        'delete',
        '--url',
        auth['url'].toString(),
        '-u',
        auth['username'].toString(),
        '-p',
        auth['password'].toString(),
        '--id',
        output.trim(),
      ]);

      final deleteOutput =
          await process.stdout.transform(utf8.decoder).join();
      final deleteExitCode = await process.exitCode;
      print(deleteOutput);
      expect(deleteExitCode, equals(0));
      expect(deleteOutput, isNotNull);
    }, timeout: Timeout(Duration(seconds: 300)));

    test(
        'Command to createCalendarEvent using title and deleteCalendarEvent by id',
        () async {
      final authFile = File('test/data/credentials/auth_ietf.json');
      final authContent = await authFile.readAsString();
      final auth = jsonDecode(authContent);

      var process = await Process.start('dart', [
        'bin/jmap_cli.dart',
        'calendarEvent',
        'create',
        '--url',
        auth['url'].toString(),
        '-u',
        auth['username'].toString(),
        '-p',
        auth['password'].toString(),
        '--title',
        'title1',
        '--calendarIds',
        'c'
      ]);

      var output = await process.stdout.transform(utf8.decoder).join();
      var createExitCode = await process.exitCode;

      expect(createExitCode, equals(0));

      process = await Process.start('dart', [
        'bin/jmap_cli.dart',
        'calendarEvent',
        'delete',
        '--url',
        auth['url'].toString(),
        '-u',
        auth['username'].toString(),
        '-p',
        auth['password'].toString(),
        '--id',
        output.trim()
      ]);

      final deleteOutput =
          await process.stdout.transform(utf8.decoder).join();
      final deleteExitCode = await process.exitCode;

      expect(deleteExitCode, equals(0));
      expect(deleteOutput, isNotNull);
    }, timeout: Timeout(Duration(seconds: 300)));
 

    test('Command to getChangesCalendarEvent data', () async {
      final authFile = File('test/data/credentials/auth_ietf.json');
      final authContent = await authFile.readAsString();
      final auth = jsonDecode(authContent);

      final process = await Process.start('dart', [
        'bin/jmap_cli.dart',
        'calendarEvent',
        'changes',
        '--url',
        auth['url'].toString(),
        '-u',
        auth['username'].toString(),
        '-p',
        auth['password'].toString(),
      ]);

      final output = await process.stdout.transform(utf8.decoder).join();
      final exitCode = await process.exitCode;

      print(output);

      expect(exitCode, equals(0));
      expect(isJSON(output), true);

      final json = jsonDecode(output);
      expect(json['accountId'], isNotNull);
    }, timeout: Timeout(Duration(seconds: 300)));

    test('Command to Changes data with explicit state', () async {
      var authFile = File('test/data/credentials/auth_ietf.json');

      var authContent = await authFile.readAsString();
      var auth = jsonDecode(authContent);

      var process = await Process.start('dart', [
        'bin/jmap_cli.dart',
        'calendarEvent',
        'changes',
        '--url',
        auth['url'].toString(),
        '-u',
        auth['username'].toString(),
        '-p',
        auth['password'].toString(),
        '--state',
        's3yba'
      ]);

      var stdoutData = process.stdout.transform(utf8.decoder).join();
      var output = await stdoutData;
      print(output);

      var exitCode = await process.exitCode;

      expect(exitCode, equals(0));
      expect(isJSON(output), true);
    }, timeout: Timeout(Duration(seconds: 300)));
  });
  group('CLI tests for Cyrus get command', () {
    test('Command to getCalendarEvent data', () async {
      final authFile = File('test/data/credentials/auth_cyrus.json');
      final authContent = await authFile.readAsString();
      final auth = jsonDecode(authContent);

      final process = await Process.start('dart', [
        'bin/jmap_cli.dart',
        'calendarEvent',
        'get',
        '--url',
        auth['url'].toString(),
        '-u',
        auth['username'].toString(),
        '-p',
        auth['password'].toString(),
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

    test(
        'Command to createCalendarEvent using json file and deleteCalendarEvent using json file',
        () async {
      final authFile = File('test/data/credentials/auth_cyrus.json');
      final authContent = await authFile.readAsString();
      final auth = jsonDecode(authContent);

      var process = await Process.start('dart', [
        'bin/jmap_cli.dart',
        'calendarEvent',
        'create',
        '--url',
        auth['url'].toString(),
        '-u',
        auth['username'].toString(),
        '-p',
        auth['password'].toString(),
        '-f',
        'test/data/calendarEvent/calendar_event_cyrus.json'
      ]);

      var output = await process.stdout.transform(utf8.decoder).join();
      print(output);
      var createExitCode = await process.exitCode;

      expect(createExitCode, equals(0));

      process = await Process.start('dart', [
        'bin/jmap_cli.dart',
        'calendarEvent',
        'delete',
        '--url',
        auth['url'].toString(),
        '-u',
        auth['username'].toString(),
        '-p',
        auth['password'].toString(),
        '--id',
        output.trim(),
      ]);
      final deleteOutput =
          await process.stdout.transform(utf8.decoder).join();
      final deleteExitCode = await process.exitCode;
      print(deleteOutput);

      expect(deleteExitCode, equals(0));
      expect(deleteOutput, isNotNull);
    }, timeout: Timeout(Duration(seconds: 300)));

    test(
        'Command to createCalendarEvent using title and deleteCalendarEvent by id',
        () async {
      final authFile = File('test/data/credentials/auth_cyrus.json');
      final authContent = await authFile.readAsString();
      final auth = jsonDecode(authContent);

      var process = await Process.start('dart', [
        'bin/jmap_cli.dart',
        'calendarEvent',
        'create',
        '--url',
        auth['url'].toString(),
        '-u',
        auth['username'].toString(),
        '-p',
        auth['password'].toString(),
        '--title',
        'title1',
        '--calendarIds',
        'Default'
      ]);

      var output = await process.stdout.transform(utf8.decoder).join();
      var createExitCode = await process.exitCode;
      print(output);

      expect(createExitCode, equals(0));

      process = await Process.start('dart', [
        'bin/jmap_cli.dart',
        'calendarEvent',
        'delete',
        '--url',
        auth['url'].toString(),
        '-u',
        auth['username'].toString(),
        '-p',
        auth['password'].toString(),
        '--id',
        output.trim()
      ]);

      final deleteOutput =
          await process.stdout.transform(utf8.decoder).join();
      final deleteExitCode = await process.exitCode;

      expect(deleteExitCode, equals(0));
      expect(deleteOutput, isNotNull);
    }, timeout: Timeout(Duration(seconds: 300)));
 

    test('Command to getChangesCalendarEvent data', () async {
      final authFile = File('test/data/credentials/auth_cyrus.json');
      final authContent = await authFile.readAsString();
      final auth = jsonDecode(authContent);

      final process = await Process.start('dart', [
        'bin/jmap_cli.dart',
        'calendarEvent',
        'changes',
        '--url',
        auth['url'].toString(),
        '-u',
        auth['username'].toString(),
        '-p',
        auth['password'].toString(),
      ]);

      final output = await process.stdout.transform(utf8.decoder).join();
      final exitCode = await process.exitCode;

      print(output);

      expect(exitCode, equals(0));
      expect(isJSON(output), true);

      final json = jsonDecode(output);
      expect(json['accountId'], isNotNull);
    }, timeout: Timeout(Duration(seconds: 300)));
  });
  group('CLI tests for JsContact get command', () {
    test('Command to getCalendarEvent data', () async {
      final authFile = File('test/data/credentials/auth_jscontact.json');
      final authContent = await authFile.readAsString();
      final auth = jsonDecode(authContent);

      final process = await Process.start('dart', [
        'bin/jmap_cli.dart',
        'calendarEvent',
        'get',
        '--url',
        auth['url'].toString(),
        '-u',
        auth['username'].toString(),
        '-p',
        auth['password'].toString(),
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

    test(
        'Command to createCalendarEvent using json file and deleteCalendarEvent using json file',
        () async {
      final authFile = File('test/data/credentials/auth_jscontact.json');
      final authContent = await authFile.readAsString();
      final auth = jsonDecode(authContent);

      var process = await Process.start('dart', [
        'bin/jmap_cli.dart',
        'calendarEvent',
        'create',
        '--url',
        auth['url'].toString(),
        '-u',
        auth['username'].toString(),
        '-p',
        auth['password'].toString(),
        '-f',
        'test/data/calendarEvent/calendar_event_jscontact.json'
      ]);

      var output = await process.stdout.transform(utf8.decoder).join();
      print(output);
      var createExitCode = await process.exitCode;

      expect(createExitCode, equals(0));
      process = await Process.start('dart', [
        'bin/jmap_cli.dart',
        'calendarEvent',
        'delete',
        '--url',
        auth['url'].toString(),
        '-u',
        auth['username'].toString(),
        '-p',
        auth['password'].toString(),
        '--id',
        output.trim(),
      ]);
      print(output.trim());
      final deleteOutput =
          await process.stdout.transform(utf8.decoder).join();
      final deleteExitCode = await process.exitCode;
      print(deleteOutput);

      expect(deleteExitCode, equals(0));
      expect(deleteOutput, isNotNull);
    }, timeout: Timeout(Duration(seconds: 300)));

    test(
        'Command to createCalendarEvent using title and deleteCalendarEvent by id',
        () async {
      final authFile = File('test/data/credentials/auth_jscontact.json');
      final authContent = await authFile.readAsString();
      final auth = jsonDecode(authContent);

      var process = await Process.start('dart', [
        'bin/jmap_cli.dart',
        'calendarEvent',
        'create',
        '--url',
        auth['url'].toString(),
        '-u',
        auth['username'].toString(),
        '-p',
        auth['password'].toString(),
        '--title',
        'title1',
      ]);

      var output = await process.stdout.transform(utf8.decoder).join();
      var createExitCode = await process.exitCode;
      print(output);

      expect(createExitCode, equals(0));

      process = await Process.start('dart', [
        'bin/jmap_cli.dart',
        'calendarEvent',
        'delete',
        '--url',
        auth['url'].toString(),
        '-u',
        auth['username'].toString(),
        '-p',
        auth['password'].toString(),
        '--id',
        output.trim()
      ]);

      final deleteOutput =
          await process.stdout.transform(utf8.decoder).join();
        
      final deleteExitCode = await process.exitCode;

      expect(deleteExitCode, equals(0));
      expect(deleteOutput, isNotNull);
    }, timeout: Timeout(Duration(seconds: 300)));
  });
}

// Function to check if a string is valid JSON
bool isJSON(String str) {
  try {
    jsonDecode(str);
    return true;
  } catch (_) {
    return false;
  }
}
