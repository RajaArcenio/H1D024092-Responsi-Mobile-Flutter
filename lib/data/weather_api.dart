import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/city.dart';
import '../models/weather.dart';

class WeatherApi {
  WeatherApi(this.client);
  final http.Client client;

  Future<Map<String, dynamic>> _get(Uri uri) async {
    final response = await client.get(uri).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw http.ClientException('HTTP ${response.statusCode}', uri);
    }
    return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  }

  Future<List<City>> search(String name) async {
    final json = await _get(
      Uri.https('geocoding-api.open-meteo.com', '/v1/search', {
        'name': name,
        'count': '12',
        'language': 'id',
        'format': 'json',
      }),
    );
    final results = json['results'] as List? ?? [];
    return results
        .map((item) => City.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Weather?> forecast(City city) async {
    final json = await _get(
      Uri.https('api.open-meteo.com', '/v1/forecast', {
        'latitude': city.latitude.toString(),
        'longitude': city.longitude.toString(),
        'timezone': 'auto',
        'forecast_days': '7',
        'current': 'temperature_2m,relative_humidity_2m,apparent_temperature,precipitation,weather_code,wind_speed_10m,is_day',
        'daily': 'weather_code,temperature_2m_min,temperature_2m_max,precipitation_probability_max',
      }),
    );
    return Weather.fromJson(json);
  }
}
