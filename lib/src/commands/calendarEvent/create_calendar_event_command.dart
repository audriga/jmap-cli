import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:jmap_cli/src/commands/base_command.dart';
import 'package:jmap_dart_client/http/http_client.dart';
import 'package:jmap_dart_client/jmap/account_id.dart';
import 'package:jmap_dart_client/jmap/calendar_event/calendar_event.dart';
import 'package:jmap_dart_client/jmap/core/id.dart';
import 'package:jmap_dart_client/util/calendar_event_util.dart';

class CreateCalendarEventCommand extends BaseCommand {
  @override
  final name = 'create';

  @override
  List<String> get aliases => ['calendarEvent.create'];

  @override
  final description = 'Create calendar event using file or arguments';

  CreateCalendarEventCommand() {
    argParser.addOption(
      'file',
      abbr: 'f',
      help: 'Path to a JSON file containing the calendar event definition.',
    );
    argParser.addOption(
      'title',
      abbr: 't',
      help: 'Title of the calendar event (ignored if --file is used).',
    );
    argParser.addOption(
      'calendarIds',
      help: 'Calendar ID the event belongs to (required for IETF and Cyrus).',
    );
    argParser.addOption(
      'start',
      help: 'Event start time in ISO 8601 format.',
    );
    argParser.addOption(
      'duration',
      help: 'Event duration in ISO 8601 duration format.',
    );
  }

  String _formatDate(DateTime dt) {
    return DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(dt);
  }

  @override
  Future<int> run() async {
    try {
      if (argResults == null) return 1;

      final filePath = argResults!['file'];
      final calendarIdArg = argResults!['calendarIds'];

      final live = await buildClientAndAccount(argResults!, 'POST');

      final HttpClient httpClient = live.httpClient;

      String accountId =
          argResults!['accountId'] ?? live.accountId.id.value;

      CalendarEvent event;

      if (filePath != null) {
        final file = File(filePath);
        if (!file.existsSync()) {
          throw Exception('Invalid file path');
        }

        final decoded =
            json.decode(await file.readAsString()) as Map<String, dynamic>;

        decoded['calendarIds'] ??= {'default': true};
        event = CalendarEvent.fromJson(decoded);
      } else {
        final title = argResults!['title'] ?? 'New Event';
        final duration = argResults!['duration'];
        final rawStart = argResults!['start'];

        final start = rawStart != null && rawStart.trim().isNotEmpty
            ? rawStart.trim()
            : _formatDate(DateTime.now());

        Map<String, bool>? calendarIds;
        if (calendarIdArg != null) {
          calendarIds = {calendarIdArg: true};
        }

        event = CalendarEvent(
          title: title,
          start: start,
          duration: duration,
          calendarIds: calendarIds,
        );
      }

      final response = await CalendarEventUtil.createCalendarEvent(
        client: httpClient,
        accountId: AccountId(Id(accountId)),
        event: event,
      );

      final created = response.created?.values.first;
      final id = created?.id?.id.value;

      if (id != null) {
        print(id);
      }

      return 0;
    } catch (e) {
      print('Error: $e');
      return 1;
    }
  }
}
