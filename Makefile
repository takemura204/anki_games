ifneq (,$(wildcard .env))
  include .env
  export
endif

FLUTTER := flutter
PUBSPEC := packages/app_it_pass/pubspec.yaml

.PHONY: \
  deploy-quiz-data \
  bump-it-pass \
  build-ios-it-pass    upload-ios-it-pass    release-ios-it-pass    open-ios-it-pass \
  build-android-it-pass upload-android-it-pass release-android-it-pass open-android-it-pass \
  release-it-pass

# ================================================================
# クイズデータ — Firebase Hosting デプロイ
# ================================================================
# 使い方: make deploy-quiz-data
# quiz/it_pass/, quiz/fe/, quiz/fp3/ のJSONと manifest.json を
# Firebase Hosting (quiz-data ターゲット) へデプロイする。
# アプリビルドとは独立して実行できる。
deploy-quiz-data:
	dart run packages/quiz_data/scripts/generate_manifest.dart
	npx -y firebase-tools@latest target:apply hosting quiz-data quiz-data-anki-quiz-dev --project anki-quiz-dev
	npx -y firebase-tools@latest deploy --only hosting:quiz-data --project anki-quiz-dev

# ----------------------------------------------------------------
# ビルド番号を pubspec.yaml で自動インクリメント
# ----------------------------------------------------------------
bump-it-pass:
	@old=$$(grep '^version:' $(PUBSPEC) | sed 's/version: //'); \
	 base=$$(echo $$old | cut -d'+' -f1); \
	 build=$$(echo $$old | cut -d'+' -f2); \
	 new="$$base+$$((build + 1))"; \
	 sed -i '' "s/^version: $$old/version: $$new/" $(PUBSPEC); \
	 echo "  Bumped $$old → $$new"

# ================================================================
# iOS — TestFlight
# ================================================================
build-ios-it-pass:
	$(FLUTTER) build ipa --release \
		--flavor it_pass \
		-t lib/main_it_pass.dart \
		--export-options-plist=ios/ExportOptions.plist

upload-ios-it-pass:
	xcrun altool --upload-app --type ios \
		--apiKey "$(APP_STORE_CONNECT_API_KEY_ID)" \
		--apiIssuer "$(APP_STORE_CONNECT_API_ISSUER_ID)" \
		--file "$$(find build/ios/ipa -name '*.ipa' 2>/dev/null | head -1)"

release-ios-it-pass:
	@$(MAKE) --no-print-directory bump-it-pass
	@$(MAKE) --no-print-directory build-ios-it-pass
	@$(MAKE) --no-print-directory upload-ios-it-pass

open-ios-it-pass:
	open build/ios/ipa

# ================================================================
# Android — Google Play 内部テスト
# ================================================================
build-android-it-pass:
	$(FLUTTER) build appbundle --release \
		--flavor it_pass \
		-t lib/main_it_pass.dart

upload-android-it-pass:
	cd android && ./gradlew publishIt_passReleaseBundle

release-android-it-pass:
	@$(MAKE) --no-print-directory bump-it-pass
	@$(MAKE) --no-print-directory build-android-it-pass
	@$(MAKE) --no-print-directory upload-android-it-pass

open-android-it-pass:
	open build/app/outputs/bundle/it_passRelease

# ================================================================
# 両プラットフォーム同時リリース（推奨）
# ================================================================
release-it-pass:
	@$(MAKE) --no-print-directory bump-it-pass
	@$(MAKE) --no-print-directory build-ios-it-pass
	@$(MAKE) --no-print-directory build-android-it-pass
	@$(MAKE) --no-print-directory upload-ios-it-pass
	@$(MAKE) --no-print-directory upload-android-it-pass
