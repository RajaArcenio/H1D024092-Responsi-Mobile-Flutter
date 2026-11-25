import 'package:flutter/services.dart';

const _channel = MethodChannel('langit_kota/locations');

Future<String?> readPreference(String key) =>
    _channel.invokeMethod<String>('read', {'key': key});

Future<void> writePreference(String key, String value) =>
    _channel.invokeMethod<void>('write', {'key': key, 'value': value});
