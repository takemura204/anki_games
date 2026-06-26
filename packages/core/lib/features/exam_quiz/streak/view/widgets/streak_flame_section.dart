part of '../streak_banner.dart';

class _StreakFlameSection extends StatelessWidget {
  const _StreakFlameSection({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        ShaderMask(
          shaderCallback: (b) => const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFD08BFF), Color(0xFF7C3AED)],
          ).createShader(b),
          child: const Icon(
            Icons.local_fire_department_rounded,
            color: Colors.white,
            size: 75,
          ),
        ),
        Positioned(
          bottom: 10,
          child: Text(
            '$count',
            style: TextStyle(
              fontFamily: AppTextStyle.fontFamily,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: context.appColors.fg,
              height: 1,
              shadows: const [
                Shadow(
                  color: Color(0xBB7C3AED),
                  blurRadius: 6,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
