import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:glassmorphism/glassmorphism.dart';
import '../../data/services/cache_service.dart';
import '../screens/user/mobile_video_player.dart';

class VideoListWidget extends StatelessWidget {
  final Future<List<Map<String, dynamic>>> future;
  final bool canEdit;
  final String userRole;
  final VoidCallback onRefresh;

  const VideoListWidget({
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
          return SizedBox(height: 200, child: Center(child: Text('No hay videos disponibles', style: GoogleFonts.outfit(color: Colors.white70))));
        }
        return _buildVideoList(snapshot.data!, context);
      },
    );
  }

  Widget _buildVideoList(List<Map<String, dynamic>> videos, BuildContext context) {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: videos.length,
        itemBuilder: (context, index) {
          final video = videos[index];
          return Container(
            width: 280,
            margin: const EdgeInsets.only(right: 16),
            child: Stack(
              children: [
                GestureDetector(
                  onTap: () {
                    print('🎬 DEBUG: Tapping video: ${video['title']}');
                    print('🎬 DEBUG: Video data: $video');
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MobileVideoPlayer(video: video),
                      ),
                    );
                  },
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
                        Expanded(
                          flex: 2,
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                            child: video['thumbnail_url'] != null
                                ? Image.network(
                                    video['thumbnail_url'],
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      color: Colors.grey.shade800,
                                      child: const Icon(Icons.video_library, size: 40, color: Colors.white54),
                                    ),
                                  )
                                : Container(
                                    color: Colors.grey.shade800,
                                    child: const Icon(Icons.video_library, size: 40, color: Colors.white54),
                                  ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Flexible(
                                  child: Text(
                                    video['title'] ?? 'Sin título',
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Flexible(
                                  child: Text(
                                    video['category'] ?? 'Sin categoría',
                                    style: GoogleFonts.outfit(
                                      fontSize: 10,
                                      color: Colors.white70,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (video['views'] != null)
                                  Flexible(
                                    child: Text(
                                      '${video['views']} vistas',
                                      style: GoogleFonts.outfit(
                                        fontSize: 9,
                                        color: Colors.white54,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (canEdit && (userRole == 'bibliotecario' || userRole == 'admin'))
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
                      onSelected: (value) => _handleMenuAction(value, video, context),
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
                        if (userRole == 'admin')
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

  void _handleMenuAction(String action, Map<String, dynamic> video, BuildContext context) {
    if (action == 'edit') {
      _showEditDialog(context, video);
    } else if (action == 'delete' && userRole == 'admin') {
      _showDeleteDialog(context, video);
    }
  }

  void _showEditDialog(BuildContext context, Map<String, dynamic> video) {
    final titleController = TextEditingController(text: video['title'] ?? '');
    final urlController = TextEditingController(text: video['video_id'] ?? '');
    final descriptionController = TextEditingController(text: video['description'] ?? '');
    final thumbnailController = TextEditingController(text: video['thumbnail_url'] ?? '');
    String selectedCategory = video['category'] ?? 'General';
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: Text('Editar Video', style: GoogleFonts.outfit(color: Colors.white)),
          content: SizedBox(
            width: 500,
            height: 400,
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
                    controller: urlController,
                    style: GoogleFonts.outfit(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'URL del Video',
                      labelStyle: GoogleFonts.outfit(color: Colors.white70),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white.withOpacity(0.3))),
                      focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.orange)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: thumbnailController,
                    style: GoogleFonts.outfit(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'URL de la portada (opcional)',
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
                  await Supabase.instance.client.from('videos').update({
                    'title': titleController.text,
                    'video_id': urlController.text,
                    'description': descriptionController.text.isEmpty ? null : descriptionController.text,
                    'category': selectedCategory,
                    'thumbnail_url': thumbnailController.text.isEmpty ? null : thumbnailController.text,
                  }).eq('id', video['id']);
                  
                  Navigator.pop(context);
                  onRefresh();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Video actualizado correctamente', style: GoogleFonts.outfit()), backgroundColor: Colors.green),
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

  void _showDeleteDialog(BuildContext context, Map<String, dynamic> video) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text('Eliminar video', style: GoogleFonts.outfit(color: Colors.white)),
        content: Text('¿Seguro que quieres eliminar este video?', style: GoogleFonts.outfit(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: GoogleFonts.outfit(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await Supabase.instance.client.from('videos').delete().eq('id', video['id']);
                onRefresh();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Video eliminado correctamente', style: GoogleFonts.outfit()), backgroundColor: Colors.green),
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