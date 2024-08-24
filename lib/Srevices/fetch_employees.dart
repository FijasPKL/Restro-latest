import 'dart:convert';
import 'package:http/http.dart' as http;

import '../Utils/GlobalFn.dart';

class emplyee_api {
  Future<List<Map<String, dynamic>>?> fetchEmployees() async {
    final String? baseUrl = await fnGetBaseUrl();
    final String apiUrl = '${baseUrl}api/Employee/Employees';
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData.containsKey('Data') &&
            responseData['Data'].containsKey('Employees')) {
          final List<dynamic> employeesList = responseData['Data']['Employees'];
          return List<Map<String, dynamic>>.from(employeesList);
        } else {
          print('Invalid API response structure');
        }
      } else {
        print('Failed to load employees. Status code: ${response.statusCode}');
      }
    } catch (error) {
      print('Error fetching employees: $error');
    }
    return null;
  }
}
