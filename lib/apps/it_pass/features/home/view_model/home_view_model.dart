import 'package:hooks_riverpod/hooks_riverpod.dart';

class HomeState {
  const HomeState();
}

final AutoDisposeNotifierProvider<HomeViewModel, HomeState>
    homeViewModelProvider =
    NotifierProvider.autoDispose<HomeViewModel, HomeState>(HomeViewModel.new);

class HomeViewModel extends AutoDisposeNotifier<HomeState> {
  @override
  HomeState build() => const HomeState();
}
