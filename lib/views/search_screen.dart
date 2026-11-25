import 'package:flutter/material.dart';

import '../models/city.dart';
import '../viewmodels/weather_view_model.dart';
import 'common.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen(this.vm, this.onSelect, {super.key});
  final WeatherViewModel vm;
  final ValueChanged<City> onSelect;
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final controller = TextEditingController(text: widget.vm.query);
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Widget locations(List<City> cities) => Surface(
    Column(
      children: [
        for (final city in cities)
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xffeaf2ea),
              child: Icon(Icons.location_on_outlined, color: teal),
            ),
            title: Text(city.name),
            subtitle: Text(city.subtitle),
            trailing: StarButton(widget.vm, city),
            onTap: () => widget.onSelect(city),
          ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final vm = widget.vm;
    return PageBody(
      children: [
        const SizedBox(height: 12),
        Text('Cari lokasi', style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 14),
        TextField(
          controller: controller,
          textInputAction: TextInputAction.search,
          onChanged: vm.search,
          onSubmitted: (term) => vm.search(term, immediately: true),
          decoration: InputDecoration(
            hintText: 'Masukkan nama kota',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: controller.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Hapus pencarian',
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      controller.clear();
                      vm.search('');
                    },
                  ),
          ),
        ),
        const SizedBox(height: 24),
        if (vm.query.isEmpty) ...[
          Text('Lokasi favorit', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          if (vm.favorites.isEmpty)
            const Surface(
              Notice(
                Icons.star_border_rounded,
                'Belum ada lokasi favorit',
                'Ketuk bintang pada kota untuk menyimpannya di sini.',
              ),
            )
          else
            locations(vm.favorites),
        ] else ...[
          Text(
            'Hasil pencarian',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          switch (vm.searchState) {
            LoadState.loading => const LinearProgressIndicator(
              semanticsLabel: 'Mencari lokasi',
            ),
            LoadState.ready => locations(vm.results),
            LoadState.empty => const Surface(
              Notice(
                Icons.search_off,
                'Kota tidak ditemukan',
                'Coba ejaan atau nama kota lain.',
              ),
            ),
            LoadState.error => Surface(
              Notice(
                Icons.wifi_off,
                'Pencarian gagal',
                'Periksa koneksi internet dan coba lagi.',
                retry: () => vm.search(vm.query, immediately: true),
              ),
            ),
            LoadState.idle => const Text('Masukkan minimal dua karakter.'),
          },
        ],
        const SizedBox(height: 20),
        Text(
          'Data lokasi dari GeoNames melalui Open-Meteo',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
