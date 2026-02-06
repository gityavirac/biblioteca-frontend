import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:glassmorphism/glassmorphism.dart';
import '../../data/services/cache_service.dart';
import '../screens/user/book_detail_screen.dart';

class BookListWidget extends StatelessWidget {
  final Future<List<Map<String, dynamic>>> future;
  final bool canEdit;
  final String userRole;
  final VoidCallback onRefresh;

  const BookListWidget({
    super.key,
    required this.future,
    required this.canEdit,
    required this.userRole,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator(color: Colors.white)));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return SizedBox(height: 200, child: Center(child: Text('No hay libros disponibles', style: GoogleFonts.outfit(color: Colors.white70))));
        }
        return _buildBookList(snapshot.data!, context);
      },
    );
  }

  Widget _buildBookList(List<Map<String, dynamic>> books, BuildContext context) {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: books.length,
        itemBuilder: (context, index) {
          final book = books[index];
          return Container(
            width: 160,
            margin: const EdgeInsets.only(right: 16),
            child: Stack(
              children: [
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BookDetailScreen(book: book),
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
                        Container(
                          height: 120,
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
                        Container(
                          height: 60,
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  book['title'] ?? 'Sin título',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                    height: 1.2,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text(
                                  book['author'] ?? 'Autor desconocido',
                                  style: GoogleFonts.outfit(
                                    fontSize: 9,
                                    color: Colors.white70,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (canEdit && (userRole == 'bibliotecario' || userRole == 'admin' || 
                    (userRole == 'profesor' && book['created_by'] == Supabase.instance.client.auth.currentUser?.id)))
                  Positioned(
                    top: 4,
                    right: 4,
                    child: PopupMenuButton<String>(
                      icon: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.more_vert, color: Colors.white, size: 16),
                      ),
                      onSelected: (value) => _handleMenuAction(value, book, context),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 16),
                              SizedBox(width: 8),
                              Text('Editar'),
                            ],
                          ),
                        ),
                        if (userRole == 'admin' || (userRole == 'profesor' && book['created_by'] == Supabase.instance.client.auth.currentUser?.id))
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 16, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Eliminar', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _handleMenuAction(String action, Map<String, dynamic> book, BuildContext context) {
    if (action == 'edit') {
      _showEditDialog(context, book);
    } else if (action == 'delete' && (userRole == 'admin' || (userRole == 'profesor' && book['created_by'] == Supabase.instance.client.auth.currentUser?.id))) {
      _showDeleteDialog(context, book);
    }
  }

  void _showEditDialog(BuildContext context, Map<String, dynamic> book) {
    final titleController = TextEditingController(text: book['title'] ?? '');
    final authorController = TextEditingController(text: book['author'] ?? '');
    final descriptionController = TextEditingController(text: book['description'] ?? '');
    final fileUrlController = TextEditingController(text: book['file_url'] ?? '');
    final coverUrlController = TextEditingController(text: book['cover_url'] ?? '');
    final isbnController = TextEditingController(text: book['isbn'] ?? '');
    final yearController = TextEditingController(text: book['year']?.toString() ?? '');
    final locationController = TextEditingController(text: book['physical_location'] ?? '');
    
    String selectedFormat = book['format'] ?? 'pdf';
    String selectedCategory = book['category'] ?? 'General';
    bool isPhysical = book['is_physical'] ?? false;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: Text('Editar Libro', style: GoogleFonts.outfit(color: Colors.white)),
          content: SizedBox(
            width: 500,
            height: 600,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: titleController,
                    style: GoogleFonts.outfit(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Título',
                      labelStyle: GoogleFonts.outfit(color: Colors.white70),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white.withOpacity(0.3))),
                      focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.orange)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: authorController,
                    style: GoogleFonts.outfit(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Autor',
                      labelStyle: GoogleFonts.outfit(color: Colors.white70),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white.withOpacity(0.3))),
                      focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.orange)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    maxLines: 3,
                    style: GoogleFonts.outfit(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Descripción',
                      labelStyle: GoogleFonts.outfit(color: Colors.white70),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white.withOpacity(0.3))),
                      focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.orange)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: fileUrlController,
                    style: GoogleFonts.outfit(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'URL del archivo',
                      labelStyle: GoogleFonts.outfit(color: Colors.white70),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white.withOpacity(0.3))),
                      focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.orange)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: coverUrlController,
                    style: GoogleFonts.outfit(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'URL de la portada',
                      labelStyle: GoogleFonts.outfit(color: Colors.white70),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white.withOpacity(0.3))),
                      focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.orange)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: isbnController,
                    style: GoogleFonts.outfit(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'ISBN',
                      labelStyle: GoogleFonts.outfit(color: Colors.white70),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white.withOpacity(0.3))),
                      focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.orange)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: yearController,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.outfit(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Año',
                      labelStyle: GoogleFonts.outfit(color: Colors.white70),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white.withOpacity(0.3))),
                      focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.orange)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedFormat,
                    style: GoogleFonts.outfit(color: Colors.white),
                    dropdownColor: const Color(0xFF1E293B),
                    decoration: InputDecoration(
                      labelText: 'Formato',
                      labelStyle: GoogleFonts.outfit(color: Colors.white70),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white.withOpacity(0.3))),
                      focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.orange)),
                    ),
                    items: ['pdf', 'epub'].map((format) => DropdownMenuItem(
                      value: format,
                      child: Text(format.toUpperCase()),
                    )).toList(),
                    onChanged: (value) => setState(() => selectedFormat = value!),
                  ),
                  const SizedBox(height: 16),
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: Supabase.instance.client.from('categories').select().eq('is_active', true).order('name'),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const CircularProgressIndicator(color: Colors.white);
                      }
                      final categories = snapshot.data!;
                      return DropdownButtonFormField<String>(
                        value: categories.any((cat) => cat['name'] == selectedCategory) ? selectedCategory : categories.first['name'],
                        style: GoogleFonts.outfit(color: Colors.white),
                        dropdownColor: const Color(0xFF1E293B),
                        decoration: InputDecoration(
                          labelText: 'Categoría',
                          labelStyle: GoogleFonts.outfit(color: Colors.white70),
                          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white.withOpacity(0.3))),
                          focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.orange)),
                        ),
                        items: categories.map<DropdownMenuItem<String>>((category) => DropdownMenuItem(
                          value: category['name'],
                          child: Text(category['name']),
                        )).toList(),
                        onChanged: (value) => setState(() => selectedCategory = value!),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Libro Físico', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                        CheckboxListTile(
                          title: Text('¿Es un libro físico?', style: GoogleFonts.outfit(color: Colors.white70)),
                          value: isPhysical,
                          onChanged: (value) => setState(() => isPhysical = value ?? false),
                          activeColor: Colors.orange,
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                        if (isPhysical)
                          TextField(
                            controller: locationController,
                            style: GoogleFonts.outfit(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Ubicación en biblioteca',
                              labelStyle: GoogleFonts.outfit(color: Colors.white70),
                              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white.withOpacity(0.3))),
                              focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.orange)),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar', style: GoogleFonts.outfit(color: Colors.white70)),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await Supabase.instance.client.from('books').update({
                    'title': titleController.text,
                    'author': authorController.text,
                    'description': descriptionController.text.isEmpty ? null : descriptionController.text,
                    'file_url': fileUrlController.text,
                    'cover_url': coverUrlController.text.isEmpty ? null : coverUrlController.text,
                    'isbn': isbnController.text.isEmpty ? null : isbnController.text,
                    'year': yearController.text.isEmpty ? null : int.tryParse(yearController.text),
                    'format': selectedFormat,
                    'category': selectedCategory,
                    'is_physical': isPhysical,
                    'physical_location': isPhysical ? locationController.text : null,
                  }).eq('id', book['id']);
                  
                  Navigator.pop(context);
                  onRefresh();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Libro actualizado correctamente', style: GoogleFonts.outfit()), backgroundColor: Colors.green),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al actualizar: $e', style: GoogleFonts.outfit()), backgroundColor: Colors.red),
                  );
                }
              },
              child: Text('Guardar', style: GoogleFonts.outfit(color: Colors.orange)),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, Map<String, dynamic> book) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text('Eliminar libro', style: GoogleFonts.outfit(color: Colors.white)),
        content: Text('¿Seguro que quieres eliminar este libro?', style: GoogleFonts.outfit(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: GoogleFonts.outfit(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await Supabase.instance.client.from('books').delete().eq('id', book['id']);
                onRefresh();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Libro eliminado correctamente', style: GoogleFonts.outfit()), backgroundColor: Colors.green),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error al eliminar: $e', style: GoogleFonts.outfit()), backgroundColor: Colors.red),
                );
              }
            },
            child: Text('Eliminar', style: GoogleFonts.outfit(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}