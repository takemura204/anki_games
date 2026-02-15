import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'tetris_model.freezed.dart';
part 'tetris_model.g.dart';

@freezed
abstract class Tetris with _$Tetris {
  const factory Tetris({
    @Default(false) bool isLoading,
  }) = _Tetris;
}

@riverpod
class TetrisModel extends _$TetrisModel {
  @override
  Tetris build() {
    return Tetris();
  }
}
