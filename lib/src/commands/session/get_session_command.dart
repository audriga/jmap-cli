import 'dart:convert';
import 'dart:io' show Platform;
import 'package:args/args.dart';
import 'package:jmap_cli/src/commands/base_command.dart';
import 'package:jmap_dart_client/util/session_util.dart';

class GetSessionCommand extends BaseCommand {
   @override
  final name = 'get';

  @override
  List<String> get aliases => ['session.get'];

  @override
  final description = 'Get all information of JMAP Session';

  @override
  Future<int> run() async {
    try {
      if (argResults == null) return 1;

      final live = await getLiveClient(argResults!, 'GET');
      print('accountId   : ${live.accountId.id.value}');
      print('username    : ${live.session.username.value}');
      print('apiUrl      : ${live.session.apiUrl}');
      print('downloadUrl : ${live.downloadTemplate}');
      print('capabilities:');
      for (final cap in live.capabilities.keys) {
         print('  - $cap');
      }

      return 0;
    } catch (e) {
      print('Exception: $e');
      return 1;
    }
  }


  Future<JmapLiveClient> getLiveClient(
    ArgResults args,
    String httpMethod,
  ) async {
    final raw = (args['url'] as String?)?.isNotEmpty == true
        ? args['url'] as String
        : Platform.environment['JMAP_URL'];

    if (raw == null || raw.isEmpty) {
      throw Exception('Missing --url');
    }

    if (raw.trim().startsWith('{')) {
      return createLiveClientFromJson(
        credentialsJson: raw,
        httpMethod: httpMethod,
      );
    }

    final username = (args['userName'] as String?)?.isNotEmpty == true
        ? args['userName'] as String
        : Platform.environment['JMAP_USERNAME'];
    final password = (args['userPassword'] as String?)?.isNotEmpty == true
        ? args['userPassword'] as String
        : Platform.environment['JMAP_PASSWORD'];
    final token = (args['token'] as String?)?.isNotEmpty == true
        ? args['token']
        : Platform.environment['JMAP_TOKEN'];

    return createLiveClientFromJson(
      credentialsJson: jsonEncode({
        'url': raw,
        if (token != null) 'token': token,
        if (token == null) 'username': username,
        if (token == null) 'password': password,
      }),
      httpMethod: httpMethod,
    );
  }
}