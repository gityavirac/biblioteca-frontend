import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/optimized_theme.dart';
import '../../../../data/services/cache_service.dart';
import '../category_videos_view.dart';
import '../mobile_video_player.dart';
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
  Map<String, List<String>> categories = {};
  bool _loadingCategories = true;
  String? _showAllTitle;
  Future<List<Map<String, dynamic>>>? _showAllFuture;
  
  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final response = await Supabase.instance.client
          .from('categories')
          .select()
          .eq('is_active', true)
          .order('name');
      
      setState(() {
        categories = {};
        for (var category in response) {
          categories[category['name']] = ['General']; // Subcategoría por defecto
        }
        _loadingCategories = false;
      });
    } catch (e) {
      print('Error cargando categorías: $e');
      setState(() => _loadingCategories = false);
    }
  }

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

    if (_showAllTitle != null && _showAllFuture != null) {
      return _AllVideosView(
        title: _showAllTitle!,
        onBack: () => setState(() {
          _showAllTitle = null;
          _showAllFuture = null;
        }),
      );
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_loadingCategories)
            const Center(child: CircularProgressIndicator(color: Colors.white))
          else
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: OptimizedTheme.heading3.copyWith(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              onPressed: () => setState(() {
                _showAllTitle = title;
                _showAllFuture = future;
              }),
              icon: const Icon(Icons.grid_view, color: Colors.white70, size: 16),
              label: const Text('Ver todos', style: TextStyle(color: Colors.white70, fontSize: 13)),
            ),
          ],
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

class _AllVideosView extends StatelessWidget {
  final String title;
  final VoidCallback onBack;

  const _AllVideosView({required this.title, required this.onBack});

  Future<List<Map<String, dynamic>>> _loadAll() async {
    try {
      return await Supabase.instance.client
          .from('videos')
          .select()
          .order('created_at', ascending: false);
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
                  Text('Volver', style: OptimizedTheme.bodyText),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(title, style: OptimizedTheme.heading3.copyWith(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _loadAll(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Colors.white));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(child: Text('No hay videos disponibles', style: OptimizedTheme.bodyTextSmall));
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
                      MaterialPageRoute(builder: (_) => MobileVideoPlayer(video: video)),
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
                                style: OptimizedTheme.caption.copyWith(fontSize: 11, fontWeight: FontWeight.w600),
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