import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'gravity_sand_view_model.freezed.dart';
part 'gravity_sand_view_model.g.dart';

/// State for the Gravity Sand feature.
@freezed
abstract class GravitySandState with _$GravitySandState {
  /// Creates the default state.
  const factory GravitySandState({
    @Default(false) bool isLoading,
  }) = _GravitySandState;
}

/// ViewModel for the Gravity Sand feature.
@riverpod
class GravitySandViewModel extends _$GravitySandViewModel {
  @override
  GravitySandState build() {
    return const GravitySandState();
  }
}
