import 'package:jmap_cli/jmap_cli.dart';
import 'package:jmap_cli/src/commands/base_command.dart';

class EmailCommand extends BaseCommand {
  @override
  final name = 'email';

  @override
  final description = 'Manage JMAP emails';

  EmailCommand() {
    addSubcommand(GetEmailCommand());
    addSubcommand(CreateEmailCommand());
    addSubcommand(SendEmailCommand());
    addSubcommand(DeleteEmailCommand());
    addSubcommand(ChangesEmailCommand());
    addSubcommand(QueryEmailCommand());
  }

  @override
  Future<int> run() async {
    print('Usage: jmap-cli email <command> [options]');
    print('');
    print('Available commands:');
    print('  get        Get emails or a single email by id (use -o out.eml for raw MIME, --all for paged fetch)');
    print('  create     Create an email from args or a file (.eml files are imported via Email/import)');
    print('  send       Create and submit an email for delivery');
    print('  delete     Delete an email');
    print('  query      Query email ids with optional filter and paging');
    print('  changes    Show email changes since a given state');
    return 1;
  }
}
