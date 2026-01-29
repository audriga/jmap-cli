import 'package:jmap_cli/src/commands/base_command.dart';
import 'package:jmap_cli/src/common/jmap_util.dart';
import 'package:jmap_dart_client/jmap/core/id.dart';
import 'package:jmap_dart_client/util/contact_util.dart';

class DeletecontactCommand extends BaseCommand {
  @override
  final name = 'delete';

  @override
  List<String> get aliases => ['contact.delete'];

  @override
  final description = 'Delete a contact by id';

  DeletecontactCommand() {
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

      final id = args['id'];
      if (id == null || id is! String || id.isEmpty) {
        print('Missing --id');
        return 1;
      }

      final apiVersion =
          JmapUtils.parseApiVersion(args['apiVersion']);

      final live = await buildClientAndAccount(args, 'POST');

      final resp = await ContactUtil.deleteContact(
        client: live.httpClient,
        accountId: live.accountId,
        id: Id(id.toString()),
        apiVersion: apiVersion,
      );
      if (resp.destroyed != null && resp.destroyed!.isNotEmpty) {
        print(id);
        return 0;
      }
      print('contact could not be deleted');
      return 1;
    } catch (e) {
      print('Error: $e');
      return 1;
    }
  }
}
