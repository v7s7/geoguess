import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/country.dart';

class CountryApi {
  // Added 'region' and 'capital' to fields
  static const String _url = 'https://restcountries.com/v3.1/all?fields=name,cca2,translations,region,capital';

  Future<List<Country>> fetchCountries() async {
    try {
      final response = await http
          .get(Uri.parse(_url))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data
            .map((json) => Country.fromJson(json))
            .where((c) => c.cca2 != 'IL')
            .toList();
      } else {
        throw Exception('Server returned ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching data: $e');
    }
  }
}