import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'data/location_store.dart';
import 'data/weather_api.dart';
import 'viewmodels/weather_view_model.dart';
import 'views/common.dart';
import 'views/search_screen.dart';
import 'views/weather_screen.dart';

void main() => runApp(const LangitKota());

class LangitKota extends StatefulWidget {
  const LangitKota({super.key, this.client});
  final http.Client? client;
  @override
  State<LangitKota> createState() => _LangitKotaState();
}

class _LangitKotaState extends State<LangitKota> {
  late final client = widget.client ?? http.Client();
  late final vm = WeatherViewModel(WeatherApi(client), LocationStore());
  final messenger = GlobalKey<ScaffoldMessengerState>();
  int tab = 0;

  @override
  void initState() {
    super.initState();
    vm.addListener(_showStorageMessage);
    unawaited(vm.start());
  }

  void _showStorageMessage() {
    final text = vm.storageMessage;
    if (text == null) return;
    vm.storageMessage = null;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) =>
          messenger.currentState?.showSnackBar(SnackBar(content: Text(text))),
    );
  }

  @override
  void dispose() {
    vm.dispose();
    if (widget.client == null) client.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ColorScheme.fromSeed(
      seedColor: teal,
      brightness: Brightness.light,
    ).copyWith(primary: teal, surface: paper, onSurface: ink);
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colors,
      fontFamily: 'Roboto',
    );
    return MaterialApp(
      title: 'LangitKota',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: messenger,
      theme: base.copyWith(
        scaffoldBackgroundColor: paper,
        textTheme: base.textTheme.copyWith(
          headlineLarge: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 34,
            letterSpacing: -1.4,
            fontWeight: FontWeight.w700,
            color: ink,
          ),
          titleLarge: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 21,
            letterSpacing: -.5,
            fontWeight: FontWeight.w700,
            color: ink,
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: paper,
          foregroundColor: ink,
          surfaceTintColor: Colors.transparent,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: line),
          ),
        ),
        navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: Color(0xffd9ece0),
          height: 68,
        ),
      ),
      home: ListenableBuilder(
        listenable: vm,
        builder: (context, _) => PopScope(
          canPop: tab == 0,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop && tab != 0) setState(() => tab = 0);
          },
          child: Scaffold(
            appBar: AppBar(
              title: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.wb_twilight_rounded, color: teal),
                  SizedBox(width: 8),
                  Text(
                    'LangitKota',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -.8,
                    ),
                  ),
                ],
              ),
              actions: [
                if (tab == 0)
                  IconButton(
                    tooltip: 'Perbarui cuaca',
                    onPressed: vm.weatherState == LoadState.loading
                        ? null
                        : vm.refresh,
                    icon: const Icon(Icons.refresh_rounded),
                  ),
              ],
            ),
            body: SafeArea(
              top: false,
              child: IndexedStack(
                index: tab,
                children: [
                  WeatherScreen(vm),
                  SearchScreen(vm, (city) {
                    FocusManager.instance.primaryFocus?.unfocus();
                    unawaited(vm.select(city));
                    setState(() => tab = 0);
                  }),
                ],
              ),
            ),
            bottomNavigationBar: NavigationBar(
              selectedIndex: tab,
              onDestinationSelected: vm.initialized
                  ? (value) {
                      FocusManager.instance.primaryFocus?.unfocus();
                      setState(() => tab = value);
                    }
                  : null,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.wb_sunny_outlined),
                  selectedIcon: Icon(Icons.wb_sunny_rounded),
                  label: 'Cuaca',
                ),
                NavigationDestination(
                  icon: Icon(Icons.travel_explore_outlined),
                  selectedIcon: Icon(Icons.travel_explore),
                  label: 'Cari lokasi',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
