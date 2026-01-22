import 'package:supabase_flutter/supabase_flutter.dart';
import 'cache_service.dart';

/// Servicio para registrar y obtener estadísticas de lectura
class StatsService {
  final _supabase = Supabase.instance.client;
  
  static const String _recentBooksKey = 'recent_books_stats';
  static const String _topBooksKey = 'top_books_stats';

  /// Registra la apertura de un libro
  Future<void> recordBookOpen(String bookId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      // Registrar en historial
      await _supabase.from('book_opens_history').insert({
        'book_id': bookId,
        'user_id': userId,
      });

      // Actualizar contador
      await _supabase.rpc('increment_book_opens', params: {'book_id': bookId});
      
      // Invalidar caché
      CacheService.remove(_topBooksKey);
    } catch (e) {
      print('Error recording book open: $e');
    }
  }

  /// Actualiza el progreso de lectura del usuario
  Future<void> updateReadingProgress(String bookId, int progress) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await _supabase.from('reading_history').upsert({
        'user_id': userId,
        'book_id': bookId,
        'progress': progress,
        'last_read': DateTime.now().toIso8601String(),
      });
      
      // Invalidar caché
      CacheService.remove(_recentBooksKey);
    } catch (e) {
      print('Error updating reading progress: $e');
    }
  }

  /// Obtiene los libros recientemente leídos por el usuario actual
  Future<List<Map<String, dynamic>>> getRecentBooks() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    // Verificar caché
    final cached = CacheService.get<List<Map<String, dynamic>>>(_recentBooksKey);
    if (cached != null) return cached;

    try {
      final response = await _supabase
          .from('reading_history')
          .select('book_id, books(*)')
          .eq('user_id', userId)
          .order('last_read', ascending: false)
          .limit(10);

      final result = List<Map<String, dynamic>>.from(response);
      CacheService.set(_recentBooksKey, result);
      return result;
    } catch (e) {
      print('Error fetching recent books: $e');
      return [];
    }
  }

  /// Obtiene los libros más populares
  Future<List<Map<String, dynamic>>> getTopBooks() async {
    // Verificar caché
    final cached = CacheService.get<List<Map<String, dynamic>>>(_topBooksKey);
    if (cached != null) return cached;

    try {
      final response = await _supabase
          .from('book_stats')
          .select('book_id, open_count, books(*)')
          .order('open_count', ascending: false)
          .limit(10);

      final result = List<Map<String, dynamic>>.from(response);
      CacheService.set(_topBooksKey, result);
      return result;
    } catch (e) {
      print('Error fetching top books: $e');
      return [];
    }
  }
}