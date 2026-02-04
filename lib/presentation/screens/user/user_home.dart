import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:animate_do/animate_do.dart';
import '../../../data/services/supabase_auth_service.dart';
import '../../../core/services/lazy_loading_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/optimized_theme.dart';
import '../../../core/providers/theme_provider.dart';
import '../../widgets/common_widgets.dart';
import 'package:provider/provider.dart';
import '../auth/login_screen.dart';
import '../../../main.dart';
import 'tabs/home_tab.dart';
import 'tabs/library_tab.dart';
import 'tabs/videos_tab.dart';
import '../admin/add_book_screen.dart';
import '../admin/add_video_screen.dart';
import '../admin/categories_management_screen.dart';
import 'users_management_screen.dart';
import 'book_detail_screen.dart';
import 'mobile_video_player.dart';
import '../../../core/services/optimized_cache_service.dart';
import '../../../core/widgets/lazy_tab_view.dart';
import '../../widgets/optimized_modals.dart';

class UserHome extends StatefulWidget {
  final SupabaseAuthService authService;
  
  const UserHome({super.key, required this.authService});

  @override
  State<UserHome> createState() => _UserHomeState();
}

class _UserHomeState extends State<UserHome> with LazyLoadingMixin, TickerProviderStateMixin {
  int _selectedIndex = 0;
  String _userName = 'Usuario';
  String _userRole = 'usuario';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final ValueNotifier<bool> _searchingNotifier = ValueNotifier<bool>(false);
  bool _canEdit = false;
  late TabController _tabController;
  final Map<int, Widget> _cachedTabs = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 9, vsync: this);
    _loadUserDataAsync();
    OptimizedCacheService.instance.init();
  }

  void _loadUserDataAsync() {
    Future.microtask(() async {
      await _loadUserData();
    });
  }

  @override
  void dispose() {
    _searchingNotifier.dispose();
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        final userData = await Supabase.instance.client
            .from('users')
            .select('name, role')
            .eq('id', user.id)
            .single();
        
        if (mounted) {
          setState(() {
            _userName = userData['name'] ?? 'Usuario';
            _userRole = userData['role'] ?? 'usuario';
            final role = userData['role']?.toString().toLowerCase() ?? 'lector';
            _canEdit = ['profesor', 'bibliotecario', 'admin', 'administrador'].contains(role);
          });
        }
      } catch (e) {
        print('Error cargando datos del usuario: $e');
      }
    }
  }

  void _logout() {
    widget.authService.logout();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  void _performSearch(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _searchQuery = '';
        _cachedTabs.clear();
      });
      return;
    }
    
    setState(() {
      _searchQuery = query;
      _cachedTabs.clear();
    });
  }

  Widget _getSelectedPage() {
    // Usar caché para evitar recrear widgets
    if (!_cachedTabs.containsKey(_selectedIndex)) {
      _cachedTabs[_selectedIndex] = _createTab(_selectedIndex);
    }
    return _cachedTabs[_selectedIndex]!;
  }

  Widget _createTab(int index) {
    if (_searchQuery.isNotEmpty) {
      return _SearchResultsTab(searchQuery: _searchQuery);
    }
    
    switch (index) {
      case 0:
        return HomeTab(searchQuery: _searchQuery);
      case 1:
        return LibraryTab(canEdit: _canEdit, userRole: _userRole);
      case 2:
        return VideosTab(canEdit: _canEdit, userRole: _userRole);
      case 3:
        return _FavoritesTab(canEdit: _canEdit);
      case 4:
        return _ProfileTab(userRole: _userRole);
      case 5:
        return const _TopBooksTab();
      case 6:
        return _AddContentTab(canEdit: _canEdit);
      case 7:
        return const _UserManagementTab();
      case 8:
        return const _RequestsTab();
      case 9:
        return const _CategoriesManagementTab();
      default:
        return HomeTab(searchQuery: _searchQuery);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Para móvil (APK) usar Drawer y BottomNavigationBar, para web usar sidebar fijo
    final isMobile = !kIsWeb;
    
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      drawer: isMobile ? _buildDrawer() : null,
      bottomNavigationBar: isMobile ? _buildBottomNavigationBar() : null,
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F172A),
              Color(0xFF1E293B),
            ],
          ) : OptimizedTheme.primaryGradientLight,
        ),
        child: Row(
          children: [
            // Sidebar fijo solo para web
            if (!isMobile) _buildSidebar(),
            // Contenido principal
            Expanded(
              child: Column(
                children: [
                  _buildAppBar(),
                  Expanded(
                    child: _getSelectedPage(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.yaviracBlueDark.withOpacity(0.9),
            AppColors.yaviracOrange.withOpacity(0.95),
          ],
        ),
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white60,
        currentIndex: _selectedIndex > 4 ? 0 : _selectedIndex,
        onTap: (index) {
          _cachedTabs.clear();
          setState(() => _selectedIndex = index);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_books),
            label: 'Libros',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.video_library),
            label: 'Videos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favoritos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          gradient: Theme.of(context).brightness == Brightness.dark 
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0F172A),
                    Color(0xFF1E293B),
                  ],
                )
              : OptimizedTheme.primaryGradientLight,
        ),
        child: Column(
          children: [
            _buildUserHeader(),
            _buildMenuItems(),
            _buildLogoutButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        gradient: Theme.of(context).brightness == Brightness.dark 
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0F172A),
                    Color(0xFF1E293B),
                  ],
                )
              : OptimizedTheme.primaryGradientLight,
      ),
      child: Column(
        children: [
          _buildUserHeader(),
          _buildMenuItems(),
          _buildLogoutButton(),
        ],
      ),
    );
  }

  Widget _buildUserHeader() {
    return FadeInDown(
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'assets/images/logo.jpeg',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.school,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: AppColors.avatarGradient,
                    shape: BoxShape.circle,
                    boxShadow: [AppColors.avatarShadow],
                  ),
                  child: Center(
                    child: Text(
                      _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
                      style: OptimizedTheme.heading3.copyWith(fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _userName,
                        style: OptimizedTheme.getBodyText(context).copyWith(fontSize: 14, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          gradient: AppColors.roleGradient,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _userRole.toUpperCase(),
                          style: OptimizedTheme.caption.copyWith(
                            color: AppColors.getRoleTextColor(_userRole),
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItems() {
    return Expanded(
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _buildMenuItem(Icons.home, 'Inicio', 0),
          _buildMenuItem(Icons.library_books, 'Libros', 1),
          _buildMenuItem(Icons.video_library, 'Videos', 2),
          _buildMenuItem(Icons.favorite, 'Favoritos', 3),
          _buildMenuItem(Icons.person, 'Perfil', 4),
          const Divider(color: Colors.white24, height: 32),
          _buildMenuItem(Icons.trending_up, 'Top 10 Libros', 5),
          if (_canEdit) _buildMenuItem(Icons.add, 'Agregar Contenido', 6),
          if (_userRole == 'admin' || _userRole == 'administrador') _buildMenuItem(Icons.category, 'Gestionar Categorías', 9),
          if (_userRole == 'admin' || _userRole == 'administrador') _buildMenuItem(Icons.people, 'Gestión de Usuarios', 7),
          if (_userRole == 'admin' || _userRole == 'administrador') _buildMenuItem(Icons.help_center, 'Solicitudes', 8),
          _buildMenuItem(Icons.settings, 'Configuración', -1, onTap: () => setState(() => _selectedIndex = 4)),
          ListTile(
            leading: Icon(Icons.dark_mode, color: OptimizedTheme.getTextColor(context).withOpacity(0.7)),
            title: Text('Modo Oscuro', style: TextStyle(color: OptimizedTheme.getTextColor(context))),
            trailing: Switch(
              value: Provider.of<ThemeProvider>(context).isDarkMode,
              onChanged: (value) {
                Provider.of<ThemeProvider>(context, listen: false).toggleTheme(value);
                // Limpiar caché al cambiar tema
                setState(() => _cachedTabs.clear());
              },
              activeColor: AppColors.yaviracOrange,
            ),
            onTap: () {
               final provider = Provider.of<ThemeProvider>(context, listen: false);
               provider.toggleTheme(!provider.isDarkMode);
               setState(() => _cachedTabs.clear());
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return FadeInUp(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Container(
          width: double.infinity,
          height: 50,
          decoration: BoxDecoration(
            gradient: AppColors.logoutGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [AppColors.logoutShadow],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _logout,
              borderRadius: BorderRadius.circular(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.logout_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Cerrar Sesión',
                    style: OptimizedTheme.bodyText.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    final isMobile = !kIsWeb;
    return Container(
      width: double.infinity,
      height: isMobile ? 60 : 70,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isMobile ? [
            // Móvil: más opaco para que se vea
            AppColors.yaviracBlueDark.withOpacity(0.9),
            AppColors.yaviracOrange.withOpacity(0.8),
          ] : [
            // Web: glassmorphism
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
        ),
        border: isMobile ? null : Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
        child: Row(
          children: [
            // Botón de menú solo para móvil
            if (isMobile)
              Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu, color: Colors.white, size: 24),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
            if (isMobile) const SizedBox(width: 16),
            if (!isMobile) const Spacer(),
            Flexible(
              flex: 8,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      OptimizedTheme.getTextColor(context).withOpacity(0.1),
                      OptimizedTheme.getTextColor(context).withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: OptimizedTheme.getTextColor(context).withOpacity(0.2)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FittedBox(
                      fit: BoxFit.fitWidth,
                      child: Text(
                        'Repositorio Digital de la Biblioteca',
                        style: OptimizedTheme.heading2.copyWith(
                          fontSize: 80,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 15.0,
                          color: OptimizedTheme.getTextColor(context),
                          height: 1.0,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.fitWidth,
                      child: Text(
                        'Alfredo Costales y Piedad Peñaherrera',
                        style: OptimizedTheme.heading2.copyWith(
                          fontSize: 60,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 12.0,
                          color: OptimizedTheme.getTextColor(context).withOpacity(0.9),
                          height: 1.0,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            // Campo de búsqueda para móvil y web
            if (isMobile) _buildMobileSearchField(),
            if (!isMobile) _buildSearchField(),
            if (!isMobile) _buildSearchButton(),
            // Botón de búsqueda para móvil
            if (isMobile) _buildMobileSearchButton(),
            if (!isMobile) const SizedBox(width: 12),
            if (!isMobile) Text(
              _userName,
              style: OptimizedTheme.bodyText.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.white70,
              ),
            ),
            if (!isMobile) const SizedBox(width: 12),
            if (!isMobile) Container(
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.logout, color: Colors.redAccent),
                onPressed: _logout,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileSearchField() {
    return ValueListenableBuilder<bool>(
      valueListenable: _searchingNotifier,
      builder: (context, isSearching, child) {
        return isSearching
            ? Expanded(
                child: Container(
                  height: 40,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.yaviracOrange, width: 1),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.black, fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: 'Buscar...',
                      hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    onChanged: (value) {
                      if (value.trim().isNotEmpty) {
                        _performSearch(value);
                      }
                    },
                    onSubmitted: (value) {
                      _searchingNotifier.value = false;
                      if (value.trim().isNotEmpty) {
                        _performSearch(value);
                      } else {
                        setState(() => _searchQuery = '');
                      }
                    },
                    autofocus: true,
                  ),
                ),
              )
            : const SizedBox.shrink();
      },
    );
  }

  Widget _buildMobileSearchButton() {
    return ValueListenableBuilder<bool>(
      valueListenable: _searchingNotifier,
      builder: (context, isSearching, child) {
        return IconButton(
          icon: Icon(isSearching ? Icons.close : Icons.search, color: Colors.white),
          onPressed: () {
            _searchingNotifier.value = !_searchingNotifier.value;
            if (!_searchingNotifier.value) {
              _searchController.clear();
              setState(() => _searchQuery = '');
            }
          },
        );
      },
    );
  }

  Widget _buildSearchField() {
    return ValueListenableBuilder<bool>(
      valueListenable: _searchingNotifier,
      builder: (context, isSearching, child) {
        return isSearching
            ? Container(
                height: 40,
                width: 250,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.yaviracOrange, width: 1),
                ),
                child: TextField(
                  controller: _searchController,
                  style: OptimizedTheme.bodyText.copyWith(color: Colors.grey.shade800, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Buscar...',
                    hintStyle: OptimizedTheme.bodyTextSmall.copyWith(color: Colors.grey.shade400, fontSize: 14),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  onChanged: (value) {
                    // Búsqueda en tiempo real
                    if (value.trim().isNotEmpty) {
                      _performSearch(value);
                    }
                  },
                  onSubmitted: (value) {
                    _searchingNotifier.value = false;
                    if (value.trim().isNotEmpty) {
                      _performSearch(value);
                    } else {
                      setState(() => _searchQuery = '');
                    }
                  },
                  autofocus: true,
                ),
              )
            : const SizedBox(width: 250);
      },
    );
  }

  Widget _buildSearchButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: ValueListenableBuilder<bool>(
        valueListenable: _searchingNotifier,
        builder: (context, isSearching, child) {
          return IconButton(
            icon: Icon(isSearching ? Icons.close : Icons.search, color: Colors.white70),
            onPressed: () {
              _searchingNotifier.value = !_searchingNotifier.value;
              if (!_searchingNotifier.value) {
                _searchController.clear();
                setState(() => _searchQuery = '');
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, int index, {VoidCallback? onTap}) {
    final isSelected = _selectedIndex == index;
    return FadeInLeft(
      delay: Duration(milliseconds: 100 * index),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.menuItemGradient : null,
          borderRadius: BorderRadius.circular(16),
          border: isSelected ? null : Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              // Cerrar drawer en móvil después de seleccionar
              if (!kIsWeb && Navigator.canPop(context)) {
                Navigator.pop(context);
              }
              if (onTap != null) {
                onTap();
              } else if (index >= 0) {
                // Limpiar caché cuando cambia de tab
                _cachedTabs.clear();
                setState(() => _selectedIndex = index);
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(icon, color: isSelected 
                      ? Colors.white 
                      : OptimizedTheme.getTextColor(context).withOpacity(0.7), size: 24),
                  const SizedBox(width: 16),
                  Text(
                    title,
                    style: OptimizedTheme.getBodyText(context).copyWith(
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? Colors.white : OptimizedTheme.getTextColor(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FavoritesTab extends StatelessWidget {
  final bool canEdit;
  const _FavoritesTab({required this.canEdit});

  Future<List<Map<String, dynamic>>> _loadFavorites() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return [];

    try {
      final response = await Supabase.instance.client
          .from('favorites')
          .select('book_id, books(*)')
          .eq('user_id', user.id);
      
      return response.map((item) => item['books'] as Map<String, dynamic>).toList();
    } catch (e) {
      print('Error loading favorites: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mis Favoritos',
            style: OptimizedTheme.heading2,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _loadFavorites(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.white));
                }
                
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.favorite_border, size: 80, color: Colors.white24),
                        const SizedBox(height: 16),
                        Text(
                          'No tienes favoritos aún',
                          style: OptimizedTheme.heading3.copyWith(fontSize: 18, color: Colors.white54),
                        ),
                      ],
                    ),
                  );
                }
                
                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final book = snapshot.data![index];
                    return GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BookDetailScreen(book: book),
                        ),
                      ),
                      child: GlassmorphicContainer(
                        width: double.infinity,
                        height: double.infinity,
                        borderRadius: 8,
                        blur: 8,
                        alignment: Alignment.center,
                        border: 0,
                        linearGradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.15),
                            Colors.white.withOpacity(0.08),
                          ],
                        ),
                        borderGradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.3),
                            Colors.white.withOpacity(0.1),
                          ],
                        ),
                        child: Column(
                          children: [
                            Expanded(
                              flex: 4,
                              child: Container(
                                margin: const EdgeInsets.all(6),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: book['cover_url'] != null
                                      ? Image.network(
                                          book['cover_url'],
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          errorBuilder: (_, __, ___) => Container(
                                            color: Colors.red.withOpacity(0.2),
                                            child: const Icon(Icons.favorite, size: 30, color: Colors.red),
                                          ),
                                        )
                                      : Container(
                                          color: Colors.red.withOpacity(0.2),
                                          child: const Icon(Icons.favorite, size: 30, color: Colors.red),
                                        ),
                                ),
                              ),
                            ),
                            Flexible(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(6, 0, 6, 6),
                                child: Text(
                                  book['title'] ?? 'Sin título',
                                  style: OptimizedTheme.caption.copyWith(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
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
          ),
        ],
      ),
    );
  }
}

class _ProfileTab extends StatefulWidget {
  final String userRole;
  const _ProfileTab({required this.userRole});

  @override
  State<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<_ProfileTab> {

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white.withOpacity(0.1),
            child: const Icon(Icons.person, size: 50, color: Colors.white),
          ),
          const SizedBox(height: 16),
          FutureBuilder<Map<String, String>>(
            key: ValueKey(DateTime.now().millisecondsSinceEpoch), // Forzar rebuild
            future: _getUserData(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator(color: Colors.white);
              }
              
              final userData = snapshot.data ?? {'name': 'Usuario', 'email': 'user@biblioteca.com'};
              
              return Column(
                children: [
                  Text(
                    userData['name']!,
                    style: OptimizedTheme.heading2,
                  ),
                  Text(
                    userData['email']!,
                    style: OptimizedTheme.bodyTextSmall,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 32),
          _buildProfileTile(Icons.history, 'Historial de lectura'),
          _buildProfileTile(Icons.settings, 'Configuración', onTap: () => _showConfigDialog(context)),
          _buildProfileTile(Icons.help, 'Ayuda', onTap: () => _showHelpDialog(context)),
        ],
      ),
    );
  }

  Future<Map<String, String>> _getUserData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        final userData = await Supabase.instance.client
            .from('users')
            .select('name, email')
            .eq('id', user.id)
            .single();
        
        return {
          'name': userData['name'] ?? 'Usuario',
          'email': userData['email'] ?? user.email ?? 'user@biblioteca.com',
        };
      } catch (e) {
        return {
          'name': 'Usuario',
          'email': user.email ?? 'user@biblioteca.com',
        };
      }
    }
    return {'name': 'Usuario', 'email': 'user@biblioteca.com'};
  }

  void _showConfigDialog(BuildContext context) {
    final nameController = TextEditingController();
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text('Configuración', style: OptimizedTheme.heading3),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: OptimizedTheme.bodyText,
                decoration: InputDecoration(
                  labelText: 'Nuevo nombre',
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
                controller: passwordController,
                style: OptimizedTheme.bodyText,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Nueva contraseña',
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
                controller: confirmPasswordController,
                style: OptimizedTheme.bodyText,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Confirmar contraseña',
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
            onPressed: () async {
              await _updateUserData(context, nameController.text, passwordController.text, confirmPasswordController.text);
            },
            child: Text('Guardar', style: OptimizedTheme.bodyText),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    final requestController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Row(
          children: [
            const Icon(Icons.help, color: Colors.white),
            const SizedBox(width: 8),
            Text('Ayuda y Soporte', style: OptimizedTheme.heading3),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Escribe tu solicitud:',
                style: OptimizedTheme.bodyText.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: requestController,
                maxLines: 5,
                style: OptimizedTheme.bodyText,
                decoration: InputDecoration(
                  hintText: 'Describe tu solicitud aquí...',
                  hintStyle: OptimizedTheme.bodyTextSmall.copyWith(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 2),
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
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextButton(
              onPressed: () {
                if (requestController.text.trim().isNotEmpty) {
                  Navigator.pop(context);
                  _sendRequest(requestController.text, context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Por favor escribe tu solicitud'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Text('Enviar', style: OptimizedTheme.bodyText),
            ),
          ),
        ],
      ),
    );
  }

  void _sendRequest(String request, BuildContext context) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        print('❌ No hay usuario autenticado');
        return;
      }
      
      print('📤 Enviando solicitud: $request');
      print('👤 Usuario ID: ${user.id}');
      
      // Obtener datos del usuario
      final userData = await Supabase.instance.client
          .from('users')
          .select('name, email')
          .eq('id', user.id)
          .single();
      
      final userName = userData['name'] ?? 'Usuario';
      final userEmail = userData['email'] ?? user.email ?? 'usuario@yavirac.edu.ec';
      
      final response = await Supabase.instance.client.from('requests').insert({
        'user_id': user.id,
        'user_name': userName,
        'user_email': userEmail,
        'request_text': request,
        'status': 'pendiente',
      }).select();
      
      print('✅ Respuesta: $response');
      
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Solicitud enviada correctamente'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
      
    } catch (e) {
      print('💥 Error enviando solicitud: $e');
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al enviar solicitud: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateUserData(BuildContext context, String name, String password, String confirmPassword) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // Actualizar nombre si se proporcionó
      if (name.isNotEmpty) {
        await Supabase.instance.client
            .from('users')
            .update({'name': name})
            .eq('id', user.id);
      }

      // Actualizar contraseña si se proporcionó
      if (password.isNotEmpty) {
        if (password != confirmPassword) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Las contraseñas no coinciden')),
          );
          return;
        }
        
        await Supabase.instance.client.auth.updateUser(
          UserAttributes(password: password),
        );
      }

      Navigator.pop(context);
      setState(() {}); // Actualizar UI
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Datos actualizados correctamente')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Widget _buildProfileTile(IconData icon, String title, {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassmorphicContainer(
        width: double.infinity,
        height: 70,
        borderRadius: 12,
        blur: 10,
        alignment: Alignment.center,
        border: 0,
        linearGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
        ),
        borderGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.2),
            Colors.white.withOpacity(0.1),
          ],
        ),
        child: ListTile(
          leading: Icon(icon, color: Colors.white70),
          title: Text(title, style: OptimizedTheme.bodyText),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white54),
          onTap: onTap,
        ),
      ),
    );
  }
}

class _SearchResultsTab extends StatelessWidget {
  final String searchQuery;
  const _SearchResultsTab({required this.searchQuery});

  Future<void> _checkDatabaseContent() async {
    try {
      final allBooks = await Supabase.instance.client.from('books').select().limit(1);
      final allVideos = await Supabase.instance.client.from('videos').select().limit(1);
      
      print('📊 Total libros en BD: ${allBooks.length}');
      print('📊 Total videos en BD: ${allVideos.length}');
      
      if (allBooks.isNotEmpty) {
        print('📚 Columnas libros: ${allBooks.first.keys.toList()}');
        print('📚 Ejemplo libro: ${allBooks.first}');
      }
      if (allVideos.isNotEmpty) {
        print('🎥 Columnas videos: ${allVideos.first.keys.toList()}');
        print('🎥 Ejemplo video: ${allVideos.first}');
      }
    } catch (e) {
      print('❌ Error verificando BD: $e');
    }
  }

  Future<Map<String, List<Map<String, dynamic>>>> _searchContent() async {
    try {
      print('🔍 Buscando: $searchQuery');
      
      // Buscar en libros
      final booksResponse1 = await Supabase.instance.client
          .from('books')
          .select()
          .ilike('title', '%$searchQuery%');
      
      final booksResponse2 = await Supabase.instance.client
          .from('books')
          .select()
          .ilike('author', '%$searchQuery%');
      
      final booksResponse3 = await Supabase.instance.client
          .from('books')
          .select()
          .ilike('category', '%$searchQuery%');
      
      // Buscar en videos
      final videosResponse1 = await Supabase.instance.client
          .from('videos')
          .select()
          .ilike('title', '%$searchQuery%');
      
      final videosResponse2 = await Supabase.instance.client
          .from('videos')
          .select()
          .ilike('category', '%$searchQuery%');
      
      final videosResponse3 = await Supabase.instance.client
          .from('videos')
          .select()
          .ilike('subcategory', '%$searchQuery%');
      
      // Combinar y eliminar duplicados
      final allBooks = [...booksResponse1, ...booksResponse2, ...booksResponse3];
      final uniqueBooks = <String, Map<String, dynamic>>{};
      for (var book in allBooks) {
        uniqueBooks[book['id']] = book;
      }
      
      final allVideos = [...videosResponse1, ...videosResponse2, ...videosResponse3];
      final uniqueVideos = <String, Map<String, dynamic>>{};
      for (var video in allVideos) {
        uniqueVideos[video['id']] = video;
      }
      
      print('✅ Total únicos - Libros: ${uniqueBooks.length}, Videos: ${uniqueVideos.length}');
      
      return {
        'books': uniqueBooks.values.toList(),
        'videos': uniqueVideos.values.toList(),
      };
    } catch (e) {
      print('❌ Error en búsqueda: $e');
      return {'books': [], 'videos': []};
    }
  }

  @override
  Widget build(BuildContext context) {
    // Verificar contenido de la BD al construir
    _checkDatabaseContent();
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  // Limpiar búsqueda
                  final homeState = context.findAncestorStateOfType<_UserHomeState>();
                  homeState?._searchController.clear();
                  homeState?.setState(() {
                    homeState._searchQuery = '';
                    homeState._cachedTabs.clear();
                  });
                },
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Resultados para "$searchQuery"',
                  style: OptimizedTheme.heading2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
              future: _searchContent(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.white));
                }
                
                if (!snapshot.hasData) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off, size: 80, color: Colors.white24),
                        const SizedBox(height: 16),
                        Text(
                          'No se encontraron resultados',
                          style: OptimizedTheme.heading3.copyWith(fontSize: 18, color: Colors.white54),
                        ),
                      ],
                    ),
                  );
                }
                
                final books = snapshot.data!['books']!;
                final videos = snapshot.data!['videos']!;
                
                if (books.isEmpty && videos.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off, size: 80, color: Colors.white24),
                        const SizedBox(height: 16),
                        Text(
                          'No se encontraron resultados',
                          style: OptimizedTheme.heading3.copyWith(fontSize: 18, color: Colors.white54),
                        ),
                      ],
                    ),
                  );
                }
                
                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (books.isNotEmpty) ...[
                        Text(
                          'Libros (${books.length})',
                          style: OptimizedTheme.heading3.copyWith(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            childAspectRatio: 0.75,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: books.length,
                          itemBuilder: (context, index) => _buildBookCard(context, books[index]),
                        ),
                        const SizedBox(height: 24),
                      ],
                      if (videos.isNotEmpty) ...[
                        Text(
                          'Videos (${videos.length})',
                          style: OptimizedTheme.heading3.copyWith(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            childAspectRatio: 0.75,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: videos.length,
                          itemBuilder: (context, index) => _buildVideoCard(context, videos[index]),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookCard(BuildContext context, Map<String, dynamic> book) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BookDetailScreen(book: book),
        ),
      ),
      child: GlassmorphicContainer(
        width: double.infinity,
        height: double.infinity,
        borderRadius: 8,
        blur: 8,
        alignment: Alignment.center,
        border: 0,
        linearGradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.15),
            Colors.white.withOpacity(0.08),
          ],
        ),
        borderGradient: LinearGradient(
          colors: [
            AppColors.yaviracOrange.withOpacity(0.3),
            Colors.white.withOpacity(0.1),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              flex: 4,
              child: Container(
                margin: const EdgeInsets.all(6),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: book['cover_url'] != null
                      ? Image.network(
                          book['cover_url'],
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (_, __, ___) => Container(
                            color: AppColors.yaviracOrange.withOpacity(0.2),
                            child: const Icon(Icons.book, size: 30, color: Colors.white),
                          ),
                        )
                      : Container(
                          color: AppColors.yaviracOrange.withOpacity(0.2),
                          child: const Icon(Icons.book, size: 30, color: Colors.white),
                        ),
                ),
              ),
            ),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(6, 0, 6, 6),
                child: Column(
                  children: [
                    Text(
                      book['title'] ?? 'Sin título',
                      style: OptimizedTheme.caption.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      book['author'] ?? 'Autor desconocido',
                      style: OptimizedTheme.caption.copyWith(
                        fontSize: 8,
                        color: Colors.white70,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoCard(BuildContext context, Map<String, dynamic> video) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MobileVideoPlayer(video: video),
        ),
      ),
      child: GlassmorphicContainer(
        width: double.infinity,
        height: double.infinity,
        borderRadius: 8,
        blur: 8,
        alignment: Alignment.center,
        border: 0,
        linearGradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.15),
            Colors.white.withOpacity(0.08),
          ],
        ),
        borderGradient: LinearGradient(
          colors: [
            AppColors.yaviracBlueDark.withOpacity(0.3),
            Colors.white.withOpacity(0.1),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              flex: 4,
              child: Container(
                margin: const EdgeInsets.all(6),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: video['thumbnail_url'] != null
                          ? Image.network(
                              video['thumbnail_url'],
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder: (_, __, ___) => Container(
                                color: AppColors.yaviracBlueDark.withOpacity(0.2),
                                child: const Icon(Icons.video_library, size: 30, color: Colors.white),
                              ),
                            )
                          : Container(
                              color: AppColors.yaviracBlueDark.withOpacity(0.2),
                              child: const Icon(Icons.video_library, size: 30, color: Colors.white),
                            ),
                    ),
                    const Center(
                      child: Icon(
                        Icons.play_circle_filled,
                        size: 24,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(6, 0, 6, 6),
                child: Column(
                  children: [
                    Text(
                      video['title'] ?? 'Sin título',
                      style: OptimizedTheme.caption.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      video['category'] ?? video['subcategory'] ?? 'Sin categoría',
                      style: OptimizedTheme.caption.copyWith(
                        fontSize: 8,
                        color: Colors.white70,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBooksTab extends StatefulWidget {
  const _TopBooksTab({super.key});

  @override
  State<_TopBooksTab> createState() => _TopBooksTabState();
}

class _TopBooksTabState extends State<_TopBooksTab> {
  
  Future<List<Map<String, dynamic>>> _loadTopBooks() async {
    try {
      final response = await Supabase.instance.client
          .from('book_stats')
          .select('*, books(*)')
          .order('open_count', ascending: false)
          .limit(10);
      return response;
    } catch (e) {
      return [];
    }
  }

  Future<void> _exportStats([String format = 'csv']) async {
    try {
      // Obtener todas las estadísticas
      final stats = await Supabase.instance.client
          .from('book_stats')
          .select('*, books(title, author, category)')
          .order('open_count', ascending: false);
      
      String content;
      String fileName;
      String mimeType;
      
      switch (format) {
        case 'json':
          content = jsonEncode(stats);
          fileName = 'estadisticas_biblioteca_${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}.json';
          mimeType = 'application/json';
          break;
        case 'html':
          content = _generateHtmlReport(stats);
          fileName = 'reporte_biblioteca_${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}.html';
          mimeType = 'text/html';
          break;
        default: // csv
          content = _generateCsv(stats);
          fileName = 'estadisticas_biblioteca_${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}.csv';
          mimeType = 'text/csv';
      }
      
      // Crear blob y descargar
      final bytes = utf8.encode(content);
      final blob = html.Blob([bytes], mimeType);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', fileName)
        ..click();
      html.Url.revokeObjectUrl(url);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Estadísticas exportadas en formato ${format.toUpperCase()}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: $e')),
      );
    }
  }

  String _generateCsv(List<dynamic> stats) {
    String csv = 'Título,Autor,Categoría,Veces Abierto,Última Apertura\n';
    for (var stat in stats) {
      final book = stat['books'];
      csv += '"${book['title'] ?? 'Sin título'}",';
      csv += '"${book['author'] ?? 'Sin autor'}",';
      csv += '"${book['category'] ?? 'Sin categoría'}",';
      csv += '${stat['open_count'] ?? 0},';
      csv += '"${_formatDate(stat['updated_at'])}"\n';
    }
    return csv;
  }

  String _generateHtmlReport(List<dynamic> stats) {
    final now = DateTime.now();
    return '''
<!DOCTYPE html>
<html>
<head>
    <title>Reporte de Estadísticas - Biblioteca</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1 { color: #1E3A8A; }
        table { border-collapse: collapse; width: 100%; margin-top: 20px; }
        th, td { border: 1px solid #ddd; padding: 12px; text-align: left; }
        th { background-color: #f2f2f2; }
        .stats { background-color: #f9f9f9; padding: 15px; border-radius: 5px; margin: 20px 0; }
    </style>
</head>
<body>
    <h1>📊 Reporte de Estadísticas de la Biblioteca</h1>
    <div class="stats">
        <p><strong>Fecha del reporte:</strong> ${now.day}/${now.month}/${now.year}</p>
        <p><strong>Total de libros con estadísticas:</strong> ${stats.length}</p>
        <p><strong>Total de aperturas:</strong> ${stats.fold<int>(0, (sum, stat) => sum + ((stat['open_count'] as int?) ?? 0))}</p>
    </div>
    <table>
        <tr>
            <th>Posición</th>
            <th>Título</th>
            <th>Autor</th>
            <th>Categoría</th>
            <th>Veces Abierto</th>
            <th>Última Apertura</th>
        </tr>
${stats.asMap().entries.map((entry) {
      final index = entry.key + 1;
      final stat = entry.value;
      final book = stat['books'];
      return '''        <tr>
            <td>$index</td>
            <td>${book['title'] ?? 'Sin título'}</td>
            <td>${book['author'] ?? 'Sin autor'}</td>
            <td>${book['category'] ?? 'Sin categoría'}</td>
            <td>${stat['open_count'] ?? 0}</td>
            <td>${_formatDate(stat['updated_at'])}</td>
        </tr>''';
    }).join('\n')}
    </table>
</body>
</html>''';
  }

  Future<bool> _isAdmin() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return false;
      
      final userData = await Supabase.instance.client
          .from('users')
          .select('role')
          .eq('id', user.id)
          .single();
      
      final role = userData['role']?.toString().toLowerCase() ?? '';
      return role == 'admin' || role == 'administrador';
    } catch (e) {
      return false;
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'N/A';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Top 10 Libros Más Leídos',
                  style: OptimizedTheme.heading2,
                ),
              ),
              // Botón de exportar solo para admins
              FutureBuilder<bool>(
                future: _isAdmin(),
                builder: (context, snapshot) {
                  if (snapshot.data == true) {
                    return PopupMenuButton<String>(
                      onSelected: (format) => _exportStats(format),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'csv',
                          child: Row(
                            children: [
                              Icon(Icons.table_chart, size: 16),
                              SizedBox(width: 8),
                              Text('CSV (Excel)'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'json',
                          child: Row(
                            children: [
                              Icon(Icons.code, size: 16),
                              SizedBox(width: 8),
                              Text('JSON (Datos)'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'html',
                          child: Row(
                            children: [
                              Icon(Icons.web, size: 16),
                              SizedBox(width: 8),
                              Text('HTML (Reporte)'),
                            ],
                          ),
                        ),
                      ],
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.yaviracOrange,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.download, size: 16, color: Colors.white),
                            SizedBox(width: 4),
                            Text('Exportar', style: TextStyle(color: Colors.white)),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_drop_down, size: 16, color: Colors.white),
                          ],
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _loadTopBooks(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.white));
                }
                
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Text('No hay estadísticas disponibles', style: OptimizedTheme.bodyTextSmall),
                  );
                }
                
                return ListView.builder(
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final item = snapshot.data![index];
                    final book = item['books'];
                    final openCount = item['open_count'] ?? 0;
                    
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
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withOpacity(0.1),
                            Colors.white.withOpacity(0.05),
                          ],
                        ),
                        borderGradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withOpacity(0.2),
                            Colors.white.withOpacity(0.1),
                          ],
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.yaviracOrange,
                            foregroundColor: Colors.white,
                            child: Text('${index + 1}', style: OptimizedTheme.bodyText.copyWith(fontWeight: FontWeight.bold)),
                          ),
                          title: Text(book['title'] ?? 'Sin título', style: OptimizedTheme.bodyText.copyWith(fontWeight: FontWeight.w600)),
                          subtitle: Text('${book['author'] ?? 'Autor desconocido'} • $openCount lecturas', style: OptimizedTheme.bodyTextSmall),
                          trailing: const Icon(Icons.trending_up, color: Colors.greenAccent),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AddContentTab extends StatelessWidget {
  final bool canEdit;
  const _AddContentTab({required this.canEdit});

  @override
  Widget build(BuildContext context) {
    if (!canEdit) {
      return const Center(
        child: Text('No tienes permisos para agregar contenido', 
                   style: TextStyle(color: Colors.white70)),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Agregar Contenido',
            style: OptimizedTheme.heading2,
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => OptimizedModals.showAddBookModal(
                    context,
                    onSuccess: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Libro agregado exitosamente')),
                      );
                    },
                  ),
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.library_books, size: 64, color: Colors.white),
                        const SizedBox(height: 16),
                        Text(
                          'Agregar Libros',
                          style: OptimizedTheme.heading3.copyWith(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: GestureDetector(
                  onTap: () => OptimizedModals.showAddVideoModal(
                    context,
                    onSuccess: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Video agregado exitosamente')),
                      );
                    },
                  ),
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3B82F6), Color(0xFF1E3A8A)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.video_library, size: 64, color: Colors.white),
                        const SizedBox(height: 16),
                        Text(
                          'Agregar Videos',
                          style: OptimizedTheme.heading3.copyWith(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UserManagementTab extends StatelessWidget {
  const _UserManagementTab();

  @override
  Widget build(BuildContext context) {
    return const UsersManagementScreen();
  }
}

class _CategoriesManagementTab extends StatelessWidget {
  const _CategoriesManagementTab();

  @override
  Widget build(BuildContext context) {
    return const CategoriesManagementScreen();
  }
}

class _RequestsTab extends StatefulWidget {
  const _RequestsTab();

  @override
  State<_RequestsTab> createState() => _RequestsTabState();
}

class _RequestsTabState extends State<_RequestsTab> with AutomaticKeepAliveClientMixin {
  late Stream<List<Map<String, dynamic>>> _requestsStream;
  StreamSubscription? _subscription;
  List<Map<String, dynamic>>? _cachedData;
  Timer? _debounceTimer;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeStream();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _initializeStream() {
    _subscription?.cancel();
    _requestsStream = Supabase.instance.client
        .from('requests')
        .stream(primaryKey: ['id'])
        .eq('status', 'pendiente') // Solo solicitudes pendientes por defecto
        .order('created_at', ascending: false)
        .limit(20) // Limitar a 20 registros
        .map((data) => List<Map<String, dynamic>>.from(data));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Solicitudes de Soporte',
            style: OptimizedTheme.heading2,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _requestsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && _cachedData == null) {
                  return const Center(child: CircularProgressIndicator(color: Colors.white));
                }
                
                final data = snapshot.data ?? _cachedData ?? [];
                if (snapshot.hasData) _cachedData = snapshot.data;
                
                if (data.isEmpty) {
                  return Center(child: Text('No hay solicitudes', style: OptimizedTheme.bodyTextSmall));
                }
                
                return ListView.builder(
                  itemCount: data.length,
                  cacheExtent: 500, // Caché de widgets
                  itemBuilder: (context, index) => _RequestItem(
                    key: ValueKey(data[index]['id']), // Key para optimización
                    request: data[index],
                    onMarkResolved: (id) => _markAsResolved(context, id),
                    onDelete: (id) => _deleteRequest(context, id),
                    onShowDetails: (request) => _showRequestDetails(context, request),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _loadRequests() async {
    try {
      final response = await Supabase.instance.client
          .from('requests')
          .select()
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  void _showRequestDetails(BuildContext context, Map<String, dynamic> request) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(request['title'] ?? 'Solicitud', style: OptimizedTheme.heading3.copyWith(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Usuario: ${request['user_name'] ?? 'Desconocido'}', style: OptimizedTheme.bodyTextSmall),
              Text('Email: ${request['user_email'] ?? 'No disponible'}', style: OptimizedTheme.bodyTextSmall),
              const SizedBox(height: 16),
              Text('Descripción:', style: OptimizedTheme.bodyText.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(request['request_text'] ?? request['description'] ?? 'Sin descripción', style: OptimizedTheme.bodyText),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cerrar', style: OptimizedTheme.bodyTextSmall),
          ),
        ],
      ),
    );
  }

  Future<void> _markAsResolved(BuildContext context, String requestId) async {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      try {
        await Supabase.instance.client
            .from('requests')
            .update({'status': 'resuelto'})
            .eq('id', requestId);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('✅ Solicitud marcada como resuelta', style: OptimizedTheme.bodyText), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('❌ Error: $e', style: OptimizedTheme.bodyText), backgroundColor: Colors.red),
          );
        }
      }
    });
  }

  Future<void> _deleteRequest(BuildContext context, String requestId) async {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      try {
        await Supabase.instance.client
            .from('requests')
            .delete()
            .eq('id', requestId);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('🗑️ Solicitud eliminada', style: OptimizedTheme.bodyText), backgroundColor: Colors.orange),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('❌ Error: $e', style: OptimizedTheme.bodyText), backgroundColor: Colors.red),
          );
        }
      }
    });
  }
}

class _RequestItem extends StatelessWidget {
  final Map<String, dynamic> request;
  final Function(String) onMarkResolved;
  final Function(String) onDelete;
  final Function(Map<String, dynamic>) onShowDetails;

  const _RequestItem({
    super.key,
    required this.request,
    required this.onMarkResolved,
    required this.onDelete,
    required this.onShowDetails,
  });

  @override
  Widget build(BuildContext context) {
    final isResolved = request['status'] == 'resuelto';
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassmorphicContainer(
        width: double.infinity,
        height: 100,
        borderRadius: 12,
        blur: 10,
        alignment: Alignment.center,
        border: 0,
        linearGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            (isResolved ? Colors.green : Colors.orange).withOpacity(0.1),
            (isResolved ? Colors.green : Colors.orange).withOpacity(0.05),
          ],
        ),
        borderGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.2),
            Colors.white.withOpacity(0.1),
          ],
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: isResolved ? Colors.green : Colors.orange,
            child: Icon(
              isResolved ? Icons.check : Icons.help_outline,
              color: Colors.white,
            ),
          ),
          title: Text(
            request['request_text']?.toString().substring(0, request['request_text'].toString().length > 30 ? 30 : request['request_text'].toString().length) ?? 'Solicitud', 
            style: OptimizedTheme.bodyText.copyWith(fontWeight: FontWeight.bold)
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${request['user_name'] ?? 'Usuario'} • ayuda'.toUpperCase(), style: OptimizedTheme.bodyTextSmall),
              Text(isResolved ? 'RESUELTO' : 'PENDIENTE', style: OptimizedTheme.bodyTextSmall.copyWith(color: isResolved ? Colors.green : Colors.orange, fontWeight: FontWeight.bold)),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.visibility, color: Colors.white70),
                onPressed: () => onShowDetails(request),
              ),
              if (!isResolved)
                IconButton(
                  icon: const Icon(Icons.check_circle, color: Colors.green),
                  onPressed: () => OptimizedModals.showConfirmModal(
                    context,
                    title: 'Marcar como Resuelto',
                    message: '¿Estás seguro de que quieres marcar esta solicitud como resuelta?',
                    onConfirm: () => onMarkResolved(request['id'].toString()),
                    confirmText: 'Marcar Resuelto',
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => OptimizedModals.showConfirmModal(
                  context,
                  title: 'Eliminar Solicitud',
                  message: '¿Estás seguro de que quieres eliminar esta solicitud? Esta acción no se puede deshacer.',
                  onConfirm: () => onDelete(request['id'].toString()),
                  confirmText: 'Eliminar',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget reutilizable eliminado - ahora está en common_widgets.dart