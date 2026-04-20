part of '../filter_sheet.dart';

class _ApplyButton extends StatelessWidget {
  const _ApplyButton({
    required this.canApply,
    required this.isApplying,
    required this.onTap,
  });

  final bool canApply;
  final bool isApplying;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 10,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).padding.bottom + 10,
      ),
      child: GestureDetector(
        onTap: (canApply && !isApplying) ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 52,
          decoration: BoxDecoration(
            gradient: canApply
                ? const LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
                  )
                : null,
            color: canApply ? null : Colors.white12,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: isApplying
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    canApply ? 'この設定で出題する' : '試験回を選択してください',
                    style: TextStyle(
                      color: canApply ? Colors.white : Colors.white38,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
