# 📚 Biblioteca Digital Yavirac - Documentación de Estructura

## 🔧 Tecnologías Principales

| Tecnología | Versión | Uso |
|---|---|---|
| Flutter | SDK ^3.5.4 | Framework principal |
| Supabase | ^2.5.6 | Backend (BD + Auth + Storage) |
| Provider | ^6.1.5 | Manejo de estado (tema) |
| pdfrx | ^1.0.88 | Lector de PDF en web/móvil |
| youtube_player_iframe | ^5.1.2 | Reproductor de videos YouTube |
| glassmorphism | ^3.0.0 | Efectos visuales de vidrio |
| google_fonts | ^6.1.0 | Tipografías (Outfit, Orbitron) |
| file_picker | ^8.0.0 | Selección de archivos para subir |
| dio | ^5.4.0 | Descarga de PDFs en móvil |

---

## 🗄️ Base de Datos (Supabase)

### Tablas principales

| Tabla | Descripción |
|---|---|
| `books` | Libros digitales y físicos |
| `videos` | Videos de YouTube |
| `users` | Usuarios del sistema |
| `favorites` | Libros favoritos por usuario |
| `book_stats` | Estadísticas de lecturas por libro |
| `book_opens_history` | Historial de aperturas |
| `reading_history` | Historial de lectura |
| `requests` | Solicitudes de soporte |
| `categories` | Categorías de libros |
| `subcategories` | Subcategorías de libros |

### Campos importantes de `books`

| Campo | Tipo | Descripción |
|---|---|---|
| `id` | UUID | ID único |
| `title` | text | Título del libro |
| `author` | text | Autor |
| `file_url` | text | URL del PDF/EPUB |
| `cover_url` | text | URL de la portada |
| `category` | text | Categoría |
| `subcategory` | text | Subcategoría |
| `format` | text | `pdf` o `epub` |
| `is_physical` | bool | Si es libro físico |
| `is_physical_only` | bool | Si es solo físico (sin archivo) |
| `physical_location` | text | Ubicación en biblioteca |
| `codigo_fisico` | text | Código físico del libro |
| `created_by` | UUID | ID del usuario que lo subió |

### Roles de usuarios

| Rol | Permisos |
|---|---|
| `lector` | Solo ver y leer libros |
| `profesor` | Ver + subir/editar/eliminar sus propios libros |
| `bibliotecario` | Ver + subir/editar/eliminar sus propios libros |
| `admin` / `administrador` | Control total sobre todos los libros y usuarios |

### Función SQL importante

```sql
-- Elimina un libro y todas sus relaciones (favoritos, stats, historial)
-- Usa SECURITY DEFINER para ignorar RLS
CREATE OR REPLACE FUNCTION delete_book_complete(p_book_id UUID)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  DELETE FROM book_opens_history WHERE book_id = p_book_id;
  DELETE FROM reading_history WHERE book_id = p_book_id;
  DELETE FROM book_stats WHERE book_id = p_book_id;
  DELETE FROM favorites WHERE book_id = p_book_id;
  DELETE FROM books WHERE id = p_book_id;
END;
$$;
```

### Storage (Buckets)

| Bucket | Contenido |
|---|---|
| `Libros_digitales` | PDFs, EPUBs y portadas de libros |

> ⚠️ Se requiere política RLS de DELETE para usuarios autenticados en el bucket.

---

## 📁 Estructura de Carpetas

```
lib/
├── core/                         # Núcleo reutilizable
│   ├── constants/
│   │   └── app_constants.dart    # Constantes globales de la app
│   ├── providers/
│   │   └── theme_provider.dart   # Provider para modo oscuro/claro
│   ├── services/
│   │   ├── lazy_loading_service.dart     # Mixin para lazy loading de tabs
│   │   └── optimized_cache_service.dart  # Caché en memoria para datos frecuentes
│   ├── theme/
│   │   ├── app_colors.dart       # Colores centralizados (azul Yavirac, naranja)
│   │   ├── app_theme.dart        # Tema claro/oscuro de la app
│   │   ├── optimized_theme.dart  # Estilos de texto y gradientes optimizados
│   │   └── theme_manager.dart    # Gestor del tema
│   └── widgets/
│       ├── lazy_tab_view.dart    # Widget para cargar tabs bajo demanda
│       ├── optimized_container.dart
│       ├── optimized_image.dart  # Imagen con caché y fallback
│       └── optimized_list_view.dart
│
├── data/                         # Capa de datos
│   ├── models/
│   │   ├── book_model.dart           # Modelo de libro
│   │   ├── video_model.dart          # Modelo de video
│   │   ├── user_model.dart           # Modelo de usuario
│   │   └── support_request_model.dart # Modelo de solicitud de soporte
│   └── services/
│       ├── supabase_auth_service.dart # Autenticación con Supabase (login/logout/register)
│       ├── auth_service.dart          # Servicio de auth genérico
│       ├── cache_service.dart         # Caché simple en memoria (Map estático)
│       ├── favorites_service.dart     # CRUD de favoritos
│       ├── stats_service.dart         # Estadísticas de lecturas
│       ├── support_service.dart       # Envío de solicitudes de soporte
│       ├── debug_service.dart         # Utilidades de debug
│       ├── database_seeder.dart       # Datos de prueba (solo desarrollo)
│       ├── enum_converter.dart        # Conversores de enums
│       └── test_users_service.dart    # Usuarios de prueba (solo desarrollo)
│
├── domain/
│   └── dependency_injection.dart  # Inyección de dependencias
│
├── presentation/                  # Capa de UI
│   ├── screens/
│   │   ├── auth/
│   │   │   ├── login_screen.dart          # Pantalla de login
│   │   │   ├── register_screen.dart       # Pantalla de registro
│   │   │   ├── reset_password_screen.dart # Recuperar contraseña
│   │   │   ├── stub_html.dart             # Stub para web (dart:html)
│   │   │   └── stub_ui_web.dart           # Stub para web (dart:ui_web)
│   │   │
│   │   ├── splash/
│   │   │   └── splash_screen.dart         # Pantalla de carga inicial
│   │   │
│   │   ├── admin/                         # ⚠️ No se usa activamente
│   │   │   ├── add_book_screen.dart       # Formulario para agregar libro digital
│   │   │   ├── add_physical_book_screen.dart # Formulario para agregar libro físico
│   │   │   ├── add_video_screen.dart      # Formulario para agregar video
│   │   │   ├── admin_dashboard.dart       # Dashboard admin (no se usa en producción)
│   │   │   └── categories_management_screen.dart # Gestión de categorías
│   │   │
│   │   └── user/                          # ✅ Pantallas principales en uso
│   │       ├── tabs/
│   │       │   ├── home_tab.dart          # Tab de inicio (libros recientes, destacados)
│   │       │   ├── library_tab.dart       # Tab de biblioteca (libros por categoría)
│   │       │   └── videos_tab.dart        # Tab de videos
│   │       ├── user_home.dart             # ⭐ Pantalla principal con sidebar y todas las tabs
│   │       ├── book_detail_screen.dart    # Detalle de un libro (portada, info, botón leer)
│   │       ├── flipbook_reader.dart       # ⭐ Lector de PDF (web y móvil) con zoom
│   │       ├── book_reader_screen.dart    # Lector alternativo (solo móvil)
│   │       ├── simple_book_reader.dart    # Lector simple
│   │       ├── users_management_screen.dart # Gestión de usuarios (solo admin)
│   │       ├── category_books_view.dart   # Vista de libros por categoría
│   │       ├── category_videos_view.dart  # Vista de videos por categoría
│   │       ├── category_filter.dart       # Filtro de categorías
│   │       ├── mobile_video_player.dart   # ⭐ Reproductor de video principal
│   │       ├── youtube_video_player.dart  # Reproductor YouTube embebido
│   │       ├── video_player_screen.dart   # Pantalla completa de video
│   │       ├── minimal_video_player.dart  # Reproductor mínimo
│   │       ├── simple_video_player.dart   # Reproductor simple
│   │       └── support_screen.dart        # Pantalla de soporte
│   │
│   ├── theme/
│   │   └── glass_theme.dart       # Tema glassmorphism (colores, gradientes)
│   │
│   └── widgets/
│       ├── book_list_widget.dart   # Widget de lista/grid de libros reutilizable
│       ├── video_list_widget.dart  # Widget de lista de videos
│       ├── category_accordion.dart # Acordeón de categorías
│       ├── common_widgets.dart     # ⭐ Widgets comunes (showBookEditDialog, etc.)
│       └── optimized_modals.dart   # Modales optimizados (confirmar, agregar libro, etc.)
│
├── main.dart                       # ⭐ Entry point principal (producción)
└── main_dev.dart                   # Entry point de desarrollo
```

---

## ⭐ Archivos Más Importantes

### `lib/main.dart`
Entry point de la app. Inicializa Supabase con las credenciales y arranca la app.

### `lib/presentation/screens/user/user_home.dart`
Pantalla principal de la app. Contiene:
- Sidebar con menú de navegación
- Sistema de tabs con caché
- Todas las secciones: Inicio, Libros, Videos, Favoritos, Perfil, Top 10, Agregar Contenido, Gestión de Usuarios, Solicitudes, Categorías, Libros Físicos, Todos los Libros

### `lib/presentation/screens/user/flipbook_reader.dart`
Lector de PDF con:
- Soporte web y móvil
- Zoom con botones + y -
- Modo pantalla completa
- Modo oscuro/claro
- Navegación por páginas con teclado

### `lib/data/services/supabase_auth_service.dart`
Maneja login, logout, registro y sesión del usuario.

### `lib/presentation/widgets/common_widgets.dart`
Contiene `showBookEditDialog` — el diálogo reutilizable para editar libros.

### `lib/presentation/widgets/optimized_modals.dart`
Modales para: confirmar acciones, agregar libro digital, agregar libro físico, agregar video.

---

## 🔑 Configuración de Supabase

En `lib/main.dart` están las credenciales:

```dart
await Supabase.initialize(
  url: 'TU_SUPABASE_URL',
  anonKey: 'TU_SUPABASE_ANON_KEY',
);
```

### Políticas RLS requeridas en Storage (`Libros_digitales`):

| Operación | Política |
|---|---|
| SELECT | Acceso público (lectura) |
| INSERT | Usuarios autenticados |
| UPDATE | Usuarios autenticados |
| DELETE | Usuarios autenticados |

---

## 🚀 Cómo Correr el Proyecto

```bash
# Instalar dependencias
flutter pub get

# Correr en web (desarrollo)
flutter run -d chrome

# Correr en web sin caché
flutter run -d chrome --web-renderer html

# Build para producción web
flutter build web

# Build APK Android
flutter build apk --release
```

---

## 🧭 Flujo de la App

```
SplashScreen
    ↓
LoginScreen / RegisterScreen
    ↓
UserHome (pantalla principal)
    ├── HomeTab          → Libros recientes y destacados
    ├── LibraryTab       → Libros por categoría
    ├── VideosTab        → Videos por categoría
    ├── FavoritesTab     → Mis favoritos
    ├── ProfileTab       → Perfil + libros subidos (para roles con permiso)
    ├── TopBooksTab      → Top 10 libros más leídos
    ├── AddContentTab    → Agregar libro/video (solo canEdit)
    ├── UserManagementTab → Gestión de usuarios (solo admin)
    ├── RequestsTab      → Solicitudes de soporte (solo admin)
    ├── CategoriesTab    → Gestión de categorías (solo admin)
    ├── PhysicalBooksTab → Libros físicos disponibles
    └── AllBooksTab      → Todos los libros con paginación
```

---

## 📦 Módulo de Eliminación de Libros

Cuando se elimina un libro se ejecutan estos pasos en orden:

1. Se obtiene `file_url` y `cover_url` del libro
2. Si las URLs pertenecen al storage de Supabase, se eliminan los archivos
3. Se llama a `delete_book_complete(book_id)` que elimina en cascada:
   - `book_opens_history`
   - `reading_history`
   - `book_stats`
   - `favorites` (de todos los usuarios)
   - `books`

---

## 🎨 Sistema de Colores

Definidos en `lib/core/theme/app_colors.dart`:

| Variable | Color | Uso |
|---|---|---|
| `yaviracBlue` | Azul oscuro | Color principal |
| `yaviracBlueDark` | Azul más oscuro | Fondos sidebar |
| `yaviracBlueLight` | Azul claro | Botones secundarios |
| `yaviracOrange` | Naranja | Acentos, botones principales |
