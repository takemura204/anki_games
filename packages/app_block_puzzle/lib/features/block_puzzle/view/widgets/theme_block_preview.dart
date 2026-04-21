import 'dart:ui';

import 'package:flutter/material.dart';

import '../../model/game_theme.dart';
import '../painters/cell_renderer.dart';

// CellRenderMode ごとのシェーダーアセットパス（null = Canvas フォールバック）。
const _kShaderPaths = <CellRenderMode, String>{
  CellRenderMode.glassmorphism:
      'packages/core/shaders/block_puzzle/glassmorphism.frag',
  CellRenderMode.wireframe: 'packages/core/shaders/block_puzzle/wireframe.frag',
  CellRenderMode.matte: 'packages/core/shaders/block_puzzle/matte.frag',
  CellRenderMode.bubble: 'packages/core/shaders/block_puzzle/bubble.frag',
  CellRenderMode.ice: 'packages/core/shaders/block_puzzle/ice.frag',
  CellRenderMode.slate: 'packages/core/shaders/block_puzzle/slate.frag',
  CellRenderMode.slime: 'packages/core/shaders/block_puzzle/slime.frag',
};

Future<FragmentShader?> _loadCellShader(CellRenderMode mode) async {
  final path = _kShaderPaths[mode];
  if (path == null) {
    return null;
  }
  final program = await FragmentProgram.fromAsset(path);
  return program.fragmentShader();
}

/// テーマのブロックを 3×3 グリッドで階段状（3+2+1）に表示するプレビューウィジェット。
///
/// シェーダーが利用可能な場合は GLSL で描画し、
/// それ以外は Canvas フォールバックで描画する。
class ThemeBlockPreview extends StatefulWidget {
  /// プレビューウィジェットを作成する。
  const ThemeBlockPreview({
    required this.theme,
    this.cellSize = 20,
    super.key,
  });

  /// プレビューに使用するゲームテーマ。
  final GameTheme theme;

  /// 各セルの論理ピクセルサイズ。
  final double cellSize;

  @override
  State<ThemeBlockPreview> createState() => _ThemeBlockPreviewState();
}

class _ThemeBlockPreviewState extends State<ThemeBlockPreview>
    with SingleTickerProviderStateMixin {
  static const _gap = 4.0;

  late final AnimationController _clock;
  late final DateTime _clockStart;
  FragmentShader? _shader;

  @override
  void initState() {
    super.initState();
    _clockStart = DateTime.now();
    _clock = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();
    _initShader(widget.theme.cellStyle.renderMode);
  }

  @override
  void didUpdateWidget(ThemeBlockPreview old) {
    super.didUpdateWidget(old);
    if (old.theme.cellStyle.renderMode != widget.theme.cellStyle.renderMode) {
      _shader = null;
      _initShader(widget.theme.cellStyle.renderMode);
    }
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  Future<void> _initShader(CellRenderMode mode) async {
    final shader = await _loadCellShader(mode);
    if (mounted) {
      setState(() => _shader = shader);
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final colors = widget.theme.colorsFor(brightness);
    final cellSize = widget.cellSize;
    final totalSize = 3 * cellSize + 2 * _gap;

    return CustomPaint(
      size: Size(totalSize, totalSize),
      painter: _PreviewPainter(
        colors: colors,
        style: widget.theme.cellStyle,
        cellSize: cellSize,
        gap: _gap,
        clockStart: _clockStart,
        clock: _clock,
        shader: _shader,
      ),
    );
  }
}

class _PreviewPainter extends CustomPainter {
  _PreviewPainter({
    required this.colors,
    required this.style,
    required this.cellSize,
    required this.gap,
    required this.clockStart,
    required Listenable clock,
    this.shader,
  }) : super(repaint: clock);

  final GameThemeColors colors;
  final GameThemeCellStyle style;
  final double cellSize;
  final double gap;
  final DateTime clockStart;
  final FragmentShader? shader;

  static const _total = 3;
  static const _filledCounts = [3, 2, 1];

  @override
  void paint(Canvas canvas, Size size) {
    final time = DateTime.now().difference(clockStart).inMilliseconds / 1000.0;
    final emptyRadius = style.cellBorderRadius.clamp(0.0, cellSize / 2);
    final emptyPaint = Paint()..color = colors.emptyCellFill;

    for (var col = 0; col < _total; col++) {
      final filled = _filledCounts[col];
      for (var row = 0; row < _total; row++) {
        final left = col * (cellSize + gap);
        final top = row * (cellSize + gap);
        final rect = Rect.fromLTWH(left, top, cellSize, cellSize);

        if (row >= _total - filled) {
          drawCell(
            canvas,
            rect,
            style,
            colors,
            shader: shader,
            time: time,
          );
        } else {
          canvas.drawRRect(
            RRect.fromRectAndRadius(rect, Radius.circular(emptyRadius)),
            emptyPaint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_PreviewPainter old) =>
      old.shader != shader ||
      old.colors != colors ||
      old.style != style ||
      old.cellSize != cellSize;
}

/// テーマを表すシングルブロック（テーマボタン用）。
class ThemeSingleBlock extends StatefulWidget {
  /// シングルブロックウィジェットを作成する。
  const ThemeSingleBlock({
    required this.theme,
    required this.brightness,
    this.size = 32,
    super.key,
  });

  /// 使用するゲームテーマ。
  final GameTheme theme;

  /// 明暗モード。
  final Brightness brightness;

  /// ブロックのピクセルサイズ。
  final double size;

  @override
  State<ThemeSingleBlock> createState() => _ThemeSingleBlockState();
}

class _ThemeSingleBlockState extends State<ThemeSingleBlock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _clock;
  late final DateTime _clockStart;
  FragmentShader? _shader;

  @override
  void initState() {
    super.initState();
    _clockStart = DateTime.now();
    _clock = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();
    _initShader(widget.theme.cellStyle.renderMode);
  }

  @override
  void didUpdateWidget(ThemeSingleBlock old) {
    super.didUpdateWidget(old);
    if (old.theme.cellStyle.renderMode != widget.theme.cellStyle.renderMode) {
      _shader = null;
      _initShader(widget.theme.cellStyle.renderMode);
    }
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  Future<void> _initShader(CellRenderMode mode) async {
    final shader = await _loadCellShader(mode);
    if (mounted) {
      setState(() => _shader = shader);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.theme.colorsFor(widget.brightness);
    final style = widget.theme.cellStyle;
    final blockSize = widget.size;

    return CustomPaint(
      size: Size(blockSize, blockSize),
      painter: _SingleBlockPainter(
        colors: colors,
        style: style,
        blockSize: blockSize,
        clockStart: _clockStart,
        clock: _clock,
        shader: _shader,
      ),
    );
  }
}

class _SingleBlockPainter extends CustomPainter {
  _SingleBlockPainter({
    required this.colors,
    required this.style,
    required this.blockSize,
    required this.clockStart,
    required Listenable clock,
    this.shader,
  }) : super(repaint: clock);

  final GameThemeColors colors;
  final GameThemeCellStyle style;
  final double blockSize;
  final DateTime clockStart;
  final FragmentShader? shader;

  @override
  void paint(Canvas canvas, Size size) {
    final time = DateTime.now().difference(clockStart).inMilliseconds / 1000.0;
    final rect = Rect.fromLTWH(0, 0, blockSize, blockSize);
    drawCell(canvas, rect, style, colors, shader: shader, time: time);
  }

  @override
  bool shouldRepaint(_SingleBlockPainter old) =>
      old.shader != shader ||
      old.colors != colors ||
      old.style != style ||
      old.blockSize != blockSize;
}
