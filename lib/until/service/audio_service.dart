import 'dart:developer';

import 'package:audioplayers/audioplayers.dart';

/// Noir Mindのサウンドエフェクト再生サービス。
///
/// 複数のSEを重ねて再生できるよう、AudioPlayerプールを使用する。
class AudioService {
  AudioService._();

  static final AudioService _instance = AudioService._();

  /// シングルトンインスタンスを取得する。
  static AudioService get instance => _instance;

  static const _poolSize = 8;
  final List<AudioPlayer> _pool =
      List.generate(_poolSize, (_) => AudioPlayer());
  int _nextPlayer = 0;

  /// アセットパスのSEをステレオパン付きで再生する。
  ///
  /// [pan] は -1.0（左）〜 +1.0（右）。0.0 がセンター。
  /// [rate] は再生速度（ピッチ）。1.0 が通常。0.5〜2.0 の範囲を推奨。
  /// パスがnullまたはエラー時は無視する。
  Future<void> playWithPan(
    String? assetPath, {
    double pan = 0.0,
    double rate = 1.0,
  }) async {
    if (assetPath == null) {
      return;
    }
    try {
      final player = _pool[_nextPlayer];
      _nextPlayer = (_nextPlayer + 1) % _poolSize;
      await player.stop();
      await player.setBalance(pan.clamp(-1.0, 1.0));
      await player.setPlaybackRate(rate.clamp(0.5, 2.0));
      await player.play(AssetSource(assetPath));
    } on Exception catch (e) {
      log('AudioService: failed to play $assetPath: $e');
    }
  }

  /// アセットパスのSEを再生する（パンなし、従来互換）。
  Future<void> play(String? assetPath) => playWithPan(assetPath);

  /// リソースを解放する。
  void dispose() {
    for (final player in _pool) {
      player.dispose();
    }
  }
}
