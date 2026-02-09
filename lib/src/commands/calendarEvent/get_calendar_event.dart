import 'dart:convert';
import 'package:jmap_cli/src/commands/base_command.dart';
import 'package:jmap_dart_client/jmap/account_id.dart';
import 'package:jmap_dart_client/jmap/core/id.dart';
import 'package:jmap_dart_client/util/calendar_event_util.dart';

class GetCalendarEventCommand extends BaseCommand {
  @override
  final name = 'get';

  @override
  List<String> get aliases => ['calendarEvent.get'];

  @override
  final description = 'Get calendar events or a single event by id';

  GetCalendarEventCommand();

  @override
  Future<int> run() async {
    try {
      final args = argResults;
      if (args == null) return 1;

      final live = await buildClientAndAccount(argResults!, 'GET');

      final accountId =
          AccountId(Id(args['accountId'] ?? live.accountId.id.value));

      final id = args['id'];

      if (id != null && id is String && id.isNotEmpty) {
        final event = await CalendarEventUtil.getCalendarEventById(
          client: live.httpClient,
          accountId: accountId,
          id: id,
        );

        if (event == null) {
          print('Calendar event not found');
          return 1;
        }

        print(jsonEncode(event));
        return 0;
      }

      final events = await CalendarEventUtil.getCalendarEvents(
        client: live.httpClient,
        accountId: accountId,
      );

      print(jsonEncode(events));
      return 0;
    } catch (e) {
      print('Error: $e');
      return 1;
    }
  }
}
