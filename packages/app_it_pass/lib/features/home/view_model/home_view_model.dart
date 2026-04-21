import 'package:hooks_riverpod/hooks_riverpod.dart';

class HomeState {
  const HomeState();
}

final NotifierProvider<HomeViewModel, HomeState> homeViewModelProvider =
    NotifierProvider.autoDispose<HomeViewModel, HomeState>(HomeViewModel.new);

class HomeViewModel extends Notifier<HomeState> {
  @override
  HomeState build() => const HomeState();
}
