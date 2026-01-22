import 'package:supabase_flutter/supabase_flutter.dart';

/// Servicio para inicializar datos de prueba en la base de datos
class DatabaseSeeder {
  static final _supabase = Supabase.instance.client;

  /// Siembra libros iniciales si la tabla está vacía
  static Future<void> seedBooks() async {
    try {
      final response = await _supabase
          .from('books')
          .select('id')
          .limit(1);
      
      if (response.isEmpty) {
        await _supabase.from('books').insert([
          {
            'title': 'El Quijote',
            'author': 'Miguel de Cervantes',
            'format': 'pdf',
            'description': 'La obra maestra de la literatura española',
            'created_at': DateTime.now().toIso8601String(),
          }
        ]);
        print('✅ Libros iniciales sembrados');
      }
    } catch (e) {
      print('Error seeding books: $e');
    }
  }

  /// Siembra videos iniciales si la tabla está vacía
  static Future<void> seedVideos() async {
    try {
      final response = await _supabase
          .from('videos')
          .select('id')
          .limit(1);
      
      if (response.isEmpty) {
        print('✅ Videos iniciales sembrados');
      }
    } catch (e) {
      print('Error seeding videos: $e');
    }
  }
}