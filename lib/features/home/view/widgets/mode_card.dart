part of '../home_screen.dart';

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.badge,
    required this.colors,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final String badge;
  final GameThemeColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colors.emptyCellFill,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: colors.onSurface.withValues(alpha: 0.2),
              width: 1.0,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 30,
                color: colors.onSurface,
              ),
              const Gap(4),
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface,
                ),
              ),
              const Gap(12),
              Text(
                badge,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                  color: colors.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
