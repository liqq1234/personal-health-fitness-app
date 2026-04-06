import 'dart:math' as math;

class LatLng {
  final double latitude;
  final double longitude;

  const LatLng(this.latitude, this.longitude);

  @override
  String toString() => 'LatLng(lat: $latitude, lon: $longitude)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LatLng &&
          other.latitude == latitude &&
          other.longitude == longitude;

  @override
  int get hashCode => latitude.hashCode ^ longitude.hashCode;
}

enum LengthUnit { Meter, Kilometer, Mile }

class Distance {
  final bool roundResult;

  const Distance({this.roundResult = true});

  double as(LengthUnit unit, LatLng p1, LatLng p2) {
    final d = distance(p1, p2);
    switch (unit) {
      case LengthUnit.Meter:
        return d;
      case LengthUnit.Kilometer:
        return d / 1000.0;
      case LengthUnit.Mile:
        return d / 1609.344;
    }
  }

  double distance(LatLng p1, LatLng p2) {
    const radius = 6371000.0;
    final dLat = _degToRad(p2.latitude - p1.latitude);
    final dLon = _degToRad(p2.longitude - p1.longitude);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(p1.latitude)) *
            math.cos(_degToRad(p2.latitude)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return radius * c;
  }

  LatLng offset(LatLng from, double distanceInMeters, double bearing) {
    const radius = 6371000.0;
    final dist = distanceInMeters / radius;
    final brng = _degToRad(bearing);
    final lat1 = _degToRad(from.latitude);
    final lon1 = _degToRad(from.longitude);

    final lat2 = math.asin(
      math.sin(lat1) * math.cos(dist) +
          math.cos(lat1) * math.sin(dist) * math.cos(brng),
    );
    final lon2 = lon1 +
        math.atan2(
          math.sin(brng) * math.sin(dist) * math.cos(lat1),
          math.cos(dist) - math.sin(lat1) * math.sin(lat2),
        );

    return LatLng(_radToDeg(lat2), _radToDeg(lon2));
  }

  double bearing(LatLng p1, LatLng p2) {
    final dLon = _degToRad(p2.longitude - p1.longitude);
    final lat1 = _degToRad(p1.latitude);
    final lat2 = _degToRad(p2.latitude);

    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);

    return _radToDeg(math.atan2(y, x));
  }

  double _degToRad(double deg) => deg * (math.pi / 180.0);
  double _radToDeg(double rad) => rad * (180.0 / math.pi);
}

class Path<T extends LatLng> {
  final List<T> _coordinates = [];

  Path();
  Path.from(Iterable<T> coordinates) {
    _coordinates.addAll(coordinates);
  }

  List<T> get coordinates => _coordinates;
  int get nrOfCoordinates => _coordinates.length;

  void add(T value) => _coordinates.add(value);

  double get distance {
    const distCalc = Distance();
    double total = 0.0;
    for (int i = 0; i < _coordinates.length - 1; i++) {
      total += distCalc.distance(_coordinates[i], _coordinates[i + 1]);
    }
    return total;
  }
}
