# リリース手順書（iOS / Android）

> **app_it_pass**（ITパスポート）専用。

---

## クイックリファレンス

| コマンド | 内容 |
| --- | --- |
| `make release-it-pass` | ビルド番号自動インクリメント → iOS + Android ビルド → 両プラットフォームへアップロード |
| `make release-ios-it-pass` | iOS のみ（TestFlight） |
| `make release-android-it-pass` | Android のみ（内部テスト） |
| `make build-ios-it-pass` | iOS ビルドのみ（アップロードなし） |
| `make build-android-it-pass` | Android ビルドのみ（アップロードなし） |
| `make open-ios-it-pass` | ビルド済み IPA フォルダを Finder で開く |
| `make open-android-it-pass` | ビルド済み AAB フォルダを Finder で開く |

---

## 通常リリースフロー（毎回）

### 1. バージョン名を更新

`packages/app_it_pass/pubspec.yaml` のバージョン名（`x.y.z`）を変更する。
ビルド番号（`+N`）は `make` 実行時に自動でインクリメントされる。

```yaml
version: 1.2.0+5  # +N はそのままでよい（make が自動更新）
```

### 2. リリース実行

```bash
make release-it-pass
```

- ビルド番号が自動で `+1` される
- iOS IPA がビルドされ TestFlight へアップロード
- Android AAB がビルドされ Google Play 内部テストへアップロード

### 3. 確認

- **iOS**: App Store Connect → TestFlight タブ（反映まで 5〜30 分）
- **Android**: Google Play Console → 内部テスト → リリース

### 4. リリース後タグ

```bash
git add packages/app_it_pass/pubspec.yaml
git commit -m "chore: bump it_pass to v1.2.0"
git tag it_pass/v1.2.0 -m "Release it_pass v1.2.0"
git push origin it_pass/v1.2.0
```

---

## App Store 審査提出（本番公開時）

1. App Store Connect → 「バージョン情報」→「ビルド」欄の「＋」で TestFlight ビルドを選択
2. 以下を入力・確認:
   - スクリーンショット（iPhone 6.9 inch 必須）
   - プライバシーポリシー URL（**必須**）
   - 広告識別子: **はい**（AdMob 使用）
   - 暗号化: **はい（免除対象）**（Flutter の標準 HTTPS）
3. 「審査へ提出」

---

## 初回セットアップ（初回リリース時のみ）

<details>
<summary>展開して確認</summary>

### 1. 認証情報ファイルの準備

`.env.example` をコピーして `.env` を作成し、各値を埋める:

```bash
cp .env.example .env
```

```bash
# .env
APP_STORE_CONNECT_API_KEY_ID=XXXXXXXXXX
APP_STORE_CONNECT_API_ISSUER_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
PLAY_SERVICE_ACCOUNT_JSON=/absolute/path/to/play-service-account.json
```

### 2. iOS — App Store Connect API Key の取得

1. [App Store Connect](https://appstoreconnect.apple.com) → ユーザーとアクセス → **API キー**
2. 「＋」→ 名前任意 / ロール「App Manager」→ 「生成」
3. **Key ID** と **Issuer ID** を `.env` に記入
4. ダウンロードした `.p8` ファイルをプロジェクトルートの `private_keys/` に配置:
   ```bash
   mkdir -p private_keys
   mv ~/Downloads/AuthKey_XXXXXXXXXX.p8 private_keys/
   ```
   > `private_keys/` は `.gitignore` 済み。`.p8` はダウンロード後に再取得不可のためパスワードマネージャーでも保管推奨。
   >
   > `xcrun altool` は `./private_keys/` を自動的に検索するため、追加設定不要。

5. Apple Developer Program に Bundle ID が登録されているか確認:
   [identifiers/list](https://developer.apple.com/account/resources/identifiers/list) → `jp.tkmr.it-pass`

6. App Store Connect でアプリが作成済みか確認:
   [appstoreconnect.apple.com](https://appstoreconnect.apple.com) → 「マイ App」→ `jp.tkmr.it-pass`

7. Xcode 署名確認（`ios/Runner.xcworkspace` を開く）:
   Signing & Capabilities → `Automatically manage signing` ✓ / Team: `A6MZ7WPLWN`

### 3. Android — Google Play API サービスアカウントの取得

1. [Google Play Console](https://play.google.com/console) → 設定 → **API アクセス**
2. 「Google Cloud プロジェクトにリンク」（既存プロジェクトを選択または新規作成）
3. 「サービスアカウントを作成」→ ロール「**リリースマネージャー**」
4. サービスアカウントの「キー」→「新しいキーを追加」→ **JSON** 形式でダウンロード
5. ダウンロードした JSON ファイルのパスを `.env` の `PLAY_SERVICE_ACCOUNT_JSON` に記入
6. Google Play Console でサービスアカウントに **内部テスト** の権限を付与

> **Gradle タスク名確認**: 初回は `cd android && ./gradlew tasks --all | grep publish` を実行して `publishIt_passReleaseBundle` が存在するか確認。

### 4. Android — 署名キーの確認

`android/key.properties` と `android/it_pass_upload_key.jks` が存在するか確認:

```
android/
  key.properties          # git 管理外（.gitignore 済み）
  it_pass_upload_key.jks  # git 管理外（.gitignore 済み）
```

`key.properties` の内容例:

```properties
storePassword=YOUR_PASSWORD
keyPassword=YOUR_PASSWORD
keyAlias=it_pass
storeFile=../it_pass_upload_key.jks
```

### 5. Play App Signing の有効化（初回アップロード時・必須）

| ステップ | 操作 |
| --- | --- |
| ① AAB アップロード | Play Console → リリース → 内部テスト → 「新しいリリースを作成」→ `.aab` をアップロード |
| ② 署名の確認 | 「App Signing by Google Play」の確認ダイアログ → **「続行」** |
| ③ 完了 | 以降、同じ `it_pass_upload_key.jks` でビルドした AAB をアップロードし続ける |

> **重要**: Play App Signing を有効化すると変更不可。Google がアプリ署名キーを管理し、アップロードキーは認証にのみ使う。

</details>

---

## アプリ設定値

| | it_pass（ITパスポート） |
| --- | --- |
| フレーバー | `it_pass` |
| エントリポイント | `lib/main_it_pass.dart` |
| iOS Bundle ID | `jp.tkmr.it-pass` |
| Android Application ID | `jp.tkmr.it_pass` |
| iOS Development Team | `A6MZ7WPLWN` |
| Android 署名キー | `android/it_pass_upload_key.jks` |

---

## トラブルシューティング

| エラー | 原因 | 対処 |
| --- | --- | --- |
| `does not define custom schemes` | `packages/` 内でビルドを実行している | リポジトリルートに移動して再実行 |
| `Failed Registering Bundle Identifier` | Team が異なる Apple ID でサインインしている | Xcode Settings → Accounts で Team `A6MZ7WPLWN` の Apple ID を確認 |
| `Invalid Bundle`（アップロードエラー） | ビルド番号が重複している | `pubspec.yaml` のビルド番号をインクリメントして再ビルド |
| `keystore file not found` | `android/key.properties` または `.jks` が欠落 | `key.properties` の `storeFile` パスを確認 |
| `No matching client found for package name` | `google-services.json` にパッケージ名がない | `android/app/src/it_pass/google-services.json` が存在するか確認 |
| `No service account credentials` | `PLAY_SERVICE_ACCOUNT_JSON` が未設定 | `.env` に絶対パスで記入して再実行 |
| `altool: command not found` | Xcode Command Line Tools が未インストール | `xcode-select --install` を実行 |
| `publishIt_passReleaseBundle` タスクが存在しない | Gradle sync 未完了 | Android Studio で Sync Project を実行、またはタスク名を `./gradlew tasks --all \| grep publish` で確認 |

---

*最終更新: 2026-05-31*
