# Firebase Emulator セットアップ手順

## 前提条件（確認済み）

| ツール | バージョン | 状態 |
|---|---|---|
| Node.js | v22.22.0 | ✅ |
| Firebase CLI | 15.17.0 | ✅ |
| Java | OpenJDK 21 | ✅ |
| Firebase プロジェクト | anki-quiz-dev | ✅ |

---

## 1. エミュレータの起動

```bash
# プロジェクトルートで実行
cd /path/to/anki_games
npx -y firebase-tools@latest emulators:start --only firestore,auth
```

起動後、以下の URL でデータを確認できる：

- **Emulator UI**: http://localhost:4000
- **Firestore**: http://localhost:4000/firestore
- **Auth**: http://localhost:4000/auth

---

## 2. Flutter をエミュレータに向けて起動

```bash
# --dart-define=USE_EMULATOR=true を付けて実行
flutter run -t lib/main_it_pass.dart --flavor it_pass --dart-define=USE_EMULATOR=true
```

> `USE_EMULATOR=true` を付けない限り、本番 Firestore には一切影響しない。

---

## 3. 検証手順

### Firestore の書き込み確認

1. エミュレータを起動（手順1）
2. Flutter アプリをエミュレータモードで起動（手順2）
3. アプリ内でアカウント連携（Google/Apple）
4. 問題に回答
5. http://localhost:4000/firestore で `users/{uid}/learningHistory` を確認

### Auth の確認

- http://localhost:4000/auth でサインインユーザーの一覧・uid を確認できる

---

## 4. エミュレータのデータをリセット

```bash
# エミュレータ停止時にデータは自動リセット（永続化なし）
# 永続化したい場合:
npx -y firebase-tools@latest emulators:start --only firestore,auth --import=./emulator-data --export-on-exit
```

---

## 5. よくあるエラー

| エラー | 原因 | 解決策 |
|---|---|---|
| `EADDRINUSE` | ポートが使用中 | `lsof -i :8080` でプロセスを確認して kill |
| `Failed to connect` | エミュレータ未起動 | 手順1を先に実行 |
| iOS Simulator で接続できない | localhost が `127.0.0.1` に解決されない | Flutter コード内のホストを `127.0.0.1` に変更 |

---

## 6. firebase.json の現在の設定

```json
{
  "emulators": {
    "firestore": { "port": 8080 },
    "auth":      { "port": 9099 },
    "ui":        { "enabled": true, "port": 4000 }
  },
  "firestore": {
    "rules": "firestore.rules"
  }
}
```

---

## 参考コマンド

```bash
# ログイン確認
npx -y firebase-tools@latest login

# 現在のプロジェクト確認
npx -y firebase-tools@latest use

# Firestore ルールのみデプロイ
npx -y firebase-tools@latest deploy --only firestore:rules

# エミュレータ + UI 起動（バックグラウンド）
npx -y firebase-tools@latest emulators:start --only firestore,auth &
```
