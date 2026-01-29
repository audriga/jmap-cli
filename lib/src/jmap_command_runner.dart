import 'package:args/command_runner.dart';
import 'package:args/args.dart';
import 'package:io/io.dart';
import 'package:jmap_cli/jmap_cli.dart';
import 'dart:async';

/// Custom command runner for the JMAP CLI, handling commands and logging.
class JmapCommandRunner extends CommandRunner<int> {
  JmapCommandRunner() : super('JMAP', 'A command-line utility for jmap-dart-client library.') {
    argParser
      ..addFlag(
        'version',
        help: 'Print the current version.',
      )
      ..addFlag(
        'verbose',
        abbr: 'v',
        help: 'Show additional command output.',
        negatable: false,
      );

    addCommand(IdentityCommand());
    addCommand(FileNodesCommand());
    addCommand(ContactCommand());
    addCommand(CalendarEventCommand());
    addCommand(SessionCommand());
    addCommand(AddressBookCommand());
    addCommand(CalendarCommand());
  }

  /// Parses and executes commands from the provided [args].
  @override
  Future<int> run(Iterable<String> args) async {
    var s1 = ''' ''';

    try {
      var argumentResults = parse(args);
      final exitCode = await runCommand(argumentResults) ?? ExitCode.success.code;
      return exitCode;
    } on FormatException catch (e) {
      print(e.message);
      print(s1);
      print("CLI arguments provided are not in the expected format. Refer to the usage information for correct usage guidance below. \n");
      print(argParser.usage);
      return ExitCode.usage.code;
    } on UsageException catch (e) {
      print(e.message);
      print(s1);
      print("Incorrect usage of the program. Refer to the usage information below.\n");
      print(argParser.usage);
      return ExitCode.usage.code;
    }
  }

  /// Executes a command, handling version and help flags and delegating to the superclass for other commands.
  @override
  Future<int?> runCommand(ArgResults topLevelResults) async {
    if (topLevelResults['version'] != false) {
      print('jmap version 1.0.0');
      return ExitCode.success.code;
    }

    return super.runCommand(topLevelResults);
  }
}
