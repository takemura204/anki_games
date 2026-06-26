# クイズデータ管理ガイド

アプリビルドとクイズデータを切り離し、Firebase Hosting（CDN）で配信する仕組みの解説と運用手順。

---

## 全体構成

```
anki_games/
├── packages/quiz_data/       ← クイズデータ（JSONファイル）とデプロイスクリプト
│   ├── quiz/
│   │   ├── it_pass/          ← ITパスポート試験（30ファイル）
│   │   ├── fe/               ← 基本情報技術者試験（41ファイル）
│   │   └── fp3/              ← FP3級（50ファイル）
│   ├── scripts/
│   │   └── generate_manifest.dart  ← manifest.json 生成スクリプト
│   └── manifest.json         ← 生成物（各ファイルのSHA256ハッシュ付き）
│
└── packages/core/lib/features/exam_quiz/quiz/
    ├── datasource/
    │   ├── quiz_local_datasource.dart   ← 端末内キャッシュの読み書き
    │   └── quiz_remote_datasource.dart  ← Firebase Hosting からHTTPで取得
    ├── model/
    │   └── quiz_manifest.dart           ← マニフェストのデータモデル
    ├── sync/
    │   └── quiz_sync_notifier.dart      ← バックグラウンド差分同期
    └── repository/
        └── quiz_repository.dart         ← 端末キャッシュから問題を読み込む
```

---

## データフロー

### アプリ起動時

```
起動
 │
 ├─ 端末キャッシュあり ──→ 即クイズ利用可
 │                         ↓（バックグラウンド）
 │                         manifest.json を取得
 │                         ローカルSHA256と比較
 │                         差分ファイルのみダウンロード → キャッシュ更新
 │
 └─ 端末キャッシュなし ──→ manifest.json を取得
                           全ファイルをダウンロード
                           ↓
                           クイズ利用可
                          （ネットワークなし → エラー画面 + 再試行）
```

### データ更新時（開発者）

```
JSONファイルを編集
 ↓
make deploy-quiz-data
 ├─ generate_manifest.dart でSHA256を再計算
 ├─ manifest.json を更新
 └─ firebase deploy --only hosting:quiz-data
      ↓
      CDN に反映（~1分）
      ↓
      ユーザーの次回起動時に自動で差分更新
```

---

## クイズデータの更新手順

### 既存の試験回を更新する

```bash
# 1. packages/quiz_data/quiz/{試験種別}/ の JSON を編集・差し替え
#    例: packages/quiz_data/quiz/it_pass/it_pass_r07.json を更新

# 2. デプロイ（manifest 再生成 + Firebase Hosting へ反映）
make deploy-quiz-data
```

### 新しい試験回を追加する

```bash
# 1. JSONファイルを配置
cp /path/to/new_exam.json packages/quiz_data/quiz/it_pass/

# 2. ExamConfig に追加（アプリ側の設定ファイル）
#    packages/app_it_pass/lib/config/exam/it_pass_exam_config.dart
#    ExamMeta(eraId: 'r08', displayName: '令和8年', assetPath: '.../it_pass_r08.json', ...)

# 3. デプロイ
make deploy-quiz-data

# 4. アプリの新バージョンをリリース（ExamConfig の変更を含むため）
```

> **ポイント**: JSONファイルの中身だけの更新はアプリリリース不要。試験回の追加・削除は ExamConfig の変更を伴うためアプリリリースが必要。

---

## 新しい試験種別（アプリ）を追加する

### 1. データを配置する

```bash
mkdir packages/quiz_data/quiz/new_exam
cp /path/to/data/*.json packages/quiz_data/quiz/new_exam/
```

### 2. アプリパッケージを作成する

`docs/whitelabel/add_new_app.md` を参照。`ExamConfig` で `examTypeKey` を設定する。

```dart
// packages/app_new_exam/lib/config/new_exam_config.dart
class NewExamConfig extends ExamConfig {
  @override
  String get examTypeKey => 'new_exam';  // quiz_data/quiz/ 内のフォルダ名と一致させる
  // ...
}
```

### 3. デプロイ

```bash
make deploy-quiz-data
```

---

## manifest.json の構造

```json
{
  "schemaVersion": 1,
  "generatedAt": "2026-06-18T00:00:00Z",
  "exams": {
    "it_pass": {
      "version": "2026-06-18",
      "files": [
        {
          "name": "it_pass_r07.json",
          "sha256": "abc123...",
          "sizeBytes": 245760,
          "path": "quiz/it_pass/it_pass_r07.json"
        }
      ]
    },
    "fe": { ... },
    "fp3": { ... }
  }
}
```

- `version`: デプロイ日付（端末のキャッシュバージョンと比較）
- `sha256`: ファイルの整合性チェックに使用（差分検出も兼ねる）
- `path`: CDN上の相対パス

---

## Firebase Hosting の設定

| 項目 | 値 |
|---|---|
| ターゲット名 | `quiz-data` |
| サイト URL | `https://quiz-data-anki-quiz-dev.web.app` |
| `manifest.json` のキャッシュ | `no-cache`（常に最新を取得） |
| `quiz/**/*.json` のキャッシュ | `immutable, max-age=1年`（SHA256が変わらない限り再取得しない） |
| 無料枠 | ストレージ 10GB / 転送 10GB/月 |

---

## コスト最適化の仕組み

1. **manifest.json は no-cache**: バージョン確認だけは毎回行う（数百バイト）
2. **JSONファイルは immutable 1年**: 同じ SHA256 のファイルはブラウザ/CDNキャッシュから提供
3. **差分のみダウンロード**: SHA256 比較で変更されたファイルのみ転送
4. **端末キャッシュ**: 一度ダウンロードすれば以降はオフラインでも動作

通常運用では manifest.json（~5KB）の取得のみ発生し、ほぼコスト無しで動作します。

---

## トラブルシューティング

### アプリ起動時に「ネットワーク接続を確認してください」が表示される

- 初回インストール後にネットワークなし、または Firebase Hosting への接続失敗
- 端末のネットワーク設定を確認し、再試行ボタンをタップ

### データが更新されない（古いデータが表示される）

```bash
# manifest.json が更新されているか確認
curl https://quiz-data-anki-quiz-dev.web.app/manifest.json | python3 -m json.tool

# 再デプロイ
make deploy-quiz-data
```

### デプロイに失敗する

```bash
# Firebase CLI のログインを確認
npx firebase-tools@latest login

# プロジェクトを確認
npx firebase-tools@latest projects:list
```
