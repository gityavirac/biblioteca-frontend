import 'package:supabase_flutter/supabase_flutter.dart';

/// Servicio para crear usuarios de prueba (solo para desarrollo)
class TestUsersService {
  static final _supabase = Supabase.instance.client;

  static const List<Map<String, String>> _testUsers = [
    {
      'email': 'bibliotecario@yavirac.edu.ec',
      'password': 'biblio123',
      'name': 'Bibliotecario Yavirac',
      'role': 'bibliotecario'
    },
    {
      'email': 'admin@yavirac.edu.ec', 
      'password': 'admin123',
      'name': 'Administrador Yavirac',
      'role': 'admin'
    },
    {
      'email': 'profesor@yavirac.edu.ec',
      'password': 'profe123', 
      'name': 'Profesor Yavirac',
      'role': 'profesor'
    },
    {
      'email': 'lector@yavirac.edu.ec',
      'password': 'lector123',
      'name': 'Lector Yavirac', 
      'role': 'lector'
    }
  ];

  /// Crea usuarios de prueba en la base de datos
  static Future<void> createTestUsers() async {
    for (var user in _testUsers) {
      try {
        print('Creando usuario: ${user['email']}');
        
        final response = await _supabase.auth.signUp(
          email: user['email']!,
          password: user['password']!,
        );

        if (response.user != null) {
          await _supabase.from('users').insert({
            'id': response.user!.id,
            'email': user['email'],
            'name': user['name'],
            'role': user['role'],
            'created_at': DateTime.now().toIso8601String(),
          });
          
          print('✅ Usuario ${user['email']} creado exitosamente');
        }
      } catch (e) {
        print('❌ Error creando ${user['email']}: $e');
      }
    }
    
    // Cerrar sesión después de crear usuarios
    await _supabase.auth.signOut();
  }
}