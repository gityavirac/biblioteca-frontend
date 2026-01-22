import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/glass_theme.dart';

class FlipBookReader extends StatefulWidget {
  final Map<String, dynamic> book;

  const FlipBookReader({super.key, required this.book});

  @override
  State<FlipBookReader> createState() => _FlipBookReaderState();
}

class _FlipBookReaderState extends State<FlipBookReader> with TickerProviderStateMixin {
  String? _localFilePath;
  bool _isLoading = true;
  String? _errorMessage;
  PdfDocument? _document;
  int _currentPage = 1;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  bool _showControls = true;
  bool _isFullScreen = false;
  bool _isDarkMode = false;
  bool _isFavorite = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_fadeController);
    _fadeController.forward();
    _loadPdf();
    _checkIfFavorite();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _checkIfFavorite() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final response = await Supabase.instance.client
          .from('favorites')
          .select()
          .eq('user_id', user.id)
          .eq('book_id', widget.book['id'])
          .maybeSingle();
      
      setState(() {
        _isFavorite = response != null;
      });
    } catch (e) {
      print('Error checking favorite: $e');
    }
  }

  void _toggleFavorite() async {
    print('🔥 DEBUG: _toggleFavorite() llamado');
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      if (_isFavorite) {
        await Supabase.instance.client
            .from('favorites')
            .delete()
            .eq('user_id', user.id)
            .eq('book_id', widget.book['id']);
      } else {
        await Supabase.instance.client
            .from('favorites')
            .insert({
          'user_id': user.id,
          'book_id': widget.book['id'],
        });
      }
      
      setState(() {
        _isFavorite = !_isFavorite;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isFavorite ? 'Agregado a favoritos' : 'Eliminado de favoritos'),
          backgroundColor: const Color(0xFF1E3A8A),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      print('🔥 DEBUG: Tecla presionada: ${event.logicalKey}, _isFullScreen: $_isFullScreen');
      switch (event.logicalKey) {
        case LogicalKeyboardKey.escape:
          print('🔥 DEBUG: ESC detectado, _isFullScreen: $_isFullScreen');
          if (_isFullScreen) {
            print('🔥 DEBUG: ESC en pantalla completa - saliendo de fullscreen');
            setState(() {
              _isFullScreen = false;
              _showControls = true;
            });
            return; // Evitar propagación
          } else {
            print('🔥 DEBUG: ESC normal - cerrando libro');
            Navigator.pop(context);
            return; // Evitar propagación
          }
        case LogicalKeyboardKey.arrowLeft:
        case LogicalKeyboardKey.arrowUp:
          _previousPage();
          break;
        case LogicalKeyboardKey.arrowRight:
        case LogicalKeyboardKey.arrowDown:
          _nextPage();
          break;
      }
    }
  }

  void _toggleFullScreen() {
    print('🔥 DEBUG: _toggleFullScreen() llamado - Estado actual: $_isFullScreen');
    setState(() {
      _isFullScreen = !_isFullScreen;
      _showControls = !_isFullScreen;
    });
    print('🔥 DEBUG: _toggleFullScreen() - Nuevo estado: $_isFullScreen');
  }

  Future<void> _loadPdf() async {
    try {
      final url = widget.book['file_url'];
      if (url == null) throw Exception('URL del libro no encontrada');

      if (kIsWeb) {
        final document = await PdfDocument.openUri(Uri.parse(url));
        setState(() {
          _document = document;
          _isLoading = false;
        });
        return;
      }

      final dir = await getApplicationDocumentsDirectory();
      final fileName = '${widget.book['id']}.pdf';
      final file = File('${dir.path}/$fileName');

      if (await file.exists()) {
        _openPdfFromFile(file.path);
        return;
      }

      await Dio().download(url, file.path);
      _openPdfFromFile(file.path);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error descargando el libro: $e';
      });
    }
  }

  Future<void> _openPdfFromFile(String path) async {
    try {
      final document = await PdfDocument.openFile(path);
      setState(() {
        _localFilePath = path;
        _document = document;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error abriendo el PDF: $e';
      });
    }
  }

  void _nextPage() {
    print('🔥 DEBUG: _nextPage() llamado - Página actual: $_currentPage');
    if (_document != null && _currentPage < _document!.pages.length) {
      setState(() {
        _currentPage++;
      });
    }
  }

  void _previousPage() {
    print('🔥 DEBUG: _previousPage() llamado - Página actual: $_currentPage');
    if (_currentPage > 1) {
      setState(() {
        _currentPage--;
      });
    }
  }

  void _toggleControls() {
    print('🔥 DEBUG: _toggleControls() llamado - _isFullScreen: $_isFullScreen, _showControls: $_showControls');
    if (!_isFullScreen) {
      setState(() {
        _showControls = !_showControls;
      });
    } else {
      // Si ya está en fullscreen, solo cambiar controles
      setState(() {
        _showControls = !_showControls;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: _isDarkMode ? [
                Colors.black,
                const Color(0xFF1A1A1A),
              ] : [
                const Color(0xFF0F0F23),
                const Color(0xFF1A1A2E),
              ],
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    if (_showControls && !_isFullScreen) _buildHeader(),
                    Expanded(
                      child: _isLoading
                          ? _buildLoadingWidget()
                          : _errorMessage != null
                              ? _buildErrorWidget()
                              : _buildBookViewer(),
                    ),
                    if (_showControls && !_isFullScreen) _buildBottomControls(),
                  ],
                ),
                if (_isFullScreen) 
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: _buildFloatingHeader(),
                  ),
                if (!_isLoading && _errorMessage == null) 
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    top: _showControls && !_isFullScreen ? 100 : (_isFullScreen ? 80 : 0),
                    child: _buildNavigationOverlay(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: const CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Cargando libro...',
            style: GoogleFonts.outfit(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 50),
            const SizedBox(height: 15),
            Text(
              _errorMessage!,
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.black.withOpacity(0.3),
              Colors.transparent,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Row(
          children: [
            GlassmorphicContainer(
              width: 45,
              height: 45,
              borderRadius: 22.5,
              blur: 15,
              alignment: Alignment.center,
              border: 0,
              linearGradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.15),
                  Colors.white.withOpacity(0.05),
                ],
              ),
              borderGradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.3),
                  Colors.white.withOpacity(0.1),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                onPressed: () {
                  print('🔥 DEBUG: Botón ATRÁS presionado');
                  Navigator.pop(context);
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.book['title'] ?? 'Libro',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    widget.book['author'] ?? 'Autor desconocido',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            _buildHeaderButton(
              icon: _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.red : Colors.white,
              onTap: _toggleFavorite,
            ),
            const SizedBox(width: 8),
            _buildHeaderButton(
              icon: _isDarkMode ? Icons.light_mode : Icons.dark_mode,
              color: Colors.white,
              onTap: () {
                setState(() {
                  _isDarkMode = !_isDarkMode;
                });
              },
            ),
            const SizedBox(width: 8),
            _buildHeaderButton(
              icon: _isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
              color: Colors.white,
              onTap: () {
                print('🔥 DEBUG: Botón PANTALLA COMPLETA presionado');
                _toggleFullScreen();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GlassmorphicContainer(
      width: 45,
      height: 45,
      borderRadius: 22.5,
      blur: 15,
      alignment: Alignment.center,
      border: 0,
      linearGradient: LinearGradient(
        colors: [
          Colors.white.withOpacity(0.15),
          Colors.white.withOpacity(0.05),
        ],
      ),
      borderGradient: LinearGradient(
        colors: [
          Colors.white.withOpacity(0.3),
          Colors.white.withOpacity(0.1),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            print('🔥 DEBUG: HeaderButton presionado');
            onTap();
          },
          borderRadius: BorderRadius.circular(22.5),
          child: Container(
            width: 45,
            height: 45,
            alignment: Alignment.center,
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBookViewer() {
    if (_document == null) return const SizedBox();

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: _isFullScreen ? 0 : 20, 
        vertical: _isFullScreen ? 0 : 10
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_isFullScreen ? 0 : 15),
        boxShadow: _isFullScreen ? [] : [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_isFullScreen ? 0 : 15),
        child: Container(
          decoration: BoxDecoration(
            color: _isDarkMode ? Colors.black : Colors.white,
            borderRadius: BorderRadius.circular(_isFullScreen ? 0 : 15),
          ),
          width: double.infinity,
          height: double.infinity,
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 3.0,
            panEnabled: true,
            scaleEnabled: true,
            child: ColorFiltered(
              colorFilter: _isDarkMode 
                ? const ColorFilter.matrix([
                    -1.0, 0.0, 0.0, 0.0, 255.0,
                    0.0, -1.0, 0.0, 0.0, 255.0,
                    0.0, 0.0, -1.0, 0.0, 255.0,
                    0.0, 0.0, 0.0, 1.0, 0.0,
                  ])
                : const ColorFilter.matrix([
                    1.0, 0.0, 0.0, 0.0, 0.0,
                    0.0, 1.0, 0.0, 0.0, 0.0,
                    0.0, 0.0, 1.0, 0.0, 0.0,
                    0.0, 0.0, 0.0, 1.0, 0.0,
                  ]),
              child: PdfPageView(
                key: ValueKey('${_currentPage}_${_isDarkMode}'),
                document: _document!,
                pageNumber: _currentPage,
                alignment: Alignment.center,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    if (_document == null) return const SizedBox();

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.3),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Página $_currentPage de ${_document!.pages.length}',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.black.withOpacity(0.7),
            Colors.transparent,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _buildFloatingButton(
            icon: _isFavorite ? Icons.favorite : Icons.favorite_border,
            color: _isFavorite ? Colors.red : Colors.white,
            onTap: _toggleFavorite,
          ),
          const SizedBox(width: 8),
          _buildFloatingButton(
            icon: _isDarkMode ? Icons.light_mode : Icons.dark_mode,
            color: Colors.white,
            onTap: () {
              print('🔥 DEBUG: Botón MODO OSCURO presionado');
              setState(() {
                _isDarkMode = !_isDarkMode;
              });
            },
          ),
          const SizedBox(width: 8),
          _buildFloatingButton(
            icon: Icons.fullscreen_exit,
            color: Colors.white,
            onTap: _toggleFullScreen,
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }

  Widget _buildNavigationOverlay() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: GestureDetector(
            onTap: _previousPage,
            child: Container(
              color: Colors.transparent,
              child: _currentPage > 1
                  ? Center(
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withOpacity(0.7),
                              Colors.black.withOpacity(0.5),
                            ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.chevron_left,
                          color: Colors.white,
                          size: 35,
                        ),
                      ),
                    )
                  : const SizedBox(),
            ),
          ),
        ),
        Expanded(
          flex: 4, 
          child: GestureDetector(
            onTap: () {
              print('🔥 DEBUG: Clic en centro - activando fullscreen');
              _toggleFullScreen();
            },
            child: Container(
              color: Colors.transparent,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: GestureDetector(
            onTap: _nextPage,
            child: Container(
              color: Colors.transparent,
              child: _document != null && _currentPage < _document!.pages.length
                  ? Center(
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withOpacity(0.7),
                              Colors.black.withOpacity(0.5),
                            ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.chevron_right,
                          color: Colors.white,
                          size: 35,
                        ),
                      ),
                    )
                  : const SizedBox(),
            ),
          ),
        ),
      ],
    );
  }
}