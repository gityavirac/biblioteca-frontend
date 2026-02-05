import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:glassmorphism/glassmorphism.dart';
import '../../../core/theme/optimized_theme.dart';
import '../../../core/theme/app_colors.dart';

class CategoriesManagementScreen extends StatefulWidget {
  const CategoriesManagementScreen({super.key});

  @override
  State<CategoriesManagementScreen> createState() => _CategoriesManagementScreenState();
}

class _CategoriesManagementScreenState extends State<CategoriesManagementScreen> {
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = true;
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final response = await Supabase.instance.client
          .from('categories')
          .select()
          .eq('is_active', true)
          .order('name');
      
      setState(() {
        _categories = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      print('Error cargando categorías: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createCategory() async {
    if (_nameController.text.trim().isEmpty) return;

    try {
      await Supabase.instance.client.from('categories').insert({
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'created_by': Supabase.instance.client.auth.currentUser?.id,
      });

      _nameController.clear();
      _descriptionController.clear();
      Navigator.pop(context);
      _loadCategories();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Categoría creada exitosamente')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _deleteCategory(String id) async {
    try {
      await Supabase.instance.client
          .from('categories')
          .update({'is_active': false})
          .eq('id', id);
      
      _loadCategories();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Categoría eliminada')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _showCreateDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text('Nueva Categoría', style: OptimizedTheme.heading3),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                style: OptimizedTheme.bodyText,
                decoration: InputDecoration(
                  labelText: 'Nombre de la categoría',
                  labelStyle: OptimizedTheme.bodyTextSmall,
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.yaviracOrange),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                style: OptimizedTheme.bodyText,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Descripción (opcional)',
                  labelStyle: OptimizedTheme.bodyTextSmall,
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.yaviracOrange),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: OptimizedTheme.bodyTextSmall),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.yaviracOrange),
            onPressed: _createCategory,
            child: Text('Crear', style: OptimizedTheme.bodyText),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Gestión de Categorías',
                    style: OptimizedTheme.heading2,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _showCreateDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Nueva'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.yaviracOrange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : _categories.isEmpty
                    ? Center(
                        child: Text(
                          'No hay categorías',
                          style: OptimizedTheme.bodyText,
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          final category = _categories[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: GlassmorphicContainer(
                              width: double.infinity,
                              height: 80,
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
                              child: ListTile(
                                leading: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppColors.yaviracOrange.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.category, color: Colors.white),
                                ),
                                title: Text(
                                  category['name'],
                                  style: OptimizedTheme.bodyText.copyWith(fontWeight: FontWeight.w600),
                                ),
                                subtitle: category['description'] != null && category['description'].toString().isNotEmpty
                                    ? Text(
                                        category['description'],
                                        style: OptimizedTheme.bodyTextSmall,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      )
                                    : null,
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _showDeleteDialog(category),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(Map<String, dynamic> category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text('Eliminar Categoría', style: OptimizedTheme.heading3),
        content: Text(
          '¿Estás seguro de que quieres eliminar "${category['name']}"?',
          style: OptimizedTheme.bodyText,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: OptimizedTheme.bodyTextSmall),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              _deleteCategory(category['id']);
            },
            child: Text('Eliminar', style: OptimizedTheme.bodyText),
          ),
        ],
      ),
    );
  }
}