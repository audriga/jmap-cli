import 'package:jmap_cli/src/commands/base_command.dart';
import 'package:jmap_dart_client/util/identity_util.dart';

class GetIdentityCommand extends BaseCommand {
  @override
  final name = 'get';

  @override
  List<String> get aliases => ['identity.get'];
  @override
  final description = 'Get all information of Identity';

  GetIdentityCommand();

  @override
  Future<int> run() async {
    try {
      if (argResults == null) {
        return 1;
      }

      final live = await buildClientAndAccount(argResults!, 'GET');

      final response = await IdentityUtil.getIdentities(
        client: live.httpClient,
        accountId: live.accountId,
      );

      if (response.list.isEmpty) {
        print('No identities found');
        return 0;
      }

      for (final identity in response.list) {
        print('Account Id : ${identity.id?.id.value}');
        print('Name : ${identity.name}');
        print('Email : ${identity.email}');
        print('Text Signature : ${identity.textSignature?.value}');
        print('Html Signature : ${identity.htmlSignature?.value}');
        print('---');
      }

      return 0;
    } catch (e) {
      print('Error: $e');
      return 1;
    }
  }
}
