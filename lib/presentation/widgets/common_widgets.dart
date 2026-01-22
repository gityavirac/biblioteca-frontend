import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../screens/user/book_detail_screen.dart';
import '../screens/user/mobile_video_player.dart';

// Widgets const reutilizables
class AppWidgets {
  static const loadingIndicator = Center(
    child: CircularProgressIndicator(color: Colors.white),
  );
  
  static const noDataText = Center(
    child: Text(
      'Cargando contenido...',
      style: TextStyle(color: Colors.white70),
    ),
  );
}

// Widget optimizado para tarjetas de videos
class VideoCard extends StatelessWidget {
  final Map<String, dynamic> video;
  final double width;
  final double height;
  
  const VideoCard({
    super.key,
    required this.video,
    this.width = 140,
    this.height = 200,
  });
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MobileVideoPlayer(video: video),
        ),
      ),
      child: GlassmorphicContainer(
        width: width,
        height: height,
        borderRadius: 12,
        blur: 10,
        alignment: Alignment.center,
        border: 0,
        linearGradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
        ),
        borderGradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.2),
            Colors.white.withOpacity(0.1),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: video['thumbnail_url'] != null
                        ? Image.network(
                            video['thumbnail_url'],
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Center(
                              child: Icon(Icons.video_library, size: 40, color: Colors.white54),
                            ),
                          )
                        : const Center(
                            child: Icon(Icons.video_library, size: 40, color: Colors.white54),
                          ),
                  ),
                  const Center(
                    child: Icon(
                      Icons.play_circle_filled,
                      size: 30,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        video['title'] ?? 'Sin título',
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Flexible(
                      child: Text(
                        video['channel'] ?? 'Canal desconocido',
                        style: GoogleFonts.outfit(
                          fontSize: 8,
                          color: Colors.white70,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget optimizado para tarjetas de libros
class BookCard extends StatelessWidget {
  final Map<String, dynamic> book;
  final double width;
  final double height;
  
  const BookCard({
    super.key,
    required this.book,
    this.width = 140,
    this.height = 200,
  });
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BookDetailScreen(book: book),
        ),
      ),
      child: GlassmorphicContainer(
        width: width,
        height: height,
        borderRadius: 12,
        blur: 10,
        alignment: Alignment.center,
        border: 0,
        linearGradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
        ),
        borderGradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.2),
            Colors.white.withOpacity(0.1),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: book['cover_url'] != null
                    ? Image.network(
                        book['cover_url'],
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Icon(Icons.book, size: 40, color: Colors.white54),
                        ),
                      )
                    : const Center(
                        child: Icon(Icons.book, size: 40, color: Colors.white54),
                      ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        book['title'] ?? 'Sin título',
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Flexible(
                      child: Text(
                        book['author'] ?? 'Autor desconocido',
                        style: GoogleFonts.outfit(
                          fontSize: 8,
                          color: Colors.white70,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget para listas horizontales de contenido (libros y videos)
class HorizontalBookList extends StatelessWidget {
  final Future<List<Map<String, dynamic>>> future;
  final String searchQuery;
  final bool isVideoList;
  
  const HorizontalBookList({
    super.key,
    required this.future,
    this.searchQuery = '',
    this.isVideoList = false,
  });
  
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return AppWidgets.loadingIndicator;
          }
          
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return AppWidgets.noDataText;
          }
          
          final items = _filterItems(snapshot.data!);
          
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: isVideoList 
                    ? VideoCard(video: items[index])
                    : BookCard(book: items[index]),
              );
            },
          );
        },
      ),
    );
  }
  
  List<Map<String, dynamic>> _filterItems(List<Map<String, dynamic>> items) {
    if (searchQuery.isEmpty) return items;
    
    return items.where((item) {
      final title = (item['title'] ?? '').toString().toLowerCase();
      final author = (item['author'] ?? item['channel'] ?? '').toString().toLowerCase();
      final query = searchQuery.toLowerCase();
      return title.contains(query) || author.contains(query);
    }).toList();
  }
}

// Widget para placeholder de carga
class LoadingPlaceholder extends StatelessWidget {
  final String message;
  
  const LoadingPlaceholder({
    super.key,
    this.message = 'Cargando contenido...',
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Colors.white),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.outfit(color: Colors.white70, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

// Servicio para datos optimizado
class DataService {
  static Future<List<Map<String, dynamic>>> getTopBooks() async {
    try {
      final response = await Supabase.instance.client
          .from('books')
          .select()
          .order('created_at', ascending: false)
          .limit(10);
      return response;
    } catch (e) {
      return [];
    }
  }
  
  static Future<List<Map<String, dynamic>>> getRecentBooks() async {
    try {
      final response = await Supabase.instance.client
          .from('books')
          .select()
          .order('created_at', ascending: false)
          .limit(20);
      return response;
    } catch (e) {
      return [];
    }
  }
  
  static Future<List<Map<String, dynamic>>> getRecentVideos() async {
    try {
      final response = await Supabase.instance.client
          .from('videos')
          .select()
          .order('created_at', ascending: false)
          .limit(20);
      return response;
    } catch (e) {
      return [];
    }
  }
}