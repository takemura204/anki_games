import 'dart:convert';

import 'package:http/http.dart' as http;

import '../model/quiz_manifest.dart';

/// Firebase Hosting (CDN) からマニフェストとクイズ JSON を取得する。
class QuizRemoteDatasource {
  QuizRemoteDatasource({required this.baseUrl, http.Client? client})
      : _client = client ?? http.Client();

  /// Firebase Hosting の URL（末尾スラッシュなし）。
  /// 例: 'https://quiz-data-anki-quiz-dev.web.app'
  final String baseUrl;
  final http.Client _client;

  Future<QuizManifest> fetchManifest() async {
    final uri = Uri.parse('$baseUrl/manifest.json');
    final response = await _client.get(
      uri,
      headers: {'Cache-Control': 'no-cache'},
    );
    if (response.statusCode != 200) {
      throw QuizRemoteException(
        'manifest.json の取得に失敗しました (${response.statusCode})',
      );
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return QuizManifest.fromJson(json);
  }

  /// CDN の相対パスを使ってファイルをダウンロードしてバイト列を返す。
  /// `entry.path` は manifest.json 内の 'path' フィールドと同じ相対パス。
  Future<List<int>> downloadFile(QuizFileEntry entry) async {
    final uri = Uri.parse('$baseUrl/${entry.path}');
    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      throw QuizRemoteException(
        '${entry.name} のダウンロードに失敗しました (${response.statusCode})',
      );
    }
    return response.bodyBytes;
  }
}

class QuizRemoteException implements Exception {
  const QuizRemoteException(this.message);
  final String message;
  @override
  String toString() => 'QuizRemoteException: $message';
}
