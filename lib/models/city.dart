class City {
  const City(
    this.id,
    this.name,
    this.region,
    this.country,
    this.latitude,
    this.longitude,
  );
  final int id;
  final String name, region, country;
  final double latitude, longitude;
  static const purwokerto = City(
    1630328,
    'Purwokerto',
    'Jawa Tengah',
    'Indonesia',
    -7.42139,
    109.23444,
  );
  String get subtitle =>
      {region, country}.where((s) => s.isNotEmpty).join(', ');

  factory City.fromJson(Map<String, dynamic> json) => City(
    (json['id'] as num).toInt(),
    json['name'] as String,
    json['admin1'] as String? ?? '',
    json['country'] as String? ?? '',
    (json['latitude'] as num).toDouble(),
    (json['longitude'] as num).toDouble(),
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'admin1': region,
    'country': country,
    'latitude': latitude,
    'longitude': longitude,
  };
}
