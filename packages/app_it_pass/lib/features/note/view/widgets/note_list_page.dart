part of '../note_sheet.dart';

class _NoteListPage extends ConsumerStatefulWidget {
  const _NoteListPage({required this.onSelectItem});

  final _NoteItemSelectedCallback onSelectItem;

  @override
  ConsumerState<_NoteListPage> createState() => _NoteListPageState();
}

class _NoteListPageState extends ConsumerState<_NoteListPage> {
  static const _tabs = NoteTab.values;

  NoteTab _tab = NoteTab.review;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(NoteTab tab) {
    final idx = _tabs.indexOf(tab);
    _pageController.animateToPage(
      idx,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    setState(() => _tab = tab);
  }

  void _onPageChanged(int index) {
    setState(() => _tab = _tabs[index]);
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(noteSheetViewModelProvider);
    final reviewItems =
        asyncState.whenData((r) => r.reviewItems).value ?? const <NoteListItem>[];

    return Column(
      children: [
        _NoteTabBar(selectedTab: _tab, onTabChanged: _onTabTapped),
        const Gap(AppSpacing.sm),
        Expanded(
          child: PageView(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            children: _tabs
                .map(
                  (tab) => _NoteListContent(
                    key: ValueKey('list_${tab.name}'),
                    tab: tab,
                    asyncState: asyncState,
                    onSelectItem: widget.onSelectItem,
                  ),
                )
                .toList(),
          ),
        ),
        if (_tab == NoteTab.review && reviewItems.isNotEmpty)
          _StartReviewButton(
            count: reviewItems.length,
            onTap: () => widget.onSelectItem(
              reviewItems[0],
              fromReview: true,
              reviewQueue: reviewItems,
              reviewIndex: 0,
            ),
          ),
      ],
    );
  }
}
