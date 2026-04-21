import 'dart:async' show unawaited;
import 'dart:developer';

import 'package:audioplayers/audioplayers.dart';

/// Noir Mindのサウンドエフェクト再生サービス。
///
/// 複数のSEを重ねて再生できるよう、AudioPlayerプールを使用する。
/// 頻繁に再生する効果音は [preload] で事前にキャッシュしておくことで
/// 初回再生時の遅延をなくす。
class AudioService {
  AudioService._();

  static final _instance = AudioService._();

  /// シングルトンインスタンスを取得する。
  static AudioService get instance => _instance;

  static const _poolSize = 16;
  final List<AudioPlayer> _pool =
      List.generate(_poolSize, (_) => AudioPlayer());
  var _nextPlayer = 0;

  /// 指定したアセットパスをキャッシュへプリロードする。
  ///
  /// アプリ起動時に呼び出すことで、初回 [playWithPan] 時の
  /// ファイル読み込み遅延を排除できる。
  Future<void> preload(List<String> paths) async {
    for (final path in paths) {
      try {
        await AudioCache.instance.load(path);
      } on Exception catch (e) {
        log('AudioService: failed to preload $path: $e');
      }
    }
  }

  /// アセットパスのSEをステレオパン付きで再生する。
  ///
  /// [pan] は -1.0（左）〜 +1.0（右）。0.0 がセンター。
  /// [rate] は再生速度（ピッチ）。1.0 が通常。0.5〜2.0 の範囲を推奨。
  /// パスがnullまたはエラー時は無視する。
  void playWithPan(
    String? assetPath, {
    double pan = 0.0,
    double rate = 1.0,
  }) {
    if (assetPath == null) {
      return;
    }
    try {
      final player = _pool[_nextPlayer];
      _nextPlayer = (_nextPlayer + 1) % _poolSize;
      // stop/setBalance/setPlaybackRate は非ブロッキングで発行し、
      // play も即座に開始することで再生遅延を最小化する。
      unawaited(player.stop());
      unawaited(player.setBalance(pan.clamp(-1.0, 1.0)));
      unawaited(player.setPlaybackRate(rate.clamp(0.5, 2.0)));
      unawaited(player.play(AssetSource(assetPath)));
    } on Exception catch (e) {
      log('AudioService: failed to play $assetPath: $e');
    }
  }

  /// アセットパスのSEを再生する（パンなし、従来互換）。
  void play(String? assetPath) => playWithPan(assetPath);

  /// リソースを解放する。
  void dispose() {
    for (final player in _pool) {
      player.dispose();
    }
  }
}
