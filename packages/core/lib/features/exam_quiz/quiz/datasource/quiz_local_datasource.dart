import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';

/// Documents/quiz/{examTypeKey}/{fileName} にクイズ JSON を読み書きする。
class QuizLocalDatasource {
  QuizLocalDatasource._();

  static final QuizLocalDatasource instance = QuizLocalDatasource._();

  Future<Directory> _quizDir(String examTypeKey) async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/quiz/$examTypeKey');
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// ファイルが存在し、かつ SHA256 が一致するかを確認する。
  Future<bool> isFileValid(
    String examTypeKey,
    String fileName,
    String expectedSha256,
  ) async {
    final dir = await _quizDir(examTypeKey);
    final file = File('${dir.path}/$fileName');
    if (!file.existsSync()) return false;
    final bytes = await file.readAsBytes();
    final actual = sha256.convert(bytes).toString();
    return actual == expectedSha256;
  }

  /// ファイルが存在するかのみチェック（SHA256 なし、高速）。
  Future<bool> fileExists(String examTypeKey, String fileName) async {
    final dir = await _quizDir(examTypeKey);
    return File('${dir.path}/$fileName').existsSync();
  }

  /// JSON 文字列として読み込む。ファイルが存在しない場合は null。
  Future<String?> readFile(String examTypeKey, String fileName) async {
    final dir = await _quizDir(examTypeKey);
    final file = File('${dir.path}/$fileName');
    if (!file.existsSync()) return null;
    return file.readAsString();
  }

  /// バイト列を書き込む。
  Future<void> writeFile(
    String examTypeKey,
    String fileName,
    List<int> bytes,
  ) async {
    final dir = await _quizDir(examTypeKey);
    await File('${dir.path}/$fileName').writeAsBytes(bytes, flush: true);
  }

  /// ローカルキャッシュのバージョン文字列を読み込む。
  /// SharedPreferences ではなくファイルで管理して依存を最小化。
  Future<String?> readCachedVersion(String examTypeKey) async {
    final dir = await _quizDir(examTypeKey);
    final versionFile = File('${dir.path}/.version');
    if (!versionFile.existsSync()) return null;
    return versionFile.readAsString();
  }

  Future<void> writeCachedVersion(String examTypeKey, String version) async {
    final dir = await _quizDir(examTypeKey);
    await File('${dir.path}/.version')
        .writeAsString(version, flush: true);
  }
}
