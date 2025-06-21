// City model for South Dakota cities
class SDCity {
  final String name;
  final double latitude;
  final double longitude;
  final String nwsOffice; // Add NWS office identifier

  const SDCity({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.nwsOffice,
  });
}

// List of available South Dakota cities with their coordinates
class SDCities {
  static const SDCity siouxFalls = SDCity(
    name: 'Sioux Falls',
    latitude: 43.5446,
    longitude: -96.7311,
    nwsOffice: 'FSD', // Sioux Falls NWS office
  );

  static const SDCity rapidCity = SDCity(
    name: 'Rapid City',
    latitude: 44.0805,
    longitude: -103.2310,
    nwsOffice: 'UNR', // Rapid City NWS office
  );

  static const SDCity pierre = SDCity(
    name: 'Pierre',
    latitude: 44.3683,
    longitude: -100.3509,
    nwsOffice: 'ABR', // Aberdeen NWS office
  );

  static const SDCity aberdeen = SDCity(
    name: 'Aberdeen',
    latitude: 45.4647,
    longitude: -98.4864,
    nwsOffice: 'ABR', // Aberdeen NWS office
  );

  static const SDCity brookings = SDCity(
    name: 'Brookings',
    latitude: 44.3114,
    longitude: -96.7984,
    nwsOffice: 'FSD', // Sioux Falls NWS office
  );

  static const List<SDCity> allCities = [
    siouxFalls,
    rapidCity,
    pierre,
    aberdeen,
    brookings,
  ];
}
