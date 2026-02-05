import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VideoDebugWidget extends StatelessWidget {
  const VideoDebugWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Videos Debug'),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _getVideos(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }
          
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }
          
          final videos = snapshot.data ?? [];
          
          if (videos.isEmpty) {
            return const Center(
              child: Text(
                'No hay videos en la base de datos',
                style: TextStyle(color: Colors.white),
              ),
            );
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: videos.length,
            itemBuilder: (context, index) {
              final video = videos[index];
              return Card(
                color: Colors.grey[900],
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        video['title'] ?? 'Sin título',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('ID: ${video['id']}', style: const TextStyle(color: Colors.grey)),
                      Text('Video ID: ${video['video_id']}', style: const TextStyle(color: Colors.grey)),
                      Text('Categoría: ${video['category']}', style: const TextStyle(color: Colors.grey)),
                      Text('Vistas: ${video['views'] ?? 0}', style: const TextStyle(color: Colors.grey)),
                      if (video['description'] != null)
                        Text('Descripción: ${video['description']}', style: const TextStyle(color: Colors.grey)),
                      if (video['thumbnail_url'] != null)
                        Text('Thumbnail: ${video['thumbnail_url']}', style: const TextStyle(color: Colors.grey)),
                      Text('Creado: ${video['created_at']}', style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _getVideos() async {
    try {
      final response = await Supabase.instance.client
          .from('videos')
          .select()
          .order('created_at', ascending: false);
      return response;
    } catch (e) {
      throw Exception('Error al cargar videos: $e');
    }
  }
}