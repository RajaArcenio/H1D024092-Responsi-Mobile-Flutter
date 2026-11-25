import 'package:flutter/material.dart';

import '../models/weather.dart';
import '../viewmodels/weather_view_model.dart';
import 'common.dart';
import 'sky.dart';

class WeatherScreen extends StatelessWidget {
  const WeatherScreen(this.vm, {super.key});
  final WeatherViewModel vm;
  @override
  Widget build(BuildContext context) {
    final weather = vm.weather;
    return RefreshIndicator(
      onRefresh: vm.refresh,
      child: PageBody(
        children: [
          Row(
            children: [
              const Icon(Icons.place_outlined, size: 19, color: teal),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  vm.city.subtitle,
                  style: const TextStyle(color: teal),
                ),
              ),
              StarButton(vm, vm.city),
            ],
          ),
          Text(vm.city.name, style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 16),
          if (vm.weatherState == LoadState.loading)
            const LinearProgressIndicator(semanticsLabel: 'Memuat cuaca')
          else if (weather == null)
            Surface(
              vm.weatherState == LoadState.empty
                  ? Notice(
                      Icons.cloud_outlined,
                      'Data cuaca belum tersedia',
                      'Coba lagi atau pilih kota lain.',
                      retry: vm.refresh,
                    )
                  : Notice(
                      Icons.cloud_off_outlined,
                      'Cuaca gagal dimuat',
                      'Periksa koneksi internet lalu muat ulang.',
                      retry: vm.refresh,
                    ),
            )
          else ...[
            _CurrentCard(weather),
            const SizedBox(height: 24),
            Text(
              'Rincian hari ini',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            _Metrics(weather),
            const SizedBox(height: 24),
            Text(
              'Prakiraan 7 hari',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            const Text('Peluang hujan dan rentang suhu harian'),
            const SizedBox(height: 12),
            if (weather.days.isEmpty)
              const Surface(
                Notice(
                  Icons.date_range,
                  'Prakiraan belum tersedia',
                  'Silakan periksa kembali nanti.',
                ),
              )
            else
              Surface(
                Column(
                  children: [
                    for (final item in weather.days) ...[
                      if (item != weather.days.first)
                        const Divider(height: 1, indent: 16, endIndent: 16),
                      _DayRow(item, weather.time),
                    ],
                  ],
                ),
              ),
            const SizedBox(height: 18),
            Text(
              'Data cuaca dari Open-Meteo · ${weather.zone}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

class _CurrentCard extends StatelessWidget {
  const _CurrentCard(this.weather);
  final Weather weather;
  @override
  Widget build(BuildContext context) {
    final sky = Sky.from(weather.code);
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: CustomPaint(
        painter: Landscape(sky, weather.isDay),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 22, 14, 52),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${dateLabel(weather.time)} · ${clock(weather.time)} lokal',
                style: const TextStyle(fontWeight: FontWeight.w600, color: ink),
              ),
              const SizedBox(height: 8),
              Text(
                '${number(weather.temperature)}°',
                semanticsLabel:
                    '${number(weather.temperature)} derajat Celsius',
                style: const TextStyle(
                  fontSize: 76,
                  height: 1.05,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -5,
                  color: ink,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                sky.label,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  color: ink,
                ),
              ),
              Text(
                'Terasa seperti ${number(weather.feelsLike)}°C',
                style: const TextStyle(color: ink),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Metrics extends StatelessWidget {
  const _Metrics(this.weather);
  final Weather weather;
  @override
  Widget build(BuildContext context) {
    final metrics = [
      (Icons.water_drop_outlined, 'Kelembapan', '${number(weather.humidity)}%'),
      (Icons.air_rounded, 'Angin', '${number(weather.wind, 1)} km/j'),
      (
        Icons.grain_rounded,
        'Curah hujan',
        '${number(weather.precipitation, 1)} mm',
      ),
      (
        Icons.umbrella_outlined,
        'Peluang hujan',
        '${number(weather.days.where((d) => DateUtils.isSameDay(d.date, weather.time)).firstOrNull?.rainChance)}%',
      ),
    ];
    return LayoutBuilder(
      builder: (context, box) {
        final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
        final cols = box.maxWidth / scale >= 600
            ? 4
            : box.maxWidth / scale >= 245
            ? 2
            : 1;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final m in metrics)
              SizedBox(
                width: (box.maxWidth - (cols - 1) * 10) / cols,
                child: Surface(
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(m.$1, size: 20, color: teal),
                        const SizedBox(height: 8),
                        Text(m.$2),
                        Text(
                          m.$3,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _DayRow extends StatelessWidget {
  const _DayRow(this.day, this.now);
  final ForecastDay day;
  final DateTime now;
  @override
  Widget build(BuildContext context) {
    final sky = Sky.from(day.code);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 10,
        runSpacing: 5,
        children: [
          SizedBox(
            width: 100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateUtils.isSameDay(day.date, now)
                      ? 'Hari ini'
                      : daysId[day.date.weekday - 1],
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  '${day.date.day} ${monthsId[day.date.month - 1]}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Tooltip(
                message: sky.label,
                child: Icon(sky.icon, size: 20, color: teal),
              ),
              const SizedBox(width: 6),
              Text(
                '${number(day.rainChance)}%',
                semanticsLabel:
                    'Peluang hujan ${number(day.rainChance)} persen',
              ),
            ],
          ),
          Text(
            '${number(day.low)}°  /  ${number(day.high)}°',
            style: const TextStyle(fontWeight: FontWeight.w700),
            semanticsLabel:
                'Minimum ${number(day.low)} dan maksimum ${number(day.high)} derajat Celsius',
          ),
        ],
      ),
    );
  }
}
