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
      return CategoryBooksView(
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
        Text(
          title,
          style: OptimizedTheme.heading3.copyWith(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        BookListWidget(
          future: future,
          canEdit: widget.canEdit,
          userRole: widget.userRole,
          onRefresh: () => setState(() {}),
        ),
      ],
    );
  }
}