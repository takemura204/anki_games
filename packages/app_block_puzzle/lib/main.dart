import 'package:app_block_puzzle/bootstrap/run_block_puzzle_app.dart';

export 'package:app_block_puzzle/bootstrap/run_block_puzzle_app.dart'
    show MyApp, runBlockPuzzleApp;

Future<void> main() => runBlockPuzzleApp(initializeFirebase: false);
