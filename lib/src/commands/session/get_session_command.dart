import 'dart:convert';
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
    final raw = args['url'];
    if (raw == null || raw is! String) {
      throw Exception('Missing --url');
    }
    // If --url already contains JSON, pass it through
    if (raw.trim().startsWith('{')) {
    } else {
      final username = args['userName'];
      final password = args['userPassword'];
      final token = args['token'];

      if (token == null && (username == null || password == null)) {
        throw Exception('Missing authentication');
      }

      <String, dynamic>{
        'url': raw,
        if (token != null) 'token': token,
        if (token == null) 'username': username,
        if (token == null) 'password': password,
      };

    }

    if (raw.trim().startsWith('{')) {
      return createLiveClientFromJson(
        credentialsJson: raw,
        httpMethod: httpMethod,
      );
    }

    return createLiveClientFromJson(
      credentialsJson: jsonEncode({

        'url': raw,
        if (args['token'] != null) 'token': args['token'],
        if (args['token'] == null) 'username': args['userName'],
        if (args['token'] == null) 'password': args['userPassword'],
      }),
      httpMethod: httpMethod,
    );
  }
}