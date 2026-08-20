import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:langkah_sahabat/app.dart';
import 'package:langkah_sahabat/features/navigation/application/navigation_controller.dart';

import 'helpers/fakes.dart';

void main() {
  testWidgets('menampilkan layar pencarian tujuan', (tester) async {
    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();
    expect(find.text('Mau ke mana?'), findsOneWidget);
    expect(find.text('Perpustakaan Pusat'), findsNothing);
    expect(find.text('Lihat pratinjau rute'), findsNothing);

    await tester.enterText(
      find.byType(TextField).first,
      'Perpustakaan Pusat',
    );
    await tester.tap(find.byTooltip('Cari tujuan'));
    await tester.pumpAndSettle();

    final resultTile = find.widgetWithText(ListTile, 'Perpustakaan Pusat');
    expect(resultTile, findsOneWidget);
    await tester.tap(resultTile);
    await tester.pumpAndSettle();

    expect(find.text('Lihat pratinjau rute'), findsOneWidget);
  });

  testWidgets('layar pencarian tidak overflow pada ponsel sempit',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();

    expect(find.text('Mau ke mana?'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Widget _testApp() => ProviderScope(
      overrides: [
        locationServiceProvider.overrideWithValue(FakeLocationService()),
        ttsProvider.overrideWithValue(FakeTextToSpeechService()),
        hapticProvider.overrideWithValue(FakeHapticService()),
        routeServiceProvider.overrideWithValue(FakeRouteService()),
        mapServiceProvider.overrideWithValue(FakeMapService()),
      ],
      child: const LangkahSahabatApp(),
    );
