import 'package:supabase_flutter/supabase_flutter.dart';

/// Servicio para gestionar favoritos del usuario
class FavoritesService {
  final _supabase = Supabase.instance.client;

  /// Agrega un libro a favoritos
  Future<void> addToFavorites(String bookId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Usuario no autenticado');

    try {
      await _supabase.from('favorites').insert({
        'user_id': userId,
        'book_id': bookId,
      });
    } catch (e) {
      print('Error adding to favorites: $e');
      rethrow;
    }
  }

  /// Elimina un libro de favoritos
  Future<void> removeFromFavorites(String bookId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Usuario no autenticado');

    try {
      await _supabase
          .from('favorites')
          .delete()
          .eq('user_id', userId)
          .eq('book_id', bookId);
    } catch (e) {
      print('Error removing from favorites: $e');
      rethrow;
    }
  }

  /// Obtiene la lista de IDs de libros favoritos del usuario
  Future<List<String>> getUserFavorites() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      final response = await _supabase
          .from('favorites')
          .select('book_id')
          .eq('user_id', userId);

      return List<String>.from(response.map((item) => item['book_id']));
    } catch (e) {
      print('Error fetching favorites: $e');
      return [];
    }
  }

  /// Verifica si un libro está en favoritos
  Future<bool> isFavorite(String bookId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;

    try {
      final response = await _supabase
          .from('favorites')
          .select('id')
          .eq('user_id', userId)
          .eq('book_id', bookId)
          .limit(1);

      return response.isNotEmpty;
    } catch (e) {
      print('Error checking favorite: $e');
      return false;
    }
  }
}