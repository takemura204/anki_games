export 'package:anki_games/apps/block_puzzle/bootstrap/run_block_puzzle_app.dart'
    show MyApp, runBlockPuzzleApp;

import 'package:anki_games/apps/block_puzzle/bootstrap/run_block_puzzle_app.dart';

Future<void> main() => runBlockPuzzleApp(initializeFirebase: false);
