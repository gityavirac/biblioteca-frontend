import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/optimized_theme.dart';
import '../../../core/theme/app_colors.dart';

class CategoriesManagementScreen extends StatefulWidget {
  const CategoriesManagementScreen({super.key});

  @override
  State<CategoriesManagementScreen> createState() => _CategoriesManagementScreenState();
}

class _CategoriesManagementScreenState extends State<CategoriesManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Categorías
  List<Map<String, dynamic>> _categories = [];
  bool _loadingCategories = true;

  // Subcategorías
  List<Map<String, dynamic>> _subcategories = [];
  List<Map<String, dynamic>> _allCategories = []; // para el dropdown
  bool _loadingSubcategories = true;
  String? _filterCategoryId; // filtro por categoría en tab subcategorías

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCategories();
    _loadSubcategories();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── CATEGORÍAS ──────────────────────────────────────────────

  Future<void> _loadCategories() async {
    try {
      final response = await Supabase.instance.client
          .from('categories')
          .select()
          .eq('is_active', true)
          .order('name');
      setState(() {
        _categories = List<Map<String, dynamic>>.from(response);
        _allCategories = _categories;
        _loadingCategories = false;
      });
    } catch (e) {
      setState(() => _loadingCategories = false);
    }
  }

  Future<void> _createCategory(String name, String description) async {
    await Supabase.instance.client.from('categories').insert({
      'name': name,
      'description': description.isEmpty ? null : description,
      'created_by': Supabase.instance.client.auth.currentUser?.id,
    });
    _loadCategories();
    _loadSubcategories(); // refresca dropdown
  }

  Future<void> _updateCategory(String id, String name, String description) async {
    await Supabase.instance.client.from('categories').update({
      'name': name,
      'description': description.isEmpty ? null : description,
    }).eq('id', id);
    _loadCategories();
  }

  Future<void> _deleteCategory(String id) async {
    await Supabase.instance.client
        .from('categories')
        .update({'is_active': false})
        .eq('id', id);
    _loadCategories();
  }

  // ── SUBCATEGORÍAS ────────────────────────────────────────────

  Future<void> _loadSubcategories() async {
    try {
      var query = Supabase.instance.client
          .from('subcategories')
          .select('*, categories(name)')
          .eq('is_active', true);

      if (_filterCategoryId != null) {
        query = query.eq('category_id', _filterCategoryId!);
      }

      final response = await query.order('name');
      setState(() {
        _subcategories = List<Map<String, dynamic>>.from(response);
        _loadingSubcategories = false;
      });
    } catch (e) {
      setState(() => _loadingSubcategories = false);
    }
  }

  Future<void> _createSubcategory(String name, String description, String categoryId) async {
    await Supabase.instance.client.from('subcategories').insert({
      'name': name,
      'description': description.isEmpty ? null : description,
      'category_id': categoryId,
      'created_by': Supabase.instance.client.auth.currentUser?.id,
    });
    _loadSubcategories();
  }

  Future<void> _updateSubcategory(String id, String name, String description, String categoryId) async {
    await Supabase.instance.client.from('subcategories').update({
      'name': name,
      'description': description.isEmpty ? null : description,
      'category_id': categoryId,
    }).eq('id', id);
    _loadSubcategories();
  }

  Future<void> _deleteSubcategory(String id) async {
    await Supabase.instance.client
        .from('subcategories')
        .update({'is_active': false})
        .eq('id', id);
    _loadSubcategories();
  }

  // ── DIALOGS ──────────────────────────────────────────────────

  void _showCategoryDialog({Map<String, dynamic>? category}) {
    final nameCtrl = TextEditingController(text: category?['name'] ?? '');
    final descCtrl = TextEditingController(text: category?['description'] ?? '');
    final isEdit = category != null;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          isEdit ? 'Editar Categoría' : 'Nueva Categoría',
          style: OptimizedTheme.heading3,
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field(nameCtrl, 'Nombre', Icons.category),
              const SizedBox(height: 12),
              _field(descCtrl, 'Descripción (opcional)', Icons.description, maxLines: 3),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar', style: OptimizedTheme.bodyTextSmall),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.yaviracOrange),
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              try {
                if (isEdit) {
                  await _updateCategory(category['id'], nameCtrl.text.trim(), descCtrl.text.trim());
                } else {
                  await _createCategory(nameCtrl.text.trim(), descCtrl.text.trim());
                }
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(isEdit ? 'Categoría actualizada' : 'Categoría creada'),
                    backgroundColor: Colors.green,
                  ));
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: Text(isEdit ? 'Actualizar' : 'Crear', style: OptimizedTheme.bodyText),
          ),
        ],
      ),
    );
  }

  void _showSubcategoryDialog({Map<String, dynamic>? sub}) {
    final nameCtrl = TextEditingController(text: sub?['name'] ?? '');
    final descCtrl = TextEditingController(text: sub?['description'] ?? '');
    String? selectedCategoryId = sub?['category_id'];
    final isEdit = sub != null;

    if (_allCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Primero crea una categoría'), backgroundColor: Colors.orange),
      );
      return;
    }

    selectedCategoryId ??= _allCategories.first['id'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            isEdit ? 'Editar Subcategoría' : 'Nueva Subcategoría',
            style: OptimizedTheme.heading3,
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Dropdown categoría padre
                DropdownButtonFormField<String>(
                  value: selectedCategoryId,
                  dropdownColor: const Color(0xFF1E293B),
                  style: OptimizedTheme.bodyText,
                  decoration: InputDecoration(
                    labelText: 'Categoría padre',
                    labelStyle: OptimizedTheme.bodyTextSmall,
                    prefixIcon: const Icon(Icons.folder, color: AppColors.yaviracOrange, size: 18),
                    filled: true,
                    fillColor: Colors.black.withOpacity(0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.yaviracOrange),
                    ),
                  ),
                  items: _allCategories.map((cat) => DropdownMenuItem<String>(
                    value: cat['id'] as String,
                    child: Text(cat['name'] as String),
                  )).toList(),
                  onChanged: (val) => setDialogState(() => selectedCategoryId = val),
                ),
                const SizedBox(height: 12),
                _field(nameCtrl, 'Nombre', Icons.label_outline),
                const SizedBox(height: 12),
                _field(descCtrl, 'Descripción (opcional)', Icons.description, maxLines: 3),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancelar', style: OptimizedTheme.bodyTextSmall),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.yaviracOrange),
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty || selectedCategoryId == null) return;
                Navigator.pop(ctx);
                try {
                  if (isEdit) {
                    await _updateSubcategory(sub['id'], nameCtrl.text.trim(), descCtrl.text.trim(), selectedCategoryId!);
                  } else {
                    await _createSubcategory(nameCtrl.text.trim(), descCtrl.text.trim(), selectedCategoryId!);
                  }
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(isEdit ? 'Subcategoría actualizada' : 'Subcategoría creada'),
                      backgroundColor: Colors.green,
                    ));
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              child: Text(isEdit ? 'Actualizar' : 'Crear', style: OptimizedTheme.bodyText),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(String id, String name, bool isCategory) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Eliminar', style: OptimizedTheme.heading3),
        content: Text(
          '¿Seguro que deseas eliminar "$name"?',
          style: OptimizedTheme.bodyText,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar', style: OptimizedTheme.bodyTextSmall),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                if (isCategory) {
                  await _deleteCategory(id);
                } else {
                  await _deleteSubcategory(id);
                }
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Eliminado correctamente'), backgroundColor: Colors.orange),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: Text('Eliminar', style: OptimizedTheme.bodyText),
          ),
        ],
      ),
    );
  }

  // ── BUILD ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header con tabs
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: Text('Gestión de Categorías', style: OptimizedTheme.heading2),
              ),
              ElevatedButton.icon(
                onPressed: () => _tabController.index == 0
                    ? _showCategoryDialog()
                    : _showSubcategoryDialog(),
                icon: const Icon(Icons.add, size: 18),
                label: Text(_tabController.index == 0 ? 'Nueva Categoría' : 'Nueva Subcategoría'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.yaviracOrange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
        // TabBar
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.07),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TabBar(
            controller: _tabController,
            onTap: (_) => setState(() {}),
            indicator: BoxDecoration(
              color: AppColors.yaviracOrange,
              borderRadius: BorderRadius.circular(10),
            ),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            dividerColor: Colors.transparent,
            tabs: const [
              Tab(text: 'Categorías'),
              Tab(text: 'Subcategorías'),
            ],
          ),
        ),
        // Contenido
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildCategoriesTab(),
              _buildSubcategoriesTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoriesTab() {
    if (_loadingCategories) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }
    if (_categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.category_outlined, size: 64, color: Colors.white.withOpacity(0.3)),
            const SizedBox(height: 12),
            Text('No hay categorías', style: OptimizedTheme.bodyTextSmall),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final cat = _categories[index];
        return _buildItemCard(
          icon: Icons.category,
          iconColor: AppColors.yaviracOrange,
          title: cat['name'],
          subtitle: cat['description'],
          onEdit: () => _showCategoryDialog(category: cat),
          onDelete: () => _showDeleteDialog(cat['id'], cat['name'], true),
        );
      },
    );
  }

  Widget _buildSubcategoriesTab() {
    return Column(
      children: [
        // Filtro por categoría
        if (_allCategories.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: DropdownButtonFormField<String?>(
              value: _filterCategoryId,
              dropdownColor: const Color(0xFF1E293B),
              style: OptimizedTheme.bodyText,
              decoration: InputDecoration(
                labelText: 'Filtrar por categoría',
                labelStyle: OptimizedTheme.bodyTextSmall,
                prefixIcon: const Icon(Icons.filter_list, color: AppColors.yaviracOrange, size: 18),
                filled: true,
                fillColor: Colors.white.withOpacity(0.07),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              items: [
                const DropdownMenuItem<String?>(value: null, child: Text('Todas')),
                ..._allCategories.map((cat) => DropdownMenuItem<String?>(
                  value: cat['id'] as String,
                  child: Text(cat['name'] as String),
                )),
              ],
              onChanged: (val) {
                setState(() {
                  _filterCategoryId = val;
                  _loadingSubcategories = true;
                });
                _loadSubcategories();
              },
            ),
          ),
        Expanded(
          child: _loadingSubcategories
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : _subcategories.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.label_outline, size: 64, color: Colors.white.withOpacity(0.3)),
                          const SizedBox(height: 12),
                          Text('No hay subcategorías', style: OptimizedTheme.bodyTextSmall),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _subcategories.length,
                      itemBuilder: (context, index) {
                        final sub = _subcategories[index];
                        final catName = sub['categories']?['name'] ?? '';
                        return _buildItemCard(
                          icon: Icons.label,
                          iconColor: AppColors.yaviracBlueLight,
                          title: sub['name'],
                          subtitle: catName.isNotEmpty ? '📁 $catName' : sub['description'],
                          onEdit: () => _showSubcategoryDialog(sub: sub),
                          onDelete: () => _showDeleteDialog(sub['id'], sub['name'], false),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildItemCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: OptimizedTheme.bodyText.copyWith(fontWeight: FontWeight.w600)),
                if (subtitle != null && subtitle.isNotEmpty)
                  Text(subtitle, style: OptimizedTheme.bodyTextSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_rounded, color: AppColors.yaviracBlueLight, size: 20),
            onPressed: onEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete_rounded, color: Colors.redAccent, size: 20),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon, {int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: OptimizedTheme.bodyText,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: OptimizedTheme.bodyTextSmall,
        prefixIcon: Icon(icon, color: AppColors.yaviracOrange, size: 18),
        filled: true,
        fillColor: Colors.black.withOpacity(0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.yaviracOrange),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }
}
