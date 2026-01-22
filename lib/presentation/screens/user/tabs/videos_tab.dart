import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/optimized_theme.dart';
import '../../../../data/services/cache_service.dart';
import '../category_videos_view.dart';
import '../../../widgets/category_accordion.dart';
import '../../../widgets/video_list_widget.dart';

class VideosTab extends StatefulWidget {
  final String searchQuery;
  final bool canEdit;
  final String userRole;
  
  const VideosTab({
    super.key,
    this.searchQuery = '',
    required this.canEdit,
    required this.userRole,
  });

  @override
  State<VideosTab> createState() => _VideosTabState();
}

class _VideosTabState extends State<VideosTab> {
  String? selectedCategory;
  bool showCategoryAccordion = false;
  
  final categories = {
    'Desarrollo de Software': ['Frontend', 'Backend', 'Móvil', 'Base de Datos'],
    'Marketing': ['Digital', 'Tradicional', 'Redes Sociales', 'SEO'],
    'Guía Nacional de Turismo': ['Costas', 'Sierra', 'Oriente', 'Galápagos'],
    'Arte Culinaria': ['Cocina Nacional', 'Cocina Internacional', 'Repostería', 'Bebidas'],
    'Idiomas': ['Inglés', 'Francés', 'Alemán', 'Italiano']
  };

  @override
  Widget build(BuildContext context) {
    if (selectedCategory != null) {
      return CategoryVideosView(
        category: selectedCategory!,
        onBack: () => setState(() => selectedCategory = null),
        canEdit: widget.canEdit,
        userRole: widget.userRole,
      );
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CategoryAccordion(
            categories: categories,
            showAccordion: showCategoryAccordion,
            onToggle: () => setState(() => showCategoryAccordion = !showCategoryAccordion),
            onCategorySelected: (category) => setState(() {
              selectedCategory = category;
              showCategoryAccordion = false;
            }),
          ),
          const SizedBox(height: 32),
          _buildVideoSection('Top 10 Videos', _getRecentVideos()),
          const SizedBox(height: 32),
          _buildVideoSection('Videos Recientes', _getRecentVideos()),
          const SizedBox(height: 32),
          _buildVideoSection('Videos Recomendados', _getRecentVideos().then((data) => data.take(3).toList())),
        ],
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _getRecentVideos() async {
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

  Widget _buildVideoSection(String title, Future<List<Map<String, dynamic>>> future) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: OptimizedTheme.heading3.copyWith(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        VideoListWidget(
          future: future,
          canEdit: widget.canEdit,
          userRole: widget.userRole,
          onRefresh: () => setState(() {}),
        ),
      ],
    );
  }
}