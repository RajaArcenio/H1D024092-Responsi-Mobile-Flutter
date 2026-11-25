import 'package:web/web.dart' as web;

Future<String?> readPreference(String key) async =>
    web.window.localStorage.getItem('langit_kota.$key');

Future<void> writePreference(String key, String value) async =>
    web.window.localStorage.setItem('langit_kota.$key', value);
