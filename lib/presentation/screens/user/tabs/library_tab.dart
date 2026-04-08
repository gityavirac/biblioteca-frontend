import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:glassmorphism/glassmorphism.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/optimized_theme.dart';
import '../../../../core/services/optimized_cache_service.dart';
import '../../../../core/widgets/optimized_list_view.dart';
import '../book_detail_screen.dart';
import '../category_books_view.dart';
import '../../../widgets/category_accordion.dart';
import '../../../widgets/book_list_widget.dart';

class LibraryTab extends StatefulWidget {
  final String searchQuery;
  final bool canEdit;
  final String userRole;
  
  const LibraryTab({
    super.key,
    this.searchQuery = '',
    required this.canEdit,
    required this.userRole,
  });

  @override
  State<LibraryTab> createState() => _LibraryTabState();
}

class _LibraryTabState extends State<LibraryTab> {
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
          .select('name, subcategories(name)')
          .eq('is_active', true)
          .order('name');
      
      setState(() {
        categories = {};
        for (var cat in response) {
          final subs = (cat['subcategories'] as List)
              .map((s) => s['name'] as String)
              .toList();
          categories[cat['name'] as String] = subs.isEmpty ? ['General'] : subs;
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
      return CategoryBooksView(
        category: selectedCategory!,
        onBack: () => setState(() => selectedCategory = null),
        canEdit: widget.canEdit,
        userRole: widget.userRole,
      );
    }

    if (_showAllTitle != null && _showAllFuture != null) {
      return _AllBooksView(
        title: _showAllTitle!,
        future: _showAllFuture!,
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
          _buildBookSection('Top 10 Libros', _getTopBooks()),
          const SizedBox(height: 32),
          _buildBookSection('Libros Recientes', _getRecentBooks()),
          const SizedBox(height: 32),
          _buildBookSection('Libros Sugeridos', _getRecentBooks().then((data) => data.take(5).toList())),
        ],
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _getTopBooks() async {
    const cacheKey = 'top_books';
    
    // Verificar caché primero
    final cached = await OptimizedCacheService.instance.get<List<Map<String, dynamic>>>(cacheKey);
    if (cached != null) return cached;
    
    try {
      final response = await Supabase.instance.client
          .from('books')
          .select()
          .order('created_at', ascending: false)
          .limit(10);
      
      // Guardar en caché
      await OptimizedCacheService.instance.set(cacheKey, response);
      return response;
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _getRecentBooks() async {
    const cacheKey = 'recent_books';
    
    final cached = await OptimizedCacheService.instance.get<List<Map<String, dynamic>>>(cacheKey);
    if (cached != null) return cached;
    
    try {
      final response = await Supabase.instance.client
          .from('books')
          .select()
          .order('created_at', ascending: false)
          .limit(20);
      
      await OptimizedCacheService.instance.set(cacheKey, response);
      return response;
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _getBooksWithPagination(int page, int limit) async {
    final cacheKey = 'books_page_${page}_$limit';
    
    final cached = await OptimizedCacheService.instance.get<List<Map<String, dynamic>>>(cacheKey);
    if (cached != null) return cached;
    
    try {
      final response = await Supabase.instance.client
          .from('books')
          .select()
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false)
          .range(page * limit, (page + 1) * limit - 1);
      
      await OptimizedCacheService.instance.set(cacheKey, response);
      return response;
    } catch (e) {
      return [];
    }
  }

  Widget _buildBookSection(String title, Future<List<Map<String, dynamic>>> future) {
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
        BookListWidget(
          future: future,
          canEdit: widget.canEdit,
          userRole: widget.userRole,
          onRefresh: () async {
            await OptimizedCacheService.instance.remove('top_books');
            await OptimizedCacheService.instance.remove('recent_books');
            OptimizedCacheService.instance.clearMemory();
            setState(() {});
          },
        ),
      ],
    );
  }
}

class _AllBooksView extends StatelessWidget {
  final String title;
  final Future<List<Map<String, dynamic>>> future;
  final VoidCallback onBack;

  const _AllBooksView({
    required this.title,
    required this.future,
    required this.onBack,
  });

  Future<List<Map<String, dynamic>>> _getAllBooks() async {
    try {
      final response = await Supabase.instance.client
          .from('books')
          .select()
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
                  Text('Volver', style: OptimizedTheme.bodyText),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(title, style: OptimizedTheme.heading3.copyWith(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _getAllBooks(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Colors.white));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(child: Text('No hay libros disponibles', style: OptimizedTheme.bodyTextSmall));
              }
              final books = snapshot.data!;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: MediaQuery.of(context).size.width > 900 ? 6 : 3,
                  childAspectRatio: 0.7,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: books.length,
                itemBuilder: (context, index) {
                  final book = books[index];
                  return GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => BookDetailScreen(book: book)),
                    ),
                    child: Card(
                      color: Colors.white.withOpacity(0.1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                              child: book['cover_url'] != null
                                  ? Image.network(
                                      book['cover_url'],
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.book, size: 30, color: Colors.white54)),
                                    )
                                  : const Center(child: Icon(Icons.book, size: 30, color: Colors.white54)),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(6),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  book['title'] ?? 'Sin título',
                                  style: OptimizedTheme.caption.copyWith(fontSize: 11, fontWeight: FontWeight.w600),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  book['author'] ?? '',
                                  style: OptimizedTheme.caption.copyWith(fontSize: 9, color: Colors.white70),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
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