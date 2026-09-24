import 'dart:convert';
import 'dart:io' show Platform;
import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:dio/dio.dart';
import 'package:jmap_cli/jmap_cli.dart';
import 'package:jmap_dart_client/http/http_client.dart' as jmap_http;
import 'package:jmap_dart_client/jmap/account_id.dart';
import 'package:jmap_dart_client/jmap/core/id.dart';
import 'package:jmap_dart_client/util/session_util.dart';

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
      ..addOption('id', abbr: 'i', help: 'Id use for delete')
      ..addOption('impersonate', help: 'Email of another account to act as, requires the logged-in user to have delegation/impersonation rights on the server');
  }

  jmap_http.HttpClient createJmapHttpClient(ArgResults? args, String method) {
    final userName = (args?['userName'] as String?)?.isNotEmpty == true
        ? args!['userName'] as String
        : Platform.environment['JMAP_USERNAME'] ?? '';
    final userPassword = (args?['userPassword'] as String?)?.isNotEmpty == true
        ? args!['userPassword'] as String
        : Platform.environment['JMAP_PASSWORD'] ?? '';
    final url = (args?['url'] as String?)?.isNotEmpty == true
        ? args!['url'] as String
        : Platform.environment['JMAP_URL'] ?? '';

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
    final impersonateEmail = (args['impersonate'] as String?)?.isNotEmpty == true
        ? args['impersonate'] as String
        : null;

    if (impersonateEmail != null) {
      final live = await GetSessionCommand().getLiveClient(args, method);
      final resolvedId = await resolvePrincipalAccountId(live, impersonateEmail);
      return JmapClientContext(live.httpClient, AccountId(Id(resolvedId)));
    }

    final accountIdArg = (args['accountId'] as String?)?.isNotEmpty == true
        ? args['accountId'] as String
        : Platform.environment['JMAP_ACCOUNT_ID'];

    if (accountIdArg != null && accountIdArg.isNotEmpty) {
      final client = createJmapHttpClient(args, method);
      final accountId = AccountId(Id(accountIdArg));
      return JmapClientContext(client, accountId);
    }

    final live = await GetSessionCommand().getLiveClient(args, method);
    return JmapClientContext(live.httpClient, live.accountId);
  }

  /// Resolves the JMAP accountId for [email] using the Principals capability
  /// (Principal/query + Principal/get), the way an admin with delegation
  /// rights looks up another account without needing that account's password.
  Future<String> resolvePrincipalAccountId(
      JmapLiveClient live, String email) async {
    final body = {
      'using': ['urn:ietf:params:jmap:core', 'urn:ietf:params:jmap:principals'],
      'methodCalls': [
        [
          'Principal/query',
          {
            'accountId': live.accountId.id.value,
            'filter': {'email': email},
          },
          'c0',
        ],
        [
          'Principal/get',
          {
            'accountId': live.accountId.id.value,
            '#ids': {
              'resultOf': 'c0',
              'name': 'Principal/query',
              'path': '/ids',
            },
            'properties': ['accounts'],
          },
          'c1',
        ],
      ],
    };

    final response = await live.httpClient.post('', data: body);
    final methodResponses = response['methodResponses'] as List;
    final getResult = methodResponses[1][1] as Map<String, dynamic>;
    final list = getResult['list'] as List?;

    if (list == null || list.isEmpty) {
      throw Exception('No principal found for email: $email');
    }

    // "accounts" is keyed by accountId, with each value being that account's
    // capability map, not the capability map directly.
    final accounts = (list.first as Map<String, dynamic>)['accounts']
        as Map<String, dynamic>?;

    for (final capsForAccount in accounts?.values ?? <dynamic>[]) {
      final ownerCapability = (capsForAccount as Map<String, dynamic>)[
          'urn:ietf:params:jmap:principals:owner'] as Map<String, dynamic>?;
      final accountId = ownerCapability?['accountIdForPrincipal'] as String?;
      if (accountId != null) return accountId;
    }

    throw Exception('Could not resolve accountId for principal: $email');
  }
}

