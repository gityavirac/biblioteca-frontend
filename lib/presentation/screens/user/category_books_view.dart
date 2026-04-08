import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'book_detail_screen.dart';

class CategoryBooksView extends StatefulWidget {
  final String category;
  final VoidCallback onBack;
  final bool canEdit;
  final String userRole;

  const CategoryBooksView({
    super.key,
    required this.category,
    required this.onBack,
    required this.canEdit,
    required this.userRole,
  });

  @override
  State<CategoryBooksView> createState() => _CategoryBooksViewState();
}

class _CategoryBooksViewState extends State<CategoryBooksView> {
  List<String> _subcategories = [];
  String? _selectedSubcategory; // null = todas

  @override
  void initState() {
    super.initState();
    _loadSubcategories();
  }

  Future<void> _loadSubcategories() async {
    try {
      final catData = await Supabase.instance.client
          .from('categories')
          .select('id')
          .eq('name', widget.category)
          .eq('is_active', true)
          .maybeSingle();

      if (catData == null) return;

      final subs = await Supabase.instance.client
          .from('subcategories')
          .select('name')
          .eq('category_id', catData['id'])
          .eq('is_active', true)
          .order('name');

      if (mounted) {
        setState(() {
          _subcategories = (subs as List).map((s) => s['name'] as String).toList();
        });
      }
    } catch (e) {
      // sin subcategorías
    }
  }

  Future<List<Map<String, dynamic>>> _loadBooks() async {
    try {
      var query = Supabase.instance.client
          .from('books')
          .select()
          .eq('category', widget.category)
          .isFilter('deleted_at', null);

      if (_selectedSubcategory != null) {
        query = query.eq('subcategory', _selectedSubcategory!);
      }

      final response = await query.order('created_at', ascending: false);
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
            onTap: widget.onBack,
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
            widget.category,
            style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          // Filtros de subcategoría
          if (_subcategories.isNotEmpty) ...[
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildChip('Todos', null),
                  ..._subcategories.map((s) => _buildChip(s, s)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _loadBooks(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Colors.white));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Text('No hay libros en esta categoría', style: GoogleFonts.outfit(color: Colors.white70)),
                );
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
                      MaterialPageRoute(
                        builder: (_) => BookDetailScreen(book: book),
                      ),
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
                                      errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.book, size: 40, color: Colors.white54)),
                                    )
                                  : const Center(child: Icon(Icons.book, size: 40, color: Colors.white54)),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  book['title'] ?? 'Sin título',
                                  style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  book['author'] ?? '',
                                  style: GoogleFonts.outfit(fontSize: 10, color: Colors.white70),
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

  Widget _buildChip(String label, String? value) {
    final isSelected = _selectedSubcategory == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedSubcategory = value),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.orange : Colors.white.withOpacity(0.3),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}