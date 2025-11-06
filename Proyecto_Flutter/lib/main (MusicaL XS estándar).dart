import 'dart:convert';
import 'dart:typed_data';
import 'dart:io' as io show File;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(MiAppMusical());
}

class MiAppMusical extends StatefulWidget {
  @override
  State<MiAppMusical> createState() => _MiAppMusicalState();
}

class _MiAppMusicalState extends State<MiAppMusical> {
  ThemeMode _themeMode = ThemeMode.light;
  Color etiquetaColor = Colors.deepPurple.shade700;
  Color textColor1 = Colors.white;

  @override
  void initState() {
    super.initState();
    _cargarPreferencias();
  }

  Future<void> _cargarPreferencias() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('tema_oscuro') ?? false;
    final colorIndex = prefs.getInt('color_etiqueta') ?? 0;
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
      etiquetaColor = _coloresEtiqueta[colorIndex];
      textColor1 = colorIndex % 2 == 1 ? Colors.white : Colors.black;
    });
  }

  Future<void> cambiarTema(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tema_oscuro', mode == ThemeMode.dark);
    setState(() => _themeMode = mode);
  }

  Future<void> cambiarColorEtiqueta(Color color) async {
    final prefs = await SharedPreferences.getInstance();
    final index = _coloresEtiqueta.indexOf(color);
    await prefs.setInt('color_etiqueta', index);
    setState(() {
      etiquetaColor = color;
      textColor1 = index % 2 == 1 ? Colors.white : Colors.black;
    });
  }

  static final List<Color> _coloresEtiqueta = [
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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mi App Musical',
      themeMode: _themeMode,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: CancionDesdeArchivo(
        cambiarTema: cambiarTema,
        cambiarColorEtiqueta: cambiarColorEtiqueta,
        etiquetaColor: etiquetaColor,
        textColor1: textColor1,
      ),
    );
  }
}

class CancionDesdeArchivo extends StatefulWidget {
  final Function(ThemeMode) cambiarTema;
  final Function(Color) cambiarColorEtiqueta;
  final Color etiquetaColor;
  final Color textColor1;

  CancionDesdeArchivo({
    required this.cambiarTema,
    required this.cambiarColorEtiqueta,
    required this.etiquetaColor,
    required this.textColor1,
  });

  @override
  State<CancionDesdeArchivo> createState() => _CancionDesdeArchivoState();
}

class _CancionDesdeArchivoState extends State<CancionDesdeArchivo> {
  String contenido = '';
  int tonoOffset = 0;
  late Color etiquetaColor;
  late Color textColor1;

  final List<String> notasIngles = [
    'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'
  ];

  static final List<Color> _coloresEtiqueta = [
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

  @override
  void initState() {
    super.initState();
    etiquetaColor = widget.etiquetaColor;
    textColor1 = widget.textColor1;
  }

  Future<void> cargarArchivo() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt'],
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        String content;
        if (kIsWeb) {
          content = utf8.decode(result.files.single.bytes!);
        } else {
          final file = io.File(result.files.single.path!);
          content = await file.readAsString();
        }

        setState(() {
          contenido = content;
        });
      }
    } catch (e) {
      setState(() {
        contenido = "Error al leer el archivo: $e";
      });
    }
  }

  String notaConTono(int numero) {
    final indexOriginal = (numero - 1) % 12;
    final indexConOffset = (indexOriginal + tonoOffset) % 12;
    return notasIngles[(indexConOffset + 12) % 12];
  }

  Widget formatearConNotas(String texto) {
    final regex = RegExp(r'•(.*?)•');
    final partes = <InlineSpan>[];
    int lastIndex = 0;

    for (final match in regex.allMatches(texto)) {
      final antes = texto.substring(lastIndex, match.start);
      if (antes.isNotEmpty) {
        partes.add(TextSpan(text: antes));
      }

      final contenidoNota = match.group(1) ?? '';
      final numero = int.tryParse(
        RegExp(r'\d+').firstMatch(contenidoNota)?.group(0) ?? '',
      );

      final nota = numero != null ? notaConTono(numero) : contenidoNota;

      partes.add(WidgetSpan(
        alignment: PlaceholderAlignment.bottom,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 20.0),
              child: Text(
                contenidoNota.replaceAll(RegExp(r'\d+'), ''),
                style: TextStyle(fontSize: 16),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: etiquetaColor,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(nota, style: TextStyle(color: textColor1, fontSize: 15)),
            ),
          ],
        ),
      ));

      lastIndex = match.end;
    }

    if (lastIndex < texto.length) {
      partes.add(TextSpan(text: texto.substring(lastIndex)));
    }

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black;

    return RichText(
      text: TextSpan(
        style: TextStyle(color: textColor, fontSize: 16),
        children: partes,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textoFormateado = formatearConNotas(contenido);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black;

    return Scaffold(
      appBar: AppBar(
        title: Text('Canción con notas', style: TextStyle(color: textColor1, fontWeight: FontWeight.bold)),
        backgroundColor: etiquetaColor,
        actions: [
          ElevatedButton(
            onPressed: cargarArchivo,
            child: Text('Cargar archivo'),
          ),
          IconButton(
            icon: Icon(Icons.arrow_downward, color: textColor),
            onPressed: () => setState(() => tonoOffset--),
          ),
          IconButton(
            icon: Icon(Icons.arrow_upward, color: textColor),
            onPressed: () => setState(() => tonoOffset++),
          ),
          IconButton(
            icon: Icon(Icons.menu),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ConfiguracionScreen(
                    cambiarTema: widget.cambiarTema,
                    cambiarColorEtiqueta: (color) async {
                      await widget.cambiarColorEtiqueta(color);
                      final prefs = await SharedPreferences.getInstance();
                      final index = prefs.getInt('color_etiqueta') ?? 0;
                      setState(() {
                        etiquetaColor = _coloresEtiqueta[index];
                        textColor1 = index % 2 == 1 ? Colors.white : Colors.black;
                      });
                    },
                    textColor1: textColor1,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SizedBox(height: 20),
            Expanded(child: SingleChildScrollView(child: textoFormateado)),
          ],
        ),
      ),
    );
  }
}

class ConfiguracionScreen extends StatelessWidget {
  final Function(ThemeMode) cambiarTema;
  final Function(Color) cambiarColorEtiqueta;
  final Color textColor1;

  const ConfiguracionScreen({
    required this.cambiarTema,
    required this.cambiarColorEtiqueta,
    required this.textColor1,
  });

  @override
  Widget build(BuildContext context) {
    final colores = [
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

    return Scaffold(
      appBar: AppBar(title: Text('Configuración')),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tema', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Row(
              children: [
                TextButton(
                  onPressed: () => cambiarTema(ThemeMode.light),
                  child: Text('Claro'),
                ),
                TextButton(
                  onPressed: () => cambiarTema(ThemeMode.dark),
                  child: Text('Oscuro'),
                ),
              ],
            ),
            SizedBox(height: 18),
            Text('Color de etiquetas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Wrap(
              spacing: 5,
              children: colores.map((color) => GestureDetector(
                onTap: () => cambiarColorEtiqueta(color),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black54),
                  ),
                ),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
