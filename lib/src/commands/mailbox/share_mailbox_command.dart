import 'package:jmap_cli/src/commands/base_command.dart';
import 'package:jmap_dart_client/jmap/account_id.dart';
import 'package:jmap_dart_client/jmap/core/id.dart';
import 'package:jmap_dart_client/jmap/core/patch_object.dart';
import 'package:jmap_dart_client/util/mailbox_util.dart';

class ShareMailboxCommand extends BaseCommand {
  @override
  final name = 'share';

  @override
  List<String> get aliases => ['mailbox.share'];

  @override
  final description =
      'Share one of your own mailboxes with another account (self-service, no admin needed)';

  ShareMailboxCommand() {
    argParser
      ..addOption('withAccountId', help: 'Account id to share the mailbox with', mandatory: true)
      ..addFlag('mayReadItems', help: 'Allow reading emails in this mailbox')
      ..addFlag('mayAddItems', help: 'Allow adding emails to this mailbox')
      ..addFlag('mayRemoveItems', help: 'Allow removing emails from this mailbox')
      ..addFlag('maySetSeen', help: 'Allow marking emails as seen/unseen')
      ..addFlag('maySetKeywords', help: 'Allow setting other keywords/flags')
      ..addFlag('mayCreateChild', help: 'Allow creating child mailboxes')
      ..addFlag('mayRename', help: 'Allow renaming this mailbox')
      ..addFlag('mayDelete', help: 'Allow deleting this mailbox')
      ..addFlag('maySubmit', help: 'Allow sending mail using this mailbox')
      ..addFlag('mayShare', help: 'Allow the other account to re-share this mailbox further');
  }

  @override
  Future<int> run() async {
    try {
      final args = argResults;
      if (args == null) return 1;

      final mailboxId = args['id'] as String?;
      if (mailboxId == null || mailboxId.trim().isEmpty) {
        print('Error: --id is required (the mailbox to share)');
        return 1;
      }

      final withAccountId = args['withAccountId'] as String;

      final rights = {
        'mayReadItems': args['mayReadItems'] == true,
        'mayAddItems': args['mayAddItems'] == true,
        'mayRemoveItems': args['mayRemoveItems'] == true,
        'maySetSeen': args['maySetSeen'] == true,
        'maySetKeywords': args['maySetKeywords'] == true,
        'mayCreateChild': args['mayCreateChild'] == true,
        'mayRename': args['mayRename'] == true,
        'mayDelete': args['mayDelete'] == true,
        'maySubmit': args['maySubmit'] == true,
        'mayShare': args['mayShare'] == true,
      };

      final live = await buildClientAndAccount(args, 'POST');
      final accountId = AccountId(Id(args['accountId'] ?? live.accountId.id.value));

      final response = await MailboxUtil.updateMailbox(
        client: live.httpClient,
        accountId: accountId,
        id: Id(mailboxId),
        patch: PatchObject({
          'shareWith/$withAccountId': rights,
        }),
      );

      if (response.updated != null && response.updated!.containsKey(Id(mailboxId))) {
        print('Shared mailbox $mailboxId with account $withAccountId.');
        return 0;
      }

      print('Sharing mailbox could not be applied: ${response.notUpdated}');
      return 1;
    } catch (e) {
      print('Error: $e');
      return 1;
    }
  }
}
