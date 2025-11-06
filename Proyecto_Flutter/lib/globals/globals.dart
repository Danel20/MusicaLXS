import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:io' as io show File, Directory, Platform;

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:collection/collection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart' show rootBundle, HapticFeedback, PlatformException;
import 'package:widgets_to_image/widgets_to_image.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:screenshot/screenshot.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:universal_html/html.dart' as html;
import 'package:image/image.dart' as img0;

ThemeMode themeMode1 = ThemeMode.light;
Color etiquetaColor = Colors.purple.shade700;
Color textColor1 = Colors.white;
List<Color> coloresEtiqueta1 = [
    Colors.yellow.shade200,
    Colors.yellow.shade700,
    Colors.green.shade200,
    Colors.green.shade700,
    Colors.blue.shade200,
    Colors.blue.shade700,
    Colors.pink.shade200,
    Colors.pink.shade700,
    Colors.purple.shade200,
    Colors.purple.shade700,
  ];
List<String> notasMusicales1 = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
Map<String, dynamic> himnosApp = {};
List<TemaLista> listas = [];
List<TemaLista> listasApp = [];
String FechaDeHimnos = '';
Future<Map<String, dynamic>> cargarDatos() async {
  bool cargadoLocal = false;

  try {
    if (kIsWeb) {
      // Web: SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('himnosApp');
      if (jsonString != null) {
        himnosApp = jsonDecode(jsonString);
        FechaDeHimnos = himnosApp['fecha'];
        cargadoLocal = true;
      }
    } else {
      // Android/iOS: archivo local
      final dir = await getApplicationDocumentsDirectory();
      final file = io.File('${dir.path}/himnos.json');
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        himnosApp = jsonDecode(jsonString);
        FechaDeHimnos = himnosApp['fecha'];
        cargadoLocal = true;
      }
    }

    // Si no se cargó nada de almacenamiento interno, usar assets
    if (!cargadoLocal) {
      final rawData = await rootBundle.loadString('assets/himnos.json');
      himnosApp = jsonDecode(rawData);
      FechaDeHimnos = himnosApp['fecha'];
    }
  } catch (e) {
    final rawData = await rootBundle.loadString('assets/himnos.json');
    himnosApp = jsonDecode(rawData);
    FechaDeHimnos = himnosApp['fecha'];
  }
  return himnosApp;
}

// ----------------------
// Guardar datos internamente
// ----------------------
Future<void> guardarHimnosInterno() async {
  if (kIsWeb) {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('himnosApp', jsonEncode(himnosApp));
  } else {
    final dir = await getApplicationDocumentsDirectory();
    final file = io.File('${dir.path}/himnos.json');
    await file.writeAsString(jsonEncode(himnosApp));
  }
}

class ListaStorage {
  Future<String> get _filePath async {
    if (kIsWeb) {
      return 'MisListas.json';
    } else {
      final dir = await getApplicationDocumentsDirectory();
      final path = io.Directory('${dir.path}/MusicaLXS');
      if (!await path.exists()) {
        await path.create(recursive: true);
      }
      return '${path.path}/MisListas.json';
    }
  }

  Future<List<TemaLista>> leerListas() async {
    try {
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        final jsonString = prefs.getString('MisListas');
        if (jsonString == null) return [];
        final data = json.decode(jsonString);
        return (data['listas'] as List).map((e) => TemaLista.fromJson(e)).toList();
      } else {
        final path = await _filePath;
        final file = io.File(path);
        if (!await file.exists()) return [];
        final data = json.decode(await file.readAsString());
        return (data['listas'] as List).map((e) => TemaLista.fromJson(e)).toList();
      }
    } catch (_) {
      return [];
    }
  }

  Future<void> guardarListas(List<TemaLista> listas) async {
    final data = {'listas': listas.map((e) => e.toJson()).toList()};
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('MisListas', json.encode(data));
    } else {
      final path = await _filePath;
      final file = io.File(path);
      await file.writeAsString(json.encode(data));
    }
  }
}

// --------------------------------------
// Funciones globales de listas
// --------------------------------------
final storageListas = ListaStorage();

// Carga inicial de listas: primero persistencia, si no existe → assets
Future<void> cargarListas() async {
  final listasLocales = await storageListas.leerListas();
  if (listasLocales.isNotEmpty) {
    listasApp = listasLocales;
  } else {
    // carga desde assets
    final rawData = await rootBundle.loadString('assets/MisListas.json');
    final data = json.decode(rawData);
    listasApp = (data['listas'] as List).map((e) => TemaLista.fromJson(e)).toList();
    await storageListas.guardarListas(listasApp); // guardamos para persistencia
  }
}

class TemaLista {
  List<String> temas;
  String nota;

  TemaLista({required this.temas, required this.nota});

  Map<String, dynamic> toJson() => {
        'temas': temas,
        'nota': nota,
      };

  factory TemaLista.fromJson(Map<String, dynamic> json) => TemaLista(
        temas: List<String>.from(json['temas']),
        nota: json['nota'],
      );
}

// Fusiona con las listas locales sin perder lo que el usuario creó
Future<List<String>> actualizarListasDesdeGithubEnMemoria() async {
  final mensajes = <String>[];
  final urlRemoto = "https://raw.githubusercontent.com/Danel20/MusicaLXS/main/MisListas.json";
  final conectado = await hayConexionInternet(urlRemoto);
  if (!conectado) {
    mensajes.add("❌ No hay conexión a Internet. Intenta más tarde.");
    return mensajes;
    }
  if (!conectado) { mensajes.add("❌ No hay conexión a Internet. Intenta más tarde."); return mensajes; }
  
  try {

    final response = await http.get(Uri.parse(urlRemoto));
    if (response.statusCode != 200) {
      mensajes.add("Error al obtener listas remotas: código ${response.statusCode}");
      return mensajes;
    }

    final dataRemota = json.decode(response.body);
    final listasRemotas = (dataRemota['listas'] as List)
        .map((e) => TemaLista.fromJson(e))
        .toList();

    // Fusionar sin duplicados según el nombre de la lista
    final notasLocales = listasApp.map((l) => l.nota).toSet();
    for (var lista in listasRemotas) {
      if (!notasLocales.contains(lista.nota)) {
        listasApp.add(lista);
      }
    }

    // Guardar persistencia
    await storageListas.guardarListas(listasApp);
    mensajes.add("✅ Listas actualizadas correctamente");

  } catch (e) {
    mensajes.add("Error actualizando listas desde GitHub: $e");
  }
  return mensajes;
}


// ----------------------
// Actualizar himnos desde remoto (solo al presionar botón)
// ----------------------
Future<List<String>> actualizarJsonDesdeGithubEnMemoria() async {
  final mensajes = <String>[];
  final url = "https://raw.githubusercontent.com/Danel20/MusicaLXS/main/himnos.json";
  
  final conectado = await hayConexionInternet(url);
  if (!conectado) {
    mensajes.add("❌ No hay conexión a Internet. Intenta más tarde.");
    return mensajes;
  }

  mensajes.add("🌐 Conexión detectada. Estableciendo comunicación con el servidor...");

  try {

    final respuesta = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));

    if (respuesta.statusCode != 200) {
      mensajes.add("❌ Error al obtener JSON remoto: código ${respuesta.statusCode}");
      return mensajes;
    }

    mensajes.add("✅ Archivo remoto obtenido correctamente. Procesando...");

    final remotoJson = jsonDecode(respuesta.body);

    // Verificar fecha
    final fechaLocal = himnosApp['fecha'];
    final fechaRemota = remotoJson['fecha'];
    mensajes.add("📅 Comparando fechas (local=$fechaLocal, remoto=$fechaRemota)...");

    if (fechaLocal != null && fechaLocal == fechaRemota) {
      mensajes.add("⚡ El archivo ya está actualizado.");
      return mensajes;
    }

    mensajes.add("🔄 Fecha diferente. Actualizando contenido...");

    // Fusionar himnos
    final localHimnos = (himnosApp['himnos'] ?? []) as List<dynamic>;
    final remotoHimnos = (remotoJson['himnos'] ?? []) as List<dynamic>;

    final temasLocales = localHimnos
        .whereType<Map<String, dynamic>>()
        .map((h) => h['tema'])
        .toSet();

    for (var himno in remotoHimnos) {
      if (!temasLocales.contains(himno['tema'])) {
        localHimnos.add(himno);
      }
    }

    himnosApp = {
      'categorias': remotoJson['categorias'],
      'fecha': fechaRemota,
      'himnos': localHimnos,
    };

    // Guardar en almacenamiento interno
    await guardarHimnosInterno();

    mensajes.add("💾 JSON actualizado y guardado internamente (fecha: $fechaRemota).");

  } on TimeoutException {
    mensajes.add("⏳ El servidor tardó demasiado en responder. Intenta más tarde.");
  } catch (e) {
    mensajes.add("❌ Error inesperado actualizando JSON: $e");
  }
  
  return mensajes;
}

// =======================
// CONEXIÓN A INTERNET
// =======================
Future<bool> hayConexionInternet(String url) async {
  if (kIsWeb) {
    // En web, solo confiamos en el request HTTP
    try {
      final respuesta = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 5));
      return respuesta.statusCode == 200;
    } catch (_) {
      return false;
    }
  } else {
    // Android / iOS
    try {
      final respuesta = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 5));
      return respuesta.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}

// Aquí debes tener tus variables globales como etiquetas y colores
Color etiquetaColorx = Colors.blue;
Color textColor1x = Colors.white;
List<String> notasMusicales1x = ['C','C#','D','D#','E','F','F#','G','G#','A','A#','B'];


// ESTE ES PARA EL ITEM SELECCIONADO
class TemaItem extends StatefulWidget {
  final String tema;
  final bool seleccionado;
  final Function() onTap;
  final Function() onLongPress;

  const TemaItem({
    Key? key,
    required this.tema,
    required this.seleccionado,
    required this.onTap,
    required this.onLongPress,
  }) : super(key: key);

  @override
  _TemaItemState createState() => _TemaItemState();
}

class _TemaItemState extends State<TemaItem> with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context); // Importante
    return ListTile(
      title: Text(widget.tema),
      trailing: Icon(
        widget.seleccionado ? Icons.check_circle : Icons.radio_button_unchecked,
        color: widget.seleccionado ? etiquetaColor : Colors.grey,
      ),
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
    );
  }

  @override
  bool get wantKeepAlive => true;
}

// Este es para usarlo en BusquedaHimnos.dart
class TemaItemCard extends StatefulWidget {
  final String tema;
  final String? fragmento; // Texto adicional tipo "subtitle"
  final bool seleccionado;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const TemaItemCard({
    Key? key,
    required this.tema,
    this.fragmento,
    required this.seleccionado,
    required this.onTap,
    required this.onLongPress,
  }) : super(key: key);

  @override
  _TemaItemCardState createState() => _TemaItemCardState();
}

class _TemaItemCardState extends State<TemaItemCard> with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(3),
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título + fragmento
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.tema,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: widget.seleccionado ? FontWeight.bold : FontWeight.normal,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.fragmento != null && widget.fragmento!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '...${widget.fragmento}...',
                          style: TextStyle(color: Colors.grey[700]),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
              // Icono de selección
              Icon(
                widget.seleccionado
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
                color: widget.seleccionado ? etiquetaColor : Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}



//PARA BÚSQUEDAS

class Himno {
  final String tema;
  final String contenido;
  final List<String> categoria;
  final String nota;
  final String autor;

  Himno({
    required this.tema,
    required this.contenido,
    required this.categoria,
    required this.nota,
    required this.autor,
  });

  factory Himno.fromJson(Map<String, dynamic> json) {
    return Himno(
      tema: json['tema'],
      contenido: json['contenido'],
      categoria: List<String>.from(json['categoria']),
      nota: json['nota'],
      autor: json['autor'],
    );
  }
}

enum ModoBusqueda { todo, nota, categoria }



Future<void> captureAndSaveWidgetToGallery({
  required WidgetsToImageController controller,
  required Widget widget,
  required BuildContext context,
}) async {
  bool permissionGranted = await requestStoragePermission();

  if (!permissionGranted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Permiso denegado para guardar imágenes")),
    );
    return;
  }

  try {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final Size logicalSize = box.size;

    // Envuelve el widget en un tamaño suficientemente grande
    final wrappedWidget = Material(
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: logicalSize.width,
              // maxHeight: double.infinity,
            ),
            child: widget,
          ),
        ),
      ),
    );

    // Renderizar temporalmente
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (_) => Material(
        color: Colors.transparent,
        child: wrappedWidget,
      ),
    );
    overlay.insert(overlayEntry);

    // Espera un poco para asegurar render completo
    await Future.delayed(Duration(milliseconds: 500));

    // Captura con mayor resolución
    final pngBytes = await controller.capture();

    overlayEntry.remove();

    if (pngBytes != null) {
      final success = await saveImageToGallery(pngBytes);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success ? "Imagen guardada" : "Error al guardar imagen")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al capturar imagen")),
      );
    }
  } catch (e) {
    debugPrint("Error: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Ocurrió un error al guardar")),
    );
  }
}


// Solicita permisos de almacenamiento según la versión de Android
Future<bool> requestStoragePermission() async {
  if (!io.Platform.isAndroid) return true;

  if (io.Platform.version.contains('13') || io.Platform.version.contains('14')) {
    // Android 13 o superior (API 33+)
    final status = await Permission.photos.request(); // o Permission.mediaLibrary si usas iOS también
    return status.isGranted;
  } else {
    final status = await Permission.storage.request();
    return status.isGranted;
  }
}

// Guarda imagen en galería
Future<bool> saveImageToGallery(Uint8List pngBytes) async {
  try {
    final result = await ImageGallerySaver.saveImage(
      Uint8List.fromList(pngBytes),
      quality: 100,
      name: "captura_${DateTime.now().millisecondsSinceEpoch}",
    );
    debugPrint("Resultado guardado: $result");
    return result["isSuccess"] ?? false;
  } catch (e) {
    debugPrint("Error guardando imagen: $e");
    return false;
  }
}
