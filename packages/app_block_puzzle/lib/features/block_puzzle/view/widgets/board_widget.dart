import 'dart:async' show Timer, unawaited;
import 'dart:math';
import 'dart:ui';

import 'package:core/features/settings/view_model/settings_view_model.dart';
import 'package:core/utils/service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../model/board.dart';
import '../../model/game_theme.dart';
import '../../model/piece.dart';
import '../../view_model/block_puzzle_view_model.dart';
import '../painters/cell_renderer.dart';

/// DragTargetをボード下方へ延長するセル数。
/// 3セル分まで延長することで、3マスの高さのピースをボード最下行に配置可能にする。
const _dragExtensionCells = 3.0;

/// 8x8のゲームボード。ピースのドロップを受け付ける。
class BoardWidget extends ConsumerStatefulWidget {
  /// ボードウィジェットを作成する。
  const BoardWidget({
    required this.cellSize,
    required this.theme,
    super.key,
  });

  /// 各セルの論理ピクセルサイズ。
  final double cellSize;

  /// 現在のゲームテーマ。
  final GameTheme theme;

  @override
  ConsumerState<BoardWidget> createState() => _BoardWidgetState();
}

class _BoardWidgetState extends ConsumerState<BoardWidget>
    with TickerProviderStateMixin {
  int? _hoverRow;
  int? _hoverCol;
  int? _hoverPieceIndex;

  // シェイクアニメーション
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  // ライン消去アニメーション
  late final AnimationController _clearController;
  late final Animation<double> _clearAnimation;

  // 配置バウンスアニメーション
  late final AnimationController _bounceController;
  late final Animation<double> _bounceAnimation;

  // 消去予定セルのパルスアニメーション
  late final AnimationController _pulseController;

  // フラッシュオーバーレイ（flash/glitch用）
  late final AnimationController _flashController;

  // 波紋エフェクト（ripple用）
  final List<_Ripple> _ripples = [];
  late final AnimationController _rippleController;

  // 遅延破壊用セル遅延マップ
  Map<(int, int), double> _cellDelays = const {};
  double _maxDelay = 0;

  // ライン消去プレビュー有無のトラッキング（haptic の二重発火防止用）
  var _wasClearPreview = false;

  // サウンドタイマー（新アニメーション開始時にキャンセルして音の重複を防ぐ）
  final List<Timer> _soundTimers = [];

  // 設定値キャッシュ（build() で毎フレーム更新）
  var _soundEnabled = true;
  var _vibrationEnabled = true;

  // フローティングスコア
  final List<_FloatingScore> _floatingScores = [];

  // コンボポップアップ
  var _comboValue = 0;
  var _comboRow = 4;
  late final AnimationController _comboPopupController;
  late final Animation<double> _comboPopupOpacity;
  late final Animation<double> _comboPopupTranslateY;

  // パーティクルエフェクト
  final List<_Particle> _particles = [];
  late final AnimationController _particleController;

  // クイズ正誤フィードバックフラッシュ
  late final AnimationController _quizFeedbackController;
  late final Animation<double> _quizFeedbackOpacity;

  // セルシェーダーアニメーション用クロック
  late final AnimationController _clockController;
  late final DateTime _clockStart;
  Map<CellRenderMode, FragmentShader>? _cellShaders;

  // ライト/ダークモード（colorsFor の引数に使用）
  Brightness _brightness = Brightness.light;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    unawaited(_loadShaders());
  }

  Future<void> _loadShaders() async {
    final programs = await Future.wait([
      FragmentProgram.fromAsset('packages/core/shaders/block_puzzle/glassmorphism.frag'),
      FragmentProgram.fromAsset('packages/core/shaders/block_puzzle/wireframe.frag'),
      FragmentProgram.fromAsset('packages/core/shaders/block_puzzle/matte.frag'),
      FragmentProgram.fromAsset('packages/core/shaders/block_puzzle/bubble.frag'),
      FragmentProgram.fromAsset('packages/core/shaders/block_puzzle/ice.frag'),
      FragmentProgram.fromAsset('packages/core/shaders/block_puzzle/slate.frag'),
      FragmentProgram.fromAsset('packages/core/shaders/block_puzzle/slime.frag'),
    ]);
    if (!mounted) {
      return;
    }
    setState(() {
      _cellShaders = {
        CellRenderMode.glassmorphism: programs[0].fragmentShader(),
        CellRenderMode.wireframe: programs[1].fragmentShader(),
        CellRenderMode.matte: programs[2].fragmentShader(),
        CellRenderMode.bubble: programs[3].fragmentShader(),
        CellRenderMode.ice: programs[4].fragmentShader(),
        CellRenderMode.slate: programs[5].fragmentShader(),
        CellRenderMode.slime: programs[6].fragmentShader(),
      };
    });
  }

  void _initAnimations() {
    final anims = widget.theme.animations;
    final intensity = anims.shakeIntensity;

    _shakeController = AnimationController(
      vsync: this,
      duration: anims.shakeDuration,
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0, end: intensity),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(begin: intensity, end: -intensity),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(begin: -intensity, end: intensity * 0.5),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(begin: intensity * 0.5, end: -intensity * 0.25),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(begin: -intensity * 0.25, end: 0),
        weight: 1,
      ),
    ]).animate(_shakeController);

    _clearController = AnimationController(
      vsync: this,
      duration: anims.clearDuration,
    );
    _clearAnimation = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(
        parent: _clearController,
        curve: anims.placementCurve,
      ),
    );

    _bounceController = AnimationController(
      vsync: this,
      duration: anims.bounceDuration,
    );
    _bounceAnimation =
        _buildBounceSequence(anims.bounceSequence).animate(_bounceController);

    _pulseController = AnimationController(
      vsync: this,
      duration: anims.pulseDuration,
    );

    _particleController = AnimationController(
      vsync: this,
      duration: anims.clearDuration,
    );

    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // 消去アニメーション完了時にビューモデルへ通知する。
    _clearController.addStatusListener(_onClearAnimationStatus);

    _clockController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();
    _clockStart = DateTime.now();

    // クイズ正誤フィードバック: 650ms パルス（フェードイン → ホールド → フェードアウト）
    _quizFeedbackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _quizFeedbackOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 0.55), weight: 25),
      TweenSequenceItem(tween: ConstantTween(0.55), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 0.55, end: 0), weight: 35),
    ]).animate(_quizFeedbackController);

    // コンボポップアップ: 550ms、Scale なし（ぼやけ防止）
    _comboPopupController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _comboPopupOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 1), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 1, end: 1), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 1, end: 0), weight: 50),
    ]).animate(_comboPopupController);
    _comboPopupTranslateY = Tween<double>(begin: 0, end: -44).animate(
      CurvedAnimation(
        parent: _comboPopupController,
        curve: Curves.easeOut,
      ),
    );
  }

  /// バウンスシーケンス値リストからTweenSequenceを構築する。
  Animatable<double> _buildBounceSequence(List<double> values) {
    final items = <TweenSequenceItem<double>>[];
    for (var i = 0; i < values.length - 1; i++) {
      items.add(
        TweenSequenceItem(
          tween: Tween(begin: values[i], end: values[i + 1]),
          weight: 1,
        ),
      );
    }
    return TweenSequence<double>(items);
  }

  @override
  void dispose() {
    for (final t in _soundTimers) {
      t.cancel();
    }
    _shakeController.dispose();
    _clearController.dispose();
    _bounceController.dispose();
    _pulseController.dispose();
    _particleController.dispose();
    _flashController.dispose();
    _rippleController.dispose();
    _clockController.dispose();
    _quizFeedbackController.dispose();
    _comboPopupController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _brightness = Theme.of(context).brightness;
    final gameState = ref.watch(blockPuzzleViewModelProvider);
    final settings = ref.watch(settingsViewModelProvider);
    _soundEnabled = settings.soundEnabled;
    _vibrationEnabled = settings.vibrationEnabled;
    final theme = widget.theme;
    final boardSize = widget.cellSize * Board.size;
    // DragTarget用の下方拡張領域
    final dragExtension = widget.cellSize * _dragExtensionCells;

    // ライン消去・配置・クイズ正誤イベントを監視してアニメーション発火
    ref
      ..listen(
        blockPuzzleViewModelProvider.select((s) => s.quizAnswerCorrect),
        (prev, next) {
          if (next != null && next != prev) {
            _quizFeedbackController
              ..reset()
              ..forward();
          }
        },
      )
      ..listen(
        blockPuzzleViewModelProvider.select((s) => s.lastClearResult),
        (prev, next) {
          if (next != null && next != prev) {
            _triggerClearAnimation(next);
          }
        },
      )
      ..listen(
        blockPuzzleViewModelProvider.select((s) => s.lastPlacedCells),
        (prev, next) {
          if (next.isNotEmpty && (prev == null || prev.isEmpty)) {
            _bounceController
              ..reset()
              ..forward();
            if (_vibrationEnabled) {
              HapticFeedback.lightImpact();
            }
            // 配置位置に応じたステレオパンで再生
            final avgCol = next.map((cell) => cell.$2).reduce((a, b) => a + b) /
                next.length;
            final pan = _columnToPan(avgCol.round());
            if (_soundEnabled) {
              AudioService.instance.playWithPan(
                widget.theme.sounds.placePath,
                pan: pan,
              );
            }
          }
        },
      );

    // 配置可能かどうか判定
    final canPlace = _canPlaceHover();

    // 消去予定セル・行・列を計算（配置可能な場合のみ）
    const emptyPreview = (
      cells: <(int, int)>{},
      rows: <int>{},
      cols: <int>{},
    );
    final clearPreview =
        canPlace ? _computeClearPreview(gameState) : emptyPreview;
    final clearPreviewCells = clearPreview.cells;
    final clearPreviewRows = clearPreview.rows;
    final clearPreviewCols = clearPreview.cols;

    // ライン消去可能位置に初めて乗ったとき selectionClick haptic を発火
    final nowClearPreview = clearPreviewCells.isNotEmpty;
    if (nowClearPreview && !_wasClearPreview) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _vibrationEnabled) {
          HapticFeedback.selectionClick();
        }
      });
    }
    _wasClearPreview = nowClearPreview;

    // パルスアニメーションの制御（消去予定がある時のみ再生）
    if (clearPreviewCells.isNotEmpty) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    } else {
      if (_pulseController.isAnimating) {
        _pulseController
          ..stop()
          ..value = 0;
      }
    }

    return AnimatedBuilder(
      animation: Listenable.merge([
        _shakeAnimation,
        _clearAnimation,
        _bounceAnimation,
      ]),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeAnimation.value, 0),
          child: child,
        );
      },
      // DragTarget用に下方へ拡張した領域
      child: SizedBox(
        width: boardSize,
        height: boardSize + dragExtension,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // ボードの視覚表示（ClipRRect でボードサイズに切り抜き）
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: AnimatedBuilder(
                animation: Listenable.merge([
                  _clearAnimation,
                  _bounceAnimation,
                  _clockController,
                  _pulseController,
                  _quizFeedbackController,
                ]),
                builder: (context, _) {
                  final shaderTime =
                      DateTime.now().difference(_clockStart).inMilliseconds /
                          1000;
                  // パルス強度（0.15 ~ 0.45）はシェーダークロックと同じ
                  // AnimatedBuilder 内で計算してフル再ビルドを避ける。
                  final pulseGlow = 0.15 + _pulseController.value * 0.3;
                  return CustomPaint(
                    size: Size(boardSize, boardSize),
                    painter: _BoardPainter(
                      board: gameState.board,
                      clearingCells: gameState.clearingCells,
                      lastPlacedCells: gameState.lastPlacedCells,
                      hoverRow: _hoverRow,
                      hoverCol: _hoverCol,
                      hoverPiece: _hoverPieceIndex != null
                          ? gameState.pieces[_hoverPieceIndex!]
                          : null,
                      canPlaceHover: canPlace,
                      clearPreviewCells: clearPreviewCells,
                      clearPreviewRows: clearPreviewRows,
                      clearPreviewCols: clearPreviewCols,
                      pulseGlow: pulseGlow,
                      cellSize: widget.cellSize,
                      theme: theme,
                      brightness: _brightness,
                      clearProgress: _clearAnimation.value,
                      bounceScale: _bounceAnimation.value,
                      cellDelays: _cellDelays,
                      maxDelay: _maxDelay,
                      cellShaders: _cellShaders,
                      cellShaderTime: shaderTime,
                      quizAnswerCorrect: gameState.quizAnswerCorrect,
                      quizFeedbackCells: gameState.quizFeedbackCells,
                      quizFeedbackOpacity: _quizFeedbackOpacity.value,
                    ),
                  );
                },
              ),
            ),
            // フラッシュオーバーレイ（AnimatedBuilder で分離しフル再ビルドを回避）
            AnimatedBuilder(
              animation: _flashController,
              builder: (context, _) {
                if (!_flashController.isAnimating) {
                  return const SizedBox.shrink();
                }
                return IgnorePointer(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: ColoredBox(
                      color: (theme.clearEffect.flashColor ?? Colors.white)
                          .withValues(
                        alpha: (1 - _flashController.value) * 0.6,
                      ),
                      child: SizedBox(
                        width: boardSize,
                        height: boardSize,
                      ),
                    ),
                  ),
                );
              },
            ),
            // 波紋エフェクト（AnimatedBuilder で分離）
            AnimatedBuilder(
              animation: _rippleController,
              builder: (context, _) {
                if (_ripples.isEmpty || !_rippleController.isAnimating) {
                  return const SizedBox.shrink();
                }
                return IgnorePointer(
                  child: CustomPaint(
                    size: Size(boardSize, boardSize),
                    painter: _RipplePainter(
                      ripples: _ripples,
                      progress: _rippleController.value,
                      color: theme.colorsFor(_brightness).glowColor,
                      maxRadius: theme.clearEffect.rippleMaxRadius,
                    ),
                  ),
                );
              },
            ),
            // DragTarget（ボード＋下方拡張領域をカバー）
            Positioned.fill(
              child: DragTarget<int>(
                onWillAcceptWithDetails: (details) {
                  _updateHoverPositionWithIndex(
                    details.offset,
                    details.data,
                    context,
                  );
                  return true;
                },
                onMove: (details) {
                  _updateHoverPositionWithIndex(
                    details.offset,
                    details.data,
                    context,
                  );
                },
                onLeave: (_) {
                  setState(() {
                    _hoverRow = null;
                    _hoverCol = null;
                    _hoverPieceIndex = null;
                  });
                },
                onAcceptWithDetails: (details) {
                  final row = _hoverRow;
                  final col = _hoverCol;
                  if (row != null && col != null) {
                    ref
                        .read(
                          blockPuzzleViewModelProvider.notifier,
                        )
                        .placePiece(details.data, row, col);
                  }
                  setState(() {
                    _hoverRow = null;
                    _hoverCol = null;
                    _hoverPieceIndex = null;
                  });
                },
                builder: (context, candidateData, rejectedData) {
                  return const SizedBox.expand();
                },
              ),
            ),
            // パーティクルエフェクト描画（AnimatedBuilder で分離しフル再ビルドを回避）
            AnimatedBuilder(
              animation: _particleController,
              builder: (context, _) {
                if (_particles.isEmpty) {
                  return const SizedBox.shrink();
                }
                return IgnorePointer(
                  child: CustomPaint(
                    size: Size(boardSize, boardSize),
                    painter: _ParticlePainter(
                      particles: _particles,
                      progress: _particleController.value,
                    ),
                  ),
                );
              },
            ),
            // フローティングスコア
            ..._floatingScores.map(
              (fs) => Positioned(
                key: ValueKey(fs.id),
                left: fs.col * widget.cellSize,
                top: fs.row * widget.cellSize,
                child: IgnorePointer(
                  child: _FloatingScoreWidget(
                    floatingScore: fs,
                    cellSize: widget.cellSize,
                    textColor: theme.colorsFor(_brightness).onSurface,
                    shadowColor: theme.colorsFor(_brightness).surface,
                    onComplete: () {
                      setState(() => _floatingScores.remove(fs));
                    },
                  ),
                ),
              ),
            ),
            // コンボポップアップ: 消去ライン付近から上方フロート
            AnimatedBuilder(
              animation: _comboPopupController,
              builder: (context, _) {
                if (_comboValue < 2) {
                  return const SizedBox.shrink();
                }
                final colors = theme.colorsFor(_brightness);
                // _comboRow を -1..1 の Alignment に変換（中央寄り）
                final alignY =
                    ((_comboRow / Board.size) * 2 - 1).clamp(-0.75, 0.75);
                return IgnorePointer(
                  child: SizedBox(
                    width: boardSize,
                    height: boardSize,
                    child: Align(
                      alignment: Alignment(0, alignY),
                      child: Transform.translate(
                        offset: Offset(0, _comboPopupTranslateY.value),
                        child: Opacity(
                          opacity: _comboPopupOpacity.value,
                          child: Text(
                            'COMBO ×$_comboValue',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w800,
                              fontSize: 22,
                              letterSpacing: 2,
                              color: colors.accent,
                              shadows: [
                                Shadow(
                                  color: colors.surface,
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  bool _canPlaceHover() {
    return _hoverRow != null &&
        _hoverCol != null &&
        _hoverPieceIndex != null &&
        ref.read(blockPuzzleViewModelProvider.notifier).canPlace(
              _hoverPieceIndex!,
              _hoverRow!,
              _hoverCol!,
            );
  }

  /// 配置した場合に消去されるセル・行・列を事前計算する。
  ({Set<(int, int)> cells, Set<int> rows, Set<int> cols}) _computeClearPreview(
    BlockPuzzleState gameState,
  ) {
    const empty = (
      cells: <(int, int)>{},
      rows: <int>{},
      cols: <int>{},
    );
    if (_hoverRow == null || _hoverCol == null || _hoverPieceIndex == null) {
      return empty;
    }
    final piece = gameState.pieces[_hoverPieceIndex!];
    if (piece == null) {
      return empty;
    }
    final tempBoard = Board.from(gameState.board);
    if (!tempBoard.canPlace(piece, _hoverRow!, _hoverCol!)) {
      return empty;
    }
    tempBoard.place(piece, _hoverRow!, _hoverCol!);
    final result = tempBoard.checkClearLines();
    return (
      cells: result.clearedCells,
      rows: result.clearedRows,
      cols: result.clearedCols,
    );
  }

  /// 左端/上端から順に消えるセル遅延を計算する。
  Map<(int, int), double> _computeCellDelays(ClearResult result) {
    final delays = <(int, int), double>{};
    // セル間遅延: 1.2 倍でウェーブを適度に保ちつつテンポよく。
    final cellDelay = widget.theme.animations.cellDelay * 1.2;

    for (final (r, c) in result.cells) {
      double? delay;

      // 行クリアに含まれる場合: 左から右へ (col * delay)
      if (result.clearedRows.contains(r)) {
        delay = c * cellDelay;
      }

      // 列クリアに含まれる場合: 上から下へ (row * delay)
      if (result.clearedCols.contains(c)) {
        final colDelay = r * cellDelay;
        // 両方に含まれる（交差）場合は、早い方を採用してリズムを崩さないようにする
        if (delay != null) {
          delay = min(delay, colDelay);
        } else {
          delay = colDelay;
        }
      }

      if (delay != null) {
        // 既存のエントリがある場合（稀だが）も考慮
        final existing = delays[(r, c)];
        if (existing != null) {
          delays[(r, c)] = min(existing, delay);
        } else {
          delays[(r, c)] = delay;
        }
      }
    }
    return delays;
  }

  /// 列位置からステレオパン値を計算する (-1.0=左, +1.0=右)。
  double _columnToPan(int col) {
    return (col / (Board.size - 1)) * 2 - 1;
  }

  /// 消去アニメーション完了時にビューモデルへクリーンアップを委譲する。
  void _onClearAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted) {
      ref.read(blockPuzzleViewModelProvider.notifier).completeClearAnimation();
    }
  }

  void _triggerClearAnimation(ClearResult result) {
    final anims = widget.theme.animations;
    final clearEffect = widget.theme.clearEffect;
    final colors = widget.theme.colorsFor(_brightness);

    // 遅延破壊: セルごとの遅延を計算
    final cellDelays = _computeCellDelays(result);
    final maxDelay = cellDelays.values.fold<double>(0, (a, b) => a > b ? a : b);
    setState(() {
      _cellDelays = cellDelays;
      _maxDelay = maxDelay;
    });

    // コントローラの長さを遅延分だけ延長（1.2 倍でテンポよく）
    final scaledClearMs = (anims.clearDuration.inMilliseconds * 1.2).round();
    final totalDuration = Duration(milliseconds: scaledClearMs) +
        Duration(milliseconds: (maxDelay * 1000).round());
    _clearController.duration = totalDuration;
    _particleController.duration = totalDuration;
    _rippleController.duration = totalDuration;

    _clearController
      ..reset()
      ..forward();

    // クリアエフェクトモード別処理
    // クリアエフェクトモード別処理
    switch (clearEffect.mode) {
      case ClearEffectMode.flash:
        // _flashController ..reset() ..forward(); // 全体フラッシュ廃止
        _spawnParticles(result, anims, colors, cellDelays, totalDuration);

      case ClearEffectMode.glitch:
        _flashController
          ..reset()
          ..forward();
        // グリッチ: 強化シェイク（横+縦）
        if (anims.shakeIntensity > 0) {
          _shakeController
            ..reset()
            ..forward();
        }
        _spawnParticles(result, anims, colors, cellDelays, totalDuration);

      case ClearEffectMode.confetti:
        _spawnConfetti(
          result,
          anims,
          colors,
          clearEffect,
          cellDelays,
          totalDuration,
        );

      case ClearEffectMode.ripple:
        _spawnRipples(result, cellDelays, totalDuration);
        _spawnParticles(result, anims, colors, cellDelays, totalDuration);

      case ClearEffectMode.dice:
      case ClearEffectMode.dissolve:
      case ClearEffectMode.pop:
      case ClearEffectMode.shatter:
        _spawnParticles(result, anims, colors, cellDelays, totalDuration);
    }

    _particleController
      ..reset()
      ..forward();

    // 触覚フィードバック（ライン数に応じて強さ変更）
    if (result.linesCleared >= 2) {
      if (anims.shakeIntensity > 0 &&
          clearEffect.mode != ClearEffectMode.glitch) {
        _shakeController
          ..reset()
          ..forward();
      }
    }

    // 遅延破壊: セルごとに個別SEと触覚フィードバックを再生
    final clearPath = widget.theme.sounds.clearPath;
    // サウンド対象: クリアされた全行・全列のセル（HP≥2ノイズ含む）。
    // ビジュアルアニメーションは actualClearCells のみだが、サウンドは
    // ノイズブロックがダメージを受けた場合も同じSEを再生する。
    final soundCellDelay = widget.theme.animations.cellDelay * 1.2;
    final soundCellDelays = <(int, int), double>{};
    for (final r in result.clearedRows) {
      for (var c = 0; c < Board.size; c++) {
        final d = c * soundCellDelay;
        final existing = soundCellDelays[(r, c)];
        soundCellDelays[(r, c)] = existing == null ? d : min(existing, d);
      }
    }
    for (final c in result.clearedCols) {
      for (var r = 0; r < Board.size; r++) {
        final d = r * soundCellDelay;
        final existing = soundCellDelays[(r, c)];
        soundCellDelays[(r, c)] = existing == null ? d : min(existing, d);
      }
    }
    // 同じタイミングのセルを集約して重複音を排除する。
    // キー: 遅延ms、値: そのタイミングの全セル。
    final soundGroups = <int, List<(int, int)>>{};
    for (final entry in soundCellDelays.entries) {
      final delayMs = (entry.value * 1000).round();
      soundGroups.putIfAbsent(delayMs, () => []).add(entry.key);
    }
    final maxDelayMs =
        soundGroups.keys.fold(0, (prev, ms) => ms > prev ? ms : prev);

    // コンボ段階ごとにピッチを +12% ブースト（上限 ×1.8）。
    // ASMR感: ベースピッチを 0.1 下げて落ち着いた音質にする。
    // ASMR感: ベースピッチを 0.1 下げて落ち着いた音質にする。
    const asmrPitchOffset = -0.1;
    final comboBoost = (1.0 + (result.combo - 1) * 0.12).clamp(1.0, 1.8);
    final pitchMin =
        (widget.theme.sounds.clearPitchMin + asmrPitchOffset).clamp(0.4, 2.0);
    final pitchMax =
        (widget.theme.sounds.clearPitchMax + asmrPitchOffset).clamp(0.4, 2.0);

    for (final entry in soundGroups.entries) {
      final delayMs = entry.key;
      final cells = entry.value;
      final isLastGroup = delayMs == maxDelayMs;

      // 複数セルがある場合は列の平均でパンを計算。
      final avgCol =
          cells.map((cell) => cell.$2).reduce((a, b) => a + b) / cells.length;
      final pan = (avgCol / (Board.size - 1)) * 2 - 1;

      // セル位置の平均でベースピッチを算出し、コンボブーストを乗算。
      final avgNormPos = cells
              .map((cell) => (cell.$1 + cell.$2) / ((Board.size - 1) * 2.0))
              .reduce((a, b) => a + b) /
          cells.length;
      final rate = (pitchMin + avgNormPos * (pitchMax - pitchMin)) * comboBoost;

      late final Timer soundTimer;
      soundTimer = Timer(
        Duration(milliseconds: delayMs),
        () {
          _soundTimers.remove(soundTimer);
          if (!mounted) {
            return;
          }
          if (_soundEnabled) {
            AudioService.instance.playWithPan(clearPath, pan: pan, rate: rate);
          }
          // 最後のグループで強い振動、それ以外は軽い振動。
          if (_vibrationEnabled) {
            if (isLastGroup) {
              if (result.linesCleared >= 2) {
                HapticFeedback.heavyImpact();
              } else {
                HapticFeedback.mediumImpact();
              }
            } else {
              HapticFeedback.lightImpact();
            }
          }
        },
      );
      _soundTimers.add(soundTimer);
    }

    // フローティングスコア追加
    setState(() {
      _floatingScores.add(
        _FloatingScore(
          id: DateTime.now().microsecondsSinceEpoch,
          points: result.pointsEarned,
          row: result.placementRow,
          col: result.placementCol,
        ),
      );
    });

    // コンボポップアップ: 消去ライン付近に表示（combo >= 2）
    if (result.combo >= 2) {
      final avgRow = result.clearedRows.isEmpty
          ? result.placementRow
          : result.clearedRows.reduce((a, b) => a + b) ~/
              result.clearedRows.length;
      setState(() {
        _comboValue = result.combo;
        _comboRow = avgRow;
      });
      _comboPopupController
        ..reset()
        ..forward();
    }
  }

  /// 通常パーティクルを生成する。
  void _spawnParticles(
    ClearResult result,
    GameThemeAnimations anims,
    GameThemeColors colors,
    Map<(int, int), double> cellDelays,
    Duration totalDuration,
  ) {
    final rng = Random();
    final theme = widget.theme;
    final particleColors = colors.particleColors.isNotEmpty
        ? colors.particleColors
        : [colors.particleColor];
    final shapes = theme.clearEffect.confettiShapes.isNotEmpty
        ? theme.clearEffect.confettiShapes
        : [ParticleShape.circle];

    final durationSec = totalDuration.inMilliseconds / 1000;
    final clearDurSec = anims.clearDuration.inMilliseconds / 1000;
    // アニメーション全体の長さに対する、1ブロック分のクリア時間の割合
    final normalizedLife = durationSec > 0 ? (clearDurSec / durationSec) : 1.0;

    _particles.clear();
    for (final (r, c) in result.cells) {
      final cx = (c + 0.5) * widget.cellSize;
      final cy = (r + 0.5) * widget.cellSize;

      // このブロックの開始割合
      final delay = cellDelays[(r, c)] ?? 0;
      final startP = durationSec > 0 ? (delay / durationSec) : 0.0;
      final endP = startP + normalizedLife;

      for (var i = 0; i < anims.particlesPerCell; i++) {
        _spawnParticleForMode(
          theme.clearEffect.mode,
          cx,
          cy,
          colors.particleColor,
          rng,
          anims,
          particleColors,
          shapes,
          startP,
          endP,
        );
      }
    }
  }

  /// 紙吹雪パーティクルを生成する（多色・多形状）。
  void _spawnConfetti(
    ClearResult result,
    GameThemeAnimations anims,
    GameThemeColors colors,
    GameThemeClearEffect clearEffect,
    Map<(int, int), double> cellDelays,
    Duration totalDuration,
  ) {
    final rng = Random();
    _particles.clear();
    final particleColors = colors.particleColors.isNotEmpty
        ? colors.particleColors
        : [colors.particleColor];
    final shapes = clearEffect.confettiShapes.isNotEmpty
        ? clearEffect.confettiShapes
        : [ParticleShape.circle];

    final durationSec = totalDuration.inMilliseconds / 1000;
    final clearDurSec = anims.clearDuration.inMilliseconds / 1000;
    final normalizedLife = durationSec > 0 ? (clearDurSec / durationSec) : 1.0;

    for (final (r, c) in result.cells) {
      final cx = (c + 0.5) * widget.cellSize;
      final cy = (r + 0.5) * widget.cellSize;

      final delay = cellDelays[(r, c)] ?? 0;
      final startP = durationSec > 0 ? (delay / durationSec) : 0.0;
      final endP = startP + normalizedLife;

      for (var i = 0; i < anims.particlesPerCell; i++) {
        _spawnParticleForMode(
          widget.theme.clearEffect.mode,
          cx,
          cy,
          colors.particleColor,
          rng,
          anims,
          particleColors,
          shapes,
          startP,
          endP,
        );
      }
    }
  }

  void _spawnParticleForMode(
    ClearEffectMode mode,
    double cx,
    double cy,
    Color color,
    Random rng,
    GameThemeAnimations anims,
    List<Color> particleColors,
    List<ParticleShape> shapes,
    double startP,
    double endP,
  ) {
    switch (mode) {
      case ClearEffectMode.dice:
        // 賽の目: グリッド状に細かく切れる
        // 3x3のグリッドに分割するイメージ
        for (var i = 0; i < 3; i++) {
          for (var j = 0; j < 3; j++) {
            final offsetX = (i - 1) * widget.cellSize * 0.25;
            final offsetY = (j - 1) * widget.cellSize * 0.25;
            _particles.add(
              _Particle(
                x: cx + offsetX,
                y: cy + offsetY,
                vx: (rng.nextDouble() - 0.5) * 10, // 横にはあまり散らばらない
                vy: 50 + rng.nextDouble() * 50, // 重力で落ちる
                size: 4,
                color: color,
                shape: ParticleShape.square,
                rotationSpeed: (rng.nextDouble() - 0.5) * 2,
                startProgress: startP,
                endProgress: endP,
              ),
            );
          }
        }

      case ClearEffectMode.dissolve:
        // 崩壊: 風に吹かれるように流れる
        // final angle = (rng.nextDouble() - 0.5) * 0.5; // unused
        final speed = anims.particleMinSpeed +
            rng.nextDouble() *
                (anims.particleMaxSpeed - anims.particleMinSpeed);
        _particles.add(
          _Particle(
            x: cx + (rng.nextDouble() - 0.5) * widget.cellSize * 0.8,
            y: cy + (rng.nextDouble() - 0.5) * widget.cellSize * 0.8,
            vx: speed * (rng.nextBool() ? 1 : -1), // 左右どちらかに流れる
            vy: 20 + rng.nextDouble() * 20, // 少し落ちる
            size: 2 + rng.nextDouble() * 2,
            color: color.withValues(alpha: 0.8), // 砂っぽい
            shape: ParticleShape.square, // 砂粒
            rotation: rng.nextDouble() * 2 * pi,
            rotationSpeed: (rng.nextDouble() - 0.5) * 5,
            startProgress: startP,
            endProgress: endP,
          ),
        );

      case ClearEffectMode.pop:
        // 破裂: 弾ける + 紙吹雪
        final angle = rng.nextDouble() * 2 * pi;
        final speed = anims.particleMaxSpeed * (0.5 + rng.nextDouble() * 0.5);
        _particles.add(
          _Particle(
            x: cx,
            y: cy,
            vx: cos(angle) * speed,
            vy: sin(angle) * speed - 50, // 上に弾ける
            size: 4 + rng.nextDouble() * 4,
            color: particleColors.isNotEmpty
                ? particleColors[rng.nextInt(particleColors.length)]
                : color,
            shape: shapes.isNotEmpty
                ? shapes[rng.nextInt(shapes.length)]
                : ParticleShape.circle,
            rotation: rng.nextDouble() * 2 * pi,
            rotationSpeed: (rng.nextDouble() - 0.5) * 15, // 高速回転
            startProgress: startP,
            endProgress: endP,
          ),
        );

      case ClearEffectMode.shatter:
        // 粉砕: 鋭い破片が飛び散る
        final angle = rng.nextDouble() * 2 * pi;
        final speed = anims.particleMaxSpeed * (0.8 + rng.nextDouble() * 0.4);
        _particles.add(
          _Particle(
            x: cx + (rng.nextDouble() - 0.5) * 10,
            y: cy + (rng.nextDouble() - 0.5) * 10,
            vx: cos(angle) * speed,
            vy: sin(angle) * speed,
            size: 3 + rng.nextDouble() * 5,
            color: Colors.white.withValues(alpha: 0.9), // 氷の破片は白っぽい
            shape: ParticleShape.shard,
            rotation: rng.nextDouble() * 2 * pi,
            rotationSpeed: (rng.nextDouble() - 0.5) * 10,
            startProgress: startP,
            endProgress: endP,
          ),
        );

      case ClearEffectMode.flash:
      case ClearEffectMode.glitch:
      case ClearEffectMode.confetti:
      case ClearEffectMode.ripple:
        // 既存の汎用パーティクル
        final angle = rng.nextDouble() * 2 * pi;
        final speed = anims.particleMinSpeed +
            rng.nextDouble() *
                (anims.particleMaxSpeed - anims.particleMinSpeed);
        _particles.add(
          _Particle(
            x: cx,
            y: cy,
            vx: cos(angle) * speed,
            vy: sin(angle) * speed - 20,
            size: 3 + rng.nextDouble() * 4,
            color: particleColors.isNotEmpty
                ? particleColors[rng.nextInt(particleColors.length)]
                : color,
            shape: shapes.isNotEmpty
                ? shapes[rng.nextInt(shapes.length)]
                : ParticleShape.circle,
            rotation: rng.nextDouble() * 2 * pi,
            rotationSpeed: (rng.nextDouble() - 0.5) * 8,
            startProgress: startP,
            endProgress: endP,
          ),
        );
    }
  }

  /// 波紋エフェクトを生成する。
  void _spawnRipples(
    ClearResult result,
    Map<(int, int), double> cellDelays,
    Duration totalDuration,
  ) {
    _ripples.clear();
    final anims = widget.theme.animations;
    final durationSec = totalDuration.inMilliseconds / 1000;
    final clearDurSec = anims.clearDuration.inMilliseconds / 1000;
    // 波紋の寿命（リングのアニメーション時間を含むので、clearDurSecより長めにする）
    final rippleDurSec = clearDurSec * 1.5;
    final normalizedLife = durationSec > 0 ? (rippleDurSec / durationSec) : 1.0;

    for (final (r, c) in result.cells) {
      final delay = cellDelays[(r, c)] ?? 0;
      final startP = durationSec > 0 ? (delay / durationSec) : 0.0;
      final endP = startP + normalizedLife;

      _ripples.add(
        _Ripple(
          cx: (c + 0.5) * widget.cellSize,
          cy: (r + 0.5) * widget.cellSize,
          startProgress: startP,
          endProgress: endP,
        ),
      );
    }
    _rippleController
      ..reset()
      ..forward();
  }

  /// ピースインデックスを使ってホバー位置を更新する。
  ///
  /// feedback の配置（横中央・底辺が指の1セル上）と整合するよう、
  /// 指の位置からピースのサイズ分を引いた座標を nearest-cell にスナップする。
  void _updateHoverPositionWithIndex(
    Offset globalOffset,
    int pieceIndex,
    BuildContext ctx,
  ) {
    final box = ctx.findRenderObject()! as RenderBox;
    final local = box.globalToLocal(globalOffset);
    final piece = ref.read(blockPuzzleViewModelProvider).pieces[pieceIndex];
    final h = piece?.height ?? 1;
    final w = piece?.width ?? 1;
    final cs = widget.cellSize;

    // 指を基点にピースを横中央・底辺1セル上に配置したときの top-left 座標
    final adjustedX = local.dx - cs * (w / 2);
    final adjustedY = local.dy - cs * (h + 1);

    setState(() {
      _hoverCol = (adjustedX / cs).round().clamp(0, Board.size - w);
      _hoverRow = (adjustedY / cs).round().clamp(0, Board.size - h);
      _hoverPieceIndex = pieceIndex;
    });
  }
}

// --- パーティクルデータ ---

class _Particle {
  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.color,
    this.shape = ParticleShape.circle,
    this.rotation = 0,
    this.rotationSpeed = 0,
    required this.startProgress,
    required this.endProgress,
  });

  final double x;
  final double y;
  final double vx;
  final double vy;
  final double size;
  final Color color;
  final ParticleShape shape;
  final double rotation;
  final double rotationSpeed;
  final double startProgress;
  final double endProgress;
}

class _ParticlePainter extends CustomPainter {
  const _ParticlePainter({
    required this.particles,
    required this.progress,
  });

  final List<_Particle> particles;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      // パーティクルの個別時間を計算 (0.0 -> 1.0)
      final duration = p.endProgress - p.startProgress;
      if (duration <= 0) {
        continue;
      }

      final localProgress = (progress - p.startProgress) / duration;

      if (localProgress < 0 || localProgress > 1) {
        continue;
      }

      final opacity = (1 - localProgress).clamp(0.0, 1.0);
      if (opacity <= 0) {
        continue;
      }

      final px = p.x + p.vx * localProgress;
      final py = p.y + p.vy * localProgress;
      final s = p.size * (1 - localProgress * 0.5);
      final paint = Paint()..color = p.color.withValues(alpha: opacity);

      canvas
        ..save()
        ..translate(px, py)
        ..rotate(p.rotation + p.rotationSpeed * localProgress);

      switch (p.shape) {
        case ParticleShape.circle:
          canvas.drawCircle(Offset.zero, s, paint);
        case ParticleShape.square:
          canvas.drawRect(
            Rect.fromCenter(center: Offset.zero, width: s * 2, height: s * 2),
            paint,
          );
        case ParticleShape.star:
          _drawStar(canvas, s, paint);
        case ParticleShape.heart:
          _drawHeart(canvas, s, paint);
        case ParticleShape.shard:
          _drawShard(canvas, s, paint);
      }

      canvas.restore();
    }
  }

  void _drawStar(Canvas canvas, double size, Paint paint) {
    final path = Path();
    const points = 5;
    final outerR = size;
    final innerR = size * 0.4;
    for (var i = 0; i < points * 2; i++) {
      final r = i.isEven ? outerR : innerR;
      final angle = (i * pi / points) - pi / 2;
      final point = Offset(cos(angle) * r, sin(angle) * r);
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawHeart(Canvas canvas, double size, Paint paint) {
    final path = Path()
      ..moveTo(0, size * 0.3)
      ..cubicTo(
        -size,
        -size * 0.5,
        -size * 0.3,
        -size * 1.2,
        0,
        -size * 0.5,
      )
      ..cubicTo(
        size * 0.3,
        -size * 1.2,
        size,
        -size * 0.5,
        0,
        size * 0.3,
      );
    canvas.drawPath(path, paint);
  }

  void _drawShard(Canvas canvas, double size, Paint paint) {
    // 鋭角な三角形
    final path = Path()
      ..moveTo(0, -size) // Top
      ..lineTo(size * 0.4, size) // Bottom Right
      ..lineTo(-size * 0.4, size) // Bottom Left
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ParticlePainter oldDelegate) => true;
}

// --- 波紋データ ---

class _Ripple {
  _Ripple({
    required this.cx,
    required this.cy,
    required this.startProgress,
    required this.endProgress,
  });

  final double cx;
  final double cy;
  final double startProgress;
  final double endProgress;
}

class _RipplePainter extends CustomPainter {
  const _RipplePainter({
    required this.ripples,
    required this.progress,
    required this.color,
    required this.maxRadius,
  });

  final List<_Ripple> ripples;
  final double progress;
  final Color color;
  final double maxRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final opacity = (1 - progress).clamp(0.0, 1.0);
    if (opacity <= 0) {
      return;
    }

    // 波紋の同心円数（3つのリングを時間差で表示）
    const ringCount = 3;
    for (final ripple in ripples) {
      final duration = ripple.endProgress - ripple.startProgress;
      if (duration <= 0) {
        continue;
      }

      final rippleProgress = (progress - ripple.startProgress) / duration;
      if (rippleProgress < 0 || rippleProgress > 1) {
        continue;
      }

      final rippleOpacity = (1 - rippleProgress).clamp(0.0, 1.0);

      for (var i = 0; i < ringCount; i++) {
        final delay = i * 0.15; // リング間のズレ
        // リング個別の進行度
        final localProgress =
            ((rippleProgress - delay) / (1 - delay)).clamp(0.0, 1.0);

        if (localProgress <= 0) {
          continue;
        }

        final radius = maxRadius * localProgress;
        final ringOpacity = rippleOpacity * (1 - localProgress);
        final paint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2 * (1 - localProgress)
          ..color = color.withValues(alpha: ringOpacity * 0.6);
        canvas.drawCircle(Offset(ripple.cx, ripple.cy), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_RipplePainter oldDelegate) => true;
}

// --- フローティングスコア ---

class _FloatingScore {
  _FloatingScore({
    required this.id,
    required this.points,
    required this.row,
    required this.col,
  });

  final int id;
  final int points;
  final int row;
  final int col;
}

class _FloatingScoreWidget extends StatefulWidget {
  const _FloatingScoreWidget({
    required this.floatingScore,
    required this.cellSize,
    required this.textColor,
    required this.shadowColor,
    required this.onComplete,
  });

  final _FloatingScore floatingScore;
  final double cellSize;
  final Color textColor;
  final Color shadowColor;
  final VoidCallback onComplete;

  @override
  State<_FloatingScoreWidget> createState() => _FloatingScoreWidgetState();
}

class _FloatingScoreWidgetState extends State<_FloatingScoreWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<double> _translateY;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _opacity = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1),
      ),
    );
    _translateY = Tween<double>(begin: 0, end: -50).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.5, end: 1.2),
        weight: 2,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.2, end: 1),
        weight: 1,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.3, curve: Curves.easeOut),
      ),
    );
    _controller
      ..forward()
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          widget.onComplete();
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fs = widget.floatingScore;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Transform.translate(
          offset: Offset(0, _translateY.value),
          child: Opacity(
            opacity: _opacity.value,
            child: Transform.scale(
              scale: _scale.value.clamp(0.0, 2.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '+${fs.points}',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: widget.textColor,
                      shadows: [
                        Shadow(
                          color: widget.shadowColor,
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// --- ボード描画 ---

class _BoardPainter extends CustomPainter {
  _BoardPainter({
    required this.board,
    required this.clearingCells,
    required this.lastPlacedCells,
    required this.cellSize,
    required this.theme,
    required this.brightness,
    required this.clearProgress,
    required this.bounceScale,
    required this.clearPreviewCells,
    required this.clearPreviewRows,
    required this.clearPreviewCols,
    required this.pulseGlow,
    required this.cellDelays,
    required this.maxDelay,
    this.hoverRow,
    this.hoverCol,
    this.hoverPiece,
    this.canPlaceHover = false,
    this.cellShaders,
    this.cellShaderTime = 0,
    this.quizAnswerCorrect,
    this.quizFeedbackCells = const <(int, int)>{},
    this.quizFeedbackOpacity = 0,
  });

  final List<List<bool>> board;
  final Set<(int, int)> clearingCells;
  final Set<(int, int)> lastPlacedCells;
  final double cellSize;
  final GameTheme theme;
  final Brightness brightness;
  final double clearProgress;
  final double bounceScale;
  final int? hoverRow;
  final int? hoverCol;
  final Piece? hoverPiece;
  final bool canPlaceHover;

  /// 配置時に消去されるセルの集合（既存セルのグロー表示用）。
  final Set<(int, int)> clearPreviewCells;

  /// 消去予定の行番号の集合（行全体グロー用）。
  final Set<int> clearPreviewRows;

  /// 消去予定の列番号の集合（列全体グロー用）。
  final Set<int> clearPreviewCols;

  /// パルスアニメーションのグロー強度（0.15 ~ 0.45）。
  final double pulseGlow;

  /// セルごとの遅延秒数マップ。
  final Map<(int, int), double> cellDelays;

  /// セル遅延の最大値（秒）。
  final double maxDelay;

  /// レンダーモード別GLSLシェーダー（nullの場合はCanvasフォールバック）。
  final Map<CellRenderMode, FragmentShader>? cellShaders;

  /// シェーダーアニメーション用の経過時刻（秒）。
  final double cellShaderTime;

  /// クイズ正誤フィードバック（null = なし, true = 正解, false = 不正解）。
  final bool? quizAnswerCorrect;

  /// フィードバックで緑/赤フラッシュするセルの集合。
  final Set<(int, int)> quizFeedbackCells;

  /// フィードバックオーバーレイの不透明度（0.0 ~ 1.0）。
  final double quizFeedbackOpacity;

  @override
  void paint(Canvas canvas, Size size) {
    const gap = 1.5;
    final colors = theme.colorsFor(brightness);
    final style = theme.cellStyle;
    final shader = cellShaders?[style.renderMode];
    final emptyCellPaint = Paint()..color = colors.emptyCellFill;

    // 空セルの背景を描画
    for (var r = 0; r < Board.size; r++) {
      for (var c = 0; c < Board.size; c++) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              c * cellSize + gap,
              r * cellSize + gap,
              cellSize - gap * 2,
              cellSize - gap * 2,
            ),
            Radius.circular(style.cellBorderRadius),
          ),
          emptyCellPaint,
        );
      }
    }

    // 消去予定の行・列の空セルにグロー（行・列全体を発光させる）
    if (clearPreviewRows.isNotEmpty || clearPreviewCols.isNotEmpty) {
      final glowPaint = Paint()
        ..color = colors.glowColor.withValues(alpha: pulseGlow);
      for (var r = 0; r < Board.size; r++) {
        for (var c = 0; c < Board.size; c++) {
          if (!board[r][c] &&
              (clearPreviewRows.contains(r) || clearPreviewCols.contains(c))) {
            canvas.drawRRect(
              RRect.fromRectAndRadius(
                Rect.fromLTWH(
                  c * cellSize + gap,
                  r * cellSize + gap,
                  cellSize - gap * 2,
                  cellSize - gap * 2,
                ),
                Radius.circular(style.cellBorderRadius),
              ),
              glowPaint,
            );
          }
        }
      }
    }

    // 配置済みセルを描画
    for (var r = 0; r < Board.size; r++) {
      for (var c = 0; c < Board.size; c++) {
        if (clearingCells.contains((r, c))) {
          // 遅延破壊: このセルのアニメーション開始・終了時間を計算 (0.0 -> 1.0)
          final delay = cellDelays[(r, c)] ?? 0;
          final clearDurSec =
              theme.animations.clearDuration.inMilliseconds / 1000;
          final totalSec = maxDelay + clearDurSec;

          // t: 全体の経過時間割合 (0.0 -> 1.0)
          final t = 1 - clearProgress;

          final startT = totalSec > 0 ? (delay / totalSec) : 0.0;
          final endT = totalSec > 0 ? ((delay + clearDurSec) / totalSec) : 1.0;

          // 1. まだ始まっていない（待機中） -> 通常描画
          if (t < startT) {
            final rect = Rect.fromLTWH(
              c * cellSize + gap,
              r * cellSize + gap,
              cellSize - gap * 2,
              cellSize - gap * 2,
            );
            drawCell(canvas, rect, style, colors,
                shader: shader, time: cellShaderTime);
            continue;
          }

          // 2. 終わった -> 非表示
          if (t >= endT) {
            continue;
          }

          // 3. アニメーション中 -> エフェクト描画 (progress: 0.0 -> 1.0)
          final progress = ((t - startT) / (endT - startT)).clamp(0.0, 1.0);

          var scale = 1.0;
          var opacity = 1.0;
          Color? overlayColor;

          if (progress < 0.2) {
            // Stage 1: Anticipation (縮む/予備動作)
            // 0.2かけて 1.0 -> 0.9
            final p = progress / 0.2;
            scale = 1.0 - (0.1 * Curves.easeOut.transform(p));
          } else if (progress < 0.4) {
            // Stage 2: Glow (発光)
            // 0.2かけて 0.9 -> 1.0
            final p = (progress - 0.2) / 0.2;
            scale = 0.9 + (0.1 * Curves.elasticOut.transform(p));
            // 発光強度（山なり）
            final glowIntensity = sin(p * pi);
            overlayColor = Colors.white.withValues(alpha: 0.8 * glowIntensity);
          } else {
            // Stage 3: Pop & Fade (弾けて消える)
            // 0.6かけて 1.0 -> 1.2, opacity 1.0 -> 0.0
            final p = (progress - 0.4) / 0.6;
            scale = 1.0 + (0.2 * Curves.easeOutQuad.transform(p));
            opacity = 1.0 - p;
          }

          if (opacity <= 0) {
            continue;
          }

          // 中心からスケールさせるための矩形計算
          final currentSize = (cellSize - gap * 2) * scale;
          final offset = ((cellSize - gap * 2) - currentSize) / 2;
          final rect = Rect.fromLTWH(
            c * cellSize + gap + offset,
            r * cellSize + gap + offset,
            currentSize,
            currentSize,
          );

          drawCell(canvas, rect, style, colors,
              opacity: opacity, shader: shader, time: cellShaderTime);

          // 発光オーバーレイの描画
          if (overlayColor != null) {
            final rrect = RRect.fromRectAndRadius(
              rect,
              Radius.circular(style.cellBorderRadius),
            );
            canvas.drawRRect(rrect, Paint()..color = overlayColor);
          }
        } else if (lastPlacedCells.contains((r, c)) && bounceScale > 0) {
          final cw = (cellSize - gap * 2) * bounceScale;
          final ch = (cellSize - gap * 2) * bounceScale;
          final cx = c * cellSize + cellSize / 2;
          final cy = r * cellSize + cellSize / 2;
          final rect = Rect.fromCenter(
            center: Offset(cx, cy),
            width: cw,
            height: ch,
          );
          drawCell(canvas, rect, style, colors,
              shader: shader, time: cellShaderTime);
        } else if (board[r][c]) {
          final rect = Rect.fromLTWH(
            c * cellSize + gap,
            r * cellSize + gap,
            cellSize - gap * 2,
            cellSize - gap * 2,
          );
          drawCell(canvas, rect, style, colors,
              shader: shader, time: cellShaderTime);
          if (clearPreviewCells.contains((r, c))) {
            final rrect = RRect.fromRectAndRadius(
              rect,
              Radius.circular(style.cellBorderRadius),
            );
            canvas.drawRRect(
              rrect,
              Paint()..color = colors.glowColor.withValues(alpha: pulseGlow),
            );
          }
        }
      }
    }

    // クイズ正誤フィードバックオーバーレイ（緑=正解 / 赤=不正解）
    if (quizAnswerCorrect != null &&
        quizFeedbackCells.isNotEmpty &&
        quizFeedbackOpacity > 0) {
      final feedbackColor = quizAnswerCorrect!
          ? const Color(0xFF4CAF50)
          : const Color(0xFFEF5350);
      final feedbackPaint = Paint()
        ..color = feedbackColor.withValues(alpha: quizFeedbackOpacity);
      for (final (r, c) in quizFeedbackCells) {
        if (r >= 0 && r < Board.size && c >= 0 && c < Board.size) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(
                c * cellSize + gap,
                r * cellSize + gap,
                cellSize - gap * 2,
                cellSize - gap * 2,
              ),
              Radius.circular(style.cellBorderRadius),
            ),
            feedbackPaint,
          );
        }
      }
    }

    // ホバープレビュー
    if (canPlaceHover &&
        hoverRow != null &&
        hoverCol != null &&
        hoverPiece != null) {
      final previewPaint = Paint()
        ..color = colors.onSurface.withValues(alpha: 0.2);

      for (final (dr, dc) in hoverPiece!.offsets) {
        final r = hoverRow! + dr;
        final c = hoverCol! + dc;
        if (r >= 0 && r < Board.size && c >= 0 && c < Board.size) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(
                c * cellSize + gap,
                r * cellSize + gap,
                cellSize - gap * 2,
                cellSize - gap * 2,
              ),
              Radius.circular(style.cellBorderRadius),
            ),
            previewPaint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_BoardPainter oldDelegate) => true;
}
