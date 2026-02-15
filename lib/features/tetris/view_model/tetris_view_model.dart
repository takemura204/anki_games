import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'tetris_view_model.freezed.dart';
part 'tetris_view_model.g.dart';

@freezed
abstract class TetrisState with _$TetrisState {
  const factory TetrisState({
    @Default(false) bool isLoading,
  }) = _TetrisState;
}

@riverpod
class TetrisViewModel extends _$TetrisViewModel {
  @override
  TetrisState build() {
    return TetrisState();
  }
}
