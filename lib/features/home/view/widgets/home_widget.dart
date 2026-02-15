part of '../home_screen.dart';

class _HomeWidget extends StatelessWidget {
  const _HomeWidget();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const GravitySandScreen(),
              ),
            ),
            child: Text(t.gravitySand.title),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const NoirMindScreen(),
              ),
            ),
            child: Text(t.noirMind.title),
          ),
        ],
      ),
    );
  }
}
