import 'dart:convert';
import 'package:jmap_cli/src/commands/base_command.dart';
import 'package:jmap_cli/src/common/jmap_util.dart';
import 'package:jmap_dart_client/jmap/contact/card.dart';
import 'package:jmap_dart_client/jmap/contact/contact_api_version.dart';
import 'package:jmap_dart_client/jmap/contact/contact_card.dart';
import 'package:jmap_dart_client/util/contact_util.dart';

class GetContactCommand extends BaseCommand {
  @override
  final name = 'get';

  @override
  List<String> get aliases => ['contact.get'];

  @override
  final description = 'Get contacts or a single contact by id';

    GetContactCommand() {
      argParser.addOption(
        'apiVersion',
        abbr: 'v',
        allowed: ['ietf', 'cyrus', 'jscontact'],
        defaultsTo: 'ietf',
      );
    }

  @override
  Future<int> run() async {
    try {
      final args = argResults;
      if (args == null) return 1;

      final apiVersion =
          JmapUtils.parseApiVersion(args['apiVersion']);

      final live = await buildClientAndAccount(args, 'GET');

      final id = args['id'];
      if (id != null && id is String && id.isNotEmpty) {
        final contact = await ContactUtil.getContactById(
          client: live.httpClient,
          accountId: live.accountId,
          id: id,
          apiVersion: apiVersion,
        );

        if (contact == null) {
          print('Contact not found');
          return 1;
        }
        if (apiVersion == ContactApiVersion.ietf) {
          print(jsonEncode(contact as ContactCard));
        } else {
          print(jsonEncode(contact as Card));
        }
        return 0;
      }
      final all = await ContactUtil.getContacts(
        client: live.httpClient,
        accountId: live.accountId,
        apiVersion: apiVersion,
      );

      print(jsonEncode(all));
      return 0;
    } catch (e) {
      print('Error: $e');
      return 1;
    }
  }
}
