/// `package:core` の `pubspec.yaml` で宣言したアセット向けの Flutter バンドルキー。
///
/// アプリから `rootBundle` / `Image.asset` 等で読むときは
/// `packages/<package名>/...` 形式が必要になる。
String corePackageAssetKey(String relativePath) {
  final normalized = relativePath.startsWith('assets/')
      ? relativePath
      : 'assets/$relativePath';
  return 'packages/core/$normalized';
}
