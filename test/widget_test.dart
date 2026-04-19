import 'package:flutter_test/flutter_test.dart';
import 'package:anki_games/common/features/purchase/service/mock_purchase_service.dart';
import 'package:anki_games/main_block_puzzle.dart';

void main() {
  testWidgets('smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp(purchaseService: MockPurchaseService()));
  });
}
