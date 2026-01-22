import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import '../../../core/theme/app_colors.dart';
import '../../theme/glass_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../../data/services/cache_service.dart';

class AddBookScreen extends StatefulWidget {
  const AddBookScreen({super.key});

  @override
  State<AddBookScreen> createState() => _AddBookScreenState();
}

class _AddBookScreenState extends State<AddBookScreen> {
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _fileUrlController = TextEditingController();
  final _coverUrlController = TextEditingController();
  final _isbnController = TextEditingController();
  final _yearController = TextEditingController();
  
  PlatformFile? _selectedFile;
  PlatformFile? _selectedCover;
  
  String _selectedFormat = 'pdf';
  String _selectedCategory = 'Desarrollo de Software';
  String _selectedSubcategory = 'Frontend';
  bool _isLoading = false;

  final Map<String, List<String>> _categories = {
    'Desarrollo de Software': ['Frontend', 'Backend', 'Móvil', 'Base de Datos'],
    'Marketing': ['Digital', 'Tradicional', 'Redes Sociales', 'SEO'],
    'Guía Nacional de Turismo': ['Destinos', 'Hoteles', 'Restaurantes', 'Actividades'],
    'Arte Culinaria': ['Cocina Nacional', 'Cocina Internacional', 'Repostería', 'Bebidas'],
    'Idioma': ['Inglés', 'Francés', 'Alemán', 'Portugués'],
  };

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'epub'],
    );

    if (result != null) {
      setState(() {
        _selectedFile = result.files.single;
        _fileUrlController.text = 'Archivo seleccionado: ${_selectedFile!.name}';
      });
    }
  }

  Future<void> _pickCover() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    if (result != null) {
      setState(() {
        _selectedCover = result.files.single;
        _coverUrlController.text = 'Imagen seleccionada: ${_selectedCover!.name}';
      });
    }
  }

  Future<void> _addBook() async {
    if (_titleController.text.isEmpty || _authorController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa título y autor')),
      );
      return;
    }

    if (_fileUrlController.text.isEmpty && _selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega URL o selecciona archivo')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? fileUrl;
      String? coverUrl;

      // Subir archivo si es local
      if (_selectedFile != null) {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${_titleController.text.replaceAll(' ', '_')}.$_selectedFormat';
        
        if (_selectedFile!.bytes != null) {
          await Supabase.instance.client.storage
              .from('books')
              .uploadBinary(fileName, _selectedFile!.bytes!);
          
          fileUrl = Supabase.instance.client.storage
              .from('books')
              .getPublicUrl(fileName);
        }
      } else {
        fileUrl = _fileUrlController.text;
      }

      // Subir portada si es local
      if (_selectedCover != null) {
        final coverName = '${DateTime.now().millisecondsSinceEpoch}_cover_${_titleController.text.replaceAll(' ', '_')}.jpg';
        
        if (_selectedCover!.bytes != null) {
          await Supabase.instance.client.storage
              .from('covers')
              .uploadBinary(coverName, _selectedCover!.bytes!);
          
          coverUrl = Supabase.instance.client.storage
              .from('covers')
              .getPublicUrl(coverName);
        }
      } else if (_coverUrlController.text.isNotEmpty && !_coverUrlController.text.contains('seleccionada')) {
        coverUrl = _coverUrlController.text;
      }

      await Supabase.instance.client.from('books').insert({
        'title': _titleController.text,
        'author': _authorController.text,
        'description': _descriptionController.text.isEmpty ? null : _descriptionController.text,
        'file_url': fileUrl,
        'cover_url': coverUrl,
        'isbn': _isbnController.text.isEmpty ? null : _isbnController.text,
        'year': _yearController.text.isEmpty ? null : int.tryParse(_yearController.text),
        'format': _selectedFormat,
        'category': _selectedCategory,
        'subcategory': _selectedSubcategory,
        'categories': [_selectedCategory],
        'published_date': DateTime.now().toIso8601String().split('T')[0],
        'created_by': Supabase.instance.client.auth.currentUser?.id,
      });

      if (mounted) {
        // Limpiar caché para actualizar las listas
        CacheService.remove('recent_books_stats');
        CacheService.remove('top_books_stats');
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Libro agregado exitosamente', style: GoogleFonts.outfit()),
            backgroundColor: GlassTheme.successColor,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e', style: GoogleFonts.outfit()), backgroundColor: Colors.redAccent),
      );
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.yaviracBlue,
              AppColors.yaviracBlueDark,
              Colors.black,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: _buildForm(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return FadeInDown(
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: AppColors.avatarGradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.yaviracOrange.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AGREGAR LIBRO',
                    style: GoogleFonts.orbitron(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                  Text(
                    'Expande la biblioteca digital',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.yaviracOrange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.yaviracOrange.withOpacity(0.5),
                ),
              ),
              child: const Icon(Icons.library_books, color: Colors.white, size: 30),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return FadeInUp(
      child: Container(
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.1),
              Colors.white.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.yaviracOrange.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Información Básica', Icons.info_outline),
            const SizedBox(height: 20),
            _buildBasicInfo(),
            const SizedBox(height: 30),
            _buildSectionTitle('Archivos', Icons.cloud_upload),
            const SizedBox(height: 20),
            _buildFileSection(),
            const SizedBox(height: 30),
            _buildSectionTitle('Detalles', Icons.tune),
            const SizedBox(height: 20),
            _buildDetailsSection(),
            const SizedBox(height: 30),
            _buildSectionTitle('Categorización', Icons.category),
            const SizedBox(height: 20),
            _buildCategorySection(),
            const SizedBox(height: 40),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: AppColors.avatarGradient,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.orbitron(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.yaviracOrange,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildBasicInfo() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildInput(_titleController, 'Título', Icons.title, 0),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildInput(_authorController, 'Autor', Icons.person_outline, 100),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildInput(_descriptionController, 'Descripción', Icons.description_outlined, 200, maxLines: 3),
      ],
    );
  }

  Widget _buildFileSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: 3,
              child: _buildInput(_fileUrlController, 'URL del archivo (PDF/EPUB)', Icons.link, 300),
            ),
            const SizedBox(width: 12),
            _buildFileButton('ARCHIVO', Icons.folder_open, _pickFile),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: _buildInput(_coverUrlController, 'URL de la portada', Icons.image_outlined, 400),
            ),
            const SizedBox(width: 12),
            _buildFileButton('PORTADA', Icons.photo_library, _pickCover),
          ],
        ),
        if (_selectedFile != null || _selectedCover != null)
          Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.yaviracOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.yaviracOrange.withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_selectedFile != null)
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: AppColors.yaviracOrange, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Archivo: ${_selectedFile!.name}',
                          style: GoogleFonts.outfit(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                if (_selectedCover != null)
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: AppColors.yaviracOrange, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Portada: ${_selectedCover!.name}',
                          style: GoogleFonts.outfit(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildDetailsSection() {
    return Row(
      children: [
        Expanded(
          child: _buildInput(_isbnController, 'ISBN', Icons.qr_code, 500),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildInput(_yearController, 'Año', Icons.calendar_today_outlined, 600, keyboardType: TextInputType.number),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildDropdown(
            _selectedFormat,
            'Formato',
            ['pdf', 'epub'],
            (value) => setState(() => _selectedFormat = value!),
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySection() {
    return Row(
      children: [
        Expanded(
          child: _buildDropdown(
            _selectedCategory,
            'Categoría',
            _categories.keys.toList(),
            (value) => setState(() {
              _selectedCategory = value!;
              _selectedSubcategory = _categories[value]!.first;
            }),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildDropdown(
            _selectedSubcategory,
            'Subcategoría',
            _categories[_selectedCategory]!,
            (value) => setState(() => _selectedSubcategory = value!),
          ),
        ),
      ],
    );
  }

  Widget _buildInput(TextEditingController controller, String label, IconData icon, int delay, {int maxLines = 1, TextInputType? keyboardType}) {
    return FadeInLeft(
      delay: Duration(milliseconds: delay),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.yaviracOrange.withOpacity(0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.yaviracOrange.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: GoogleFonts.outfit(color: Colors.white70, fontSize: 12),
            prefixIcon: Icon(icon, color: AppColors.yaviracOrange, size: 20),
            filled: true,
            fillColor: Colors.black.withOpacity(0.3),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.yaviracOrange, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildFileButton(String text, IconData icon, VoidCallback onPressed) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        gradient: AppColors.sidebarGradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.yaviracOrange.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  text,
                  style: GoogleFonts.orbitron(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(String value, String label, List<String> items, ValueChanged<String?> onChanged) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.yaviracOrange.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.yaviracOrange.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.outfit(color: Colors.white70, fontSize: 12),
          filled: true,
          fillColor: Colors.black.withOpacity(0.3),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.yaviracOrange, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        dropdownColor: AppColors.yaviracBlueDark,
        style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
        items: items.map((item) => DropdownMenuItem(
          value: item,
          child: Text(item, style: GoogleFonts.outfit(color: Colors.white)),
        )).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Center(
      child: FadeInUp(
        delay: const Duration(milliseconds: 700),
        child: Container(
          width: 300,
          height: 55,
          decoration: BoxDecoration(
            gradient: AppColors.sidebarGradient,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: AppColors.yaviracOrange.withOpacity(0.4),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isLoading ? null : _addBook,
              borderRadius: BorderRadius.circular(15),
              child: Center(
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_circle_outline, color: Colors.white),
                          const SizedBox(width: 12),
                          Text(
                            'AGREGAR LIBRO',
                            style: GoogleFonts.orbitron(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}