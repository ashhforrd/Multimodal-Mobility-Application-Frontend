import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:langkah_sahabat/app.dart';

void main() {
  testWidgets('menampilkan layar pencarian tujuan', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: LangkahSahabatApp()));
    await tester.pumpAndSettle();
    expect(find.text('Mau ke mana?'), findsOneWidget);
    expect(find.text('Perpustakaan Pusat'), findsOneWidget);
  });
}
