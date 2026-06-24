import '../api/api_client.dart';

/// Gestión de usuarios vía API HTTP (solo staff/admin según el backend).
class UserService {
  final _api = ApiClient.instance;

  Future<List<Map<String, dynamic>>> getUsers() async {
    try {
      return await _api.getList('/users');
    } catch (e) {
      print('Error fetching users: $e');
      return [];
    }
  }

  Future<void> updateRole(String id, String role) async {
    await _api.patch('/users/$id', data: {'role': role});
  }

  Future<void> deleteUser(String id) async {
    await _api.delete('/users/$id');
  }
}
