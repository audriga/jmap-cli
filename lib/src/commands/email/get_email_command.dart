import 'dart:convert';
import 'dart:io';
import 'package:jmap_cli/src/commands/base_command.dart';
import 'package:jmap_cli/src/commands/session/get_session_command.dart';
import 'package:jmap_dart_client/jmap/account_id.dart';
import 'package:jmap_dart_client/jmap/core/id.dart';
import 'package:jmap_dart_client/jmap/mail/email/email_filter_condition.dart';
import 'package:jmap_dart_client/jmap/mail/mailbox/mailbox.dart';
import 'package:jmap_dart_client/util/email_util.dart';

class GetEmailCommand extends BaseCommand {
  @override
  final name = 'get';

  @override
  List<String> get aliases => ['email.get'];

  @override
  final description = 'Get emails or a single email by id';

  GetEmailCommand() {
    argParser
      ..addFlag('all', help: 'Fetch all emails using paged queries (for large mailboxes).')
      ..addOption('mailboxId', abbr: 'm', help: 'Filter by mailbox id when using --all.')
      ..addOption('batchSize', help: 'Number of emails to fetch per page when using --all (default: 50).')
      ..addOption('output', abbr: 'o', help: 'Write output to a file. If the path ends in .eml, downloads raw MIME instead of JSON.');
  }

  @override
  Future<int> run() async {
    try {
      final args = argResults;
      if (args == null) return 1;

      final idArg = args['id'] as String?;

      final outputPath = args['output'] as String?;
      if (outputPath != null && outputPath.endsWith('.eml')) {
        if (idArg == null || idArg.trim().isEmpty) {
          print('Error: --id is required when downloading MIME');
          return 1;
        }
        final live = await GetSessionCommand().getLiveClient(args, 'GET');
        final accountId = AccountId(Id(args['accountId'] ?? live.accountId.id.value));
        final authHeader = live.dio.options.headers['authorization'] as String? ??
            live.dio.options.headers['Authorization'] as String? ?? '';

        final mimeBytes = await EmailUtil.downloadEmailMime(
          client: live.httpClient,
          accountId: accountId,
          emailId: idArg,
          dio: live.dio,
          downloadUrlTemplate: live.downloadTemplate ?? '',
          authorization: authHeader,
        );

        await File(outputPath).writeAsBytes(mimeBytes);
        print('MIME written to $outputPath');
        return 0;
      }

      final live = await buildClientAndAccount(args, 'GET');
      final accountId = AccountId(Id(args['accountId'] ?? live.accountId.id.value));

      if (idArg != null && idArg.isNotEmpty) {
        final email = await EmailUtil.getEmailById(
          client: live.httpClient,
          accountId: accountId,
          id: idArg,
        );

        if (email == null) {
          print('Email not found');
          return 1;
        }

        print(jsonEncode(email));
        return 0;
      }

      if (args['all'] == true) {
        final mailboxIdArg = args['mailboxId'] as String?;
        final batchSizeArg = args['batchSize'] as String?;
        final filter = mailboxIdArg != null
            ? EmailFilterCondition(inMailbox: MailboxId(Id(mailboxIdArg)))
            : null;
        final batchSize = batchSizeArg != null ? int.parse(batchSizeArg) : 50;
        final emails = await EmailUtil.getAllEmails(
          client: live.httpClient,
          accountId: accountId,
          filter: filter,
          batchSize: batchSize,
        );
        print(jsonEncode(emails));
        return 0;
      }

      final resp = await EmailUtil.getEmails(
        client: live.httpClient,
        accountId: accountId,
      );

      print(jsonEncode(resp));
      return 0;
    } catch (e) {
      print('Error: $e');
      return 1;
    }
  }
}
