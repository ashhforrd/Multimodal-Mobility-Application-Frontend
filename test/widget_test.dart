import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:langkah_sahabat/app.dart';
import 'package:langkah_sahabat/core/theme/app_theme.dart';
import 'package:langkah_sahabat/data/models/geo_point.dart';
import 'package:langkah_sahabat/features/navigation/application/navigation_controller.dart';
import 'package:langkah_sahabat/shared/widgets/navigation_map.dart';

import 'helpers/fakes.dart';

void main() {
  test('design system menggunakan letter spacing minus dua persen', () {
    final textTheme = AppTheme.light.textTheme;
    final styles = [
      textTheme.displayLarge,
      textTheme.displayMedium,
      textTheme.displaySmall,
      textTheme.headlineLarge,
      textTheme.headlineMedium,
      textTheme.headlineSmall,
      textTheme.titleLarge,
      textTheme.titleMedium,
      textTheme.titleSmall,
      textTheme.bodyLarge,
      textTheme.bodyMedium,
      textTheme.bodySmall,
      textTheme.labelLarge,
      textTheme.labelMedium,
      textTheme.labelSmall,
    ];

    for (final style in styles) {
      expect(style, isNotNull);
      expect(style!.fontSize, isNotNull);
      expect(
        style.letterSpacing,
        closeTo(style.fontSize! * -.02, .001),
      );
    }
  });

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

  testWidgets('lokasi aktif ditandai dengan tombol sukses berwarna hijau',
      (tester) async {
    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Gunakan lokasi saat ini'));
    await tester.pumpAndSettle();

    expect(find.text('Lokasi saat ini digunakan'), findsOneWidget);
    final action = tester.widget<AnimatedContainer>(
      find.byKey(const Key('current-location-action')),
    );
    final decoration = action.decoration! as BoxDecoration;
    expect(decoration.color, AppTheme.success);
  });

  testWidgets(
      'pilihan peta tampil di beranda dan ubah tujuan membuka peta kembali',
      (tester) async {
    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Pilih melalui peta'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    final picker = find.byKey(const Key('destination-map-picker'));
    expect(picker, findsOneWidget);
    final map = tester.widget<NavigationMap>(picker);
    map.onPointSelected!(
      const GeoPoint(latitude: -6.8912, longitude: 107.6103),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(
      find.byKey(
        const Key('selected-map-destination'),
        skipOffstage: false,
      ),
      findsOneWidget,
    );
    expect(
      find.text('Mau ke mana?', skipOffstage: false),
      findsOneWidget,
    );
    expect(find.text('Lihat pratinjau rute'), findsOneWidget);

    await tester.tap(find.text('Lihat pratinjau rute'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('Pratinjau rute'), findsOneWidget);

    final changeDestination = find.text(
      'Ubah tujuan',
      skipOffstage: false,
    );
    await tester.ensureVisible(changeDestination);
    await tester.pump();
    await tester.tap(changeDestination);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(
      find.text('Mau ke mana?', skipOffstage: false),
      findsOneWidget,
    );
    expect(find.byKey(const Key('destination-map-picker')), findsOneWidget);
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
