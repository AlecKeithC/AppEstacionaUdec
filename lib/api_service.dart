import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'parking.dart';

class ServerException implements Exception {
  final String message;
  ServerException(this.message);
}

class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);
}

class ApiService {
  static const _baseHost = 'PAGINAWEBAPI.com';
  static const _basePath = '/parkings/';

  Future<List<Parking>> fetchParkings() async {
    final client = http.Client();
    try {
      final uri = Uri.https(_baseHost, _basePath);
      final response = await client.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        List<dynamic> jsonResponse = jsonDecode(response.body);
        return jsonResponse
            .map((data) => Parking.fromJson(data as Map<String, dynamic>))
            .where((parking) => parking.active)
            .toList();
            } else {
              throw ServerException('Error del servidor: ${response.statusCode}');
            }
          } on SocketException {
            throw NetworkException('Sin conexión a Internet');
          } on http.ClientException {
            throw NetworkException('Error del cliente HTTP');
          } on TimeoutException {
            throw NetworkException('La solicitud ha expirado');
          } on FormatException {
            throw Exception('Falló al decodificar los datos');
          } catch (e) {
            throw Exception('Ocurrió un error desconocido: $e');
          } finally {
            client.close();
          }
        }
      }
