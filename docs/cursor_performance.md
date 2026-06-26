# Cursor メモリ / パフォーマンス対策

Cursor のメモリ消費・CPU 負荷・Agent コンテキスト肥大を抑えるための設定とガイド。

## このリポジトリで適用済みの対策

| ファイル | 内容 | 効果 |
|---|---|---|
| `.cursorignore` | build 成果物・生成コード・大容量データ・機密を除外 | インデックス/Agent コンテキストの軽量化 |
| `.vscode/settings.json` | `files.watcherExclude` / `search.exclude` / `files.exclude` / `dart.analysisExcludedFolders` | ファイル監視・検索・解析の負荷削減（RAM 削減の主因） |
| `.gitignore` | `debug-info/` を追加 | 生成 symbols の混入防止 |
| 削除 | `firebase-debug.log` / `firestore-debug.log` / `debug-info/` | 再生成可能なディスククリーン |

> `.cursorignore` を更新したら Cursor Settings > Indexing & Docs で **Resync Index** を実行すると即時反映される。

## ユーザー側で手動実施を推奨（全体設定・このリポジトリ外）

最新調査（Cursor 公式 Docs / フォーラム）で、メモリ肥大の最大要因は **拡張機能（特に複数 AI 拡張の併用）** とされている。

1. **不要拡張の無効化（最優先）**
   - `cursor --disable-extensions` で起動し、改善するか確認 → 原因なら拡張を1つずつ有効化して特定。
   - Cursor 内蔵 AI と別の AI 拡張（Claude Code / Cline / Copilot 等）を併用しない。1つに絞る。
   - 使っていない言語拡張（Java / C++ / Python 等）を無効化。
   - Settings > Application > Experimental > Extension Monitor で重い拡張を特定。

2. **完全終了は `Cmd + Q`**
   - ウィンドウを閉じるだけでは extension-host が残りメモリリークの原因になる。終了は必ず `Cmd + Q`。

3. **ハードウェアアクセラレーション無効化（描画が重い場合）**
   - コマンドパレット > `Preferences: Configure Runtime Arguments` で `argv.json` を開き、
     `"disable-hardware-acceleration": true` を有効化 → 再起動。

4. **チャットログ肥大の回避**
   - 長くなった会話は要約してから新規チャットに切り替える（このリポジトリの `agent-operating.mdc` 方針と同じ）。

5. **同時に開くウィンドウ数を最小化**
   - 複数ワークスペースの同時起動はメモリを大きく消費する。
