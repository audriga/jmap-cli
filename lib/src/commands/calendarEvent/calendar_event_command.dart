import 'package:jmap_cli/jmap_cli.dart';
import 'package:jmap_cli/src/commands/base_command.dart';

class CalendarEventCommand extends BaseCommand {
  @override
  final name = 'calendarEvent';

  @override
  final description = 'Manage JMAP calendar events';

  CalendarEventCommand() {
    addSubcommand(GetCalendarEventCommand());
    addSubcommand(CreateCalendarEventCommand());
    addSubcommand(DeleteCalendarEventCommand());
    addSubcommand(ChangesCalendarEventCommand());
  }

  @override
  Future<int> run() async {
    print('Usage: jmap-cli calendar <command> [options]');
    print('');
    print('Available commands:');
    print('  get        Get calendar events or a single event by id');
    print('  create     Create a calendar event');
    print('  delete     Delete a calendar event');
    print('  changes    Show calendar event changes');
    return 1;
  }
}
