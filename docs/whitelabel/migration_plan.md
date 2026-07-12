# core 移行計画書

`app_it_pass` の全 feature を `core` へ物理移動し、  
`app_it_pass` と `app_fe` を「ブランド設定のみの薄いラッパー」にする計画。

**目標完了後の状態**: `app_fe` が `app_it_pass` に依存せず、`core` のみに依存する。  
**推定工数**: エンジニア 1 名 × 3〜5 日（集中作業）

---

## 依存グラフ（トポロジカル順）

```
Tier 0 (依存なし):
  auth(1)  backup(3)  review(1)  learning(7)  notification(5)
  note(17)  streak(9)  purchase(6)

Tier 1 (Tier 0 のみ依存):
  filter(17) → purchase
  profile(11) → auth
  report(9)   → learning, purchase, streak

Tier 2 (Tier 1 依存):
  onboarding(15) → learning, notification, quiz(※循環注意)
  settings(6)    → auth, backup, notification, onboarding, profile, purchase

Tier 3 (全依存):
  quiz(22) → filter, learning, notification, onboarding, report
```

移動は **Tier 0 → 1 → 2 → 3** の順に行う。

---

## 対象ファイル一覧（手動 import 更新が必要）

### Tier 0: 独立 feature

#### `auth` (1 file)
```
features/auth/providers/auth_user_provider.dart
```
移動先: `core/lib/features/auth/`

#### `backup` (3 files)
```
features/backup/providers/auto_restore_message_provider.dart
features/backup/service/backup_service.dart
features/backup/view_model/backup_view_model.dart
```
移動先: `core/lib/features/backup/`

#### `review` (1 file)
```
features/review/repository/review_repository.dart
```
移動先: `core/lib/features/review/`

#### `learning` (7 files)
```
features/learning/model/learning_level.dart
features/learning/model/question_learning_stats.dart
features/learning/providers/it_pass_learning_stats_provider.dart  ← 名前に注意
features/learning/repository/local_learning_history_repository.dart
features/learning/repository/firestore_learning_history_repository.dart
features/learning/repository/learning_history_repository.dart (interface?)
features/learning/providers/learning_history_provider.dart
```
移動先: `core/lib/features/learning/`

> ⚠️ `it_pass_learning_stats_provider.dart` の名前はリネームが必要か検討

#### `notification` (5 files)
```
features/notification/model/notification_settings.dart
features/notification/model/notification_time_slot.dart
features/notification/repository/notification_repository.dart
features/notification/service/notification_service.dart
features/notification/view_model/notification_view_model.dart
```
移動先: `core/lib/features/notification/`

#### `note` (17 files)
```
features/note/model/*.dart
features/note/repository/local_bookmark_repository.dart
features/note/repository/firestore_bookmark_repository.dart
features/note/repository/firestore_quiz_history_repository.dart
features/note/providers/bookmark_provider.dart
features/note/view/note_sheet.dart
features/note/view/widgets/note_detail_page.dart
features/note/view/widgets/note_list_content.dart
features/note/view_model/note_sheet_view_model.dart
```
移動先: `core/lib/features/note/`

#### `streak` (9 files)
```
features/streak/model/*.dart
features/streak/repository/local_streak_repository.dart
features/streak/repository/firestore_streak_repository.dart
features/streak/view/streak_banner.dart
features/streak/view/widgets/*.dart
features/streak/view_model/*.dart
```
移動先: `core/lib/features/streak/`

#### `purchase` (6 files)
```
features/purchase/view/paywall_sheet.dart
features/purchase/view/widgets/cta_section.dart
features/purchase/view/widgets/feature_list.dart
features/purchase/view/widgets/header.dart
features/purchase/view/widgets/plan_selector.dart
```
移動先: `core/lib/features/purchase/view/`  
（model/service/view_model は既に `core` にある）

---

### Tier 1: purchase・auth に依存する feature

#### `filter` (17 files)
```
features/filter/model/quiz_filter.dart
features/filter/model/quiz_order_mode.dart
features/filter/model/quiz_filter.freezed.dart (再生成)
features/filter/model/quiz_filter.g.dart (再生成)
features/filter/repository/filter_repository.dart
features/filter/view/filter_sheet.dart
features/filter/view/widgets/apply_button.dart
features/filter/view/widgets/era_chip.dart
features/filter/view/widgets/era_section.dart
features/filter/view/widgets/glass_expansion_tile.dart
features/filter/view/widgets/major_section.dart
features/filter/view/widgets/system_section.dart
features/filter/view_model/filter_view_model.dart
features/filter/view_model/filter_view_model.freezed.dart (再生成)
features/filter/view_model/filter_view_model.g.dart (再生成)
```
移動先: `core/lib/features/filter/`

#### `profile` (11 files)
```
features/profile/router/profile_modal_router.dart
features/profile/view/profile_page.dart
features/profile/view/widgets/*.dart
features/profile/view_model/profile_view_model.dart
features/profile/view_model/profile_view_model.g.dart (再生成)
```
移動先: `core/lib/features/profile/`

#### `report` (9 files)
```
features/report/view/report_sheet.dart
features/report/view/widgets/report_paywall_banner.dart
features/report/view/widgets/report_progress_section.dart
features/report/view_model/progress_dashboard_provider.dart
features/report/view_model/report_stats_provider.dart
features/report/view_model/*.g.dart (再生成)
```
移動先: `core/lib/features/report/`

---

### Tier 2: Tier 1 に依存する feature

#### `onboarding` (15 files)
```
features/onboarding/model/onboarding_plan.dart
features/onboarding/model/onboarding_question.dart
features/onboarding/repository/onboarding_repository.dart
features/onboarding/view/widgets/onboarding_category_page.dart
features/onboarding/view/widgets/onboarding_done_page.dart
features/onboarding/view/widgets/onboarding_feature_page.dart
features/onboarding/view/widgets/onboarding_intro_page.dart
features/onboarding/view/widgets/onboarding_notification_page.dart
features/onboarding/view/widgets/onboarding_page_anim.dart
features/onboarding/view/widgets/onboarding_premium_page.dart
features/onboarding/view/widgets/onboarding_quiz_page.dart
features/onboarding/view/widgets/onboarding_review_page.dart
features/onboarding/view/widgets/onboarding_tracking_page.dart
features/onboarding/view_model/onboarding_ui_notifier.dart
features/onboarding/view_model/onboarding_view_model.dart
```
移動先: `core/lib/features/onboarding/`

#### `settings` (6 files)
```
features/settings/view/settings_sheet.dart
features/settings/view/widgets/*.dart
features/settings/view_model/theme_mode_view_model.dart
features/settings/view_model/*.g.dart (再生成)
```
移動先: `core/lib/features/settings/`

---

### Tier 3: 全依存

#### `quiz` (22 files)
```
features/quiz/model/exam_meta.dart         (re-export → 削除可)
features/quiz/model/question.dart          (re-export → 削除可)
features/quiz/model/quiz_session.dart
features/quiz/repository/quiz_repository.dart
features/quiz/repository/quiz_question_ordering.dart
features/quiz/repository/quiz_resume_repository.dart
features/quiz/repository/motivation_last_shown_repository.dart
features/quiz/view_model/quiz_view_model.dart
features/quiz/view_model/quiz_view_model.freezed.dart (再生成)
features/quiz/view_model/quiz_view_model.g.dart (再生成)
features/quiz/view/quiz_screen.dart
features/quiz/view/quiz_paging.dart
features/quiz/view/quiz_shell_widgets.dart
features/quiz/view/modals/result_detail_sheet.dart
features/quiz/view/widgets/choice_button.dart
features/quiz/view/widgets/finished_result_page.dart
features/quiz/view/widgets/footer.dart
features/quiz/view/widgets/header.dart
features/quiz/view/widgets/motivation_start_card.dart
features/quiz/view/widgets/question_card.dart
features/quiz/view/widgets/quiz_network_image.dart
features/quiz/view/widgets/quiz_page_item.dart
features/quiz/view/widgets/quiz_skeleton.dart
features/quiz/view/widgets/session_end_page.dart
```
移動先: `core/lib/features/exam_quiz/` (既存ディレクトリに統合)

---

### コンポーネント (8 files)

`app_it_pass/lib/components/` → `core/lib/components/`

```
components/admob_glass.dart         ← ItPassColorScheme 依存を BrandConfig 化
components/app_bottom_sheet.dart
components/buttons.dart             ← ItPassColorScheme 依存を BrandConfig 化
components/category_filter_section.dart
components/checkmark_painter.dart
components/explanation_card.dart
components/glass_widget.dart        ← ItPassColorScheme 依存を BrandConfig 化
```

> ⚠️ `glass_widget.dart`, `buttons.dart`, `admob_glass.dart` は `ItPassColorScheme` を直接参照。  
> 移動時に `Theme.of(context).extension<ItPassColorScheme>()` 経由に変更が必要。

---

### config (4 dirs)

```
config/lifecycle/ → core/lib/config/lifecycle/
config/router/    → core/lib/config/router/
config/quotes/    → core/lib/config/quotes/
```

---

## 移動手順（1 Tier ずつ実施）

### Phase 1: Tier 0（独立 feature）
```bash
# 各 feature ごとに:
# 1. cp -r packages/app_it_pass/lib/features/XXX packages/core/lib/features/XXX
# 2. find packages/core/lib/features/XXX -name "*.dart" | xargs sed -i \
#      "s|package:app_it_pass/features/XXX|package:core/features/XXX|g"
# 3. flutter analyze
```

### Phase 2: Tier 1（filter/profile/report）
Phase 1 完了後に実施。同じ手順。

### Phase 3: Tier 2（onboarding/settings）
Phase 2 完了後に実施。

### Phase 4: Tier 3 + components（quiz + components）
Phase 3 完了後に実施。quiz_screen の ItPassColorScheme 依存を除去。

### Phase 5: app_it_pass を薄いラッパーに
- 各 feature に re-export ファイルを作成（後方互換）または削除
- pubspec.yaml から不要な依存を削除
- app_fe の pubspec.yaml から `app_it_pass:` を削除

---

## ブランド固有 Widget の汎用化

`glass_widget.dart` の例:
```dart
// Before (app_it_pass固有)
final c = context.appColors; // ItPassColorScheme
gradient = LinearGradient(colors: [c.bgStart, c.bgEnd]);

// After (汎用化)
final theme = Theme.of(context);
final colors = theme.extension<ItPassColorScheme>(); // nullableで取得
gradient = colors != null
    ? LinearGradient(colors: [colors.bgStart, colors.bgEnd])
    : LinearGradient(colors: [theme.colorScheme.surface, theme.colorScheme.surfaceVariant]);
```

---

## チェックリスト

- [x] Phase 1: auth, backup, review, learning, notification, note(model/repository/providers), streak(model/repository/view_model), daily_study_log を core 移動  
  （purchase/view・streak/view・note/view/view_model は app_it_pass components に依存するため Phase 4 で移動）
- [x] Phase 1 後: `flutter analyze` 0件
- [x] Phase 2: filter(model/repository), profile(model/repository/view_model), report(model/report_stats_provider) を core 移動  
  （filter/view_model・filter/view・profile/view・profile/router・report/view_model(progress_dashboard)・report/view は quiz/components 依存で Phase 4）
- [x] Phase 2 後: `flutter analyze` 0件
- [x] Phase 3: onboarding(model/repository/view_model), settings(view_model/theme_mode) を core 移動  
  （onboarding/view/widgets・settings/view は app_it_pass components に依存するため Phase 4 で移動）
- [x] Phase 3 後: `flutter analyze` 0件
- [x] Phase 4: quiz + components + 全 view を core 移動（ItPassColorScheme→core、components→core/components/、lifecycle/quotes/router→core/config/、quiz model/repo/vm + 全 view 一括移動）  
  pubspec に追加: `fl_chart`, `google_sign_in`, `sign_in_with_apple`, `app_tracking_transparency`, `share_plus`, `package_info_plus`, `flutter_cache_manager`
- [x] Phase 4 後: `flutter analyze` 0件（core・app_it_pass 両方）
- [x] Phase 5: app_it_pass を薄いラッパー化（config/brand, config/env, config/exam, main.dart の 8 ファイルのみ）
- [x] app_fe の pubspec から `app_it_pass:` 依存を削除（import も 0件確認済み）
- [x] `flutter analyze` 全パッケージ 0件（core・app_it_pass・app_fe）
- [ ] app_fe と app_it_pass を実機で動作確認

---

## 注意事項

1. **`.g.dart` / `.freezed.dart`**: 移動後は必ず `dart run build_runner build --delete-conflicting-outputs` を実行
2. **`ItPassColorScheme` 参照**: `context.appColors` を `Theme.of(context).extension<ItPassColorScheme>()` に変更
3. **アセットパス**: `packages/app_it_pass/assets/` は移動後 `packages/core/assets/` に変更が必要な箇所がある
4. **Firebase 依存**: `firestore_*_repository.dart` は `cloud_firestore` が必要（core の pubspec に追加済み）
