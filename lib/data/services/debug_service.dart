import 'package:supabase_flutter/supabase_flutter.dart';

/// Servicio de debug para desarrollo (solo usar en modo debug)
class DebugService {
  static final _supabase = Supabase.instance.client;

  /// Muestra información de debug sobre el usuario actual y sus favoritos
  static Future<void> debugUserInfo() async {
    final user = _supabase.auth.currentUser;
    
    if (user == null) {
      print('❌ No hay usuario autenticado');
      return;
    }

    print('🔍 === DEBUG INFO ===');
    print('👤 Usuario ID: ${user.id}');
    print('📧 Email: ${user.email}');
    
    try {
      // Obtener datos del usuario desde la tabla users
      final userData = await _supabase
          .from('users')
          .select('name, role')
          .eq('id', user.id)
          .single();
      
      print('👤 Nombre: ${userData['name']}');
      print('🎭 Rol: ${userData['role']}');
      
      // Obtener favoritos del usuario
      final favorites = await _supabase
          .from('favorites')
          .select('book_id, books(title)')
          .eq('user_id', user.id);
      
      print('❤️ Favoritos (${favorites.length}):');
      for (var fav in favorites) {
        final bookTitle = fav['books']['title'] ?? 'Sin título';
        print('  - $bookTitle (ID: ${fav['book_id']})');
      }
      
    } catch (e) {
      print('❌ Error obteniendo datos: $e');
    }
    
    print('🔍 === FIN DEBUG ===');
  }

  /// Limpia todos los favoritos del usuario actual (solo para debug)
  static Future<void> clearUserFavorites() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      print('❌ No hay usuario autenticado');
      return;
    }

    try {
      await _supabase
          .from('favorites')
          .delete()
          .eq('user_id', user.id);
      
      print('🗑️ Favoritos del usuario ${user.email} eliminados');
    } catch (e) {
      print('❌ Error eliminando favoritos: $e');
    }
  }
}