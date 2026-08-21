import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:langkah_sahabat/core/constants/app_constants.dart';
import 'package:langkah_sahabat/shared/widgets/auto_closing_dialog.dart';

void main() {
  testWidgets('dialog tertutup otomatis tepat setelah lima detik',
      (tester) async {
    var autoCloseCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: _DialogHost(
          onAutoClose: () => autoCloseCount++,
        ),
      ),
    );

    await tester.tap(find.text('Buka dialog'));
    await tester.pumpAndSettle();
    expect(find.text('Dialog navigasi'), findsOneWidget);

    await tester.pump(
      kNavigationDialogAutoCloseDuration - const Duration(milliseconds: 1),
    );
    expect(find.text('Dialog navigasi'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1));
    await tester.pumpAndSettle();

    expect(find.text('Dialog navigasi'), findsNothing);
    expect(autoCloseCount, 1);
  });

  testWidgets('menutup manual membatalkan timer otomatis', (tester) async {
    var autoCloseCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: _DialogHost(
          onAutoClose: () => autoCloseCount++,
        ),
      ),
    );

    await tester.tap(find.text('Buka dialog'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tutup'));
    await tester.pumpAndSettle();
    await tester.pump(kNavigationDialogAutoCloseDuration);

    expect(find.text('Dialog navigasi'), findsNothing);
    expect(autoCloseCount, 0);
  });
}

class _DialogHost extends StatelessWidget {
  const _DialogHost({required this.onAutoClose});

  final VoidCallback onAutoClose;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: FilledButton(
            onPressed: () => showAutoClosingDialog<void>(
              context: context,
              duration: kNavigationDialogAutoCloseDuration,
              onAutoClose: onAutoClose,
              builder: (dialogContext) => AlertDialog(
                title: const Text('Dialog navigasi'),
                actions: [
                  FilledButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Tutup'),
                  ),
                ],
              ),
            ),
            child: const Text('Buka dialog'),
          ),
        ),
      );
}
