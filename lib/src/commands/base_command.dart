import 'dart:convert';
import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:dio/dio.dart';
import 'package:jmap_cli/jmap_cli.dart';
import 'package:jmap_dart_client/http/http_client.dart' as jmap_http;
import 'package:jmap_dart_client/jmap/account_id.dart';
import 'package:jmap_dart_client/jmap/core/id.dart';

class JmapClientContext {
  final jmap_http.HttpClient httpClient;
  final AccountId accountId;

  JmapClientContext(this.httpClient, this.accountId);
}

abstract class BaseCommand extends Command<int> {
  BaseCommand() {
    argParser
      ..addOption('url', help: 'URL of the server')
      ..addOption('userName', abbr: 'u', help: 'User Name')
      ..addOption('userPassword', abbr: 'p', help: 'User Password')
      ..addOption('token', help: 'User Token')
      ..addOption('accountId', abbr: 'a', help: 'Account Id')
      ..addOption('id', abbr: 'i', help: 'Id use for delete');
  }

  jmap_http.HttpClient createJmapHttpClient(ArgResults? args, String method) {
    final userName = args?['userName'] as String? ?? '';
    final userPassword = args?['userPassword'] as String? ?? '';
     final url = args?['url'] as String? ?? '';

    final auth = 'Basic ${base64Encode(utf8.encode('$userName:$userPassword'))}';

    final headers = <String, String>{
      'content-type': 'application/json; charset=utf-8',
      'accept': 'application/json;jmapVersion=rfc-8621',
      'authorization': auth,
    };

    final options = BaseOptions(
      method: method.toUpperCase(),
      baseUrl: url,
      headers: headers,
    );

    final dio = Dio(options);
    return jmap_http.HttpClient(dio);
  }

  Future<JmapClientContext> buildClientAndAccount(
      ArgResults args, String method) async {
    final accountIdArg = args['accountId'] as String?;

    if (accountIdArg != null && accountIdArg.isNotEmpty) {
      final client = createJmapHttpClient(args, method);
      final accountId = AccountId(Id(accountIdArg));
      return JmapClientContext(client, accountId);
    }

    final live = await GetSessionCommand().getLiveClient(args, method);
    return JmapClientContext(live.httpClient, live.accountId);
  }
}

