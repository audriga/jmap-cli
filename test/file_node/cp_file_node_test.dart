import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:jmap_cli/src/common/jmap_util.dart';

void main() {
  group('CLI FileNode tests', () {
    test('fileNodes cp recursive local folder to remote', () async {
      final auth = await jsonDecode(
        await File('test/data/credentials/auth_ietf.json').readAsString(),
      );

      final localDir = Directory('recursive_upload');
      await localDir.create(recursive: true);

      await File('${localDir.path}/a.txt').writeAsString('A');
      await Directory('${localDir.path}/sub').create();
      await File('${localDir.path}/sub/b.txt').writeAsString('B');

      final remoteDir =
          'jmap:UploadTestFolder/recursive_upload_${DateTime.now().millisecondsSinceEpoch}';

      final process = await Process.start('dart', [
        'bin/jmap_cli.dart',
        'fileNodes',
        'cp',
        '-r',
        localDir.path,
        remoteDir,
        '--url',
        auth['url'],
        '-u',
        auth['username'],
        '-p',
        auth['password'],
      ]);

      final stderrData =
          await process.stderr.transform(utf8.decoder).join();
      final exitCode = await process.exitCode;

      expect(exitCode, 0, reason: stderrData);

      await localDir.delete(recursive: true);
    }, timeout: const Timeout(Duration(seconds: 300)));

    test('fileNodes cp recursive remote folder to local', () async {
      final auth = await jsonDecode(
        await File('test/data/credentials/auth_ietf.json').readAsString(),
      );

      final remoteDir =
          'jmap:UploadTestFolder/recursive_download_${DateTime.now().millisecondsSinceEpoch}';

      await Process.start('dart', [
        'bin/jmap_cli.dart',
        'fileNodes',
        'mkdir',
        '$remoteDir/sub',
        '--url',
        auth['url'],
        '-u',
        auth['username'],
        '-p',
        auth['password'],
      ]).then((p) async => p.exitCode);

      final tmp = File('tmp_recursive.txt');
      await tmp.writeAsString('X');

      await Process.start('dart', [
        'bin/jmap_cli.dart',
        'fileNodes',
        'cp',
        tmp.path,
        '$remoteDir/sub/file.txt',
        '--url',
        auth['url'],
        '-u',
        auth['username'],
        '-p',
        auth['password'],
      ]).then((p) async => p.exitCode);

      final localDir = Directory('recursive_download');
      if (localDir.existsSync()) {
        await localDir.delete(recursive: true);
      }

      final process = await Process.start('dart', [
        'bin/jmap_cli.dart',
        'fileNodes',
        'cp',
        '-r',
        remoteDir,
        localDir.path,
        '--url',
        auth['url'],
        '-u',
        auth['username'],
        '-p',
        auth['password'],
      ]);

      final stderrData =
          await process.stderr.transform(utf8.decoder).join();
      final exitCode = await process.exitCode;

      expect(exitCode, 0, reason: stderrData);
      expect(File('${localDir.path}/sub/file.txt').existsSync(), true);

      await tmp.delete();
      await localDir.delete(recursive: true);
    }, timeout: const Timeout(Duration(seconds: 300)));
    
    test('fileNodes cp remote folder to local without -r fails with clear message',
    () async {
        final auth = jsonDecode(
          await File('test/data/credentials/auth_ietf.json').readAsString(),
        );

        final process = await Process.start(
          'dart',
          [
            'bin/jmap_cli.dart',
            'fileNodes',
            'cp',
            'jmap:UploadTestFolder',
            'downloaded_folder',
            '--url',
            auth['url'],
            '-u',
            auth['username'],
            '-p',
            auth['password'],
          ],
        );

        final stderrData =
            await process.stderr.transform(utf8.decoder).join();
        final stdoutData =
            await process.stdout.transform(utf8.decoder).join();
        final exitCode = await process.exitCode;

        expect(exitCode, isNot(0));

        expect(
          stdoutData + stderrData,
          contains('folder download is not supported without -r'),
        );
      },
      timeout: const Timeout(Duration(seconds: 300)),
    );
    test('fileNodes cp remote folder to local  download with -r succeeds',
      () async {
        final auth = jsonDecode(
          await File('test/data/credentials/auth_ietf.json').readAsString(),
        );

        final outDir = Directory('downloaded_recursive_folder');
        if (outDir.existsSync()) {
          outDir.deleteSync(recursive: true);
        }

        final process = await Process.start(
          'dart',
          [
            'bin/jmap_cli.dart',
            'fileNodes',
            'cp',
            'jmap:UploadTestFolder',
            outDir.path,
            '-r',
            '--url',
            auth['url'],
            '-u',
            auth['username'],
            '-p',
            auth['password'],
          ],
        );

        final stderrData =
            await process.stderr.transform(utf8.decoder).join();
        final exitCode = await process.exitCode;

        expect(exitCode, 0, reason: stderrData);
        expect(outDir.existsSync(), true);

        outDir.deleteSync(recursive: true);
      },
      timeout: const Timeout(Duration(seconds: 300)),
    );
    test('fileNodes cp uploads empty local folder recursively', () async {
        final auth = jsonDecode(
          await File('test/data/credentials/auth_ietf.json').readAsString(),
        );

        // Create empty local directory
        final dir = Directory('empty_test_dir');
        if (!dir.existsSync()) {
          dir.createSync(recursive: true);
        }

        final process = await Process.start(
          'dart',
          [
            'bin/jmap_cli.dart',
            'fileNodes',
            'cp',
            '-r',
            '--url',
            auth['url'],
            '-u',
            auth['username'],
            '-p',
            auth['password'],
            dir.path,
            'jmap:/empty_test_dir',
          ],
        );

        final stderrData =
            await process.stderr.transform(utf8.decoder).join();
        final exitCode = await process.exitCode;

        expect(exitCode, 0, reason: stderrData);

        dir.deleteSync(recursive: true);
      },
      timeout: const Timeout(Duration(seconds: 300)),
    );
  });
  group('CLI FileNode roundtrip tests real API', () {
    test('Roundtrip: upload local -> JMAP -> download back', () async {
      final auth = jsonDecode(
        await File('test/data/credentials/auth_ietf.json').readAsString(),
      );

      final originalFile = File('roundtrip_source_test.txt');
      const content = 'roundtrip test content';
      await originalFile.writeAsString(content);

      final remotePath = 'jmap:UploadTestFolder/roundtrip_test_1.txt';
      final downloadedFile = File('roundtrip_downloaded.txt');

      final uploadProcess = await Process.start(
        'dart',
        [
          'bin/jmap_cli.dart',
          'fileNodes',
          'cp',
          originalFile.path,
          remotePath,
          '--url',
          auth['url'],
          '-u',
          auth['username'],
          '-p',
          auth['password'],
        ],
      );

      final uploadStderr =
          await uploadProcess.stderr.transform(utf8.decoder).join();
      final uploadExitCode = await uploadProcess.exitCode;

      expect(uploadExitCode, 0, reason: uploadStderr);

      final downloadProcess = await Process.start(
        'dart',
        [
          'bin/jmap_cli.dart',
          'fileNodes',
          'cp',
          remotePath,
          downloadedFile.path,
          '--url',
          auth['url'],
          '-u',
          auth['username'],
          '-p',
          auth['password'],
        ],
      );

      final downloadStderr =
          await downloadProcess.stderr.transform(utf8.decoder).join();
      final downloadExitCode = await downloadProcess.exitCode;

      expect(downloadExitCode, 0, reason: downloadStderr);
      expect(downloadedFile.existsSync(), true);

      final downloadedContent = await downloadedFile.readAsString();
      expect(downloadedContent, content);

      await originalFile.delete();
      await downloadedFile.delete();
    }, timeout: const Timeout(Duration(seconds: 300)));
  });
  group('CLI FileNode tests: hierarchical fileNodes cp', () {
    test('fileNodes cp remote to local', () async {
      final auth = await jsonDecode(await File('test/data/credentials/auth_ietf.json').readAsString());

      final localPath = 'hier_download.txt';

      final remotePath =
          'jmap:UploadTestFolder/SubFolder/test_upload_local.txt';

      final process = await Process.start('dart', ['bin/jmap_cli.dart',
        'fileNodes',
        'cp',
        remotePath,
        localPath,
        '--url',
        auth['url'],
        '-u',
        auth['username'],
        '-p',
        auth['password'],
      ]);

      final stderrData = await process.stderr.transform(utf8.decoder).join();
      final exitCode = await process.exitCode;

      expect(exitCode, 0, reason: stderrData);
      expect(File(localPath).existsSync(), true);
      expect((await File(localPath).readAsString()).isNotEmpty, true);
      await File('hier_download.txt').delete();
    }, timeout: const Timeout(Duration(seconds: 300)));

    test('fileNodes cp local to remote', () async {
      final auth = await jsonDecode(await File('test/data/credentials/auth_ietf.json').readAsString());

      final file = File('hier_upload.txt');
      await file.writeAsString('hierarchical upload');
      final remoteFile = JmapUtils().uniqueFileName('hier_upload.txt');
      final remotePath =
          'jmap:UploadTestFolder/SubFolder/$remoteFile';

      final process = await Process.start('dart', ['bin/jmap_cli.dart',
        'fileNodes',
        'cp',
        file.path,
        remotePath,
        '--url',
        auth['url'],
        '-u',
        auth['username'],
        '-p',
        auth['password'],
      ]);

      final stderrData = await process.stderr.transform(utf8.decoder).join();
      final exitCode = await process.exitCode;

      expect(exitCode, 0, reason: stderrData);
      await File('hier_upload.txt').delete();
    }, timeout: const Timeout(Duration(seconds: 300)));
  });
  
  group('CLI FileNode tests: root upload', () {
    test('fileNodes cp local to jmap root', () async {
      final auth = jsonDecode(
        await File('test/data/credentials/auth_ietf.json').readAsString(),
      );

      final file = File('${DateTime.now().millisecondsSinceEpoch}_root_upload_test.txt');
      await file.writeAsString('upload to root');

      final process = await Process.start(
        'dart',
        [
          'bin/jmap_cli.dart',
          'fileNodes',
          'cp',
          file.path,
          'jmap:',
          '--url',
          auth['url'],
          '-u',
          auth['username'],
          '-p',
          auth['password'],
        ],
      );
      final stderrData =
          await process.stderr.transform(utf8.decoder).join();
      final exitCode = await process.exitCode;

      expect(exitCode, 0, reason: stderrData);

      await file.delete();
    }, timeout: const Timeout(Duration(seconds: 300)));

    test('fileNodes cp local to jmap root in /', () async {
      final auth = jsonDecode(
        await File('test/data/credentials/auth_ietf.json').readAsString(),
      );

     final file = File('${DateTime.now().millisecondsSinceEpoch}_root_upload_test_1.txt');
      await file.writeAsString('upload to root');

      final process = await Process.start(
        'dart',
        [
          'bin/jmap_cli.dart',
          'fileNodes',
          'cp',
          file.path,
          'jmap:/',
          '--url',
          auth['url'],
          '-u',
          auth['username'],
          '-p',
          auth['password'],
        ],
      );
      final stderrData =
          await process.stderr.transform(utf8.decoder).join();
      final exitCode = await process.exitCode;

      expect(exitCode, 0, reason: stderrData);

      await file.delete();
    }, timeout: const Timeout(Duration(seconds: 300)));
  });
}
