import '../../../adapters/dio/contracts/http_client.dart';

import '../models/user.dart';

/// Service that fetches users from the JSONPlaceholder API.
///
/// Depends on [HttpClient] (provided by DioAdapter), NOT on Dio directly.
/// This is the key benefit of the adapter pattern.
class UserService {
  final HttpClient _http;

  UserService(this._http);

  /// Fetches all users from the API.
  Future<List<User>> getUsers() async {
    final response = await _http.get('/users');

    if (!response.isSuccess) {
      throw Exception('Failed to fetch users: ${response.statusCode}');
    }

    final List<dynamic> data = response.data as List<dynamic>;
    return data
        .map((json) => User.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Fetches a single user by ID.
  Future<User> getUser(int id) async {
    final response = await _http.get('/users/$id');

    if (!response.isSuccess) {
      throw Exception('Failed to fetch user $id: ${response.statusCode}');
    }

    return User.fromJson(response.data as Map<String, dynamic>);
  }
}
