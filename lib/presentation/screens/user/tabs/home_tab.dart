import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/optimized_theme.dart';
import '../../../../data/services/cache_service.dart';
import '../../../widgets/common_widgets.dart';

class HomeTab extends StatefulWidget {
  final String searchQuery;
  
  const HomeTab({super.key, this.searchQuery = ''});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  String? _showAllTitle;
  bool _showAllIsVideo = false;

  @override
  Widget build(BuildContext context) {
    if (_showAllTitle != null) {
      return _AllContentView(
        title: _showAllTitle!,
        isVideo: _showAllIsVideo,
        onBack: () => setState(() => _showAllTitle = null),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeHeader(),
          const SizedBox(height: 32),
          _buildTopBooksSection(),
          const SizedBox(height: 32),
          _buildSection('Libros Recientes', DataService.getRecentBooks()),
          const SizedBox(height: 24),
          _buildSection('Videos Recientes', DataService.getRecentVideos(), isVideo: true),
        ],
      ),
    );
  }
  
  Widget _buildWelcomeHeader() {
    return FadeInDown(
      child: Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [AppColors.primaryShadow],
        ),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '¡Bienvenido!',
                      style: OptimizedTheme.heading1.copyWith( // Header siempre tiene fondo oscuro (gradient), mantener blanco
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Descubre miles de libros y videos educativos',
                      style: OptimizedTheme.bodyText.copyWith( // Header mantiene blanco
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/images/1.jpeg',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.white.withOpacity(0.1),
                      child: const Icon(Icons.auto_stories, size: 40, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildTopBooksSection() {
    return GlassmorphicContainer(
      width: double.infinity,
      height: 300,
      borderRadius: 20,
      blur: 15,
      alignment: Alignment.center,
      border: 0,
      linearGradient: LinearGradient(
        colors: [
          Colors.white.withOpacity(0.05),
          Colors.white.withOpacity(0.02),
        ],
      ),
      borderGradient: LinearGradient(
        colors: [
          Colors.white.withOpacity(0.1),
          Colors.white.withOpacity(0.05),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.yaviracOrange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.trending_up, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Top 10 Más Leídos',
                      style: OptimizedTheme.heading3.copyWith(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () => setState(() {
                    _showAllTitle = 'Top 10 Más Leídos';
                    _showAllIsVideo = false;
                  }),
                  icon: const Icon(Icons.grid_view, color: Colors.white70, size: 16),
                  label: const Text('Ver todos', style: TextStyle(color: Colors.white70, fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: HorizontalBookList(
                future: DataService.getTopBooks(),
                searchQuery: widget.searchQuery,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSection(String title, Future<List<Map<String, dynamic>>> future, {bool isVideo = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
            ),
            TextButton.icon(
              onPressed: () => setState(() {
                _showAllTitle = title;
                _showAllIsVideo = isVideo;
              }),
              icon: const Icon(Icons.grid_view, color: Colors.white70, size: 16),
              label: const Text('Ver todos', style: TextStyle(color: Colors.white70, fontSize: 13)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        HorizontalBookList(
          future: future,
          searchQuery: widget.searchQuery,
          isVideoList: isVideo,
        ),
      ],
    );
  }
}

class _AllContentView extends StatelessWidget {
  final String title;
  final bool isVideo;
  final VoidCallback onBack;

  const _AllContentView({
    required this.title,
    required this.isVideo,
    required this.onBack,
  });

  Future<List<Map<String, dynamic>>> _loadAll() async {
    try {
      if (isVideo) {
        return await Supabase.instance.client
            .from('videos')
            .select()
            .order('created_at', ascending: false);
      } else {
        return await Supabase.instance.client
            .from('books')
            .select()
            .order('created_at', ascending: false);
      }
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
                return Center(child: Text('No hay contenido disponible', style: OptimizedTheme.bodyTextSmall));
              }
              final items = snapshot.data!;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: MediaQuery.of(context).size.width > 900
                      ? (isVideo ? 4 : 6)
                      : (isVideo ? 2 : 3),
                  childAspectRatio: isVideo ? 1.4 : 0.7,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  return isVideo
                      ? VideoCard(video: items[index])
                      : BookCard(book: items[index]);
                },
              );
            },
          ),
        ],
      ),
    );
  }
}