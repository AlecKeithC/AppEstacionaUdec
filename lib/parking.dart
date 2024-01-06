import 'package:google_maps_flutter/google_maps_flutter.dart';

class Parking {
  final int id;
  final int freeSpaces;
  final int totalSpaces;
  final String pkName;
  final double latitude;
  final double longitude;
  final bool reducedCapacity;
  final bool academico;
  final bool estudiante;
  final bool administrativo;
  final bool otro;
  final bool active;
  final DateTime lastUpdate;
  final bool estatica;

  Parking({
    required this.id,
    required this.freeSpaces,
    required this.totalSpaces,
    required this.pkName,
    required this.latitude,
    required this.longitude,
    required this.reducedCapacity,
    required this.academico,
    required this.estudiante,
    required this.administrativo,
    required this.otro,
    required this.active,
    required this.lastUpdate,
    required this.estatica,
  });
  LatLng get latLng => LatLng(latitude, longitude);

  bool getCategory(String? userType) {
    if (userType == null) {
      return true; // Si no se ha definido un tipo de usuario, se muestran todos los estacionamientos
    }
    switch (userType) {
      case 'academico':
        return academico;
      case 'estudiante':
        return estudiante;
      case 'administrativo':
        return administrativo;
      case 'otro':
        return otro;
      default:
        return true;
    }
  }

  factory Parking.fromJson(Map<String, dynamic> json) {
    return Parking(
      id: json['id'],
      freeSpaces: json['free_spaces'],
      totalSpaces: json['total_spaces'],
      pkName: json['pk_name'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      reducedCapacity: json['reduced_capacity'],
      academico: json['academico'],
      estudiante: json['estudiante'],
      administrativo: json['administrativo'],
      otro: json['otro'],
      active: json['active'],
      lastUpdate: DateTime.parse(json['last_update']),
      estatica: json['estatica'],
    );
  }
}
