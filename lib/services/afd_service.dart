import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/sd_city.dart';

/// A service class to handle fetching the Area Forecast Discussion (AFD)
/// from the National Weather Service (NWS) API.
class AfdService {
  /// Fetches the latest AFD for a given NWS office.
  ///
  /// Throws an [Exception] if the network call fails or if no AFD is available.
  static Future<String> fetchAfd(SDCity city) async {
    final office = city.nwsOffice;
    final url = 'https://api.weather.gov/products/types/AFD/locations/$office';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['@graph'] != null && data['@graph'].isNotEmpty) {
        final productId = data['@graph'][0]['@id'];
        final productResp = await http.get(Uri.parse(productId));

        if (productResp.statusCode == 200) {
          final productData = json.decode(productResp.body);
          return productData['productText'] ?? 'No AFD text available.';
        }
      }
      throw Exception('No AFD data found in the response.');
    } else {
      throw Exception('Failed to load AFD (status ${response.statusCode})');
    }
  }
} 