import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/location_store.dart';
import '../data/weather_api.dart';
import '../models/city.dart';
import '../models/weather.dart';

enum LoadState { idle, loading, ready, empty, error }

class WeatherViewModel extends ChangeNotifier {
  WeatherViewModel(this.api, this.store);
  final WeatherApi api;
  final LocationStore store;
  City city = City.purwokerto;
  List<City> favorites = [], results = [];
  Weather? weather;
  LoadState weatherState = LoadState.loading, searchState = LoadState.idle;
  String query = '';
  bool initialized = false, savingFavorite = false;
  String? storageMessage;
  int _forecastId = 0, _searchId = 0;
  Timer? _debounce;
  bool _disposed = false;

  Future<void> start() async {
    try {
      final (lastCity, stars) = await store.read();
      city = lastCity ?? City.purwokerto;
      favorites = stars;
    } catch (_) {
      storageMessage = 'Lokasi tersimpan belum bisa dibaca.';
    }
    if (_disposed) return;
    initialized = true;
    await refresh();
  }

  Future<void> refresh() async {
    final id = ++_forecastId;
    weatherState = LoadState.loading;
    weather = null;
    notifyListeners();
    try {
      final data = await api.forecast(city);
      if (_disposed || id != _forecastId) return;
      weather = data;
      weatherState = data == null ? LoadState.empty : LoadState.ready;
    } catch (_) {
      if (_disposed || id != _forecastId) return;
      weatherState = LoadState.error;
    }
    notifyListeners();
  }

  Future<void> select(City next) async {
    city = next;
    final loading = refresh();
    try {
      await store.saveCity(next);
    } catch (_) {
      if (!_disposed && city.id == next.id) {
        storageMessage = 'Kota terakhir gagal disimpan.';
        notifyListeners();
      }
    }
    await loading;
  }

  bool isFavorite(City value) => favorites.any((c) => c.id == value.id);

  Future<void> toggleFavorite(City value) async {
    if (!initialized || savingFavorite) return;
    savingFavorite = true;
    final next = isFavorite(value)
        ? favorites.where((c) => c.id != value.id).toList()
        : [...favorites, value];
    notifyListeners();
    try {
      await store.saveFavorites(next);
      if (!_disposed) favorites = next;
    } catch (_) {
      storageMessage = 'Perubahan favorit gagal disimpan. Coba lagi.';
    } finally {
      if (!_disposed) {
        savingFavorite = false;
        notifyListeners();
      }
    }
  }

  void search(String text, {bool immediately = false}) {
    final term = text.trim();
    query = term;
    final id = ++_searchId;
    _debounce?.cancel();
    results = [];
    if (term.length < 2) {
      searchState = LoadState.idle;
    } else {
      searchState = LoadState.loading;
      _debounce = Timer(
        immediately ? Duration.zero : const Duration(milliseconds: 350),
        () => _fetchResults(term, id),
      );
    }
    notifyListeners();
  }

  Future<void> _fetchResults(String term, int id) async {
    try {
      final data = await api.search(term);
      if (_disposed || id != _searchId) return;
      results = data;
      searchState = data.isEmpty ? LoadState.empty : LoadState.ready;
    } catch (_) {
      if (_disposed || id != _searchId) return;
      searchState = LoadState.error;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _debounce?.cancel();
    super.dispose();
  }
}
