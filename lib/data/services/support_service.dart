import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/support_request_model.dart';
import 'enum_converter.dart';

/// Servicio para gestionar solicitudes de soporte
class SupportService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Crea una nueva solicitud de soporte
  Future<bool> createRequest({
    required String title,
    required String description,
    required RequestType type,
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return false;

      await _client.from('support_requests').insert({
        'user_id': user.id,
        'title': title,
        'description': description,
        'type': EnumConverter.requestTypeToString(type),
        'status': EnumConverter.requestStatusToString(RequestStatus.pendiente),
      });

      return true;
    } catch (e) {
      print('Error creating support request: $e');
      return false;
    }
  }

  /// Obtiene las solicitudes del usuario actual
  Future<List<SupportRequest>> getUserRequests() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return [];

      final response = await _client
          .from('support_requests')
          .select('*, users(name, email)')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      return _mapToSupportRequests(response);
    } catch (e) {
      print('Error fetching user requests: $e');
      return [];
    }
  }

  /// Obtiene todas las solicitudes (solo para admins)
  Future<List<SupportRequest>> getAllRequests() async {
    try {
      final response = await _client
          .from('support_requests')
          .select('*, users(name, email)')
          .order('created_at', ascending: false);

      return _mapToSupportRequests(response);
    } catch (e) {
      print('Error fetching all requests: $e');
      return [];
    }
  }

  /// Marca una solicitud como resuelta
  Future<bool> markAsResolved(String requestId) async {
    try {
      await _client.from('support_requests').update({
        'status': EnumConverter.requestStatusToString(RequestStatus.resuelto),
        'resolved_at': DateTime.now().toIso8601String(),
      }).eq('id', requestId);

      return true;
    } catch (e) {
      print('Error marking request as resolved: $e');
      return false;
    }
  }

  /// Elimina una solicitud
  Future<bool> deleteRequest(String requestId) async {
    try {
      await _client.from('support_requests').delete().eq('id', requestId);
      return true;
    } catch (e) {
      print('Error deleting request: $e');
      return false;
    }
  }

  /// Mapea respuestas JSON a objetos SupportRequest
  List<SupportRequest> _mapToSupportRequests(List<dynamic> response) {
    return response.map<SupportRequest>((json) {
      json['user_name'] = json['users']?['name'];
      json['user_email'] = json['users']?['email'];
      return SupportRequest.fromJson(json);
    }).toList();
  }
}