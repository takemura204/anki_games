import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mono_games/features/noir_mind/model/board.dart';
import 'package:mono_games/features/noir_mind/model/piece.dart';
import 'package:mono_games/features/noir_mind/view_model/noir_mind_view_model.dart';

/// ドラッグフィードバックの上方オフセット（ボードセル数）。
const _dragOffsetCells = 2.0;

/// 8x8のゲームボード。ピースのドロップを受け付ける。
class BoardWidget extends ConsumerStatefulWidget {
  /// ボードウィジェットを作成する。
  const BoardWidget({required this.cellSize, super.key});

  /// 各セルの論理ピクセルサイズ。
  final double cellSize;

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

  // フローティングスコア
  final List<_FloatingScore> _floatingScores = [];

  // パーティクルエフェクト
  final List<_Particle> _particles = [];
  late final AnimationController _particleController;

  @override
  void initState() {
    super.initState();

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0, end: 4),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 4, end: -4),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(begin: -4, end: 2),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 2, end: -1),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(begin: -1, end: 0),
        weight: 1,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _shakeController,
        curve: Curves.easeOut,
      ),
    );

    _clearController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _clearAnimation = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(
        parent: _clearController,
        curve: Curves.easeOut,
      ),
    );

    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _bounceAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0, end: 1.12),
        weight: 3,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.12, end: 0.96),
        weight: 2,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.96, end: 1),
        weight: 1,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _bounceController,
        curve: Curves.easeOut,
      ),
    );

    // 消去予定セルのパルス（ゆっくり明滅、0.8秒周期）
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..addListener(() {
        setState(() {});
      });

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..addListener(() {
        setState(() {});
      });
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _clearController.dispose();
    _bounceController.dispose();
    _pulseController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(noirMindViewModelProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final boardSize = widget.cellSize * Board.size;
    // DragTarget用の下方拡張領域
    final dragExtension = widget.cellSize * _dragOffsetCells;

    // ライン消去・配置イベントを監視してアニメーション発火
    ref
      ..listen(
        noirMindViewModelProvider.select((s) => s.lastClearResult),
        (prev, next) {
          if (next != null && prev == null) {
            _triggerClearAnimation(next);
          }
        },
      )
      ..listen(
        noirMindViewModelProvider.select((s) => s.lastPlacedCells),
        (prev, next) {
          if (next.isNotEmpty && (prev == null || prev.isEmpty)) {
            _bounceController
              ..reset()
              ..forward();
            HapticFeedback.lightImpact();
          }
        },
      );

    // 配置可能かどうか判定
    final canPlace = _canPlaceHover();

    // 消去予定セルを計算（配置可能な場合のみ）
    final clearPreviewCells = canPlace
        ? _computeClearPreview(gameState)
        : const <(int, int)>{};

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

    // パルス強度（0.15 ~ 0.45 の間で滑らかに変動）
    final pulseGlow = 0.15 + _pulseController.value * 0.3;

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
                ]),
                builder: (context, _) {
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
                      pulseGlow: pulseGlow,
                      cellSize: widget.cellSize,
                      pieceColor: colorScheme.onSurface,
                      emptyCellColor:
                          colorScheme.surfaceContainerHighest,
                      gridColor: colorScheme.outlineVariant
                          .withValues(alpha: 0.3),
                      clearProgress: _clearAnimation.value,
                      bounceScale: _bounceAnimation.value,
                    ),
                  );
                },
              ),
            ),
            // DragTarget（ボード＋下方拡張領域をカバー）
            Positioned.fill(
              child: DragTarget<int>(
                onWillAcceptWithDetails: (details) {
                  _updateHoverPosition(
                    details.offset,
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
                          noirMindViewModelProvider.notifier,
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
                  // 透明（ヒット検出のみ、描画はCustomPaintが担当）
                  return const SizedBox.expand();
                },
              ),
            ),
            // パーティクルエフェクト描画
            if (_particles.isNotEmpty)
              IgnorePointer(
                child: CustomPaint(
                  size: Size(boardSize, boardSize),
                  painter: _ParticlePainter(
                    particles: _particles,
                    progress: _particleController.value,
                    color: colorScheme.onSurface,
                  ),
                ),
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
                    onComplete: () {
                      setState(() => _floatingScores.remove(fs));
                    },
                  ),
                ),
              ),
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
        ref.read(noirMindViewModelProvider.notifier).canPlace(
              _hoverPieceIndex!,
              _hoverRow!,
              _hoverCol!,
            );
  }

  /// 配置した場合に消去されるセルを事前計算する。
  Set<(int, int)> _computeClearPreview(NoirMindState gameState) {
    if (_hoverRow == null ||
        _hoverCol == null ||
        _hoverPieceIndex == null) {
      return const {};
    }

    final piece = gameState.pieces[_hoverPieceIndex!];
    if (piece == null) {
      return const {};
    }

    // ボードを複製してピースを仮配置
    final tempBoard = Board.from(gameState.board);
    if (!tempBoard.canPlace(piece, _hoverRow!, _hoverCol!)) {
      return const {};
    }
    tempBoard.place(piece, _hoverRow!, _hoverCol!);

    // 消去チェック
    final result = tempBoard.checkClearLines();
    return result.clearedCells;
  }

  void _triggerClearAnimation(ClearResult result) {
    _clearController
      ..reset()
      ..forward();

    // パーティクル生成（消去セルから放射状に）
    final rng = Random();
    _particles.clear();
    for (final (r, c) in result.cells) {
      final cx = (c + 0.5) * widget.cellSize;
      final cy = (r + 0.5) * widget.cellSize;
      for (var i = 0; i < 6; i++) {
        final angle = rng.nextDouble() * 2 * pi;
        final speed = 30 + rng.nextDouble() * 50;
        _particles.add(
          _Particle(
            x: cx,
            y: cy,
            vx: cos(angle) * speed,
            vy: sin(angle) * speed,
            size: 2 + rng.nextDouble() * 3,
          ),
        );
      }
    }
    _particleController
      ..reset()
      ..forward();

    // 触覚フィードバック（ライン数に応じて強さ変更）
    if (result.linesCleared >= 2) {
      _shakeController
        ..reset()
        ..forward();
      HapticFeedback.heavyImpact();
    } else {
      HapticFeedback.mediumImpact();
    }

    // フローティングスコア追加
    setState(() {
      _floatingScores.add(
        _FloatingScore(
          id: DateTime.now().microsecondsSinceEpoch,
          points: result.pointsEarned,
          combo: result.combo,
          row: result.placementRow,
          col: result.placementCol,
        ),
      );
    });
  }

  void _updateHoverPosition(
    Offset globalOffset,
    BuildContext ctx,
  ) {
    final box = ctx.findRenderObject()! as RenderBox;
    final local = box.globalToLocal(globalOffset);
    // ドラッグフィードバックのオフセット分を調整（指の上に表示）
    final adjustedY = local.dy - widget.cellSize * _dragOffsetCells;
    setState(() {
      _hoverCol = (local.dx / widget.cellSize).floor();
      _hoverRow = (adjustedY / widget.cellSize).floor();
    });
  }

  void _updateHoverPositionWithIndex(
    Offset globalOffset,
    int pieceIndex,
    BuildContext ctx,
  ) {
    _updateHoverPosition(globalOffset, ctx);
    setState(() {
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
  });

  final double x;
  final double y;
  final double vx;
  final double vy;
  final double size;
}

class _ParticlePainter extends CustomPainter {
  const _ParticlePainter({
    required this.particles,
    required this.progress,
    required this.color,
  });

  final List<_Particle> particles;
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final opacity = (1 - progress).clamp(0.0, 1.0);
    if (opacity <= 0) {
      return;
    }

    final paint = Paint()..color = color.withValues(alpha: opacity);

    for (final p in particles) {
      final px = p.x + p.vx * progress;
      final py = p.y + p.vy * progress;
      final s = p.size * (1 - progress * 0.5);
      canvas.drawCircle(Offset(px, py), s, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter oldDelegate) => true;
}

// --- フローティングスコア ---

class _FloatingScore {
  _FloatingScore({
    required this.id,
    required this.points,
    required this.combo,
    required this.row,
    required this.col,
  });

  final int id;
  final int points;
  final int combo;
  final int row;
  final int col;
}

class _FloatingScoreWidget extends StatefulWidget {
  const _FloatingScoreWidget({
    required this.floatingScore,
    required this.cellSize,
    required this.onComplete,
  });

  final _FloatingScore floatingScore;
  final double cellSize;
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
    // ポップイン効果: 0 → 1.2 → 1.0
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
    final colorScheme = Theme.of(context).colorScheme;
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
                      color: colorScheme.onSurface,
                      shadows: [
                        Shadow(
                          color: colorScheme.surface,
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                  if (fs.combo > 1)
                    Text(
                      'COMBO x${fs.combo}',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        letterSpacing: 1,
                        color: colorScheme.onSurface
                            .withValues(alpha: 0.7),
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
    required this.pieceColor,
    required this.emptyCellColor,
    required this.gridColor,
    required this.clearProgress,
    required this.bounceScale,
    required this.clearPreviewCells,
    required this.pulseGlow,
    this.hoverRow,
    this.hoverCol,
    this.hoverPiece,
    this.canPlaceHover = false,
  });

  final List<List<bool>> board;
  final Set<(int, int)> clearingCells;
  final Set<(int, int)> lastPlacedCells;
  final double cellSize;
  final Color pieceColor;
  final Color emptyCellColor;
  final Color gridColor;
  final double clearProgress;
  final double bounceScale;
  final int? hoverRow;
  final int? hoverCol;
  final Piece? hoverPiece;
  final bool canPlaceHover;

  /// 配置時に消去されるセルの集合（グロー表示用）。
  final Set<(int, int)> clearPreviewCells;

  /// パルスアニメーションのグロー強度（0.15 ~ 0.45）。
  final double pulseGlow;

  @override
  void paint(Canvas canvas, Size size) {
    const gap = 1.5;
    const cellRadius = 3.0;
    final emptyCellPaint = Paint()..color = emptyCellColor;

    // 空セルの背景を描画（ボードの存在感を出す）
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
            const Radius.circular(cellRadius),
          ),
          emptyCellPaint,
        );
      }
    }

    // 配置済みセルを描画（グラデーション付き立体タイル）
    for (var r = 0; r < Board.size; r++) {
      for (var c = 0; c < Board.size; c++) {
        if (clearingCells.contains((r, c))) {
          // 消去アニメーション: フェード+縮小
          _drawGradientCell(
            canvas,
            r,
            c,
            gap,
            cellRadius,
            opacity: clearProgress,
            shrink: (1 - clearProgress) * cellSize * 0.3,
          );
        } else if (lastPlacedCells.contains((r, c)) &&
            bounceScale > 0) {
          // 配置直後のバウンスアニメーション
          _drawGradientCellScaled(
            canvas,
            r,
            c,
            gap,
            cellRadius,
            bounceScale,
          );
        } else if (board[r][c]) {
          _drawGradientCell(canvas, r, c, gap, cellRadius);
          // 消去予定セルのパルスグロー
          if (clearPreviewCells.contains((r, c))) {
            _drawGlowOverlay(
              canvas,
              r,
              c,
              gap,
              cellRadius,
              pulseGlow,
            );
          }
        }
      }
    }

    // ホバープレビュー（配置可能な場合のみ表示）
    if (canPlaceHover &&
        hoverRow != null &&
        hoverCol != null &&
        hoverPiece != null) {
      final previewPaint = Paint()
        ..color = pieceColor.withValues(alpha: 0.2);

      for (final (dr, dc) in hoverPiece!.offsets) {
        final r = hoverRow! + dr;
        final c = hoverCol! + dc;
        if (r >= 0 &&
            r < Board.size &&
            c >= 0 &&
            c < Board.size) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(
                c * cellSize + gap,
                r * cellSize + gap,
                cellSize - gap * 2,
                cellSize - gap * 2,
              ),
              const Radius.circular(cellRadius),
            ),
            previewPaint,
          );
        }
      }
    }
  }

  /// 消去予定セルにパルスグローオーバーレイを描画する。
  void _drawGlowOverlay(
    Canvas canvas,
    int r,
    int c,
    double gap,
    double cellRadius,
    double glowAlpha,
  ) {
    final rect = Rect.fromLTWH(
      c * cellSize + gap,
      r * cellSize + gap,
      cellSize - gap * 2,
      cellSize - gap * 2,
    );
    final rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(cellRadius),
    );
    // 白いグロー（パルスで明滅）
    canvas.drawRRect(
      rrect,
      Paint()..color = Colors.white.withValues(alpha: glowAlpha),
    );
  }

  /// グラデーション付きセルを描画（立体感のあるリッチなタイル）。
  void _drawGradientCell(
    Canvas canvas,
    int r,
    int c,
    double gap,
    double cellRadius, {
    double opacity = 1.0,
    double shrink = 0.0,
  }) {
    final rect = Rect.fromLTWH(
      c * cellSize + gap + shrink,
      r * cellSize + gap + shrink,
      cellSize - gap * 2 - shrink * 2,
      cellSize - gap * 2 - shrink * 2,
    );
    final rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(cellRadius),
    );

    // ベースカラー
    final basePaint = Paint()
      ..color = pieceColor.withValues(alpha: opacity);
    canvas.drawRRect(rrect, basePaint);

    // 上部ハイライト（光沢感）
    final highlightPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: 0.25 * opacity),
          Colors.white.withValues(alpha: 0),
        ],
        stops: const [0.0, 0.5],
      ).createShader(rect);
    canvas.drawRRect(rrect, highlightPaint);

    // 下部シャドウ（奥行き感）
    final shadowPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.black.withValues(alpha: 0),
          Colors.black.withValues(alpha: 0.15 * opacity),
        ],
        stops: const [0.6, 1.0],
      ).createShader(rect);
    canvas.drawRRect(rrect, shadowPaint);
  }

  /// スケール付きグラデーションセル（バウンスアニメーション用）。
  void _drawGradientCellScaled(
    Canvas canvas,
    int r,
    int c,
    double gap,
    double cellRadius,
    double scale,
  ) {
    final cw = (cellSize - gap * 2) * scale;
    final ch = (cellSize - gap * 2) * scale;
    final cx = c * cellSize + cellSize / 2;
    final cy = r * cellSize + cellSize / 2;
    final rect = Rect.fromCenter(
      center: Offset(cx, cy),
      width: cw,
      height: ch,
    );
    final rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(cellRadius),
    );

    // ベース
    canvas.drawRRect(rrect, Paint()..color = pieceColor);

    // ハイライト
    final highlightPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: 0.25),
          Colors.white.withValues(alpha: 0),
        ],
        stops: const [0.0, 0.5],
      ).createShader(rect);
    canvas.drawRRect(rrect, highlightPaint);

    // シャドウ
    final shadowPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.black.withValues(alpha: 0),
          Colors.black.withValues(alpha: 0.15),
        ],
        stops: const [0.6, 1.0],
      ).createShader(rect);
    canvas.drawRRect(rrect, shadowPaint);
  }

  @override
  bool shouldRepaint(_BoardPainter oldDelegate) => true;
}
