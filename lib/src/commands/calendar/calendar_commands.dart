import 'package:jmap_cli/jmap_cli.dart';
import 'package:jmap_cli/src/commands/base_command.dart';

class CalendarCommand extends BaseCommand {
  @override
  final name = 'calendar';

  @override
  final description = 'Manage JMAP calendar';

  CalendarCommand() {
    addSubcommand(GetCalendarCommand());
    addSubcommand(CreateCalendarCommand());
    addSubcommand(ChangesCalendarCommand());
    addSubcommand(DeleteCalendarCommand());
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
