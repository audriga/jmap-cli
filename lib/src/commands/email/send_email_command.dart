import 'package:jmap_cli/src/commands/base_command.dart';
import 'package:jmap_dart_client/jmap/account_id.dart';
import 'package:jmap_dart_client/jmap/core/id.dart';
import 'package:jmap_dart_client/jmap/mail/email/email.dart';
import 'package:jmap_dart_client/jmap/mail/email/email_address.dart';
import 'package:jmap_dart_client/jmap/mail/email/email_body_part.dart';
import 'package:jmap_dart_client/jmap/mail/email/email_body_value.dart';
import 'package:jmap_dart_client/jmap/mail/email/submission/address.dart';
import 'package:jmap_dart_client/jmap/mail/email/submission/email_submission.dart';
import 'package:jmap_dart_client/jmap/mail/email/submission/envelope.dart';
import 'package:jmap_dart_client/jmap/mail/mailbox/mailbox.dart';
import 'package:http_parser/http_parser.dart';
import 'package:jmap_dart_client/util/email_util.dart';

class SendEmailCommand extends BaseCommand {
  @override
  final name = 'send';

  @override
  List<String> get aliases => ['email.send'];

  @override
  final description = 'Create and submit an email for delivery via Email/set + EmailSubmission/set';

  SendEmailCommand() {
    argParser
      ..addOption(
        'emailId',
        help: 'Id of an already-created email to submit. '
            'If provided, --from/--to/--subject/--body are ignored.',
      )
      ..addOption('identityId', help: 'Identity id to use for sending. Required.')
      ..addOption('from', help: 'Sender email address.')
      ..addOption('to', help: 'Recipient email address (comma-separated for multiple).')
      ..addOption('subject', abbr: 's', help: 'Email subject.')
      ..addOption('body', abbr: 'b', help: 'Plain-text body.')
      ..addOption('mailboxId', abbr: 'm', help: 'Mailbox id to store the sent email in (e.g. Sent folder id).');
  }

  @override
  Future<int> run() async {
    try {
      if (argResults == null) return 1;

      final live = await buildClientAndAccount(argResults!, 'POST');
      final accountId = AccountId(Id(argResults!['accountId'] ?? live.accountId.id.value));

      final identityIdArg = argResults!['identityId'] as String?;
      if (identityIdArg == null || identityIdArg.trim().isEmpty) {
        print('Error: --identityId is required');
        return 1;
      }

      String emailId;
      final existingEmailId = argResults!['emailId'] as String?;

      if (existingEmailId != null && existingEmailId.isNotEmpty) {
        emailId = existingEmailId;
      } else {
        final fromArg = argResults!['from'] as String?;
        final toArg = argResults!['to'] as String?;
        final subject = argResults!['subject'] as String? ?? '';
        final body = argResults!['body'] as String?;
        final mailboxIdArg = argResults!['mailboxId'] as String?;

        if (fromArg == null || toArg == null) {
          print('Error: --from and --to are required when not providing --emailId');
          return 1;
        }

        final toAddresses = toArg
            .split(',')
            .map((a) => EmailAddress(null, a.trim()))
            .toSet();

        final email = Email(
          subject: subject,
          from: {EmailAddress(null, fromArg)},
          to: toAddresses,
          mailboxIds: mailboxIdArg != null ? {MailboxId(Id(mailboxIdArg)): true} : null,
          bodyValues: body != null
              ? {PartId('text1'): EmailBodyValue(value: body, isEncodingProblem: false, isTruncated: false)}
              : null,
          textBody: body != null
              ? {EmailBodyPart(partId: PartId('text1'), type: MediaType.parse('text/plain'))}
              : null,
        );

        final createResp = await EmailUtil.createEmail(
          client: live.httpClient,
          accountId: accountId,
          email: email,
        );

        final createdId = createResp.created?.values.first.id?.id.value;
        if (createdId == null) {
          final createErrors = createResp.notCreated?.map((k, v) => MapEntry(k.value, '${v.type.value}: ${v.description}'));
          print('Error: failed to create email draft: $createErrors');
          return 1;
        }
        emailId = createdId;
      }

      final fromArg = argResults!['from'] as String?;
      final toArg = argResults!['to'] as String?;

      Envelope? envelope;
      if (fromArg != null && toArg != null) {
        envelope = Envelope(
          Address(fromArg),
          toArg.split(',').map((a) => Address(a.trim())).toSet(),
        );
      }

      final submission = EmailSubmission(
        identityId: Id(identityIdArg),
        emailId: EmailId(Id(emailId)),
        envelope: envelope,
      );

      final sendResp = await EmailUtil.sendEmail(
        client: live.httpClient,
        accountId: accountId,
        submission: submission,
      );

      final submissionId = sendResp.created?.values.first.id?.id.value;
      if (submissionId != null) {
        print(submissionId);
        return 0;
      }

      final errors = sendResp.notCreated?.map((k, v) => MapEntry(k.value, '${v.type.value}: ${v.description}'));
      print('Error: email submission failed: $errors');
      return 1;
    } catch (e) {
      print('Error: $e');
      return 1;
    }
  }
}
