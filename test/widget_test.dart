import 'package:app_block_puzzle/main_block_puzzle.dart';
import 'package:core/features/purchase/service/mock_purchase_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp(purchaseService: MockPurchaseService()));
  });
}
