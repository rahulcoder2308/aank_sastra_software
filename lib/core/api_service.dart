import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'https://aanksastra.in/backend/public/api';
  static Function()? onUnauthenticated;

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', token);
  }

  static Future<void> clearAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('user_data');
  }

  static void _logRequest(String method, String url, {dynamic body}) {
    log("🚀 API REQUEST: $method $url");
    if (body != null) log("📦 Payload: ${jsonEncode(body)}");
  }

  static void _logResponse(String method, String url, http.Response response) {
    log("📊 API RESPONSE [$method $url]");
    log("[log] 🔢 Status: ${response.statusCode}");
    log("[log] 📝 Body: ${response.body}");

    if (response.statusCode == 401) {
      log("[log] ⚠️ Unauthenticated! Triggering auto-logout.");
      if (onUnauthenticated != null) {
        onUnauthenticated!();
      }
    }
  }

  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    try {
      final url = '$baseUrl/login';
      final payload = {'email': email, 'password': password};
      _logRequest("POST", url, body: payload);

      final response = await http
          .post(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 10));

      _logResponse("POST", url, response);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        await saveToken(data['access_token']);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_data', jsonEncode(data['user']));
        return data;
      } else {
        throw Exception(data['error'] ?? data['message'] ?? 'Login failed');
      }
    } catch (e) {
      log("❌ LOGIN ERROR: $e");
      rethrow;
    }
  }

  static Future<Map<String, String>> getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<Map<String, dynamic>> getProfile() async {
    final url = '$baseUrl/profile';
    _logRequest("GET", url);

    final response = await http.get(
      Uri.parse(url),
      headers: await getHeaders(),
    );

    _logResponse("GET", url, response);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_data', jsonEncode(data));
      return data;
    } else {
      throw Exception('Failed to fetch profile');
    }
  }

  static Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final url = '$baseUrl/change-password';
    final payload = {
      'current_password': currentPassword,
      'new_password': newPassword,
      'new_password_confirmation': confirmPassword,
    };
    _logRequest("POST", url, body: payload);

    final response = await http.post(
      Uri.parse(url),
      headers: await getHeaders(),
      body: jsonEncode(payload),
    );

    _logResponse("POST", url, response);

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Failed to update password');
    }
  }

  static Future<Map<String, dynamic>> analyzeMobile(String mobileNumber) async {
    final url = '$baseUrl/analyze-mobile';
    final payload = {'mobile_number': mobileNumber};
    _logRequest("POST", url, body: payload);

    final response = await http.post(
      Uri.parse(url),
      headers: await getHeaders(),
      body: jsonEncode(payload),
    );

    _logResponse("POST", url, response);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Failed to analyze mobile number');
    }
  }

  static Future<Map<String, dynamic>> analyzeName(String name) async {
    final url = '$baseUrl/analyze-name';
    final payload = {'name': name};
    _logRequest("POST", url, body: payload);

    final response = await http.post(
      Uri.parse(url),
      headers: await getHeaders(),
      body: jsonEncode(payload),
    );

    _logResponse("POST", url, response);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Failed to analyze name');
    }
  }

  static Future<Map<String, dynamic>> analyzeDriverConductor({
    required int driver,
    required int conductor,
  }) async {
    final url = '$baseUrl/analyze-driver-conductor';
    final payload = {'driver': driver, 'conductor': conductor};
    _logRequest("POST", url, body: payload);

    final response = await http.post(
      Uri.parse(url),
      headers: await getHeaders(),
      body: jsonEncode(payload),
    );

    _logResponse("POST", url, response);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final data = jsonDecode(response.body);
      throw Exception(
        data['message'] ?? 'Failed to analyze driver-conductor relationship',
      );
    }
  }

  // --- USER MANAGEMENT ---
  static Future<List<dynamic>> getUsers() async {
    final url = '$baseUrl/users';
    _logRequest("GET", url);

    final response = await http.get(
      Uri.parse(url),
      headers: await getHeaders(),
    );

    _logResponse("GET", url, response);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch users');
    }
  }

  static Future<Map<String, dynamic>> createUser(
    Map<String, dynamic> userData,
  ) async {
    final url = '$baseUrl/users';
    _logRequest("POST", url, body: userData);

    final response = await http.post(
      Uri.parse(url),
      headers: await getHeaders(),
      body: jsonEncode(userData),
    );

    _logResponse("POST", url, response);

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Failed to create user');
    }
  }

  static Future<Map<String, dynamic>> updateUser(
    int userId,
    Map<String, dynamic> userData,
  ) async {
    final url = '$baseUrl/users/$userId';
    _logRequest("PUT", url, body: userData);

    final response = await http.put(
      Uri.parse(url),
      headers: await getHeaders(),
      body: jsonEncode(userData),
    );

    _logResponse("PUT", url, response);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Failed to update user');
    }
  }

  static Future<void> deleteUser(int userId) async {
    final url = '$baseUrl/users/$userId';
    _logRequest("DELETE", url);

    final response = await http.delete(
      Uri.parse(url),
      headers: await getHeaders(),
    );

    _logResponse("DELETE", url, response);

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Failed to delete user');
    }
  }

  static Future<Map<String, dynamic>> updateUserPermissions(
    int userId,
    List<dynamic> permissions,
  ) async {
    final url = '$baseUrl/users/$userId/permissions';
    final payload = {'permissions': permissions};
    _logRequest("POST", url, body: payload);

    final response = await http.post(
      Uri.parse(url),
      headers: await getHeaders(),
      body: jsonEncode(payload),
    );

    _logResponse("POST", url, response);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Failed to update permissions');
    }
  }

  // --- DAILY WORK ---
  static Future<Map<String, dynamic>> getDailyWork({
    int page = 1,
    String? search,
    String? date,
  }) async {
    final queryParams = {
      'page': page.toString(),
      if (search != null && search.isNotEmpty) 'search': search,
      if (date != null && date.isNotEmpty) 'date': date,
    };

    final uri = Uri.parse(
      '$baseUrl/daily-work',
    ).replace(queryParameters: queryParams);
    final url = uri.toString();
    _logRequest("GET", url);

    final response = await http.get(uri, headers: await getHeaders());

    _logResponse("GET", url, response);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch daily work');
    }
  }

  static Future<Map<String, dynamic>> createDailyWork(
    Map<String, dynamic> data,
  ) async {
    final url = '$baseUrl/daily-work';
    _logRequest("POST", url, body: data);

    final response = await http.post(
      Uri.parse(url),
      headers: await getHeaders(),
      body: jsonEncode(data),
    );

    _logResponse("POST", url, response);

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Failed to create work entry');
    }
  }

  static Future<Map<String, dynamic>> updateDailyWork(
    int id,
    Map<String, dynamic> data,
  ) async {
    final url = '$baseUrl/daily-work/$id';
    _logRequest("PUT", url, body: data);

    final response = await http.put(
      Uri.parse(url),
      headers: await getHeaders(),
      body: jsonEncode(data),
    );

    _logResponse("PUT", url, response);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Failed to update work entry');
    }
  }

  static Future<void> deleteDailyWork(int id) async {
    final url = '$baseUrl/daily-work/$id';
    _logRequest("DELETE", url);

    final response = await http.delete(
      Uri.parse(url),
      headers: await getHeaders(),
    );

    _logResponse("DELETE", url, response);

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Failed to delete work entry');
    }
  }

  // --- CUSTOMERS ---
  static Future<Map<String, dynamic>> getCustomers({
    int page = 1,
    String? search,
    String? city,
    String? startDate,
    String? endDate,
  }) async {
    final queryParams = {
      'page': page.toString(),
      if (search != null && search.isNotEmpty) 'search': search,
      if (city != null && city.isNotEmpty) 'city': city,
      if (startDate != null && startDate.isNotEmpty) 'start_date': startDate,
      if (endDate != null && endDate.isNotEmpty) 'end_date': endDate,
    };

    final uri = Uri.parse(
      '$baseUrl/customers',
    ).replace(queryParameters: queryParams);
    final url = uri.toString();
    _logRequest("GET", url);

    final response = await http.get(uri, headers: await getHeaders());

    _logResponse("GET", url, response);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch customers');
    }
  }

  static Future<List<String>> getCities() async {
    final url = '$baseUrl/customers/cities';
    _logRequest("GET", url);

    final response = await http.get(
      Uri.parse(url),
      headers: await getHeaders(),
    );

    _logResponse("GET", url, response);

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => e.toString()).toList();
    } else {
      throw Exception('Failed to fetch cities');
    }
  }

  static Future<Map<String, dynamic>> createCustomer(
    Map<String, dynamic> data,
  ) async {
    final url = '$baseUrl/customers';
    _logRequest("POST", url, body: data);

    final response = await http.post(
      Uri.parse(url),
      headers: await getHeaders(),
      body: jsonEncode(data),
    );

    _logResponse("POST", url, response);

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Failed to create customer');
    }
  }

  static Future<Map<String, dynamic>> updateCustomer(
    int id,
    Map<String, dynamic> data,
  ) async {
    final url = '$baseUrl/customers/$id';
    _logRequest("PUT", url, body: data);

    final response = await http.put(
      Uri.parse(url),
      headers: await getHeaders(),
      body: jsonEncode(data),
    );

    _logResponse("PUT", url, response);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Failed to update customer');
    }
  }

  static Future<void> deleteCustomer(int id) async {
    final url = '$baseUrl/customers/$id';
    _logRequest("DELETE", url);

    final response = await http.delete(
      Uri.parse(url),
      headers: await getHeaders(),
    );

    _logResponse("DELETE", url, response);

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Failed to delete customer');
    }
  }

  // --- INQUIRIES ---
  static Future<Map<String, dynamic>> getInquiries({
    int page = 1,
    String? search,
    String? status,
  }) async {
    final queryParams = {
      'page': page.toString(),
      if (search != null && search.isNotEmpty) 'search': search,
      if (status != null && status != 'All') 'status': status,
    };

    final uri = Uri.parse(
      '$baseUrl/inquiries',
    ).replace(queryParameters: queryParams);
    final url = uri.toString();
    _logRequest("GET", url);

    final response = await http.get(uri, headers: await getHeaders());

    _logResponse("GET", url, response);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch inquiries');
    }
  }

  static Future<Map<String, dynamic>> createInquiry(
    Map<String, dynamic> data,
  ) async {
    final url = '$baseUrl/inquiries';
    _logRequest("POST", url, body: data);

    final response = await http.post(
      Uri.parse(url),
      headers: await getHeaders(),
      body: jsonEncode(data),
    );

    _logResponse("POST", url, response);

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Failed to create inquiry');
    }
  }

  static Future<Map<String, dynamic>> updateInquiry(
    int id,
    Map<String, dynamic> data,
  ) async {
    final url = '$baseUrl/inquiries/$id';
    _logRequest("PUT", url, body: data);

    final response = await http.put(
      Uri.parse(url),
      headers: await getHeaders(),
      body: jsonEncode(data),
    );

    _logResponse("PUT", url, response);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Failed to update inquiry');
    }
  }

  static Future<void> deleteInquiry(int id) async {
    final url = '$baseUrl/inquiries/$id';
    _logRequest("DELETE", url);

    final response = await http.delete(
      Uri.parse(url),
      headers: await getHeaders(),
    );

    _logResponse("DELETE", url, response);

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Failed to delete inquiry');
    }
  }

  // --- INVENTORY ---
  static Future<Map<String, dynamic>> getInventory({
    int page = 1,
    String? search,
    String? category,
    String? status,
  }) async {
    final queryParams = {
      'page': page.toString(),
      if (search != null && search.isNotEmpty) 'search': search,
      if (category != null && category != 'All') 'category': category,
      if (status != null && status != 'All') 'status': status,
    };

    final uri = Uri.parse(
      '$baseUrl/inventory',
    ).replace(queryParameters: queryParams);
    final url = uri.toString();
    _logRequest("GET", url);

    final response = await http.get(uri, headers: await getHeaders());

    _logResponse("GET", url, response);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch inventory');
    }
  }

  static Future<Map<String, dynamic>> createInventoryItem(
    Map<String, dynamic> data,
  ) async {
    final url = '$baseUrl/inventory';
    _logRequest("POST", url, body: data);

    final response = await http.post(
      Uri.parse(url),
      headers: await getHeaders(),
      body: jsonEncode(data),
    );

    _logResponse("POST", url, response);

    if (response.statusCode == 211 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Failed to create inventory item');
    }
  }

  static Future<Map<String, dynamic>> updateInventoryItem(
    int id,
    Map<String, dynamic> data,
  ) async {
    final url = '$baseUrl/inventory/$id';
    _logRequest("PUT", url, body: data);

    final response = await http.put(
      Uri.parse(url),
      headers: await getHeaders(),
      body: jsonEncode(data),
    );

    _logResponse("PUT", url, response);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Failed to update inventory item');
    }
  }

  static Future<void> deleteInventoryItem(int id) async {
    final url = '$baseUrl/inventory/$id';
    _logRequest("DELETE", url);

    final response = await http.delete(
      Uri.parse(url),
      headers: await getHeaders(),
    );

    _logResponse("DELETE", url, response);

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Failed to delete inventory item');
    }
  }

  // --- PAYMENTS ---
  static Future<Map<String, dynamic>> getPayments({
    int page = 1,
    String? search,
    String? mode,
    String? type,
    String? startDate,
    String? endDate,
  }) async {
    final queryParams = {
      'page': page.toString(),
      if (search != null && search.isNotEmpty) 'search': search,
      if (mode != null && mode != 'All') 'mode': mode,
      if (type != null && type != 'All') 'payment_type': type,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
    };

    final uri = Uri.parse(
      '$baseUrl/payments',
    ).replace(queryParameters: queryParams);
    final url = uri.toString();
    _logRequest("GET", url);

    final response = await http.get(uri, headers: await getHeaders());

    _logResponse("GET", url, response);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch payments');
    }
  }

  static Future<Map<String, dynamic>> exportPayments({
    String? type,
    String? startDate,
    String? endDate,
  }) async {
    final queryParams = {
      if (type != null && type != 'All') 'payment_type': type,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
    };

    final uri = Uri.parse(
      '$baseUrl/payments/export',
    ).replace(queryParameters: queryParams);
    final url = uri.toString();
    _logRequest("GET", url);

    final response = await http.get(uri, headers: await getHeaders());

    _logResponse("GET", url, response);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to export payments');
    }
  }

  static Future<Map<String, dynamic>> createPayment(
    Map<String, dynamic> data,
  ) async {
    final url = '$baseUrl/payments';
    _logRequest("POST", url, body: data);

    final response = await http.post(
      Uri.parse(url),
      headers: await getHeaders(),
      body: jsonEncode(data),
    );

    _logResponse("POST", url, response);

    if (response.statusCode == 211 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Failed to create payment');
    }
  }

  static Future<Map<String, dynamic>> updatePayment(
    int id,
    Map<String, dynamic> data,
  ) async {
    final url = '$baseUrl/payments/$id';
    _logRequest("PUT", url, body: data);

    final response = await http.put(
      Uri.parse(url),
      headers: await getHeaders(),
      body: jsonEncode(data),
    );

    _logResponse("PUT", url, response);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Failed to update payment');
    }
  }

  static Future<void> deletePayment(int id) async {
    final url = '$baseUrl/payments/$id';
    _logRequest("DELETE", url);

    final response = await http.delete(
      Uri.parse(url),
      headers: await getHeaders(),
    );

    _logResponse("DELETE", url, response);

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Failed to delete payment');
    }
  }

  static Future<Map<String, dynamic>> getDashboardStats() async {
    const url = '$baseUrl/dashboard';
    _logRequest("GET", url);

    final response = await http.get(
      Uri.parse(url),
      headers: await getHeaders(),
    );

    _logResponse("GET", url, response);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch dashboard stats');
    }
  }

  // --- EXPENSES ---
  static Future<Map<String, dynamic>> getExpenses({
    int page = 1,
    String? search,
    String? category,
    String? startDate,
    String? endDate,
  }) async {
    final queryParams = {
      'page': page.toString(),
      if (search != null && search.isNotEmpty) 'search': search,
      if (category != null && category != 'All') 'category': category,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
    };

    final uri = Uri.parse(
      '$baseUrl/expenses',
    ).replace(queryParameters: queryParams);
    final url = uri.toString();
    _logRequest("GET", url);

    final response = await http.get(uri, headers: await getHeaders());

    _logResponse("GET", url, response);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch expenses');
    }
  }

  static Future<Map<String, dynamic>> createExpense(
    Map<String, dynamic> data,
  ) async {
    final url = '$baseUrl/expenses';
    _logRequest("POST", url, body: data);

    final response = await http.post(
      Uri.parse(url),
      headers: await getHeaders(),
      body: jsonEncode(data),
    );

    _logResponse("POST", url, response);

    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Failed to create expense');
    }
  }

  static Future<Map<String, dynamic>> updateExpense(
    int id,
    Map<String, dynamic> data,
  ) async {
    final url = '$baseUrl/expenses/$id';
    _logRequest("PUT", url, body: data);

    final response = await http.put(
      Uri.parse(url),
      headers: await getHeaders(),
      body: jsonEncode(data),
    );

    _logResponse("PUT", url, response);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Failed to update expense');
    }
  }

  static Future<void> deleteExpense(int id) async {
    final url = '$baseUrl/expenses/$id';
    _logRequest("DELETE", url);

    final response = await http.delete(
      Uri.parse(url),
      headers: await getHeaders(),
    );

    _logResponse("DELETE", url, response);

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Failed to delete expense');
    }
  }

  static Future<Map<String, dynamic>> exportExpenses({
    String? category,
    String? startDate,
    String? endDate,
  }) async {
    final queryParams = {
      if (category != null && category != 'All') 'category': category,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
    };

    final uri = Uri.parse(
      '$baseUrl/expenses/export',
    ).replace(queryParameters: queryParams);
    final url = uri.toString();
    _logRequest("GET", url);

    final response = await http.get(uri, headers: await getHeaders());

    _logResponse("GET", url, response);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to export expenses');
    }
  }
}
