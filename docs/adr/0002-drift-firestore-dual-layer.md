# ADR-0002: ローカル DB（drift/SQLite）+ Firestore の二層同期を採用する

**Status:** Accepted  
**Date:** 2026-04-01

## Context

学習記録（正答・誤答・最終解答日）はアプリのコア価値であり、以下の制約を同時に満たす必要がある。

1. **オフライン時も全機能動作する**（地下鉄・機内での利用を想定）
2. **複数端末で記録を共有できる**（スマホ→タブレットへの移行需要）
3. **Firebase の読み取りコストを最小化する**（個人運用でコスト管理が重要）

選択肢: ① Firestore のみ ② SharedPreferences のみ ③ drift（SQLite）+ Firestore 二層

## Decision

**drift（SQLite）をプライマリストアとし、Firestore はバックアップ兼同期先として非同期プッシュする。**

読み取りは常にローカル（drift / SharedPreferences）から行う。Firestore への書き込みはユーザーがログイン済みの場合のみ、回答処理と非同期に実行する。

## Rationale

### Firestore のみを選ばなかった理由

- ネットワーク不通時に読み書きがブロックされる（Firestore のオフラインキャッシュは制限が多く信頼性が低い）。
- 起動のたびにリモート読み取りが発生し、学習記録が増えるほど Firestore 課金が増加する。

### SharedPreferences のみを選ばなかった理由

- 問題数が増えると JSON 全体の読み書きが遅くなる（SQLite のインデックスが使えない）。
- 端末変更・機種変時に記録が完全消失する。

### drift + Firestore の二層を選んだ理由

- 全読み書きがローカルに閉じるためレスポンスが速く、オフラインでも動作する。
- Firestore は「ログイン成功後の同期バックアップ」に限定することで読み取り課金がほぼゼロ。
- drift のスキーマ変更はマイグレーション機能で安全に対応できる。

### マージ戦略

端末 A と端末 B の記録を同期する際、「新しいほうで上書き」を採用すると片方の回答が消える問題がある。本アプリでは `correctCount + wrongCount の加算マージ` を採用し、どちらの記録も失わない。

## Consequences

- **良い点**: ネットワーク状態に依存しない高速 UI。Firestore 課金が最小。
- **悪い点**: ローカルとリモートの整合性保証が複雑になる。`SyncedLearningHistoryRepository` がマージロジックを持ち、テストが重要。
- **悪い点**: drift スキーマの変更にはマイグレーションが必要（変更コストあり）。

## Alternatives Considered

- **Realm（MongoDB）**: Firestore との統合が弱く、オフライン同期は優秀だが Firebase Authとの組み合わせに追加の実装コストがかかる。
- **Hive**: 軽量だが型安全なクエリが書けない。問題数が増えたときのフィルタリング性能が不安。
- **iCloud/Android Backup**: プラットフォーム固有で iOS/Android 共通化が困難。
