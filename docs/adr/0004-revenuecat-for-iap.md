# ADR-0004: サブスクリプション課金管理に RevenueCat を採用する

**Status:** Accepted  
**Date:** 2026-04-01

## Context

iOS/Android 両プラットフォームでサブスクリプション課金を提供するにあたり、以下の要件を満たす必要があった。

1. iOS StoreKit / Android Billing Library の差異を吸収したい
2. サーバーサイドのレシート検証を自前で持ちたくない（個人開発でバックエンド運用コストゼロが前提）
3. MRR・チャーン・トライアル転換率などのサブスクリプション指標を即座に確認したい
4. A/Bテスト（paywall の文言・価格変更）を素早く回したい

## Decision

**`purchases_flutter`（RevenueCat）を採用し、課金ロジックを RevenueCat SDK に委譲する。**

## Rationale

### 自前実装を選ばなかった理由

iOS のレシート検証を自前でサーバー実装すると：
- Apple の `/verifyReceipt` API の仕様変更への追従が必要
- サブスクリプション更新・払い戻し・グレースピリオドの各ステートを Webhook で受け取り処理するバックエンドが必要
- Android の Purchase Token 管理が別途必要

個人開発でサーバーを持たずにこれを全自前で実装・維持するコストは非現実的。

### 他の SDK（Adapty / Superwall）との比較

| 観点 | Adapty | Superwall | **RevenueCat（採用）** |
|---|---|---|---|
| Flutter サポート | ○ | △（Web主体） | ◎（公式 SDK） |
| 無料枠 | MTU ベース | 限定的 | **$2,500/月 以下無料** |
| ダッシュボード | ○ | ◎（paywall特化） | ◎（総合） |
| 実績・ドキュメント | 中 | 中 | **最大・豊富** |

RevenueCat は Flutter エコシステムでの採用実績が最多で、`purchases_flutter` のメンテが活発。個人開発の収益規模では無料枠に収まる。

### RevenueCat を選んだ理由

- **ゼロサーバー**: レシート検証・Webhook 処理を RevenueCat が代行。バックエンドが不要。
- **クロスプラットフォーム統一**: `Purchases.getOfferings()` / `Purchases.purchasePackage()` の2行で iOS・Android 両対応が完結。
- **Entitlement 管理**: 「プレミアムかどうか」の判定を `CustomerInfo.entitlements.active` の1行で確認できる。アプリ側でストア固有のレシート解析が不要。
- **ダッシュボード**: MRR・LTV・チャーン率・トライアル転換率をリアルタイム確認。ビジネスの健全性を数値で把握できる。

## Consequences

- **良い点**: バックエンドゼロでサブスクリプションの全ライフサイクルを管理できる。課金指標の可視化がすぐできる。
- **良い点**: Entitlement が RevenueCat 側で管理されるため、アプリ側のコードは `isActive` のチェックのみ。
- **悪い点**: RevenueCat がサービス停止・価格変更した場合の依存リスクがある。ただし SDK は OSS であり、APIの呼び出し部分は `PurchaseRepository` 抽象に隠蔽しているため移行コストは限定的。
- **悪い点**: 収益の一部（$2,500/月超過後）が RevenueCat への支払いになる。現在の収益規模では無料枠に収まる。

## Alternatives Considered

- **自前実装（Supabase + Functions）**: コントロールが最大だが、個人開発での維持コストと障害リスクが高い。
- **Adapty**: 機能は近いが Flutter サポートの成熟度が RevenueCat に劣る（2024年時点）。
