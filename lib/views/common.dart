import 'package:flutter/material.dart';

import '../models/city.dart';
import '../viewmodels/weather_view_model.dart';

const ink = Color(0xff173c37);
const teal = Color(0xff276958);
const paper = Color(0xfff6f8f4);
const line = Color(0xffdde5dd);
const daysId = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
const monthsId = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'Mei',
  'Jun',
  'Jul',
  'Agu',
  'Sep',
  'Okt',
  'Nov',
  'Des',
];
String dateLabel(DateTime date) =>
    '${daysId[date.weekday - 1]}, ${date.day} ${monthsId[date.month - 1]}';
String number(num? n, [int digits = 0]) =>
    n == null ? '—' : n.toStringAsFixed(digits).replaceAll('.', ',');
String clock(DateTime time) =>
    '${time.hour.toString().padLeft(2, '0')}.${time.minute.toString().padLeft(2, '0')}';

class StarButton extends StatelessWidget {
  const StarButton(this.vm, this.city, {super.key});
  final WeatherViewModel vm;
  final City city;
  @override
  Widget build(BuildContext context) {
    final saved = vm.isFavorite(city);
    return IconButton(
      tooltip: saved ? 'Hapus dari favorit' : 'Simpan ke favorit',
      onPressed: vm.initialized && !vm.savingFavorite
          ? () => vm.toggleFavorite(city)
          : null,
      icon: Icon(
        saved ? Icons.star_rounded : Icons.star_border_rounded,
        color: teal,
      ),
    );
  }
}

class Notice extends StatelessWidget {
  const Notice(this.icon, this.title, this.detail, {this.retry, super.key});
  final IconData icon;
  final String title, detail;
  final VoidCallback? retry;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
    child: Column(
      children: [
        Icon(icon, color: teal, size: 32),
        const SizedBox(height: 10),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 5),
        Text(detail, textAlign: TextAlign.center),
        if (retry != null)
          TextButton.icon(
            onPressed: retry,
            icon: const Icon(Icons.refresh),
            label: const Text('Coba lagi'),
          ),
      ],
    ),
  );
}

class PageBody extends StatelessWidget {
  const PageBody({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
    children: [
      Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ),
      ),
    ],
  );
}

class Surface extends StatelessWidget {
  const Surface(this.child, {super.key});
  final Widget child;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: RoundedRectangleBorder(
      side: const BorderSide(color: line),
      borderRadius: BorderRadius.circular(20),
    ),
    clipBehavior: Clip.antiAlias,
    child: child,
  );
}
