import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:langkah_sahabat/app.dart';
import 'package:langkah_sahabat/core/theme/app_theme.dart';
import 'package:langkah_sahabat/data/models/assistant_response.dart';
import 'package:langkah_sahabat/data/models/geo_point.dart';
import 'package:langkah_sahabat/data/services/text_to_speech_service.dart';
import 'package:langkah_sahabat/features/navigation/application/navigation_controller.dart';
import 'package:langkah_sahabat/features/navigation/application/navigation_state.dart';
import 'package:langkah_sahabat/features/navigation/presentation/active_navigation_screen.dart';
import 'package:langkah_sahabat/features/navigation/presentation/route_preview_screen.dart';
import 'package:langkah_sahabat/features/navigation/widgets/manual_feedback_actions.dart';
import 'package:langkah_sahabat/features/recovery/presentation/route_recovery_view.dart';
import 'package:langkah_sahabat/features/voice/application/voice_controller.dart';
import 'package:langkah_sahabat/features/voice/presentation/voice_interaction_panel.dart';
import 'package:langkah_sahabat/shared/widgets/navigation_map.dart';
import 'package:go_router/go_router.dart';

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

    expect(find.text('Lihat pratinjau rute'), findsNothing);
    expect(find.text('Pratinjau rute'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('preview-route-library')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('Pratinjau rute'), findsOneWidget);
    await tester.pageBack();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
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

  testWidgets('lokasi saat ini otomatis menjadi titik awal tanpa tombol',
      (tester) async {
    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();

    expect(find.text('Gunakan lokasi saat ini'), findsNothing);
    expect(
      find.text('Titik awal otomatis memakai lokasi saat ini'),
      findsOneWidget,
    );
  });

  testWidgets('panah kartu destinasi selalu berwarna putih', (tester) async {
    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Perpustakaan Pusat');
    await tester.tap(find.byTooltip('Cari tujuan'));
    await tester.pumpAndSettle();

    final button = tester.widget<IconButton>(
      find.byKey(const ValueKey('preview-route-library')),
    );
    expect(button.style?.foregroundColor?.resolve({}), Colors.white);
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
    expect(
      find.text('Perpustakaan Pusat', skipOffstage: false),
      findsWidgets,
    );
    expect(find.text('Tujuan dipilih'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.text('Lihat pratinjau rute'), findsNothing);

    final previewAction =
        find.byKey(const ValueKey('preview-route-map-reverse-library'));
    expect(tester.widget<IconButton>(previewAction).onPressed, isNotNull);
    await tester.ensureVisible(previewAction);
    await tester.pump();
    await tester.tap(
      previewAction,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('Pratinjau rute'), findsOneWidget);
    expect(find.byKey(const Key('route-endpoints')), findsOneWidget);
    expect(find.text('Titik awal'), findsOneWidget);
    expect(find.text('Tujuan'), findsOneWidget);

    final changeDestination = find.text('Ubah tujuan');
    await tester.scrollUntilVisible(
      changeDestination,
      300,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .last,
    );
    await tester.pump();
    await tester.tap(changeDestination);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(
      find.text('Mau ke mana?', skipOffstage: false),
      findsOneWidget,
    );
    expect(find.byKey(const Key('destination-map-picker')), findsOneWidget);
    await tester.tapAt(const Offset(8, 8));
    await tester.pump(const Duration(milliseconds: 350));
  });

  testWidgets('navigasi terbuka tanpa menunggu audio dan peta mengikuti arah',
      (tester) async {
    final tts = BlockingTextToSpeechService();
    addTearDown(tts.complete);
    final container = ProviderContainer(
      overrides: [
        locationServiceProvider.overrideWithValue(FakeLocationService()),
        ttsProvider.overrideWithValue(tts),
        hapticProvider.overrideWithValue(FakeHapticService()),
        routeServiceProvider.overrideWithValue(FakeRouteService()),
        mapServiceProvider.overrideWithValue(FakeMapService()),
      ],
    );
    addTearDown(container.dispose);
    await container
        .read(navigationProvider.notifier)
        .selectDestination(testDestination);
    final router = GoRouter(
      initialLocation: '/preview',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const Scaffold(
            body: Text('Beranda pengujian'),
          ),
        ),
        GoRoute(
          path: '/preview',
          builder: (_, __) => const RoutePreviewScreen(),
        ),
        GoRoute(
          path: '/navigation',
          builder: (_, __) => const ActiveNavigationScreen(),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          theme: AppTheme.light,
          routerConfig: router,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('Pratinjau rute'), findsOneWidget);

    final start = find.text('Mulai navigasi');
    await tester.scrollUntilVisible(
      start,
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(start);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('Navigasi aktif'), findsOneWidget);
    final map = tester.widget<NavigationMap>(
      find.byKey(const Key('active-navigation-map')),
    );
    expect(map.followUser, isTrue);
    expect(find.byKey(const Key('follow-walking-direction')), findsOneWidget);
    expect(tts.spokenTexts, isNotEmpty);
    tts.complete();

    final finish = find.text('Selesai perjalanan');
    await tester.scrollUntilVisible(
      finish,
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(finish);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('Selesaikan perjalanan?'), findsOneWidget);

    await tester.tap(find.text('Batal'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('Navigasi aktif'), findsOneWidget);

    await tester.ensureVisible(finish);
    await tester.tap(finish);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('Selesaikan perjalanan?'), findsOneWidget);
    final confirmButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Ya, selesai'),
    );
    confirmButton.onPressed!();
    for (var index = 0; index < 10; index++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(container.read(navigationProvider).routeStatus, RouteStatus.idle);
    expect(find.text('Beranda pengujian'), findsOneWidget);
  });

  testWidgets('panel bantuan suara berjalan hands-free tanpa tombol input',
      (tester) async {
    const response = AssistantResponse(text: 'Belok kiri setelah gerbang.');
    final voiceService = FakeVoiceService();
    final container = ProviderContainer(
      overrides: [
        locationServiceProvider.overrideWithValue(FakeLocationService()),
        ttsProvider.overrideWithValue(FakeTextToSpeechService()),
        hapticProvider.overrideWithValue(FakeHapticService()),
        routeServiceProvider.overrideWithValue(FakeRouteService()),
        voiceServiceProvider.overrideWithValue(voiceService),
        geminiServiceProvider.overrideWithValue(FakeGeminiService(response)),
      ],
    );
    addTearDown(container.dispose);
    await container
        .read(navigationProvider.notifier)
        .selectDestination(testDestination);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: VoiceInteractionPanel()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    const question = 'Saya harus belok di mana?';
    expect(voiceService.listenCount, 1);
    expect(find.text('Mulai mendengarkan'), findsNothing);
    expect(find.text('Kirim teks'), findsNothing);
    expect(find.byType(TextField), findsNothing);

    voiceService.emitText(question);
    voiceService.complete();
    await tester.pumpAndSettle();

    expect(voiceService.listenCount, 2);
    expect(container.read(voiceProvider).isListening, isTrue);
    expect(container.read(voiceProvider).transcript, isEmpty);
    expect(find.text(question), findsOneWidget);
    expect(find.text(response.text), findsOneWidget);
  });

  testWidgets('aksi bantuan manual berfungsi dan item tampil tanpa ikon',
      (tester) async {
    final tts = FakeTextToSpeechService();
    final container = ProviderContainer(
      overrides: [
        locationServiceProvider.overrideWithValue(FakeLocationService()),
        ttsProvider.overrideWithValue(tts),
        hapticProvider.overrideWithValue(FakeHapticService()),
        routeServiceProvider.overrideWithValue(FakeRouteService()),
      ],
    );
    addTearDown(container.dispose);
    final navigation = container.read(navigationProvider.notifier);
    await navigation.selectDestination(testDestination);
    await navigation.start();
    var recoveryRequests = 0;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light,
          home: _ManualFeedbackHost(
            onRecoveryRequested: () async => recoveryRequests++,
          ),
        ),
      ),
    );

    Future<void> openPanel() async {
      await tester.tap(find.text('Buka panel pengujian'));
      await tester.pumpAndSettle();
    }

    await openPanel();
    expect(find.byType(CircleAvatar), findsNothing);
    expect(find.byType(Icon), findsOneWidget);
    final headerLeft = tester.getTopLeft(find.text('Bantuan')).dx;
    for (final label in [
      'Ulangi instruksi',
      'Dengarkan instruksi berikutnya',
      'Saya bingung',
      'Pulihkan rute',
    ]) {
      expect(tester.getTopLeft(find.text(label)).dx, closeTo(headerLeft, .1));
    }

    tts.spokenTexts.clear();
    await tester.tap(find.text('Ulangi instruksi'));
    await tester.pumpAndSettle();
    expect(tts.spokenTexts.single, navigation.state.activeInstruction);

    await openPanel();
    tts.spokenTexts.clear();
    await tester.tap(find.text('Dengarkan instruksi berikutnya'));
    await tester.pumpAndSettle();
    expect(tts.spokenTexts.single, navigation.state.nextStep!.instruction);

    await openPanel();
    tts.spokenTexts.clear();
    await tester.tap(find.text('Saya bingung'));
    await tester.pumpAndSettle();
    expect(tts.spokenTexts.single, startsWith('Cari'));
    expect(navigation.state.activeInstruction, startsWith('Cari'));

    await openPanel();
    await tester.tap(find.text('Pulihkan rute'));
    await tester.pumpAndSettle();
    expect(recoveryRequests, 1);
  });

  testWidgets('pulihkan rute membuka kalkulasi dari bantuan manual',
      (tester) async {
    final routeService = FakeRouteService();
    final container = ProviderContainer(
      overrides: [
        locationServiceProvider.overrideWithValue(FakeLocationService()),
        ttsProvider.overrideWithValue(FakeTextToSpeechService()),
        hapticProvider.overrideWithValue(FakeHapticService()),
        routeServiceProvider.overrideWithValue(routeService),
      ],
    );
    addTearDown(container.dispose);
    await container
        .read(navigationProvider.notifier)
        .selectDestination(testDestination);
    await container.read(navigationProvider.notifier).start();
    final router = GoRouter(
      initialLocation: '/navigation',
      routes: [
        GoRoute(
          path: '/navigation',
          builder: (_, __) => const ActiveNavigationScreen(),
        ),
        GoRoute(
          path: '/recovery',
          builder: (_, __) => const RouteRecoveryView(),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          theme: AppTheme.light,
          routerConfig: router,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    final openHelp = find.text('Buka bantuan');
    await tester.scrollUntilVisible(
      openHelp,
      300,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .last,
    );
    await tester.tap(openHelp);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(find.text('Pulihkan rute'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Pemulihan rute'), findsOneWidget);
    expect(routeService.recoveryOrigins, isNotEmpty);
    expect(
      find.byKey(const Key('recovery-navigation-map')),
      findsOneWidget,
    );
  });
}

class _ManualFeedbackHost extends StatelessWidget {
  const _ManualFeedbackHost({required this.onRecoveryRequested});

  final Future<void> Function() onRecoveryRequested;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: FilledButton(
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              builder: (_) => ManualFeedbackActions(
                onRecoveryRequested: onRecoveryRequested,
              ),
            ),
            child: const Text('Buka panel pengujian'),
          ),
        ),
      );
}

Widget _testApp({TextToSpeechService? tts}) => ProviderScope(
      overrides: [
        locationServiceProvider.overrideWithValue(FakeLocationService()),
        ttsProvider.overrideWithValue(tts ?? FakeTextToSpeechService()),
        hapticProvider.overrideWithValue(FakeHapticService()),
        routeServiceProvider.overrideWithValue(FakeRouteService()),
        mapServiceProvider.overrideWithValue(FakeMapService()),
      ],
      child: const LangkahSahabatApp(),
    );
