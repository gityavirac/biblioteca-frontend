import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/services/supabase_auth_service.dart';
import '../../../data/services/cache_service.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/support_request_model.dart';
import '../../theme/glass_theme.dart';
import '../auth/login_screen.dart';
import 'add_book_screen.dart';
import 'add_physical_book_screen.dart';

class AdminDashboard extends StatefulWidget {
  final SupabaseAuthService authService;
  
  const AdminDashboard({super.key, required this.authService});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  void _logout() {
    widget.authService.logout();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Panel de Administración', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: GlassTheme.glassDecoration.gradient,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
          ),
        ],
      ),
      body: Container(
        decoration: GlassTheme.decorationBackground,
        child: IndexedStack(
          index: _selectedIndex,
          children: const [
            _DashboardTab(),
            _BooksTab(),
            _VideosTab(),
            _UsersTab(),
            _RequestsTab(),
          ],
        ),
      ),
      bottomNavigationBar: GlassmorphicContainer(
        width: double.infinity,
        height: 70,
        borderRadius: 0,
        blur: 20,
        alignment: Alignment.center,
        border: 0,
        linearGradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.3),
            Colors.black.withOpacity(0.3),
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
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: GlassTheme.primaryColor,
          unselectedItemColor: Colors.white54,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard),
              label: 'Dashboard',
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
              icon: Icon(Icons.people),
              label: 'Usuarios',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.support_agent),
              label: 'Solicitudes',
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 100, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Estadísticas', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 16),
          const Row(
            children: [
              Expanded(child: _StatCard(title: 'Total Libros', value: '1,234', icon: Icons.book)),
              SizedBox(width: 16),
              Expanded(child: _StatCard(title: 'Usuarios Activos', value: '567', icon: Icons.people)),
            ],
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              Expanded(child: _StatCard(title: 'Lecturas Hoy', value: '89', icon: Icons.visibility)),
              SizedBox(width: 16),
              Expanded(child: _StatCard(title: 'Nuevos Registros', value: '12', icon: Icons.person_add)),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({required this.title, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return GlassmorphicContainer(
      width: double.infinity,
      height: 120,
      borderRadius: 16,
      blur: 20,
      alignment: Alignment.center,
      border: 2,
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: GlassTheme.secondaryColor),
            const SizedBox(height: 8),
            Text(value, style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            Text(title, style: GoogleFonts.outfit(color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}

class _BooksTab extends StatefulWidget {
  const _BooksTab();

  @override
  State<_BooksTab> createState() => _BooksTabState();
}

class _BooksTabState extends State<_BooksTab> {
  
  Future<List<Map<String, dynamic>>> _loadBooks() async {
    try {
      final response = await Supabase.instance.client
          .from('books')
          .select()
          .order('created_at', ascending: false);
      print('Books loaded: ${response.length}'); // Debug
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error loading books: $e'); // Debug
      return [];
    }
  }
  
  Future<void> _deleteBook(String bookId) async {
    try {
      await Supabase.instance.client
          .from('books')
          .delete()
          .eq('id', bookId);
      
      // Refresh UI
      if (mounted) {
        setState(() {}); // Refresh UI
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Libro eliminado correctamente', style: GoogleFonts.outfit()),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar libro: $e', style: GoogleFonts.outfit()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 100, 16, 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Gestión de Libros', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              Row(
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GlassTheme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AddBookScreen()),
                      );
                      if (result == true) {
                        if (mounted) setState(() {});
                      }
                    },
                    icon: const Icon(Icons.cloud_upload),
                    label: Text('Libro Digital', style: GoogleFonts.outfit()),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AddPhysicalBookScreen()),
                      );
                      if (result == true) {
                        if (mounted) setState(() {});
                      }
                    },
                    icon: const Icon(Icons.location_on),
                    label: Text('Libro Físico', style: GoogleFonts.outfit()),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _loadBooks(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.white));
                }
                
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No hay libros agregados', style: GoogleFonts.outfit(color: Colors.white70)));
                }
                
                return ListView.builder(
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final book = snapshot.data![index];
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
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: book['cover_url'] != null
                                ? Image.network(
                                    book['cover_url'],
                                    width: 40,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(Icons.book, color: Colors.white54),
                                  )
                                : const Icon(Icons.book, color: Colors.white54),
                          ),
                          title: Text(book['title'], style: GoogleFonts.outfit(color: Colors.white)),
                          subtitle: Text('${book['author']} • ${book['format'].toUpperCase()}', style: GoogleFonts.outfit(color: Colors.white70)),
                          trailing: PopupMenuButton(
                            icon: const Icon(Icons.more_vert, color: Colors.white70),
                            color: const Color(0xFF1E293B),
                            itemBuilder: (context) => [
                              PopupMenuItem(value: 'edit', child: Text('Editar', style: GoogleFonts.outfit(color: Colors.white))),
                              PopupMenuItem(value: 'delete', child: Text('Eliminar', style: GoogleFonts.outfit(color: Colors.white))),
                            ],
                            onSelected: (value) {
                              if (value == 'delete') {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    backgroundColor: const Color(0xFF1E293B),
                                    title: Text('Confirmar eliminación', style: GoogleFonts.outfit(color: Colors.white)),
                                    content: Text('¿Estás seguro de que quieres eliminar este libro?', style: GoogleFonts.outfit(color: Colors.white70)),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: Text('Cancelar', style: GoogleFonts.outfit(color: Colors.white70)),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                          _deleteBook(book['id']);
                                        },
                                        child: Text('Eliminar', style: GoogleFonts.outfit(color: Colors.red)),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            },
                          ),
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

class _VideosTab extends StatefulWidget {
  const _VideosTab();

  @override
  State<_VideosTab> createState() => _VideosTabState();
}

class _VideosTabState extends State<_VideosTab> {
  
  Future<List<Map<String, dynamic>>> _loadVideos() async {
    try {
      final response = await Supabase.instance.client
          .from('videos')
          .select()
          .order('created_at', ascending: false);
      print('Videos loaded: ${response.length}'); // Debug
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error loading videos: $e'); // Debug
      return [];
    }
  }
  
  Future<void> _deleteVideo(String videoId) async {
    try {
      await Supabase.instance.client
          .from('videos')
          .delete()
          .eq('id', videoId);
      
      // Refresh UI
      if (mounted) {
        setState(() {}); // Refresh UI
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Video eliminado correctamente', style: GoogleFonts.outfit()),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar video: $e', style: GoogleFonts.outfit()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAddVideoDialog() {
    final titleController = TextEditingController();
    final urlController = TextEditingController();
    final categoryController = TextEditingController();
    final descriptionController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text('Agregar Video', style: GoogleFonts.outfit(color: Colors.grey[800])),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                style: GoogleFonts.outfit(color: Colors.grey[800]),
                decoration: InputDecoration(
                  labelText: 'Título del video',
                  labelStyle: GoogleFonts.outfit(color: Colors.grey[600]),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF1E3A8A)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: urlController,
                style: GoogleFonts.outfit(color: Colors.grey[800]),
                decoration: InputDecoration(
                  labelText: 'URL del video (YouTube)',
                  labelStyle: GoogleFonts.outfit(color: Colors.grey[600]),
                  hintText: 'https://www.youtube.com/watch?v=...',
                  hintStyle: GoogleFonts.outfit(color: Colors.grey[500]),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF1E3A8A)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: categoryController,
                style: GoogleFonts.outfit(color: Colors.grey[800]),
                decoration: InputDecoration(
                  labelText: 'Categoría',
                  labelStyle: GoogleFonts.outfit(color: Colors.grey[600]),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF1E3A8A)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                maxLines: 3,
                style: GoogleFonts.outfit(color: Colors.grey[800]),
                decoration: InputDecoration(
                  labelText: 'Descripción',
                  labelStyle: GoogleFonts.outfit(color: Colors.grey[600]),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF1E3A8A)),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: GoogleFonts.outfit(color: Colors.grey[600])),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextButton(
              onPressed: () => _addVideo(
                titleController.text,
                urlController.text,
                categoryController.text,
                descriptionController.text,
              ),
              child: Text('Agregar', style: GoogleFonts.outfit(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addVideo(String title, String url, String category, String description) async {
    if (title.isEmpty || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Título y URL son obligatorios')),
      );
      return;
    }

    try {
      // Extraer video ID de YouTube
      String? videoId = _extractYouTubeId(url);
      if (videoId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('URL de YouTube inválida')),
        );
        return;
      }

      await Supabase.instance.client.from('videos').insert({
        'title': title,
        'video_id': url,
        'category': category.isEmpty ? 'General' : category,
        'description': description,
        'thumbnail_url': 'https://img.youtube.com/vi/$videoId/maxresdefault.jpg',
        'views': 0,
        'created_at': DateTime.now().toIso8601String(),
      });

      Navigator.pop(context);
      setState(() {}); // Refresh
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Video agregado correctamente'),
          backgroundColor: Color(0xFF1E3A8A),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  String? _extractYouTubeId(String url) {
    RegExp regExp = RegExp(
      r'(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})',
      caseSensitive: false,
    );
    Match? match = regExp.firstMatch(url);
    return match?.group(1);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 100, 16, 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Gestión de Videos', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _showAddVideoDialog,
                icon: const Icon(Icons.add),
                label: Text('Agregar Video', style: GoogleFonts.outfit()),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _loadVideos(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.white));
                }
                
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No hay videos agregados', style: GoogleFonts.outfit(color: Colors.white70)));
                }
                
                return ListView.builder(
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final video = snapshot.data![index];
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
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: video['thumbnail_url'] != null
                                ? Image.network(
                                    video['thumbnail_url'],
                                    width: 60,
                                    height: 40,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(Icons.video_library, color: Colors.white54),
                                  )
                                : const Icon(Icons.video_library, color: Colors.white54),
                          ),
                          title: Text(video['title'], style: GoogleFonts.outfit(color: Colors.white)),
                          subtitle: Text('${video['category']} • ${video['views']} vistas', style: GoogleFonts.outfit(color: Colors.white70)),
                          trailing: PopupMenuButton(
                            icon: const Icon(Icons.more_vert, color: Colors.white70),
                            color: const Color(0xFF1E293B),
                            itemBuilder: (context) => [
                              PopupMenuItem(value: 'edit', child: Text('Editar', style: GoogleFonts.outfit(color: Colors.white))),
                              PopupMenuItem(value: 'delete', child: Text('Eliminar', style: GoogleFonts.outfit(color: Colors.white))),
                            ],
                            onSelected: (value) {
                              if (value == 'delete') {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    backgroundColor: const Color(0xFF1E293B),
                                    title: Text('Confirmar eliminación', style: GoogleFonts.outfit(color: Colors.white)),
                                    content: Text('¿Estás seguro de que quieres eliminar este video?', style: GoogleFonts.outfit(color: Colors.white70)),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: Text('Cancelar', style: GoogleFonts.outfit(color: Colors.white70)),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                          _deleteVideo(video['id']);
                                        },
                                        child: Text('Eliminar', style: GoogleFonts.outfit(color: Colors.red)),
                                      ),
                                    ],
                                  ),
                                );
                              } else if (value == 'edit') {
                                // Implementar edición de video si es necesario
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Función de editar en desarrollo', style: GoogleFonts.outfit())),
                                );
                              }
                            },
                          ),
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

class _UsersTab extends StatefulWidget {
  const _UsersTab();

  @override
  State<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<_UsersTab> {
  String? debugInfo;
  
  Future<List<Map<String, dynamic>>> _loadUsers() async {
    try {
      print('Intentando cargar usuarios...');
      setState(() => debugInfo = 'Cargando usuarios...');
      
      // Primero intentar con la función debug
      try {
        final debugResponse = await Supabase.instance.client
            .rpc('get_all_users_debug');
        print('Usuarios cargados con función debug: ${debugResponse.length}');
        setState(() => debugInfo = 'Cargados ${debugResponse.length} usuarios con función debug');
        if (debugResponse.isNotEmpty) {
          return List<Map<String, dynamic>>.from(debugResponse);
        }
      } catch (debugError) {
        print('Error con función debug: $debugError');
        setState(() => debugInfo = 'Error con función debug: $debugError');
      }
      
      // Si falla, intentar consulta directa
      final response = await Supabase.instance.client
          .from('users')
          .select()
          .order('created_at', ascending: false);
      
      print('Usuarios cargados con consulta directa: ${response.length}');
      setState(() => debugInfo = 'Cargados ${response.length} usuarios con consulta directa');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error cargando usuarios: $e');
      setState(() => debugInfo = 'Error: $e');
      return [];
    }
  }
  
  Future<void> _deleteUser(String userId) async {
    try {
      await Supabase.instance.client
          .from('users')
          .delete()
          .eq('id', userId);
      setState(() {}); // Refresh
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Usuario eliminado', style: GoogleFonts.outfit())),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e', style: GoogleFonts.outfit())),
        );
      }
    }
  }

  Future<void> _changeUserRole(String userId, String newRole) async {
    try {
      await Supabase.instance.client
          .from('users')
          .update({'role': newRole})
          .eq('id', userId);
      setState(() {}); // Refresh
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rol actualizado', style: GoogleFonts.outfit())),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e', style: GoogleFonts.outfit())),
        );
      }
    }
  }

  void _showRoleDialog(String userId, String currentRole) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text('Cambiar Rol', style: GoogleFonts.outfit(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            'lector', 'profesor', 'bibliotecario', 'admin'
          ].map((role) => ListTile(
            title: Text(role.toUpperCase(), style: GoogleFonts.outfit(color: Colors.white)),
            leading: Radio<String>(
              value: role,
              groupValue: currentRole,
              onChanged: (value) {
                Navigator.pop(context);
                if (value != null) _changeUserRole(userId, value);
              },
              activeColor: GlassTheme.primaryColor,
            ),
          )).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 100, 16, 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Gestión de Usuarios', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
          if (debugInfo != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.5)),
              ),
              child: Text(
                'Debug: $debugInfo',
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 12),
              ),
            ),
          const SizedBox(height: 16),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _loadUsers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.white));
                }
                
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.people_outline, size: 64, color: Colors.white54),
                        const SizedBox(height: 16),
                        Text('No hay usuarios registrados', style: GoogleFonts.outfit(fontSize: 18, color: Colors.white70)),
                        const SizedBox(height: 8),
                        Text('Los usuarios aparecerán aquí cuando se registren en la aplicación', style: GoogleFonts.outfit(color: Colors.white54)),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: GlassTheme.primaryColor,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => setState(() {}),
                          icon: const Icon(Icons.refresh),
                          label: Text('Recargar', style: GoogleFonts.outfit()),
                        ),
                      ],
                    ),
                  );
                }
                
                return ListView.builder(
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final user = snapshot.data![index];
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
                            backgroundColor: _getRoleColor(user['role']),
                            child: const Icon(Icons.person, color: Colors.white),
                          ),
                          title: Text(user['name'] ?? 'Sin nombre', style: GoogleFonts.outfit(color: Colors.white)),
                          subtitle: Text('${user['email']} • ${user['role'].toUpperCase()}', style: GoogleFonts.outfit(color: Colors.white70)),
                          trailing: PopupMenuButton(
                            icon: const Icon(Icons.more_vert, color: Colors.white70),
                            color: const Color(0xFF1E293B),
                            itemBuilder: (context) => [
                              PopupMenuItem(value: 'role', child: Text('Cambiar Rol', style: GoogleFonts.outfit(color: Colors.white))),
                              PopupMenuItem(value: 'delete', child: Text('Eliminar', style: GoogleFonts.outfit(color: Colors.white))),
                            ],
                            onSelected: (value) {
                              if (value == 'delete') {
                                _deleteUser(user['id']);
                              } else if (value == 'role') {
                                _showRoleDialog(user['id'], user['role']);
                              }
                            },
                          ),
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

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin': return Colors.red;
      case 'bibliotecario': return Colors.blue;
      case 'profesor': return Colors.green;
      case 'lector': return Colors.orange;
      default: return Colors.grey;
    }
  }
}

class _RequestsTab extends StatefulWidget {
  const _RequestsTab();

  @override
  State<_RequestsTab> createState() => _RequestsTabState();
}

class _RequestsTabState extends State<_RequestsTab> {
  
  Future<List<Map<String, dynamic>>> _loadRequests() async {
    try {
      final response = await Supabase.instance.client
          .from('requests')
          .select('*, users(name, email)')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }
  
  Future<void> _markAsResolved(String requestId) async {
    try {
      await Supabase.instance.client
          .from('requests')
          .update({
            'status': 'resuelto',
            'resolved_at': DateTime.now().toIso8601String(),
          })
          .eq('id', requestId);
      setState(() {}); // Refresh
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Solicitud marcada como resuelta', style: GoogleFonts.outfit())),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e', style: GoogleFonts.outfit())),
        );
      }
    }
  }
  
  Future<void> _deleteRequest(String requestId) async {
    try {
      await Supabase.instance.client
          .from('requests')
          .delete()
          .eq('id', requestId);
      setState(() {}); // Refresh
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Solicitud eliminada', style: GoogleFonts.outfit())),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e', style: GoogleFonts.outfit())),
        );
      }
    }
  }

  void _showRequestDetails(Map<String, dynamic> request) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(request['title'], style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Usuario: ${request['users']?['name'] ?? 'Desconocido'}', style: GoogleFonts.outfit(color: Colors.white70)),
              Text('Email: ${request['users']?['email'] ?? 'No disponible'}', style: GoogleFonts.outfit(color: Colors.white70)),
              Text('Tipo: ${request['type'].toUpperCase()}', style: GoogleFonts.outfit(color: Colors.white70)),
              const SizedBox(height: 16),
              Text('Descripción:', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(request['description'], style: GoogleFonts.outfit(color: Colors.white)),
              ),
            ],
          ),
        ),
        actions: [
          if (request['status'] == 'pendiente')
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _markAsResolved(request['id']);
              },
              child: Text('Marcar como Resuelto', style: GoogleFonts.outfit(color: Colors.green)),
            ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteRequest(request['id']);
            },
            child: Text('Eliminar', style: GoogleFonts.outfit(color: Colors.red)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cerrar', style: GoogleFonts.outfit(color: Colors.white70)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 100, 16, 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Solicitudes de Soporte', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _loadRequests(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.white));
                }
                
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No hay solicitudes', style: GoogleFonts.outfit(color: Colors.white70)));
                }
                
                return ListView.builder(
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final request = snapshot.data![index];
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
                          title: Text(request['title'], style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${request['users']?['name'] ?? 'Usuario'} • ${request['type'].toUpperCase()}', style: GoogleFonts.outfit(color: Colors.white70)),
                              Text(isResolved ? 'RESUELTO' : 'PENDIENTE', style: GoogleFonts.outfit(color: isResolved ? Colors.green : Colors.orange, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.visibility, color: Colors.white70),
                                onPressed: () => _showRequestDetails(request),
                              ),
                              if (!isResolved)
                                IconButton(
                                  icon: const Icon(Icons.check_circle, color: Colors.green),
                                  onPressed: () => _markAsResolved(request['id']),
                                ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteRequest(request['id']),
                              ),
                            ],
                          ),
                          onTap: () => _showRequestDetails(request),
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