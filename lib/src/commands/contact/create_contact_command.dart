import 'dart:convert';
import 'dart:io';
import 'package:jmap_cli/src/commands/base_command.dart';
import 'package:jmap_cli/src/common/jmap_util.dart';
import 'package:jmap_dart_client/jmap/contact/card.dart';
import 'package:jmap_dart_client/jmap/contact/components.dart';
import 'package:jmap_dart_client/jmap/contact/contact.dart';
import 'package:jmap_dart_client/jmap/contact/contact_card.dart';
import 'package:jmap_dart_client/jmap/contact/name.dart';
import 'package:jmap_dart_client/util/contact_util.dart';

class CreateContactCommand extends BaseCommand {
  @override
  final name = 'create';
  
  @override
  List<String> get aliases => ['contact.create'];

  @override
  final description = 'Create a contact using file or fullName';

  CreateContactCommand() {
    argParser
      ..addOption('file', abbr: 'f')
      ..addOption('fullName')
      ..addOption(
        'apiVersion',
        allowed: ['ietf', 'cyrus', 'jscontact'],
        defaultsTo: 'ietf',
      )
      ..addOption(
        'addressBookIds',
        abbr: 'b',
        help: 'Required for ietf',
      );
  }

  @override
  Future<int> run() async {
    try {
      final args = argResults;
      if (args == null) return 1;

      final apiVersion =
          JmapUtils.parseApiVersion(args['apiVersion']);

      final live = await buildClientAndAccount(args, 'POST');

      Contact contact;

      final filePath = args['file'];

      if (filePath != null) {
        final file = File(filePath);
        if (!file.existsSync()) {
          print('File not found: $filePath');
          return 1;
        }

        final json = jsonDecode(await file.readAsString());

        if (apiVersion.name == 'ietf') {
          contact = ContactCard.fromJson(json);
        } else {
          contact = Card.fromJson(json, apiVersion: apiVersion);
        }
      } else {
        final fullName = args['fullName'];
        if (fullName == null || fullName.isEmpty) {
          print('Missing --fullName');
          return 1;
        }

        if (apiVersion.name == 'ietf') {
          final addressBookId = args['addressBookIds'];
          if (addressBookId == null) {
            print('--addressBookIds is required for ietf');
            return 1;
          }

          final parts = fullName.split(RegExp(r'\s+'));
          final components = <Components>{};

          if (parts.isNotEmpty) {
            // first part is always given name
            components.add(
              Components(kind: 'given', value: parts.first),
            );
          }

          if (parts.length == 2) {
            // second part is simple surname
            components.add(
              Components(kind: 'surname', value: parts[1]),
            );
          } else if (parts.length >= 3) {
            // middle part => surname
            final middle = parts.sublist(1, parts.length - 1).join(' ');
            components.add(
              Components(kind: 'surname', value: middle),
            );
            // last part => surname2
            components.add(
              Components(kind: 'surname2', value: parts.last),
            );
          }

          contact = ContactCard(
            addressBookIds: {addressBookId: true},
            name: Name(components: components),
          );
        } else {
          contact = Card(fullName: fullName);
        }
      }
      final response = await ContactUtil.createContact(
        client: live.httpClient,
        accountId: live.accountId,
        contact: contact,
        apiVersion: apiVersion,
      );
      final created = response.created;
      if (created == null || created.isEmpty) {
        print('Contact creation failed');
        return 1;
      }

      print(created.values.first.id!.value);
      return 0;
    } catch (e) {
      print('Error: $e');
      return 1;
    }
  }
}
