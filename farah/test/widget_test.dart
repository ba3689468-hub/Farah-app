import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:farah/main.dart';

void main() {
  testWidgets('Farah app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: FarahApp()));
  });
}
