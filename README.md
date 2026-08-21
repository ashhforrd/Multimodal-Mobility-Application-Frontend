# Langkah Sahabat

Flutter thesis prototype for real-time, multimodal pedestrian navigation. It combines OpenStreetMap, live GPS, walking directions, Indonesian voice guidance, and haptic action alerts.

## Current capabilities

- Live place search and reverse geocoding through Nominatim
- Real walking routes, geometry, distance, duration, and maneuvers from OSRM
- Foreground GPS tracking, direction-following map, and route-deviation detection
- Automatic action-point alerts and spoken instructions
- Live recovery route to rejoin the original route
- Gemini assistance when a valid API key is configured

## Run

Requirements: Flutter stable with Dart 3.4+, internet access, Xcode for iOS, or the Android SDK and JDK 17 for Android.

```sh
cp .env.example .env
flutter pub get
flutter run
```

```env
GEMINI_API_KEY=
GEMINI_MODEL=gemini-3.5-flash
ROUTING_BASE_URL=https://routing.openstreetmap.de/routed-foot
GEOCODING_BASE_URL=https://nominatim.openstreetmap.org
NOMINATIM_EMAIL=
```

Set `NOMINATIM_EMAIL` when appropriate to identify higher-volume requests. The app reports unavailable services instead of silently substituting simulated location, route, or assistant data.

Create a restricted Gemini API key in [Google AI Studio](https://aistudio.google.com/app/apikey), then set `GEMINI_API_KEY` in the local `.env`. While the voice panel is open, questions are submitted after a two-second pause and listening resumes automatically after each spoken answer.

## Native field test

### iPhone

Install full Xcode and CocoaPods, connect and trust the iPhone, enable Developer Mode, and configure an Apple development team in `ios/Runner.xcworkspace`.

```sh
flutter devices
flutter run -d <iphone-device-id>
```

Keep the app in the foreground while walking. The current implementation does not provide background or offline navigation.

### Android

Enable Developer options and USB debugging, connect and authorize the phone, then run:

```sh
flutter devices
flutter run --release -d <android-device-id>
```

After installation, disconnect the cable and launch Langkah Sahabat from the Android home screen. The Android build includes location, microphone, internet, speech-recognition, and text-to-speech declarations.

## Web test from a phone

```sh
flutter run -d web-server --web-hostname any --web-port 8080
```

Open `http://<mac-local-ip>:8080` from a phone on the same Wi-Fi. Browsers can require HTTPS for microphone and geolocation, so native iOS is the recommended field-test target.

## Thesis demo controls

Demo controls are hidden during field testing. Enable them explicitly with:

```sh
flutter run --dart-define=SHOW_DEMO_CONTROLS=true
```

The Home screen will show **Developer automatic test**. It runs a deterministic mock walk through slight turns, regular turns, action alerts, and arrival without GPS or network access.

## Architecture

```text
lib/
  core/       design system and configuration
  data/       models and services S01–S07
  features/   destination, navigation, voice, alerts, and recovery modules
  shared/     reusable OpenStreetMap component
```

- S01 `LocationService`: GPS permission, initial position, and position stream
- S02 `RouteService`: OSRM walking route and recovery route
- S03 `MapService`: Nominatim search and route calculations
- S04–S07: speech-to-text, text-to-speech, haptics, and Gemini

See [requirements traceability](docs/requirements_traceability.md) for the FR, module, component, service, and test mapping.

## Dependencies and external services

No new Flutter package was added for real routing. The implementation reuses `http` and the existing `flutter_map`, `latlong2`, `geolocator`, `speech_to_text`, `flutter_tts`, Riverpod, and routing packages.

Add OSRM and Nominatim as external services in the thesis report. Their public endpoints are suitable for prototype field tests, not production-scale traffic; both base URLs are configurable without an app update.

## Verify

```sh
dart format lib test
flutter analyze
flutter test
flutter build web
flutter build ios --debug --no-codesign
```

## Safety and limitations

- Always follow real-world signs, sidewalks, crossings, and local rules.
- Public routing, geocoding, and map services have no application-specific SLA.
- Guidance depends on GPS and OpenStreetMap data quality.
- Navigation currently works only in the foreground and requires internet access.
- Street or path names are used when dedicated landmark data is unavailable.
