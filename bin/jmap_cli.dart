import 'package:jmap_cli/src/jmap_command_runner.dart';
import 'dart:io';

void main(List<String> args) async {
  try {
    int exit = await JmapCommandRunner().run(args);
    await _flushThenExit(exit);
  } catch (e) {
    print('Error: $e');
    exit(1);
  }
}

/// Closes stdout and stderr, then exits the application with the given [status] code.
Future _flushThenExit(int status) {
  return Future.wait<void>([stdout.close(), stderr.close()]).then<void>((_) => exit(status));
}
