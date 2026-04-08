import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart' as app_user;
import 'enum_converter.dart';

/// Servicio de autenticación con Supabase
class SupabaseAuthService {
  final _supabase = Supabase.instance.client;
  
  String? lastError;
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

      // Verificar si el correo ya existe en public.users
      final existing = await _supabase
          .from('users')
          .select('id')
          .eq('email', email)
          .maybeSingle();

      if (existing != null) {
        lastError = 'User already registered';
        return false;
      }

      print('Intentando registrar usuario: $email');

      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'name': name},
      );

      if (response.user != null) {
        try {
          await _supabase.from('users').insert({
            'id': response.user!.id,
            'email': email,
            'name': name,
            'role': 'lector',
            'created_at': DateTime.now().toIso8601String(),
          });
        } catch (e) {
          print('❌ Error insertando en public.users: $e');
          lastError = e.toString();
          return false;
        }

        _currentUser = app_user.User(
          id: response.user!.id,
          email: email,
          name: name,
          role: app_user.UserRole.lector,
          createdAt: DateTime.now(),
        );
        return true;
      }
    } catch (e) {
      print('Error en registro: $e');
      lastError = e.toString();
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

          // Verificar si el usuario está desactivado
          if (userData['is_active'] == false) {
            await _supabase.auth.signOut();
            lastError = 'USUARIO_DESACTIVADO';
            return false;
          }

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