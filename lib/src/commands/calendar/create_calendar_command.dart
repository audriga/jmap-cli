import 'package:jmap_cli/src/commands/base_command.dart';
import 'package:jmap_dart_client/jmap/account_id.dart';
import 'package:jmap_dart_client/jmap/calendar/calendar.dart';
import 'package:jmap_dart_client/jmap/core/id.dart';
import 'package:jmap_dart_client/util/calendar_util.dart';

class CreateCalendarCommand extends BaseCommand {
  @override
  final name = 'create';

  @override
  List<String> get aliases => ['calendar.create'];

  @override
  final description = 'Create a calendar (only name)';

  CreateCalendarCommand() {
    argParser.addOption(
      'name',
      abbr: 'n',
      help: 'Calendar name',
    );
  }

  @override
  Future<int> run() async {
    try {
      if (argResults == null) return 1;

      final calName = (argResults!['name'] as String?)?.trim();
      if (calName == null || calName.isEmpty) {
        print('Error: missing --name');
        return 1;
      }

      final live = await buildClientAndAccount(argResults!, 'POST');
      final accountId = AccountId(Id(argResults!['accountId'] ?? live.accountId.id.value));

      final resp = await CalendarUtil.createCalendar(
        client: live.httpClient,
        accountId: accountId,
        calendar: Calendar(name: calName),
      );

      final created = resp.created?.values.first;
      final id = created?.id?.value;

      if (id != null && id.isNotEmpty) {
        print(id);
      } else {
        print('Error: calendar id not returned');
        return 1;
      }

      return 0;
    } catch (e) {
      print('Error: $e');
      return 1;
    }
  }
}
