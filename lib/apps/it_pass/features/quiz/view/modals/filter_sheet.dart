import 'dart:ui';

import 'package:anki_games/apps/it_pass/features/quiz/model/exam_meta.dart';
import 'package:anki_games/apps/it_pass/features/quiz/model/quiz_filter.dart';
import 'package:anki_games/apps/it_pass/features/quiz/repository/filter_repository.dart';
import 'package:anki_games/apps/it_pass/features/quiz/view_model/quiz_view_model.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

Future<void> showQuizFilterBottomSheet(
  BuildContext context,
  WidgetRef ref,
) async {
  final savedFilter = await FilterRepository().load();
  if (!context.mounted) {
    return;
  }

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _QuizFilterSheet(
      initialFilter: savedFilter,
      onApply: (filter) async {
        await FilterRepository().save(filter);
        ref.invalidate(quizViewModelProvider);
      },
    ),
  );
}

class _QuizFilterSheet extends StatefulWidget {
  const _QuizFilterSheet({
    required this.initialFilter,
    required this.onApply,
  });

  final QuizFilter initialFilter;
  final Future<void> Function(QuizFilter) onApply;

  @override
  State<_QuizFilterSheet> createState() => _QuizFilterSheetState();
}

class _QuizFilterSheetState extends State<_QuizFilterSheet> {
  late Set<String> _selectedEraIds;
  late Set<String> _selectedSystems;
  late Set<String> _selectedMajors;

  final _systemExpanded = <String, bool>{
    'ストラテジ系': false,
    'マネジメント系': false,
    'テクノロジ系': false,
  };

  var _isApplying = false;

  @override
  void initState() {
    super.initState();
    _selectedEraIds = Set.from(widget.initialFilter.selectedEraIds);
    _selectedSystems = Set.from(widget.initialFilter.selectedSystems);
    _selectedMajors = Set.from(widget.initialFilter.selectedMajors);
  }

  bool get _canApply => _selectedEraIds.isNotEmpty;

  void _toggleEra(String eraId) {
    setState(() {
      if (_selectedEraIds.contains(eraId)) {
        _selectedEraIds.remove(eraId);
      } else {
        _selectedEraIds.add(eraId);
      }
    });
  }

  void _toggleSystem(String system) {
    setState(() {
      if (_selectedSystems.contains(system)) {
        _selectedSystems.remove(system);
        final majors = ExamMeta.categoryTree[system] ?? [];
        _selectedMajors.removeAll(majors);
      } else {
        _selectedSystems.add(system);
      }
    });
  }

  void _toggleMajor(String major) {
    setState(() {
      if (_selectedMajors.contains(major)) {
        _selectedMajors.remove(major);
      } else {
        _selectedMajors.add(major);
      }
    });
  }

  void _selectAllEras() {
    setState(() {
      _selectedEraIds = ExamMeta.all.map((m) => m.eraId).toSet();
    });
  }

  void _clearAllEras() {
    setState(() => _selectedEraIds.clear());
  }

  Future<void> _apply() async {
    setState(() => _isApplying = true);
    final filter = QuizFilter(
      selectedEraIds: _selectedEraIds,
      selectedSystems: _selectedSystems,
      selectedMajors: _selectedMajors,
    );
    await widget.onApply(filter);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          height: screenHeight * 0.88,
          decoration: BoxDecoration(
            color: const Color(0xFF0D0B2B).withValues(alpha: 0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
          ),
          child: Column(
            children: [
              _buildHandle(),
              _buildHeader(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  children: [
                    _buildSectionLabel('分野（系統）'),
                    _buildSystemSection(),
                    const Gap(24),
                    _buildSectionLabel('中分類'),
                    _buildMajorSection(),
                    const Gap(24),
                    _buildSectionLabel('試験回'),
                    _buildEraSection(),
                    const Gap(32),
                  ],
                ),
              ),
              _buildApplyButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHandle() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.white24,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          const Text(
            '出題範囲を絞り込む',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white54),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.5),
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildEraSection() {
    final groups = <ExamGroup, List<ExamMeta>>{};
    for (final meta in ExamMeta.all) {
      groups.putIfAbsent(meta.group, () => []).add(meta);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _smallButton(
              '全選択',
              onTap: _selectAllEras,
              active: _selectedEraIds.length == ExamMeta.all.length,
            ),
            const SizedBox(width: 8),
            _smallButton('全解除', onTap: _clearAllEras, active: false),
          ],
        ),
        const SizedBox(height: 12),
        ...groups.entries.map((entry) {
          final groupLabel = switch (entry.key) {
            ExamGroup.reiwa => '令和',
            ExamGroup.heisei => '平成',
            ExamGroup.sample => 'サンプル',
          };
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  groupLabel,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 11,
                  ),
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: entry.value.map((meta) {
                  final selected = _selectedEraIds.contains(meta.eraId);
                  return _EraChip(
                    label: meta.displayName,
                    selected: selected,
                    onTap: () => _toggleEra(meta.eraId),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
          );
        }),
        if (!_canApply)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFFBBF24),
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  '試験回を1つ以上選択してください',
                  style: TextStyle(
                    color: const Color(0xFFFBBF24).withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSystemSection() {
    final systems = ExamMeta.categoryTree.keys.toList();
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: systems.map((system) {
        final explicit = _selectedSystems.contains(system);
        return GestureDetector(
          onTap: () => _toggleSystem(system),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: explicit
                  ? const Color(0xFF7C3AED).withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: explicit
                    ? const Color(0xFF7C3AED)
                    : Colors.white.withValues(alpha: 0.15),
              ),
            ),
            child: Text(
              system,
              style: TextStyle(
                color: explicit ? Colors.white : Colors.white54,
                fontSize: 13,
                fontWeight: explicit ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMajorSection() {
    if (_selectedSystems.isEmpty) {
      return Text(
        '分野を選択すると中分類で絞り込めます（任意）',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.3),
          fontSize: 12,
        ),
      );
    }

    return Column(
      children: _selectedSystems.map((system) {
        final majors = ExamMeta.categoryTree[system] ?? [];
        final isExpanded = _systemExpanded[system] ?? false;
        return _GlassExpansionTile(
          title: system,
          isExpanded: isExpanded,
          onToggle: () => setState(
            () => _systemExpanded[system] = !isExpanded,
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: majors.map((major) {
              final selected = _selectedMajors.contains(major);
              return GestureDetector(
                onTap: () => _toggleMajor(major),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFF10B981).withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selected
                          ? const Color(0xFF10B981).withValues(alpha: 0.6)
                          : Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Text(
                    major,
                    style: TextStyle(
                      color:
                          selected ? const Color(0xFF10B981) : Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildApplyButton() {
    return Container(
      padding: EdgeInsets.only(
        top: 10,
        left: 10,
        right: 10,
        bottom: MediaQuery.of(context).padding.bottom,
      ),
      child: GestureDetector(
        onTap: (_canApply && !_isApplying) ? _apply : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 52,
          decoration: BoxDecoration(
            gradient: _canApply
                ? const LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
                  )
                : null,
            color: _canApply ? null : Colors.white12,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: _isApplying
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    _canApply ? 'この設定で出題する' : '試験回を選択してください',
                    style: TextStyle(
                      color: _canApply ? Colors.white : Colors.white38,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _smallButton(
    String label, {
    required VoidCallback onTap,
    required bool active,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? const Color(0xFF7C3AED).withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active
                ? const Color(0xFF7C3AED).withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? const Color(0xFF7C3AED) : Colors.white38,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _EraChip extends StatelessWidget {
  const _EraChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF4F46E5).withValues(alpha: 0.25)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? const Color(0xFF7C3AED).withValues(alpha: 0.7)
                : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.white38,
            fontSize: 11,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _GlassExpansionTile extends StatelessWidget {
  const _GlassExpansionTile({
    required this.title,
    required this.isExpanded,
    required this.onToggle,
    required this.child,
  });

  final String title;
  final bool isExpanded;
  final VoidCallback onToggle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            children: [
              InkWell(
                onTap: onToggle,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      AnimatedRotation(
                        turns: isExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Colors.white38,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (isExpanded)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: child,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
