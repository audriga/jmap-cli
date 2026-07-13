import 'dart:convert';
import 'package:jmap_cli/src/commands/base_command.dart';
import 'package:jmap_dart_client/jmap/account_id.dart';
import 'package:jmap_dart_client/jmap/core/id.dart';
import 'package:jmap_dart_client/jmap/core/unsigned_int.dart';
import 'package:jmap_dart_client/jmap/mail/email/email_filter_condition.dart';
import 'package:jmap_dart_client/jmap/mail/mailbox/mailbox.dart';
import 'package:jmap_dart_client/util/email_util.dart';

class QueryEmailCommand extends BaseCommand {
  @override
  final name = 'query';

  @override
  List<String> get aliases => ['email.query'];

  @override
  final description = 'Query email ids, optionally filtering by mailbox id';

  QueryEmailCommand() {
    argParser
      ..addOption('mailboxId', abbr: 'm', help: 'Filter emails to this mailbox id.')
      ..addOption('limit', abbr: 'l', help: 'Maximum number of ids to return.')
      ..addOption('position', help: 'Zero-based index of the first result to return (for paging).');
  }

  @override
  Future<int> run() async {
    try {
      if (argResults == null) return 1;

      final live = await buildClientAndAccount(argResults!, 'POST');
      final accountId = AccountId(Id(argResults!['accountId'] ?? live.accountId.id.value));

      final mailboxIdArg = argResults!['mailboxId'] as String?;
      final limitArg = argResults!['limit'] as String?;
      final positionArg = argResults!['position'] as String?;

      final filter = mailboxIdArg != null
          ? EmailFilterCondition(inMailbox: MailboxId(Id(mailboxIdArg)))
          : null;

      final limit = limitArg != null ? UnsignedInt(int.parse(limitArg)) : null;
      final position = positionArg != null ? int.parse(positionArg) : null;

      final resp = await EmailUtil.queryEmails(
        client: live.httpClient,
        accountId: accountId,
        filter: filter,
        limit: limit,
        position: position,
      );

      print(jsonEncode(resp));
      return 0;
    } catch (e) {
      print('Error: $e');
      return 1;
    }
  }
}
