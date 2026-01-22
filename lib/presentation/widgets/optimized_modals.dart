import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/optimized_theme.dart';

class OptimizedModals {
  
  // Modal para reproducir videos
  static void showVideoModal(BuildContext context, String videoUrl, String title) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog.fullscreen(
        child: Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            title: Text(
              title,
              style: OptimizedTheme.heading3,
            ),
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: AspectRatio(
                aspectRatio: 16/9,
                child: _VideoPlayer(videoUrl: videoUrl),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Modal para leer PDFs
  static void showPdfModal(BuildContext context, String pdfUrl, String title) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog.fullscreen(
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: AppColors.yaviracBlueDark,
            title: Text(
              title,
              style: OptimizedTheme.heading3,
            ),
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.open_in_new, color: Colors.white),
                onPressed: () => _openInNewTab(pdfUrl),
              ),
            ],
          ),
          body: _PdfViewer(pdfUrl: pdfUrl),
        ),
      ),
    );
  }

  // Modal para agregar libro
  static void showAddBookModal(BuildContext context, {Function()? onSuccess}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: BoxDecoration(
            color: AppColors.yaviracBlueDark,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.yaviracOrange.withOpacity(0.3)),
          ),
          child: _AddBookForm(onSuccess: onSuccess),
        ),
      ),
    );
  }

  // Modal para agregar video
  static void showAddVideoModal(BuildContext context, {Function()? onSuccess}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: BoxDecoration(
            color: AppColors.yaviracBlueDark,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.yaviracOrange.withOpacity(0.3)),
          ),
          child: _AddVideoForm(onSuccess: onSuccess),
        ),
      ),
    );
  }

  // Modal de confirmación
  static void showConfirmModal(
    BuildContext context, {
    required String title,
    required String message,
    required VoidCallback onConfirm,
    String confirmText = 'Confirmar',
    String cancelText = 'Cancelar',
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.yaviracBlueDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(
          title,
          style: OptimizedTheme.heading3,
        ),
        content: Text(
          message,
          style: OptimizedTheme.bodyText,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(cancelText, style: OptimizedTheme.bodyTextSmall),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.yaviracOrange),
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            child: Text(confirmText, style: OptimizedTheme.bodyText),
          ),
        ],
      ),
    );
  }

  static void _openInNewTab(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }
}

// Widget para reproductor de video optimizado
class _VideoPlayer extends StatelessWidget {
  final String videoUrl;

  const _VideoPlayer({required this.videoUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.black,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.play_circle_outline, size: 80, color: Colors.white),
            const SizedBox(height: 16),
            Text(
              'Reproducir Video',
              style: OptimizedTheme.heading3,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _openInNewTab(videoUrl),
              child: const Text('Abrir Video'),
            ),
          ],
        ),
      ),
    );
  }

  void _openInNewTab(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }
}

// Widget para visor de PDF optimizado
class _PdfViewer extends StatelessWidget {
  final String pdfUrl;

  const _PdfViewer({required this.pdfUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.picture_as_pdf, size: 80, color: Colors.white),
            const SizedBox(height: 16),
            Text(
              'Documento PDF',
              style: OptimizedTheme.heading3,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _openInNewTab(pdfUrl),
              child: const Text('Abrir PDF'),
            ),
          ],
        ),
      ),
    );
  }

  void _openInNewTab(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }
}

// Formulario optimizado para agregar libros
class _AddBookForm extends StatefulWidget {
  final Function()? onSuccess;

  const _AddBookForm({this.onSuccess});

  @override
  State<_AddBookForm> createState() => _AddBookFormState();
}

class _AddBookFormState extends State<_AddBookForm> {
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _fileUrlController = TextEditingController();
  final _coverUrlController = TextEditingController();
  
  String _selectedCategory = 'Desarrollo de Software';
  bool _isLoading = false;

  final Map<String, List<String>> _categories = {
    'Desarrollo de Software': ['Frontend', 'Backend', 'Móvil', 'Base de Datos'],
    'Marketing': ['Digital', 'Tradicional', 'Redes Sociales', 'SEO'],
    'Guía Nacional de Turismo': ['Costas', 'Sierra', 'Oriente', 'Galápagos'],
    'Arte Culinaria': ['Cocina Nacional', 'Cocina Internacional', 'Repostería', 'Bebidas'],
    'Idiomas': ['Inglés', 'Francés', 'Alemán', 'Italiano']
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Agregar Libro',
          style: OptimizedTheme.heading2,
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildInput(_titleController, 'Título', Icons.title),
              const SizedBox(height: 16),
              _buildInput(_authorController, 'Autor', Icons.person),
              const SizedBox(height: 16),
              _buildInput(_descriptionController, 'Descripción', Icons.description, maxLines: 3),
              const SizedBox(height: 16),
              _buildInput(_fileUrlController, 'URL del PDF', Icons.link),
              const SizedBox(height: 16),
              _buildInput(_coverUrlController, 'URL de la portada', Icons.image),
              const SizedBox(height: 16),
              _buildDropdown(),
              const SizedBox(height: 32),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput(TextEditingController controller, String label, IconData icon, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: OptimizedTheme.bodyText,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: OptimizedTheme.bodyTextSmall,
        prefixIcon: Icon(icon, color: AppColors.yaviracOrange),
        filled: true,
        fillColor: Colors.black.withOpacity(0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.yaviracOrange),
        ),
      ),
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      decoration: InputDecoration(
        labelText: 'Categoría',
        labelStyle: OptimizedTheme.bodyTextSmall,
        filled: true,
        fillColor: Colors.black.withOpacity(0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      dropdownColor: AppColors.yaviracBlueDark,
      style: OptimizedTheme.bodyText,
      items: _categories.keys.map((category) => DropdownMenuItem(
        value: category,
        child: Text(category),
      )).toList(),
      onChanged: (value) => setState(() => _selectedCategory = value!),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.yaviracOrange,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: _isLoading ? null : _submitBook,
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                'Agregar Libro',
                style: OptimizedTheme.bodyText.copyWith(fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  Future<void> _submitBook() async {
    if (_titleController.text.isEmpty || _authorController.text.isEmpty || _fileUrlController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa los campos obligatorios')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await Supabase.instance.client.from('books').insert({
        'title': _titleController.text,
        'author': _authorController.text,
        'description': _descriptionController.text.isEmpty ? null : _descriptionController.text,
        'file_url': _fileUrlController.text,
        'cover_url': _coverUrlController.text.isEmpty ? null : _coverUrlController.text,
        'category': _selectedCategory,
        'created_by': Supabase.instance.client.auth.currentUser?.id,
      });

      if (mounted) {
        Navigator.pop(context);
        widget.onSuccess?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Libro agregado exitosamente')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }

    setState(() => _isLoading = false);
  }
}

// Formulario optimizado para agregar videos
class _AddVideoForm extends StatefulWidget {
  final Function()? onSuccess;

  const _AddVideoForm({this.onSuccess});

  @override
  State<_AddVideoForm> createState() => _AddVideoFormState();
}

class _AddVideoFormState extends State<_AddVideoForm> {
  final _titleController = TextEditingController();
  final _urlController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String _selectedCategory = 'Desarrollo de Software';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Agregar Video',
          style: OptimizedTheme.heading2,
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildInput(_titleController, 'Título del Video', Icons.video_library),
              const SizedBox(height: 16),
              _buildInput(_urlController, 'URL del Video', Icons.link),
              const SizedBox(height: 16),
              _buildInput(_descriptionController, 'Descripción', Icons.description, maxLines: 3),
              const SizedBox(height: 32),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput(TextEditingController controller, String label, IconData icon, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: OptimizedTheme.bodyText,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: OptimizedTheme.bodyTextSmall,
        prefixIcon: Icon(icon, color: AppColors.yaviracOrange),
        filled: true,
        fillColor: Colors.black.withOpacity(0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.yaviracOrange),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.yaviracOrange,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: _isLoading ? null : _submitVideo,
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                'Agregar Video',
                style: OptimizedTheme.bodyText.copyWith(fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  Future<void> _submitVideo() async {
    if (_titleController.text.isEmpty || _urlController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa los campos obligatorios')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await Supabase.instance.client.from('videos').insert({
        'title': _titleController.text,
        'video_id': _urlController.text,
        'description': _descriptionController.text.isEmpty ? null : _descriptionController.text,
        'category': _selectedCategory,
        'created_by': Supabase.instance.client.auth.currentUser?.id,
      });

      if (mounted) {
        Navigator.pop(context);
        widget.onSuccess?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Video agregado exitosamente')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }

    setState(() => _isLoading = false);
  }
}