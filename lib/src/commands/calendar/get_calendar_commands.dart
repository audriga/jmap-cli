import 'dart:convert';
import 'package:jmap_cli/src/commands/base_command.dart';
import 'package:jmap_dart_client/jmap/account_id.dart';
import 'package:jmap_dart_client/jmap/core/id.dart';
import 'package:jmap_dart_client/util/calendar_util.dart';

class GetCalendarCommand extends BaseCommand {
  @override
  final name = 'get';

  @override
  List<String> get aliases => ['calendar.get'];

  @override
  final description = 'Get calendar or a single calendar by id';

  GetCalendarCommand();

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
        final cal = await CalendarUtil.getCalendarById(
          client: live.httpClient,
          accountId: accountId,
          id: id,
        );

        if (cal == null) {
          print('Calendar not found');
          return 1;
        }

        print(jsonEncode(cal));
        return 0;
      }

      final cals = await CalendarUtil.getCalendars(
        client: live.httpClient,
        accountId: accountId,
      );

      print(jsonEncode(cals));
      return 0;
    } catch (e) {
      print('Error: $e');
      return 1;
    }
  }
}
