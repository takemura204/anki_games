import 'dart:async' show unawaited;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mono_games/features/noir_mind/model/game_theme.dart';
import 'package:mono_games/features/noir_mind/model/piece.dart';
import 'package:mono_games/features/noir_mind/view/painters/cell_renderer.dart';

/// ドラッグ可能なピースウィジェット。
class PieceWidget extends StatefulWidget {
  /// ドラッグ可能なピースウィジェットを作成する。
  const PieceWidget({
    required this.piece,
    required this.pieceIndex,
    required this.cellSize,
    required this.theme,
    super.key,
  });

  /// 描画するピース。
  final Piece piece;

  /// トレイ内のインデックス（ドラッグデータとして使用）。
  final int pieceIndex;

  /// 各セルの論理ピクセルサイズ。
  final double cellSize;

  /// 現在のゲームテーマ。
  final GameTheme theme;

  @override
  State<PieceWidget> createState() => _PieceWidgetState();
}

class _PieceWidgetState extends State<PieceWidget>
    with SingleTickerProviderStateMixin {
  bool _isDragging = false;
  FragmentShader? _shader;
  late final AnimationController _clockController;
  late final DateTime _clockStart;

  @override
  void initState() {
    super.initState();
    _clockStart = DateTime.now();
    _clockController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();
    _clockController.addListener(_onTick);
    unawaited(_loadShader(widget.theme.cellStyle.renderMode));
  }

  @override
  void didUpdateWidget(PieceWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.theme.cellStyle.renderMode !=
        widget.theme.cellStyle.renderMode) {
      setState(() => _shader = null);
      unawaited(_loadShader(widget.theme.cellStyle.renderMode));
    }
  }

  void _onTick() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadShader(CellRenderMode mode) async {
    final path = _shaderPath(mode);
    if (path == null) {
      return;
    }
    final program = await FragmentProgram.fromAsset(path);
    if (mounted) {
      setState(() => _shader = program.fragmentShader());
    }
  }

  static String? _shaderPath(CellRenderMode mode) => switch (mode) {
        CellRenderMode.glassmorphism =>
          'shaders/noir_mind/glassmorphism.frag',
        CellRenderMode.wireframe => 'shaders/noir_mind/wireframe.frag',
        CellRenderMode.matte => 'shaders/noir_mind/matte.frag',
        CellRenderMode.bubble => 'shaders/noir_mind/bubble.frag',
        CellRenderMode.ice => 'shaders/noir_mind/ice.frag',
        CellRenderMode.slate => 'shaders/noir_mind/slate.frag',
        CellRenderMode.slime => 'shaders/noir_mind/slime.frag',
        _ => null,
      };

  double get _time =>
      DateTime.now().difference(_clockStart).inMilliseconds / 1000.0;

  @override
  void dispose() {
    _clockController
      ..removeListener(_onTick)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Draggable<int>(
      data: widget.pieceIndex,
      onDragStarted: () {
        HapticFeedback.selectionClick();
        setState(() => _isDragging = true);
      },
      onDragEnd: (_) {
        setState(() => _isDragging = false);
      },
      onDraggableCanceled: (_, __) {
        setState(() => _isDragging = false);
      },
      // ドラッグ中のフィードバック（指の上にオフセット、ボードセル等倍サイズ）
      feedback: Transform.translate(
        offset: Offset(0, -(widget.cellSize / 0.6) * 2),
        child: Material(
          color: Colors.transparent,
          child: Opacity(
            opacity: 0.85,
            child: _PieceShape(
              piece: widget.piece,
              cellSize: widget.cellSize / 0.6,
              theme: widget.theme,
              shader: _shader,
              time: _time,
            ),
          ),
        ),
      ),
      // ドラッグ中は元の位置を空にする
      childWhenDragging: SizedBox(
        width: widget.piece.width * widget.cellSize,
        height: widget.piece.height * widget.cellSize,
      ),
      child: AnimatedScale(
        scale: _isDragging ? 1.15 : 1,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: _PieceShape(
          piece: widget.piece,
          cellSize: widget.cellSize,
          theme: widget.theme,
          shader: _shader,
          time: _time,
        ),
      ),
    );
  }
}

class _PieceShape extends StatelessWidget {
  const _PieceShape({
    required this.piece,
    required this.cellSize,
    required this.theme,
    required this.shader,
    required this.time,
  });

  final Piece piece;
  final double cellSize;
  final GameTheme theme;
  final FragmentShader? shader;
  final double time;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(piece.width * cellSize, piece.height * cellSize),
      painter: _PiecePainter(
        piece: piece,
        cellSize: cellSize,
        theme: theme,
        brightness: Theme.of(context).brightness,
        shader: shader,
        time: time,
      ),
    );
  }
}

class _PiecePainter extends CustomPainter {
  _PiecePainter({
    required this.piece,
    required this.cellSize,
    required this.theme,
    required this.brightness,
    required this.shader,
    required this.time,
  });

  final Piece piece;
  final double cellSize;
  final GameTheme theme;
  final Brightness brightness;
  final FragmentShader? shader;
  final double time;

  @override
  void paint(Canvas canvas, Size size) {
    const gap = 1.5;

    for (final (row, col) in piece.offsets) {
      final rect = Rect.fromLTWH(
        col * cellSize + gap,
        row * cellSize + gap,
        cellSize - gap * 2,
        cellSize - gap * 2,
      );
      drawCell(
        canvas,
        rect,
        theme.cellStyle,
        theme.colorsFor(brightness),
        shader: shader,
        time: time,
      );
    }
  }

  @override
  bool shouldRepaint(_PiecePainter oldDelegate) {
    if (shader == null) {
      return theme != oldDelegate.theme;
    }
    return theme != oldDelegate.theme ||
        shader != oldDelegate.shader ||
        time != oldDelegate.time;
  }
}
