import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'mobile_video_player.dart';

class CategoryVideosView extends StatelessWidget {
  final String category;
  final VoidCallback onBack;
  final bool canEdit;
  final String userRole;

  const CategoryVideosView({
    super.key,
    required this.category,
    required this.onBack,
    required this.canEdit,
    required this.userRole,
  });

  Future<List<Map<String, dynamic>>> _loadVideosByCategory() async {
    try {
      final response = await Supabase.instance.client
          .from('videos')
          .select()
          .eq('category', category)
          .order('created_at', ascending: false);
      return response;
    } catch (e) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onBack,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text('Volver', style: GoogleFonts.outfit(color: Colors.white)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            category,
            style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 24),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _loadVideosByCategory(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Colors.white));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Text('No hay videos en esta categoría', style: GoogleFonts.outfit(color: Colors.white70)),
                );
              }
              final videos = snapshot.data!;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: MediaQuery.of(context).size.width > 900 ? 4 : 2,
                  childAspectRatio: 1.4,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: videos.length,
                itemBuilder: (context, index) {
                  final video = videos[index];
                  return GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MobileVideoPlayer(video: video),
                      ),
                    ),
                    child: Card(
                      color: Colors.white.withOpacity(0.1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        children: [
                          Expanded(
                            flex: 3,
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                              child: video['thumbnail_url'] != null
                                  ? Image.network(
                                      video['thumbnail_url'],
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        color: Colors.grey.shade800,
                                        child: const Icon(Icons.video_library, size: 30, color: Colors.white54),
                                      ),
                                    )
                                  : Container(
                                      color: Colors.grey.shade800,
                                      child: const Icon(Icons.video_library, size: 30, color: Colors.white54),
                                    ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: Text(
                                video['title'] ?? 'Sin título',
                                style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}