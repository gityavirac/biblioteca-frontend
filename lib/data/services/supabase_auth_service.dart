import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart' as app_user;
import 'enum_converter.dart';

/// Servicio de autenticación con Supabase
class SupabaseAuthService {
  final _supabase = Supabase.instance.client;
  
  app_user.User? _currentUser;
  
  app_user.User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;

  /// Convierte string a UserRole usando EnumConverter
  app_user.UserRole _parseUserRole(String? role) {
    return EnumConverter.parseUserRole(role);
  }

  Future<bool> register(String email, String password, String name) async {
    try {
      // Validar campos
      if (email.isEmpty || password.isEmpty || name.isEmpty) {
        print('Error: Campos vacíos');
        return false;
      }

      if (password.length < 6) {
        print('Error: Contraseña debe tener al menos 6 caracteres');
        return false;
      }

      print('Intentando registrar usuario: $email');
      
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'name': name}, // Agregar metadata
      );

      print('Respuesta de signUp: ${response.user?.id}');

      if (response.user != null) {
        try {
          print('✅ Usuario creado en auth.users: ${response.user!.id}');
          
          // Insertar en public.users
          final insertResult = await _supabase.from('users').insert({
            'id': response.user!.id,
            'email': email,
            'name': name,
            'role': 'user', // Cambiar de 'lector' a 'user' para coincidir con las políticas
            'created_at': DateTime.now().toIso8601String(),
          }).select();
          
          print('✅ Usuario insertado en public.users: $insertResult');
          
        } catch (e) {
          print('❌ Error insertando usuario en tabla public.users: $e');
          // Continuar aunque falle el insert en public.users
        }

        _currentUser = app_user.User(
          id: response.user!.id,
          email: email,
          name: name,
          role: app_user.UserRole.lector, // Mantener lector en el modelo
          createdAt: DateTime.now(),
        );
        return true;
      }
    } catch (e) {
      print('Error en registro: $e');
      if (e.toString().contains('anonymous_provider_disabled')) {
        print('Error específico: Registro anónimo deshabilitado en Supabase');
      }
    }
    return false;
  }

  Future<bool> login(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        try {
          final userData = await _supabase
              .from('users')
              .select()
              .eq('id', response.user!.id)
              .single();

          _currentUser = app_user.User(
            id: response.user!.id,
            email: userData['email'],
            name: userData['name'],
            role: _parseUserRole(userData['role']),
            createdAt: DateTime.parse(userData['created_at']),
          );
        } catch (e) {
          // Si no existe en users, crear usuario básico
          _currentUser = app_user.User(
            id: response.user!.id,
            email: email,
            name: 'Usuario',
            role: app_user.UserRole.lector,
            createdAt: DateTime.now(),
          );
        }
        return true;
      }
    } catch (e) {
      print('Error en login: $e');
    }
    return false;
  }

  Future<void> resetPassword(String email) async {
    try {
      print('🔄 Enviando email de reset a: $email');
      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: 'https://bibliotecad1.netlify.app/reset-password',
      );
      print('✅ Email de reset enviado correctamente');
    } catch (e) {
      print('❌ Error enviando email de reset: $e');
      throw e;
    }
  }

  Future<void> logout() async {
    await _supabase.auth.signOut();
    _currentUser = null;
  }
}