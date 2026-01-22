import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:glassmorphism/glassmorphism.dart';
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

  final categories = const {
    'Desarrollo de Software': ['Frontend', 'Backend', 'Móvil', 'Base de Datos'],
    'Marketing': ['Digital', 'Tradicional', 'Redes Sociales', 'SEO'],
    'Guía Nacional de Turismo': ['Costas', 'Sierra', 'Oriente', 'Galápagos'],
    'Arte Culinaria': ['Cocina Nacional', 'Cocina Internacional', 'Repostería', 'Bebidas'],
    'Idiomas': ['Inglés', 'Francés', 'Alemán', 'Italiano']
  };

  Future<List<Map<String, dynamic>>> _loadVideosBySubcategory(String category, String subcategory) async {
    try {
      final response = await Supabase.instance.client
          .from('videos')
          .select()
          .eq('category', category)
          .eq('subcategory', subcategory);
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
          // Botón volver
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
          
          // Título de categoría
          Text(
            category,
            style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 24),
          
          // Subcategorías
          ...categories[category]!.map((subcategory) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subcategory,
                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
                ),
                const SizedBox(height: 12),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _loadVideosBySubcategory(category, subcategory),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator(color: Colors.white)));
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return SizedBox(
                        height: 100,
                        child: Center(
                          child: Text('No hay videos en esta subcategoría', style: GoogleFonts.outfit(color: Colors.white70)),
                        ),
                      );
                    }
                    return SizedBox(
                      height: 200,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) {
                          final video = snapshot.data![index];
                          return Container(
                            width: 280,
                            margin: const EdgeInsets.only(right: 16),
                            child: GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MobileVideoPlayer(video: video),
                                ),
                              ),
                              child: GlassmorphicContainer(
                                width: double.infinity,
                                height: double.infinity,
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
                                      flex: 2,
                                      child: ClipRRect(
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                        child: video['thumbnail_url'] != null
                                            ? Image.network(
                                                video['thumbnail_url'],
                                                width: double.infinity,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) => Container(
                                                  color: Colors.grey.shade800,
                                                  child: const Icon(Icons.video_library, size: 40, color: Colors.white54),
                                                ),
                                              )
                                            : Container(
                                                color: Colors.grey.shade800,
                                                child: const Icon(Icons.video_library, size: 40, color: Colors.white54),
                                              ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Flexible(
                                              child: Text(
                                                video['title'] ?? 'Sin título',
                                                style: GoogleFonts.outfit(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.white,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (video['views'] != null)
                                              Flexible(
                                                child: Text(
                                                  '${video['views']} vistas',
                                                  style: GoogleFonts.outfit(
                                                    fontSize: 9,
                                                    color: Colors.white54,
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
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }
}