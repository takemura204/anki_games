part of '../quiz_screen.dart';

class _QuizNetworkImage extends StatelessWidget {
  const _QuizNetworkImage({
    required this.url,
    required this.heroTag,
    this.borderRadius,
    this.tapToView = true,
  });

  final String url;

  /// Hero タグ。呼び出し元が一意な値を渡す責務を持つ
  final String heroTag;
  final BorderRadiusGeometry? borderRadius;

  /// true のとき → タップで拡大ビューを開く
  /// false のとき → 長押しで拡大ビューを開く（タップは素通り）
  final bool tapToView;

  void _openViewer(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.transparent,
        pageBuilder: (_, __, ___) =>
            _ImageViewerPage(url: url, heroTag: heroTag),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 280),
        reverseTransitionDuration: const Duration(milliseconds: 220),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(10);

    return GestureDetector(
      onTap: tapToView ? () => _openViewer(context) : null,
      onLongPress: tapToView ? null : () => _openViewer(context),
      child: ClipRRect(
        borderRadius: radius,
        clipBehavior: Clip.hardEdge,
        child: ColoredBox(
          color: Colors.white.withValues(alpha: 1),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.topCenter,
                child: Hero(
                  tag: heroTag,
                  child: CachedNetworkImage(
                    imageUrl: url,
                    fit: BoxFit.none,
                    filterQuality: FilterQuality.high,
                    fadeInDuration: const Duration(milliseconds: 120),
                    fadeOutDuration: const Duration(milliseconds: 80),
                    placeholder: (context, url) => const SizedBox(
                      width: 80,
                      height: 60,
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black26,
                          ),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => const SizedBox(
                      width: 200,
                      height: 60,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.broken_image_outlined,
                              color: Colors.black26,
                            ),
                            SizedBox(height: 4),
                            Text(
                              '画像を読み込めませんでした',
                              style: TextStyle(
                                color: Colors.black45,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ImageViewerPage extends StatefulWidget {
  const _ImageViewerPage({required this.url, required this.heroTag});

  final String url;
  final String heroTag;

  @override
  State<_ImageViewerPage> createState() => _ImageViewerPageState();
}

class _ImageViewerPageState extends State<_ImageViewerPage>
    with SingleTickerProviderStateMixin {
  final _transformationController = TransformationController();
  late final AnimationController _animController;
  Animation<Matrix4>? _animation;
  Offset _doubleTapPosition = Offset.zero;

  static const _zoomScale = 2.5;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    )..addListener(() {
        if (_animation != null) {
          _transformationController.value = _animation!.value;
        }
      });
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _animateTo(Matrix4 target) {
    _animController.stop();
    _animation = Matrix4Tween(
      begin: _transformationController.value,
      end: target,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeInOutCubic,
      ),
    );
    _animController.forward(from: 0);
  }

  void _onDoubleTapDown(TapDownDetails details) {
    _doubleTapPosition = details.localPosition;
  }

  void _onDoubleTap() {
    final isZoomed = _transformationController.value.getMaxScaleOnAxis() > 1.1;
    if (isZoomed) {
      _animateTo(Matrix4.identity());
    } else {
      final x = -_doubleTapPosition.dx * (_zoomScale - 1);
      final y = -_doubleTapPosition.dy * (_zoomScale - 1);
      _animateTo(
        Matrix4.identity()
          ..translateByDouble(x, y, 0, 1)
          ..scaleByDouble(_zoomScale, _zoomScale, 1, 1),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: Colors.black),
          GestureDetector(
            onDoubleTapDown: _onDoubleTapDown,
            onDoubleTap: _onDoubleTap,
            child: InteractiveViewer(
              transformationController: _transformationController,
              minScale: 0.5,
              maxScale: 5,
              child: Center(
                child: Hero(
                  tag: widget.heroTag,
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(8),
                    child: CachedNetworkImage(
                      imageUrl: widget.url,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black45,
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(8),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
