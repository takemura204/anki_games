part of '../filter_sheet.dart';

class _FilterHeader extends StatelessWidget {
  const _FilterHeader({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 8, 4),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              '出題範囲を絞り込む',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white54),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}
