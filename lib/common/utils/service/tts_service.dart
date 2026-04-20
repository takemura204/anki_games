import 'package:flutter_tts/flutter_tts.dart';

/// テキスト読み上げ（TTS）サービス。
///
/// シングルトンとして使用する。英語 (en-US) の読み上げに特化。
class TtsService {
  TtsService._();

  /// シングルトンインスタンス。
  static final instance = TtsService._();

  final _tts = FlutterTts();
  var _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) {
      return;
    }
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(1);
    _initialized = true;
  }

  /// [text] を英語で読み上げる。前の再生中は停止してから開始する。
  Future<void> speak(String text) async {
    try {
      await _ensureInitialized();
      await _tts.stop();
      await _tts.speak(text);
    } on Exception catch (_) {
      // TTS エンジン初期化失敗時はサイレントに無視
    }
  }

  /// 再生中の音声を停止する。
  Future<void> stop() async {
    try {
      await _tts.stop();
    } on Exception catch (_) {}
  }
}
