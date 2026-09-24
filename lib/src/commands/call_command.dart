import 'dart:convert';
import 'package:jmap_cli/src/commands/base_command.dart';

/// Capabilities declared by default when --using is not given, covering
/// everything the Stalwart test server has been seen to advertise. Declaring
/// unused capabilities is harmless per the JMAP spec, so this saves having to
/// look up the right URN for ad-hoc/debugging calls.
const _defaultCapabilities = [
  'urn:ietf:params:jmap:core',
  'urn:ietf:params:jmap:mail',
  'urn:ietf:params:jmap:calendars',
  'urn:ietf:params:jmap:calendars:parse',
  'urn:ietf:params:jmap:contacts',
  'urn:ietf:params:jmap:contacts:parse',
  'urn:ietf:params:jmap:filenode',
  'urn:ietf:params:jmap:principals',
  'urn:ietf:params:jmap:principals:availability',
  'urn:ietf:params:jmap:submission',
  'urn:ietf:params:jmap:vacationresponse',
  'urn:ietf:params:jmap:sieve',
  'urn:ietf:params:jmap:blob',
  'urn:ietf:params:jmap:quota',
];

class CallCommand extends BaseCommand {
  @override
  final name = 'call';

  @override
  final description =
      'Run an arbitrary JMAP method call and print the raw JSON response';

  CallCommand() {
    argParser
      ..addOption('method', abbr: 'm', help: 'JMAP method name, e.g. Principal/query', mandatory: true)
      ..addOption('args', help: 'JSON arguments for the method', defaultsTo: '{}')
      ..addOption('using', help: 'Comma-separated capability URNs to declare (default: all known ones)')
      ..addOption('callId', help: 'Method call id', defaultsTo: 'c0');
  }

  @override
  Future<int> run() async {
    try {
      final args = argResults;
      if (args == null) return 1;

      final method = args['method'] as String;
      final callId = args['callId'] as String;

      Map<String, dynamic> methodArgs;
      try {
        methodArgs = jsonDecode(args['args'] as String) as Map<String, dynamic>;
      } catch (e) {
        print('Error: --args is not valid JSON: $e');
        return 1;
      }

      final usingArg = args['using'] as String?;
      final using = (usingArg != null && usingArg.isNotEmpty)
          ? usingArg.split(',').map((s) => s.trim()).toList()
          : _defaultCapabilities;

      final live = await buildClientAndAccount(args, 'POST');

      methodArgs.putIfAbsent('accountId', () => live.accountId.id.value);

      final body = {
        'using': using,
        'methodCalls': [
          [method, methodArgs, callId],
        ],
      };

      final response = await live.httpClient.post('', data: body);
      print(const JsonEncoder.withIndent('  ').convert(response));
      return 0;
    } catch (e) {
      print('Error: $e');
      return 1;
    }
  }
}
