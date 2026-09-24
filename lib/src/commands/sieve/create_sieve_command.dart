import 'dart:io';
import 'package:jmap_cli/src/commands/base_command.dart';
import 'package:jmap_cli/src/commands/session/get_session_command.dart';
import 'package:jmap_dart_client/jmap/account_id.dart';
import 'package:jmap_dart_client/jmap/core/id.dart';
import 'package:jmap_dart_client/util/sieve_util.dart';

class CreateSieveCommand extends BaseCommand {
  @override
  final name = 'create';

  @override
  List<String> get aliases => ['sieve.create'];

  @override
  final description = 'Create a sieve script from a file or inline content';

  CreateSieveCommand() {
    argParser
      ..addOption('name', abbr: 'n', help: 'Name of the sieve script.', mandatory: true)
      ..addOption('file', abbr: 'f', help: 'Path to a file containing the sieve script source.')
      ..addOption('content', help: 'Sieve script source, given inline instead of a file.');
  }

  @override
  Future<int> run() async {
    try {
      final args = argResults;
      if (args == null) return 1;

      final name = args['name'] as String;
      final filePath = args['file'] as String?;
      final inlineContent = args['content'] as String?;

      String content;
      if (filePath != null) {
        final file = File(filePath);
        if (!file.existsSync()) {
          print('File not found: $filePath');
          return 1;
        }
        content = await file.readAsString();
      } else if (inlineContent != null) {
        content = inlineContent;
      } else {
        print('Error: either --file or --content is required');
        return 1;
      }

      final live = await GetSessionCommand().getLiveClient(args, 'POST');
      final accountId = AccountId(Id(args['accountId'] ?? live.accountId.id.value));

      final uploadTemplate = Uri.decodeFull(live.session.uploadUrl.toString())
          .replaceFirst('{accountId}', accountId.id.value);
      // Cyrus returns a server-relative path; make it absolute to avoid Dio
      // appending it to the JMAP API path and producing a duplicate segment.
      final uploadUrl = uploadTemplate.startsWith('http://') || uploadTemplate.startsWith('https://')
          ? uploadTemplate
          : Uri.parse(live.dio.options.baseUrl)
              .replace(path: uploadTemplate)
              .toString();

      final id = await SieveUtil.createSieveScript(
        client: live.httpClient,
        accountId: accountId,
        name: name,
        content: content,
        httpUploadUrl: uploadUrl,
      );

      if (id != null) {
        print(id);
        return 0;
      }

      print('Sieve script could not be created!');
      return 1;
    } catch (e) {
      print('Error: $e');
      return 1;
    }
  }
}
