import 'dart:convert';
import 'dart:io';
import 'package:http_parser/http_parser.dart';
import 'package:jmap_cli/src/commands/base_command.dart';
import 'package:jmap_dart_client/jmap/account_id.dart';
import 'package:jmap_dart_client/jmap/core/id.dart';
import 'package:jmap_dart_client/jmap/mail/email/email.dart';
import 'package:jmap_dart_client/jmap/mail/email/email_address.dart';
import 'package:jmap_dart_client/jmap/mail/email/email_body_part.dart';
import 'package:jmap_dart_client/jmap/mail/email/email_body_value.dart';
import 'package:jmap_dart_client/jmap/mail/mailbox/mailbox.dart';
import 'package:jmap_dart_client/util/email_util.dart';

class CreateEmailCommand extends BaseCommand {
  @override
  final name = 'create';

  @override
  List<String> get aliases => ['email.create'];

  @override
  final description = 'Create an email using a file or arguments';

  CreateEmailCommand() {
    argParser
      ..addOption('file', abbr: 'f', help: 'Path to a JSON or .eml file. .eml files are imported via Email/import automatically.')
      ..addOption('subject', abbr: 's', help: 'Email subject.')
      ..addOption('from', help: 'Sender email address.')
      ..addOption('to', help: 'Recipient email address.')
      ..addOption('body', abbr: 'b', help: 'Plain-text body of the email.')
      ..addOption('mailboxId', abbr: 'm', help: 'Mailbox id to place the email in.');
  }

  @override
  Future<int> run() async {
    try {
      if (argResults == null) return 1;

      final live = await buildClientAndAccount(argResults!, 'POST');
      final accountId = AccountId(Id(argResults!['accountId'] ?? live.accountId.id.value));

      final filePath = argResults!['file'] as String?;

      if (filePath != null && filePath.endsWith('.eml')) {
        final mailboxIdArg = argResults!['mailboxId'] as String?;
        if (mailboxIdArg == null) {
          print('Error: --mailboxId is required when importing a .eml file');
          return 1;
        }
        final file = File(filePath);
        if (!file.existsSync()) throw Exception('File not found: $filePath');
        final id = await EmailUtil.importEmailMime(
          client: live.httpClient,
          accountId: accountId,
          mimeBytes: await file.readAsBytes(),
          mailboxId: mailboxIdArg,
        );
        print(id);
        return 0;
      }

      Email email;

      if (filePath != null) {
        final file = File(filePath);
        if (!file.existsSync()) throw Exception('File not found: $filePath');
        final decoded = json.decode(await file.readAsString()) as Map<String, dynamic>;
        final mailboxIdArg = argResults!['mailboxId'];
        if (mailboxIdArg != null && !decoded.containsKey('mailboxIds')) {
          decoded['mailboxIds'] = <String, dynamic>{mailboxIdArg: true};
        }
        email = Email.fromJson(decoded);
      } else {
        final subject = argResults!['subject'] ?? 'New Email';
        final fromAddr = argResults!['from'];
        final toAddr = argResults!['to'];
        final body = argResults!['body'];
        final mailboxIdArg = argResults!['mailboxId'];

        email = Email(
          subject: subject,
          from: fromAddr != null ? {EmailAddress(null, fromAddr)} : null,
          to: toAddr != null ? {EmailAddress(null, toAddr)} : null,
          mailboxIds: mailboxIdArg != null ? {MailboxId(Id(mailboxIdArg)): true} : null,
          bodyValues: body != null
              ? {PartId('text1'): EmailBodyValue(value: body, isEncodingProblem: false, isTruncated: false)}
              : null,
          textBody: body != null ? {EmailBodyPart(partId: PartId('text1'), type: MediaType.parse('text/plain'))} : null,
        );
      }

      final resp = await EmailUtil.createEmail(
        client: live.httpClient,
        accountId: accountId,
        email: email,
      );

      final created = resp.created?.values.first;
      final id = created?.id?.id.value;

      if (id != null) {
        print(id);
        return 0;
      }

      final errors = resp.notCreated?.map((k, v) => MapEntry(k.value, '${v.type.value}: ${v.description}'));
      print('Email could not be created: $errors');
      return 1;
    } catch (e) {
      print('Error: $e');
      return 1;
    }
  }
}
