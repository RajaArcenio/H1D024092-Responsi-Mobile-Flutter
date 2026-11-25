class ForecastDay {
  const ForecastDay(this.date, this.low, this.high, this.rainChance, this.code);
  final DateTime date;
  final num? low, high, rainChance;
  final int? code;
}

class Weather {
  Weather._(
    this.time,
    this.zone,
    this.temperature,
    this.feelsLike,
    this.humidity,
    this.wind,
    this.precipitation,
    this.code,
    this.isDay,
    this.days,
  );
  final DateTime time;
  final String zone;
  final num? temperature, feelsLike, humidity, wind, precipitation;
  final int? code;
  final bool isDay;
  final List<ForecastDay> days;

  static Weather? fromJson(Map<String, dynamic> json) {
    final current = json['current'] as Map<String, dynamic>?;
    if (current == null ||
        current['time'] == null ||
        (current['temperature_2m'] == null &&
            current['weather_code'] == null)) {
      return null;
    }
    final daily = json['daily'] as Map<String, dynamic>? ?? {};
    final dates = daily['time'] as List? ?? [];
    num? value(String field, int i) {
      final values = daily[field] as List?;
      return values != null && i < values.length ? values[i] as num? : null;
    }

    final days = <ForecastDay>[];
    for (var i = 0; i < dates.length; i++) {
      final date = DateTime.tryParse(dates[i]?.toString() ?? '');
      if (date != null) {
        days.add(
          ForecastDay(
            date,
            value('temperature_2m_min', i),
            value('temperature_2m_max', i),
            value('precipitation_probability_max', i),
            value('weather_code', i)?.toInt(),
          ),
        );
      }
    }
    return Weather._(
      DateTime.parse(current['time'] as String),
      json['timezone'] as String? ?? '',
      current['temperature_2m'] as num?,
      current['apparent_temperature'] as num?,
      current['relative_humidity_2m'] as num?,
      current['wind_speed_10m'] as num?,
      current['precipitation'] as num?,
      (current['weather_code'] as num?)?.toInt(),
      current['is_day'] != 0,
      days,
    );
  }
}
