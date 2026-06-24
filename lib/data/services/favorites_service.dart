import '../api/api_client.dart';

/// Servicio para gestionar favoritos del usuario (vía API HTTP).
class FavoritesService {
  final _api = ApiClient.instance;

  /// Agrega un libro a favoritos
  Future<void> addToFavorites(String bookId) async {
    await _api.post('/favorites', data: {'bookId': bookId});
  }

  /// Elimina un libro de favoritos
  Future<void> removeFromFavorites(String bookId) async {
    await _api.delete('/favorites/$bookId');
  }

  /// Obtiene la lista de IDs de libros favoritos del usuario
  Future<List<String>> getUserFavorites() async {
    try {
      final data = await _api.get('/favorites');
      return List<String>.from(data as List);
    } catch (e) {
      print('Error fetching favorites: $e');
      return [];
    }
  }

  /// Verifica si un libro está en favoritos
  Future<bool> isFavorite(String bookId) async {
    try {
      final data = await _api.getMap('/favorites/$bookId');
      return data['isFavorite'] == true;
    } catch (e) {
      print('Error checking favorite: $e');
      return false;
    }
  }
}
