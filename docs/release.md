# リリース手順書（iOS / Android）

> **anki_games モノレポ** 全アプリ共通。

---

## アプリ別設定値


|                      | it_pass（ITパスポート）                 | blockPuzzle（Block.）          |
| -------------------- | -------------------------------- | ---------------------------- |
| フレーバー                | `it_pass`                        | `blockPuzzle`                |
| エントリポイント             | `lib/main_it_pass.dart`          | `lib/main_block_puzzle.dart` |
| iOS Bundle ID        | `jp.tkmr.it-pass`                | `jp.block.puzzle`            |
|                      | Android Application ID           | `jp.tkmr.it_pass`            |
| iOS Development Team | `A6MZ7WPLWN`                     | `A6MZ7WPLWN`                 |
| Android 署名キー         | `android/it_pass_upload_key.jks` | —                            |


---

## 通常リリースフロー（毎回）

### 1. バージョン更新

`packages/<アプリ>/pubspec.yaml` を編集:

```yaml
version: 1.2.0+5   # バージョン名+ビルド番号（ビルド番号は必ずインクリメント）
```

### 2. ビルド前チェック

```bash
# リポジトリルートで実行
flutter pub get
flutter analyze        # エラー 0 件を確認
```

### 3-A. iOS ビルド → TestFlight

```bash
# ビルド（リポジトリルートで実行）
flutter build ipa --release --flavor it_pass -t lib/main_it_pass.dart

# Finder でフォルダを開く
open build/ios/ipa
```

`ITパスポート.ipa` を **Transporter**（[App Store](https://apps.apple.com/us/app/transporter/id1450874784)）にドラッグ＆ドロップ → 「配信」。

> App Store Connect に反映まで 5〜30 分。その後 TestFlight タブでビルドを確認。

### 3-B. Android ビルド → Google Play

```bash
# ビルド（リポジトリルートで実行）
flutter build appbundle --release --flavor it_pass -t lib/main_it_pass.dart

# Finder でフォルダを開く
open build/app/outputs/bundle/
```

出力: `build/app/outputs/bundle/it_passRelease/app-it_pass-release.aab`

[Google Play Console](https://play.google.com/console) → 対象アプリ → リリース → トラック選択 → `.aab` をアップロード。

> **初回アップロード時**: 「App Signing by Google Play」の確認画面が表示される。「続行」で有効化（推奨・変更不可）。詳細は [初回セットアップ > Play App Signing](#play-app-signing) を参照。

---

## App Store 審査提出（本番公開時）

1. App Store Connect → 「バージョン情報」→「ビルド」欄の「＋」で TestFlight ビルドを選択
2. 以下を入力・確認:
  - スクリーンショット（iPhone 6.9 inch 必須）
  - プライバシーポリシー URL（**必須**）
  - 広告識別子: **はい**（AdMob 使用 / it_pass のみ）
  - 暗号化: **はい（免除対象）**（Flutter の標準 HTTPS）
3. 「審査へ提出」

---

## リリース後

```bash
git tag it_pass/v1.2.0 -m "Release it_pass v1.2.0"
git push origin it_pass/v1.2.0
```

---

## 初回セットアップ（初回リリース時のみ）

展開して確認

### iOS

1. **Apple Developer Program** に加入（年間 $99 / ¥12,980）
2. **Developer Portal** で Bundle ID を作成
  [identifiers/list](https://developer.apple.com/account/resources/identifiers/list) → 「＋」→ App IDs → `jp.tkmr.it-pass`
3. **App Store Connect** でアプリを作成
  [appstoreconnect.apple.com](https://appstoreconnect.apple.com) → 「マイ App」→「＋」→「新規 App」  
   Bundle ID: `jp.tkmr.it-pass` / 言語: 日本語
4. **Xcode 署名確認**（`ios/Runner.xcworkspace` を開く）
  Signing & Capabilities → `Automatically manage signing` ✓ / Team: `A6MZ7WPLWN`

> **注意**: `packages/app_it_pass/ios/` ではなくルートの `ios/Runner.xcworkspace` を開くこと。

### Android

1. **Google Play Console** でアプリを作成
  [play.google.com/console](https://play.google.com/console) → 「アプリを作成」
2. **署名キー**（`android/key.properties` + `android/it_pass_upload_key.jks`）が存在するか確認
  ※ `.gitignore` で除外済み。紛失しないようパスワードマネージャーで管理。
3. **Play App Signing の有効化（初回アップロード時・必須）**
  AAB を初めてアップロードすると Google Play が自動で署名設定画面を表示する。

  | ステップ          | 操作                                                         |
  | ------------- | ---------------------------------------------------------- |
  | ① AAB アップロード  | Play Console → リリース → 内部テスト → 「新しいリリースを作成」→ `.aab` をアップロード |
  | ② 署名の確認       | 「App Signing by Google Play」の確認ダイアログ → **「続行」**            |
  | ③ アップロードキーの登録 | Google が自動で現在の `.aab` の署名をアップロードキーとして登録する                  |
  | ④ 完了          | 以降、同じ `it_pass_upload_key.jks` でビルドした AAB をアップロードし続ける      |

  > **重要**: Play App Signing を有効化すると変更不可。Google がアプリ署名キーを管理し、アップロードキーは認証にのみ使う。アップロードキーを紛失してもGoogle側で再設定できる。

### 外部サービス

Firebase / AdMob / RevenueCat の初回セットアップ手順は **[docs/service_setup.md](service_setup.md)** を参照。

---

## トラブルシューティング


| エラー                                         | 原因                                                  | 対処                                                                     |
| ------------------------------------------- | --------------------------------------------------- | ---------------------------------------------------------------------- |
| `does not define custom schemes`            | `packages/` 内でビルドを実行している                            | リポジトリルートに移動して再実行                                                       |
| `Failed Registering Bundle Identifier`      | Team が異なる Apple ID でサインインしている                       | Xcode Settings → Accounts で Team `A6MZ7WPLWN` の Apple ID を確認           |
| `Invalid Bundle` (アップロードエラー)                | ビルド番号が重複している                                        | `pubspec.yaml` のビルド番号をインクリメントして再ビルド                                    |
| `keystore file not found`                   | `android/key.properties` または `.jks` が欠落、またはパスが誤っている | `key.properties` の `storeFile` が `../it_pass_upload_key.jks` になっているか確認 |
| `No matching client found for package name` | `google-services.json` にパッケージ名がない                   | `android/app/src/it_pass/google-services.json` が存在するか確認                |
| AdMob 審査却下                                  | `GADApplicationIdentifier` がテスト ID のまま              | 本番 ID に差し替えて再ビルド                                                       |


---

*最終更新: 2026-05-08*