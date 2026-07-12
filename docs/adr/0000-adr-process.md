# ADR-0000: ADR 運用方針

**Status:** Accepted  
**Date:** 2026-06-24

## Context

重要な技術判断の「なぜ」を将来の自分・チームメンバー・採用担当者が追跡できるようにする必要がある。コードにはWHATが書いてあるが、WHYは口頭で消えてしまいがちで、意思決定の背景が失われると同じ議論を繰り返すコストが発生する。

## Decision

本リポジトリでは `docs/adr/` ディレクトリに Architecture Decision Records（ADR）を保管する。

## 運用ルール

- ファイル名: `NNNN-<kebab-case-title>.md`（例: `0001-riverpod-over-bloc.md`）
- 番号は単調増加。欠番は作らない。
- 既存の決定を覆す場合: 既存 ADR を削除せず、新 ADR に `Supersedes: ADR-XXXX` を記載。
- 記述形式: Status / Date / Context / Decision / Rationale / Consequences / Alternatives Considered

## Consequences

- ADR を書くコストが発生するが、技術判断の透明性が向上する。
- 採用面接・コードレビュー時に「なぜこの設計か」を即座に説明できる。
