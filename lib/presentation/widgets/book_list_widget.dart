import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import '../../data/services/cache_service.dart';
import '../../core/services/optimized_cache_service.dart';
import '../screens/user/book_detail_screen.dart';

class BookListWidget extends StatefulWidget {
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
  State<BookListWidget> createState() => _BookListWidgetState();
}

class _BookListWidgetState extends State<BookListWidget> {
  final ScrollController _scrollController = ScrollController();
  bool _canScrollLeft = false;
  bool _canScrollRight = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateScrollButtons);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _updateScrollButtons() {
    if (mounted) {
      setState(() {
        _canScrollLeft = _scrollController.offset > 0;
        _canScrollRight = _scrollController.offset < _scrollController.position.maxScrollExtent;
      });
    }
  }

  void _scrollLeft() {
    _scrollController.animateTo(
      _scrollController.offset - 300,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _scrollRight() {
    _scrollController.animateTo(
      _scrollController.offset + 300,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: widget.future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator(color: Colors.white)));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return SizedBox(height: 200, child: Center(child: Text('No hay libros disponibles', style: GoogleFonts.outfit(color: Colors.white70))));
        }
        
        // Actualizar botones después de que se construya la lista
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _updateScrollButtons();
          }
        });
        
        return _buildBookList(snapshot.data!, context);
      },
    );
  }

  Widget _buildBookList(List<Map<String, dynamic>> books, BuildContext context) {
    return SizedBox(
      height: 200,
      child: Stack(
        children: [
          ListView.builder(
            controller: _scrollController,
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
                    if (widget.canEdit && (_isAdmin() || book['created_by'] == Supabase.instance.client.auth.currentUser?.id))
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
          // Flecha izquierda
          if (_canScrollLeft)
            Positioned(
              left: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: _scrollLeft,
                  ),
                ),
              ),
            ),
          // Flecha derecha
          if (_canScrollRight)
            Positioned(
              right: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_forward_ios, color: Colors.white),
                    onPressed: _scrollRight,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  bool _isAdmin() {
    return widget.userRole == 'admin' || widget.userRole == 'administrador';
  }

  void _handleMenuAction(String action, Map<String, dynamic> book, BuildContext context) {
    if (action == 'edit') {
      _showEditDialog(context, book);
    } else if (action == 'delete') {
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
    final codigoFisicoController = TextEditingController(text: book['codigo_fisico'] ?? '');
    
    String selectedFormat = book['format'] ?? 'pdf';
    String selectedCategory = book['category'] ?? 'General';
    String selectedSub = book['subcategory'] ?? '';
    bool isPhysical = book['is_physical'] ?? false;
    bool useFileUpload = false;
    bool useCoverUpload = false;
    Uint8List? selectedFile;
    String? selectedFileName;
    PlatformFile? selectedCover;
    
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
                  // Sección de archivo del libro
                  if (!isPhysical) Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Archivo del libro', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<bool>(
                              title: Text('URL del archivo', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12)),
                              value: false,
                              groupValue: useFileUpload,
                              onChanged: (value) => setState(() {
                                useFileUpload = value!;
                                selectedFile = null;
                                selectedFileName = null;
                              }),
                              activeColor: Colors.orange,
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<bool>(
                              title: Text('Subir archivo', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12)),
                              value: true,
                              groupValue: useFileUpload,
                              onChanged: (value) => setState(() {
                                useFileUpload = value!;
                                fileUrlController.clear();
                              }),
                              activeColor: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      if (!useFileUpload)
                        TextField(
                          controller: fileUrlController,
                          style: GoogleFonts.outfit(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'URL del archivo',
                            labelStyle: GoogleFonts.outfit(color: Colors.white70),
                            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white.withOpacity(0.3))),
                            focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.orange)),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: selectedFile != null ? Colors.orange : Colors.white.withOpacity(0.3)),
                          ),
                          child: selectedFile == null
                              ? Column(
                                  children: [
                                    const Icon(Icons.cloud_upload, size: 40, color: Colors.orange),
                                    const SizedBox(height: 8),
                                    Text('Seleccionar archivo PDF/EPUB', style: GoogleFonts.outfit(color: Colors.white)),
                                    const SizedBox(height: 8),
                                    ElevatedButton(
                                      onPressed: () async {
                                        try {
                                          FilePickerResult? result = await FilePicker.platform.pickFiles(
                                            type: FileType.custom,
                                            allowedExtensions: ['pdf', 'epub'],
                                            withData: true,
                                          );
                                          if (result != null && result.files.single.bytes != null) {
                                            setState(() {
                                              selectedFile = result.files.single.bytes!;
                                              selectedFileName = result.files.single.name;
                                            });
                                          }
                                        } catch (e) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Error: $e')),
                                          );
                                        }
                                      },
                                      child: const Text('Seleccionar'),
                                    ),
                                  ],
                                )
                              : Column(
                                  children: [
                                    const Icon(Icons.check_circle, size: 40, color: Colors.green),
                                    const SizedBox(height: 8),
                                    Text('Archivo: ${selectedFileName ?? "archivo.pdf"}', style: GoogleFonts.outfit(color: Colors.white)),
                                    const SizedBox(height: 8),
                                    ElevatedButton(
                                      onPressed: () => setState(() {
                                        selectedFile = null;
                                        selectedFileName = null;
                                      }),
                                      child: const Text('Quitar'),
                                    ),
                                  ],
                                ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Sección de portada
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Portada del libro', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<bool>(
                              title: Text('URL de portada', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12)),
                              value: false,
                              groupValue: useCoverUpload,
                              onChanged: (value) => setState(() {
                                useCoverUpload = value!;
                                selectedCover = null;
                              }),
                              activeColor: Colors.orange,
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<bool>(
                              title: Text('Subir imagen', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12)),
                              value: true,
                              groupValue: useCoverUpload,
                              onChanged: (value) => setState(() {
                                useCoverUpload = value!;
                                coverUrlController.clear();
                              }),
                              activeColor: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      if (!useCoverUpload)
                        TextField(
                          controller: coverUrlController,
                          style: GoogleFonts.outfit(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'URL de la portada',
                            labelStyle: GoogleFonts.outfit(color: Colors.white70),
                            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white.withOpacity(0.3))),
                            focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.orange)),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: selectedCover != null ? Colors.orange : Colors.white.withOpacity(0.3)),
                          ),
                          child: selectedCover == null
                              ? Column(
                                  children: [
                                    const Icon(Icons.image, size: 40, color: Colors.orange),
                                    const SizedBox(height: 8),
                                    Text('Seleccionar imagen', style: GoogleFonts.outfit(color: Colors.white)),
                                    const SizedBox(height: 8),
                                    ElevatedButton(
                                      onPressed: () async {
                                        try {
                                          FilePickerResult? result = await FilePicker.platform.pickFiles(
                                            type: FileType.image,
                                            withData: true,
                                          );
                                          if (result != null && result.files.single.bytes != null) {
                                            setState(() {
                                              selectedCover = result.files.single;
                                            });
                                          }
                                        } catch (e) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Error: $e')),
                                          );
                                        }
                                      },
                                      child: const Text('Seleccionar'),
                                    ),
                                  ],
                                )
                              : Column(
                                  children: [
                                    const Icon(Icons.check_circle, size: 40, color: Colors.green),
                                    const SizedBox(height: 8),
                                    Text('Imagen: ${selectedCover?.name ?? "imagen.jpg"}', style: GoogleFonts.outfit(color: Colors.white)),
                                    const SizedBox(height: 8),
                                    ElevatedButton(
                                      onPressed: () => setState(() => selectedCover = null),
                                      child: const Text('Quitar'),
                                    ),
                                  ],
                                ),
                        ),
                    ],
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
                    future: Supabase.instance.client.from('categories').select('name, subcategories(name, is_active)').eq('is_active', true).order('name'),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const CircularProgressIndicator(color: Colors.white);
                      }
                      final categories = snapshot.data!;
                      // Construir mapa categoria -> subcategorias
                      final Map<String, List<String>> catMap = {};
                      for (final cat in categories) {
                        final subs = (cat['subcategories'] as List)
                            .where((s) => s['is_active'] != false)
                            .map((s) => s['name'] as String)
                            .toList();
                        catMap[cat['name'] as String] = subs.isEmpty ? ['General'] : subs;
                      }
                      // Validar selectedCategory
                      if (!catMap.containsKey(selectedCategory) && catMap.isNotEmpty) {
                        selectedCategory = catMap.keys.first;
                      }
                      final currentSubs = catMap[selectedCategory] ?? ['General'];
                      // Validar selectedSubcategory
                      if (!currentSubs.contains(selectedSub)) selectedSub = currentSubs.first;

                      return StatefulBuilder(
                        builder: (context, setSubState) => Column(
                          children: [
                            DropdownButtonFormField<String>(
                              value: catMap.containsKey(selectedCategory) ? selectedCategory : catMap.keys.first,
                              style: GoogleFonts.outfit(color: Colors.white),
                              dropdownColor: const Color(0xFF1E293B),
                              decoration: InputDecoration(
                                labelText: 'Categoría',
                                labelStyle: GoogleFonts.outfit(color: Colors.white70),
                                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white.withOpacity(0.3))),
                                focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.orange)),
                              ),
                              items: catMap.keys.map<DropdownMenuItem<String>>((name) => DropdownMenuItem(
                                value: name,
                                child: Text(name),
                              )).toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedCategory = value!;
                                  final newSubs = catMap[value] ?? ['General'];
                                  selectedSub = newSubs.first;
                                });
                                setSubState(() {});
                              },
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              value: currentSubs.contains(selectedSub) ? selectedSub : currentSubs.first,
                              style: GoogleFonts.outfit(color: Colors.white),
                              dropdownColor: const Color(0xFF1E293B),
                              decoration: InputDecoration(
                                labelText: 'Subcategoría',
                                labelStyle: GoogleFonts.outfit(color: Colors.white70),
                                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white.withOpacity(0.3))),
                                focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.orange)),
                              ),
                              items: currentSubs.map<DropdownMenuItem<String>>((sub) => DropdownMenuItem(
                                value: sub,
                                child: Text(sub),
                              )).toList(),
                              onChanged: (value) {
                                setState(() => selectedSub = value!);
                                setSubState(() {});
                              },
                            ),
                          ],
                        ),
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
                            controller: codigoFisicoController,
                            style: GoogleFonts.outfit(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Código Físico',
                              labelStyle: GoogleFonts.outfit(color: Colors.white70),
                              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white.withOpacity(0.3))),
                              focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.orange)),
                            ),
                          ),
                        if (isPhysical) const SizedBox(height: 16),
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
                  print('📝 === ACTUALIZANDO LIBRO ===');
                  print('📝 Libro ID: ${book['id']}');
                  print('📝 Título: ${titleController.text}');
                  print('📝 Usar subida de portada: $useCoverUpload');
                  print('📝 Portada seleccionada: ${selectedCover?.name}');
                  print('📝 URL de portada: ${coverUrlController.text}');
                  
                  String? finalFileUrl;
                  if (useFileUpload && selectedFile != null) {
                    try {
                      final ext = selectedFileName?.split('.').last ?? 'pdf';
                      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$ext';
                      await Supabase.instance.client.storage
                          .from('Libros_digitales')
                          .uploadBinary(fileName, selectedFile!);
                      finalFileUrl = Supabase.instance.client.storage
                          .from('Libros_digitales')
                          .getPublicUrl(fileName);
                    } catch (e) {
                      print('❌ Error subiendo archivo: $e');
                      finalFileUrl = book['file_url']; // si falla, mantener el anterior
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error subiendo archivo: $e', style: GoogleFonts.outfit()), backgroundColor: Colors.red),
                        );
                      }
                      return;
                    }
                  } else if (!useFileUpload && fileUrlController.text.isNotEmpty) {
                    finalFileUrl = fileUrlController.text;
                  } else {
                    finalFileUrl = book['file_url']; // mantener el anterior
                  }

                  String? finalCoverUrl;
                  
                  // Subir portada si se seleccionó archivo
                  if (useCoverUpload && selectedCover != null) {
                    print('📝 Subiendo nueva portada...');
                    try {
                      final coverName = '${DateTime.now().millisecondsSinceEpoch}_cover.jpg';
                      if (selectedCover!.bytes != null) {
                        await Supabase.instance.client.storage
                            .from('Libros_digitales')
                            .uploadBinary(coverName, selectedCover!.bytes!);
                        finalCoverUrl = Supabase.instance.client.storage
                            .from('Libros_digitales')
                            .getPublicUrl(coverName);
                      }
                    } catch (storageError) {
                      print('❌ Error subiendo portada: $storageError');
                      finalCoverUrl = book['cover_url']; // si falla, mantener la anterior
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error subiendo portada: $storageError', style: GoogleFonts.outfit()), backgroundColor: Colors.red),
                        );
                      }
                      return;
                    }
                  } else if (!useCoverUpload && coverUrlController.text.isNotEmpty) {
                    finalCoverUrl = coverUrlController.text;
                    print('📝 Usando URL de portada: $finalCoverUrl');
                  } else {
                    finalCoverUrl = book['cover_url']; // Mantener la actual
                    print('📝 Manteniendo portada actual: $finalCoverUrl');
                  }
                  
                  final updateData = {
                    'title': titleController.text,
                    'author': authorController.text,
                    'description': descriptionController.text.isEmpty ? null : descriptionController.text,
                    'file_url': finalFileUrl,
                    'cover_url': finalCoverUrl,
                    'isbn': isbnController.text.isEmpty ? null : isbnController.text,
                    'year': yearController.text.isEmpty ? null : int.tryParse(yearController.text),
                    'format': selectedFormat,
                    'category': selectedCategory,
                    'subcategory': selectedSub,
                    'is_physical': isPhysical,
                    'physical_location': isPhysical ? locationController.text : null,
                    'codigo_fisico': isPhysical ? codigoFisicoController.text : null,
                  };
                  
                  print('📝 Datos a actualizar: $updateData');
                  
                  final result = await Supabase.instance.client.from('books').update(updateData).eq('id', book['id']);
                  
                  print('✅ Resultado actualización: $result');
                  
                  Navigator.pop(context);
                  print('🔄 Llamando onRefresh...');
                  await OptimizedCacheService.instance.remove('top_books');
                  await OptimizedCacheService.instance.remove('recent_books');
                  OptimizedCacheService.instance.clearMemory();
                  Future.microtask(() {
                    widget.onRefresh();
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Libro actualizado correctamente', style: GoogleFonts.outfit()), backgroundColor: Colors.green),
                  );
                } catch (e) {
                  print('❌ Error actualizando libro: $e');
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error al actualizar: $e', style: GoogleFonts.outfit()), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              child: Text('Guardar', style: GoogleFonts.outfit(color: Colors.orange)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileSection(TextEditingController fileUrlController, bool useFileUpload, Uint8List? selectedFile, String? selectedFileName, StateSetter setState, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Archivo del libro', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: RadioListTile<bool>(
                title: Text('URL del archivo', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12)),
                value: false,
                groupValue: useFileUpload,
                onChanged: (value) => setState(() {
                  useFileUpload = value!;
                  selectedFile = null;
                  selectedFileName = null;
                }),
                activeColor: Colors.orange,
              ),
            ),
            Expanded(
              child: RadioListTile<bool>(
                title: Text('Subir archivo', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12)),
                value: true,
                groupValue: useFileUpload,
                onChanged: (value) => setState(() {
                  useFileUpload = value!;
                  fileUrlController.clear();
                }),
                activeColor: Colors.orange,
              ),
            ),
          ],
        ),
        if (!useFileUpload)
          TextField(
            controller: fileUrlController,
            style: GoogleFonts.outfit(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'URL del archivo',
              labelStyle: GoogleFonts.outfit(color: Colors.white70),
              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white.withOpacity(0.3))),
              focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.orange)),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: selectedFile != null ? Colors.orange : Colors.white.withOpacity(0.3)),
            ),
            child: selectedFile == null
                ? Column(
                    children: [
                      const Icon(Icons.cloud_upload, size: 40, color: Colors.orange),
                      const SizedBox(height: 8),
                      Text('Seleccionar archivo PDF/EPUB', style: GoogleFonts.outfit(color: Colors.white)),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () => _pickFile(setState, context),
                        child: const Text('Seleccionar'),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      const Icon(Icons.check_circle, size: 40, color: Colors.green),
                      const SizedBox(height: 8),
                      Text('Archivo: ${selectedFileName ?? "archivo.pdf"}', style: GoogleFonts.outfit(color: Colors.white)),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () => setState(() {
                          selectedFile = null;
                          selectedFileName = null;
                        }),
                        child: const Text('Quitar'),
                      ),
                    ],
                  ),
          ),
      ],
    );
  }

  Widget _buildCoverSection(TextEditingController coverUrlController, bool useCoverUpload, PlatformFile? selectedCover, StateSetter setState, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Portada del libro', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: RadioListTile<bool>(
                title: Text('URL de portada', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12)),
                value: false,
                groupValue: useCoverUpload,
                onChanged: (value) => setState(() {
                  useCoverUpload = value!;
                  selectedCover = null;
                }),
                activeColor: Colors.orange,
              ),
            ),
            Expanded(
              child: RadioListTile<bool>(
                title: Text('Subir imagen', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12)),
                value: true,
                groupValue: useCoverUpload,
                onChanged: (value) => setState(() {
                  useCoverUpload = value!;
                  coverUrlController.clear();
                }),
                activeColor: Colors.orange,
              ),
            ),
          ],
        ),
        if (!useCoverUpload)
          TextField(
            controller: coverUrlController,
            style: GoogleFonts.outfit(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'URL de la portada',
              labelStyle: GoogleFonts.outfit(color: Colors.white70),
              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white.withOpacity(0.3))),
              focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.orange)),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: selectedCover != null ? Colors.orange : Colors.white.withOpacity(0.3)),
            ),
            child: selectedCover == null
                ? Column(
                    children: [
                      const Icon(Icons.image, size: 40, color: Colors.orange),
                      const SizedBox(height: 8),
                      Text('Seleccionar imagen', style: GoogleFonts.outfit(color: Colors.white)),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () => _pickCoverImage(setState, context),
                        child: const Text('Seleccionar'),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      const Icon(Icons.check_circle, size: 40, color: Colors.green),
                      const SizedBox(height: 8),
                      Text('Imagen: ${selectedCover?.name ?? "imagen.jpg"}', style: GoogleFonts.outfit(color: Colors.white)),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () => setState(() => selectedCover = null),
                        child: const Text('Quitar'),
                      ),
                    ],
                  ),
          ),
      ],
    );
  }

  Future<void> _pickFile(StateSetter setState, BuildContext context) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'epub'],
        withData: true,
      );
      if (result != null && result.files.single.bytes != null) {
        setState(() {
          // Variables locales - necesitan ser manejadas en el contexto del diálogo
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _pickCoverImage(StateSetter setState, BuildContext context) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      if (result != null && result.files.single.bytes != null) {
        setState(() {
          // Variables locales - necesitan ser manejadas en el contexto del diálogo
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
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
                final bookId = book['id'];
                final fileUrl = book['file_url'] as String?;
                final coverUrl = book['cover_url'] as String?;

                // 1. Eliminar archivos del storage
                if (fileUrl != null && fileUrl.contains('Libros_digitales')) {
                  try {
                    final fileName = Uri.parse(fileUrl).pathSegments.last;
                    await Supabase.instance.client.storage.from('Libros_digitales').remove([fileName]);
                  } catch (_) {}
                }
                if (coverUrl != null && coverUrl.contains('Libros_digitales')) {
                  try {
                    final coverName = Uri.parse(coverUrl).pathSegments.last;
                    await Supabase.instance.client.storage.from('Libros_digitales').remove([coverName]);
                  } catch (_) {}
                }

                // 2. Eliminar tablas relacionadas en orden correcto
                await Supabase.instance.client.from('book_opens_history').delete().eq('book_id', bookId);
                await Supabase.instance.client.from('reading_history').delete().eq('book_id', bookId);
                await Supabase.instance.client.from('book_stats').delete().eq('book_id', bookId);
                await Supabase.instance.client.from('favorites').delete().eq('book_id', bookId);

                // 3. Eliminar el libro
                await Supabase.instance.client.from('books').delete().eq('id', bookId);

                await OptimizedCacheService.instance.remove('top_books');
                await OptimizedCacheService.instance.remove('recent_books');
                OptimizedCacheService.instance.clearMemory();
                widget.onRefresh();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Libro eliminado completamente', style: GoogleFonts.outfit()), backgroundColor: Colors.orange),
                  );
                }
              } catch (e) {
                print('❌ Error eliminando libro: $e');
                print('❌ Tipo de error: ${e.runtimeType}');
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al eliminar: $e', style: GoogleFonts.outfit()), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: Text('Eliminar', style: GoogleFonts.outfit(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}



void showBookEditDialog({
  required BuildContext context,
  required Map<String, dynamic> book,
  required VoidCallback onRefresh,
}) {
  final titleController = TextEditingController(text: book['title'] ?? '');
  final authorController = TextEditingController(text: book['author'] ?? '');
  final descriptionController = TextEditingController(text: book['description'] ?? '');
  final coverUrlController = TextEditingController(text: book['cover_url'] ?? '');
  final fileUrlController = TextEditingController(text: book['file_url'] ?? '');
  final isbnController = TextEditingController(text: book['isbn'] ?? '');
  final yearController = TextEditingController(text: book['year']?.toString() ?? '');
  final locationController = TextEditingController(text: book['physical_location'] ?? '');
  final codigoFisicoController = TextEditingController(text: book['codigo_fisico'] ?? '');

  String selectedFormat = book['format'] ?? 'pdf';
  String selectedCategory = book['category'] ?? 'General';
  String selectedSub = book['subcategory'] ?? '';
  bool isPhysical = book['is_physical'] ?? false;
  bool useCoverUpload = false;
  PlatformFile? selectedCover;

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setS) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text('Editar Libro', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 500,
          height: 600,
          child: SingleChildScrollView(
            child: Column(
              children: [
                _editField(titleController, 'Título', Icons.title),
                const SizedBox(height: 12),
                _editField(authorController, 'Autor', Icons.person_outline),
                const SizedBox(height: 12),
                _editField(descriptionController, 'Descripción', Icons.description_outlined, maxLines: 3),
                const SizedBox(height: 12),
                _editField(fileUrlController, 'URL del archivo', Icons.link),
                const SizedBox(height: 12),
                // Portada
                Text('Portada', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: RadioListTile<bool>(
                    title: Text('URL', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12)),
                    value: false, groupValue: useCoverUpload,
                    onChanged: (v) => setS(() { useCoverUpload = false; selectedCover = null; }),
                    activeColor: Colors.orange,
                  )),
                  Expanded(child: RadioListTile<bool>(
                    title: Text('Subir imagen', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12)),
                    value: true, groupValue: useCoverUpload,
                    onChanged: (v) async {
                      final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
                      if (result != null) setS(() { useCoverUpload = true; selectedCover = result.files.single; });
                    },
                    activeColor: Colors.orange,
                  )),
                ]),
                if (!useCoverUpload) _editField(coverUrlController, 'URL de portada', Icons.image_outlined)
                else if (selectedCover != null) Text('✅ ${selectedCover!.name}', style: GoogleFonts.outfit(color: Colors.green)),
                const SizedBox(height: 12),
                _editField(isbnController, 'ISBN', Icons.qr_code),
                const SizedBox(height: 12),
                _editField(yearController, 'Año', Icons.calendar_today, keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                // Categoría y subcategoría
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _loadCatsAndSubs(),
                  builder: (ctx, snap) {
                    if (!snap.hasData) return const CircularProgressIndicator(color: Colors.white);
                    final catMap = snap.data!.first as Map<String, List<String>>;
                    if (!catMap.containsKey(selectedCategory)) selectedCategory = catMap.keys.first;
                    final subs = catMap[selectedCategory] ?? ['General'];
                    if (!subs.contains(selectedSub)) selectedSub = subs.first;
                    return StatefulBuilder(
                      builder: (ctx, setSub) => Column(children: [
                        DropdownButtonFormField<String>(
                          value: selectedCategory,
                          dropdownColor: const Color(0xFF1E293B),
                          style: GoogleFonts.outfit(color: Colors.white),
                          decoration: _dropDeco('Categoría'),
                          items: catMap.keys.map((k) => DropdownMenuItem(value: k, child: Text(k))).toList(),
                          onChanged: (v) { setS(() { selectedCategory = v!; selectedSub = (catMap[v] ?? ['General']).first; }); setSub(() {}); },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: selectedSub,
                          dropdownColor: const Color(0xFF1E293B),
                          style: GoogleFonts.outfit(color: Colors.white),
                          decoration: _dropDeco('Subcategoría'),
                          items: subs.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                          onChanged: (v) { setS(() => selectedSub = v!); setSub(() {}); },
                        ),
                      ]),
                    );
                  },
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  title: Text('¿Es libro físico?', style: GoogleFonts.outfit(color: Colors.white70)),
                  value: isPhysical,
                  onChanged: (v) => setS(() => isPhysical = v ?? false),
                  activeColor: Colors.orange,
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                if (isPhysical) ...[
                  _editField(codigoFisicoController, 'Código Físico', Icons.qr_code_2),
                  const SizedBox(height: 12),
                  _editField(locationController, 'Ubicación', Icons.location_on),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancelar', style: GoogleFonts.outfit(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () async {
              try {
                String? finalCoverUrl;
                if (useCoverUpload && selectedCover?.bytes != null) {
                  final name = '${DateTime.now().millisecondsSinceEpoch}_cover.jpg';
                  await Supabase.instance.client.storage.from('Libros_digitales').uploadBinary(name, selectedCover!.bytes!);
                  finalCoverUrl = Supabase.instance.client.storage.from('Libros_digitales').getPublicUrl(name);
                } else {
                  finalCoverUrl = coverUrlController.text.isEmpty ? book['cover_url'] : coverUrlController.text;
                }
                await Supabase.instance.client.from('books').update({
                  'title': titleController.text,
                  'author': authorController.text,
                  'description': descriptionController.text.isEmpty ? null : descriptionController.text,
                  'file_url': fileUrlController.text.isEmpty ? book['file_url'] : fileUrlController.text,
                  'cover_url': finalCoverUrl,
                  'isbn': isbnController.text.isEmpty ? null : isbnController.text,
                  'year': yearController.text.isEmpty ? null : int.tryParse(yearController.text),
                  'format': selectedFormat,
                  'category': selectedCategory,
                  'subcategory': selectedSub,
                  'is_physical': isPhysical,
                  'physical_location': isPhysical ? locationController.text : null,
                  'codigo_fisico': isPhysical ? codigoFisicoController.text : null,
                }).eq('id', book['id']);
                Navigator.pop(ctx);
                onRefresh();
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Libro actualizado', style: GoogleFonts.outfit()), backgroundColor: Colors.green),
                );
              } catch (e) {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e', style: GoogleFonts.outfit()), backgroundColor: Colors.red),
                );
              }
            },
            child: Text('Guardar', style: GoogleFonts.outfit(color: Colors.white)),
          ),
        ],
      ),
    ),
  );
}

Future<List<Map<String, dynamic>>> _loadCatsAndSubs() async {
  final cats = await Supabase.instance.client.from('categories').select('id, name').eq('is_active', true).order('name');
  final subs = await Supabase.instance.client.from('subcategories').select('name, category_id').eq('is_active', true).order('name');
  final Map<String, List<String>> map = {};
  for (final cat in cats) {
    final catSubs = (subs as List).where((s) => s['category_id'] == cat['id']).map((s) => s['name'] as String).toList();
    map[cat['name'] as String] = catSubs.isEmpty ? ['General'] : catSubs;
  }
  return [map];
}

Widget _editField(TextEditingController ctrl, String label, IconData icon, {int maxLines = 1, TextInputType? keyboardType}) {
  return TextField(
    controller: ctrl,
    maxLines: maxLines,
    keyboardType: keyboardType,
    style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.outfit(color: Colors.white60, fontSize: 12),
      prefixIcon: Icon(icon, color: Colors.orange, size: 18),
      filled: true,
      fillColor: Colors.black.withOpacity(0.3),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.orange)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    ),
  );
}

InputDecoration _dropDeco(String label) => InputDecoration(
  labelText: label,
  labelStyle: GoogleFonts.outfit(color: Colors.white60, fontSize: 12),
  filled: true,
  fillColor: Colors.black.withOpacity(0.3),
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.orange)),
);
