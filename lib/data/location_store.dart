import 'dart:convert';

import '../models/city.dart';
import 'preferences.dart';

class LocationStore {
  static const _lastKey = 'last_city';
  static const _starsKey = 'favorite_cities';
  Future<void> _writes = Future.value();

  City? _city(Object? value) {
    try {
      return City.fromJson(value as Map<String, dynamic>);
    } on Object {
      return null;
    }
  }

  Future<Object?> _readJson(String key) async {
    final raw = await readPreference(key);
    if (raw == null) return null;
    try {
      return jsonDecode(raw);
    } on FormatException {
      return null;
    }
  }

  Future<(City?, List<City>)> read() async {
    final lastCity = _city(await _readJson(_lastKey));
    final stars = await _readJson(_starsKey);
    return (
      lastCity,
      stars is List ? stars.map(_city).whereType<City>().toList() : <City>[],
    );
  }

  // Write taps in order, even when an earlier platform call takes longer.
  Future<void> _save(String key, Object value) {
    final encoded = jsonEncode(value);
    final write = _writes.then((_) => writePreference(key, encoded));
    _writes = write.catchError((Object _) {});
    return write;
  }

  Future<void> saveCity(City city) => _save(_lastKey, city.toJson());
  Future<void> saveFavorites(List<City> cities) {
    final records = cities.map((city) => city.toJson()).toList();
    return _save(_starsKey, records);
  }
}
