import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:langit_kota/data/location_store.dart';
import 'package:langit_kota/data/weather_api.dart';
import 'package:langit_kota/main.dart';
import 'package:langit_kota/models/city.dart';
import 'package:langit_kota/viewmodels/weather_view_model.dart';

const kebumen = City(
  1640765,
  'Kebumen',
  'Jawa Tengah',
  'Indonesia',
  -7.67,
  109.65,
);

// Example responses used only by tests and documented screen captures.
Map<String, dynamic> forecast() => {
  'timezone': 'Asia/Jakarta',
  'current': {
    'time': '2026-11-25T09:15',
    'temperature_2m': 28,
    'apparent_temperature': 30,
    'relative_humidity_2m': 76,
    'wind_speed_10m': 8.2,
    'precipitation': 0,
    'weather_code': 2,
    'is_day': 1,
  },
  'daily': {
    'time': List.generate(
      7,
      (i) => DateTime(2026, 11, 25 + i).toIso8601String().split('T').first,
    ),
    'temperature_2m_min': [23, 23, 22, 23, 24, 23, 22],
    'temperature_2m_max': [31, 30, 30, 29, 31, 32, 30],
    'precipitation_probability_max': [45, 60, 70, 75, 30, 25, 50],
    'weather_code': [2, 61, 61, 80, 2, 0, 3],
  },
};
http.Response response(Object obj) =>
    http.Response.bytes(utf8.encode(jsonEncode(obj)), 200);
const capture = bool.fromEnvironment('CAPTURE_DOCS');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    final values = <String, String>{};
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('langit_kota/locations'),
          (call) async {
            final key = call.arguments['key'] as String;
            if (call.method == 'read') return values[key];
            values[key] = call.arguments['value'] as String;
            return null;
          },
        );
  });
  testWidgets('Search, favorite, select and restore the city when reopening', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(412, 915);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final frame = GlobalKey();
    if (capture) {
      // Flutter widget tests normally use a square placeholder font.
      final root = Platform.environment['FLUTTER_ROOT']!;
      final font = FontLoader('Roboto');
      for (final weight in ['regular', 'medium', 'bold']) {
        final file = File(
          '$root/bin/cache/artifacts/material_fonts/roboto-$weight.ttf',
        );
        font.addFont(
          Future.value(ByteData.sublistView(file.readAsBytesSync())),
        );
      }
      await font.load();
      final icons = FontLoader('MaterialIcons');
      icons.addFont(
        Future.value(
          ByteData.sublistView(
            File(
              '$root/bin/cache/artifacts/material_fonts/materialicons-regular.otf',
            ).readAsBytesSync(),
          ),
        ),
      );
      await icons.load();
    }
    Future<void> snapshot(String name) async {
      if (!capture) return;
      await tester.runAsync(() async {
        final boundary =
            frame.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final shot = await boundary.toImage(pixelRatio: 2);
        final bytes = await shot.toByteData(format: ui.ImageByteFormat.png);
        final file = File('docs/screenshots/$name.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes!.buffer.asUint8List());
        shot.dispose();
      });
    }

    final calls = <Uri>[];
    final client = MockClient((request) async {
      expect(request.method, 'GET');
      calls.add(request.url);
      if (request.url.host == 'geocoding-api.open-meteo.com') {
        return response({
          'results': [kebumen.toJson()],
        });
      }
      return response(forecast());
    });
    Widget app() => RepaintBoundary(
      key: frame,
      child: LangitKota(client: client),
    );
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    expect(find.text('Purwokerto'), findsOneWidget);
    expect(find.text('28°'), findsOneWidget);
    expect(calls.first.queryParameters['timezone'], 'auto');
    await snapshot('cuaca');
    await tester.drag(find.byType(ListView).first, const Offset(0, -800));
    await tester.pumpAndSettle();
    expect(find.text('1 Des'), findsOneWidget);
    await snapshot('prakiraan');
    await tester.tap(find.byType(NavigationDestination).last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Kebumen');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(calls.last.queryParameters['name'], 'Kebumen');
    await tester.tap(find.byTooltip('Simpan ke favorit'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Hapus dari favorit'), findsOneWidget);
    await snapshot('pencarian');
    await tester.tap(find.widgetWithText(ListTile, 'Kebumen'));
    await tester.pumpAndSettle();
    expect(find.text('Kebumen'), findsOneWidget);
    expect(
      calls.last.queryParameters['longitude'],
      kebumen.longitude.toString(),
    );
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    expect(find.text('Kebumen'), findsOneWidget);
    expect(find.byTooltip('Hapus dari favorit'), findsOneWidget);
    await tester.tap(find.byType(NavigationDestination).last);
    await tester.pumpAndSettle();
    expect(find.text('Lokasi favorit'), findsOneWidget);
    expect(find.text('Kebumen'), findsOneWidget);
    await tester.tap(find.byTooltip('Hapus dari favorit'));
    await tester.pumpAndSettle();
    expect(find.text('Belum ada lokasi favorit'), findsOneWidget);
  });

  testWidgets('Handles errors, retry, empty forecast and empty search', (
    tester,
  ) async {
    var simulateError = true;
    final vm = WeatherViewModel(
      WeatherApi(
        MockClient(
          (_) async =>
              simulateError ? http.Response('Unavailable', 503) : response({}),
        ),
      ),
      LocationStore(),
    );
    await vm.start();
    expect(vm.weatherState, LoadState.error);
    vm.search('ab', immediately: true);
    await tester.pump(const Duration(milliseconds: 1));
    expect(vm.searchState, LoadState.error);
    simulateError = false;
    await vm.refresh();
    expect(vm.weatherState, LoadState.empty);
    vm.search('ab', immediately: true);
    await tester.pump(const Duration(milliseconds: 1));
    expect(vm.searchState, LoadState.empty);
    vm.dispose();
  });

  testWidgets('A late search cannot replace results for a newer city', (
    tester,
  ) async {
    final first = Completer<http.Response>();
    final vm = WeatherViewModel(
      WeatherApi(
        MockClient((r) async {
          if (r.url.queryParameters['name'] == 'Pur') return first.future;
          return response({
            'results': [kebumen.toJson()],
          });
        }),
      ),
      LocationStore(),
    );
    vm.search('Pur', immediately: true);
    await tester.pump(const Duration(milliseconds: 1));
    vm.search('Keb', immediately: true);
    await tester.pump(const Duration(milliseconds: 1));
    first.complete(
      response({
        'results': [City.purwokerto.toJson()],
      }),
    );
    await tester.pump(const Duration(milliseconds: 1));
    expect(vm.results.single.name, 'Kebumen');
    vm.dispose();
  });
}
