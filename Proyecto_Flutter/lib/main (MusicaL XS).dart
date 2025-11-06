import 'dart:convert';
import 'dart:typed_data';
import 'dart:io' as io show File;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MiAppMusical());
}

class MiAppMusical extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'Mi App Musical', home: CancionDesdeArchivo());
  }
}

class CancionDesdeArchivo extends StatefulWidget {
  @override
  State<CancionDesdeArchivo> createState() => _CancionDesdeArchivoState();
}

class _CancionDesdeArchivoState extends State<CancionDesdeArchivo> {
  String contenido = '';
  bool mostrarMenu = false;
  int tonoOffset = 0;

final List<String> notasIngles = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B' ];

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
  return notasIngles[(indexConOffset + 12) % 12]; // Corrige negativos
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
              padding: const EdgeInsets.only(top: 18.0),
              child: Text(
                contenidoNota.replaceAll(RegExp(r'\d+'), ''),
                style: TextStyle(fontSize: 18),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.yellow.shade200,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(nota, style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ));

      lastIndex = match.end;
    }

    if (lastIndex < texto.length) {
      partes.add(TextSpan(text: texto.substring(lastIndex)));
    }

    return RichText(
      text: TextSpan(
        style: TextStyle(color: Colors.black, fontSize: 18),
        children: partes,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textoFormateado = formatearConNotas(contenido);

    return Scaffold(
      appBar: AppBar(
        title: Text('Canción con notas'),
        actions: [
	ElevatedButton(
                  onPressed: cargarArchivo,
                  child: Text('Cargar archivo'),
                ),
                    IconButton(
                      icon: Icon(Icons.arrow_downward, color: Colors.black),
                      onPressed: () {
                        setState(() {
                          tonoOffset--;
                        });
                      },
                    ),
	IconButton(
                      icon: Icon(Icons.arrow_upward, color: Colors.black),
                      onPressed: () {
                        setState(() {
                          tonoOffset++;
                        });
                      },
                    ),
          IconButton(
            icon: Icon(Icons.menu),
            onPressed: () {
              setState(() {
                mostrarMenu = !mostrarMenu;
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                SizedBox(height: 20),
                Expanded(child: SingleChildScrollView(child: textoFormateado)),
              ],
            ),
          ),
if (mostrarMenu)
            Positioned(
              top: kToolbarHeight + 10,
              right: 10,
              child: Material(
                color: Colors.black.withOpacity(0.4),
                borderRadius: BorderRadius.circular(8),
                child: Column(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_upward, color: Colors.white),
                      onPressed: () {
                        setState(() {
                          tonoOffset++;
                        });
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.arrow_downward, color: Colors.white),
                      onPressed: () {
                        setState(() {
                          tonoOffset--;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}


/*
//FUNCIONA
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

void main() {
  runApp(MiAppMusical());
}

class MiAppMusical extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: CancionDesdeArchivo(),
    );
  }
}

class CancionDesdeArchivo extends StatefulWidget {
  @override
  State<CancionDesdeArchivo> createState() => _CancionDesdeArchivoState();
}

class _CancionDesdeArchivoState extends State<CancionDesdeArchivo> {
  String _fileContent = '';
  String _fileName = 'Ningún archivo seleccionado';

  // Método para cargar el archivo
  Future<void> cargarArchivo() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt'],
        withData: true, // IMPORTANTE para obtener los bytes en web
      );

      if (result != null && result.files.single.bytes != null) {
        String content;

        if (kIsWeb) {
          // En la web usamos los bytes
          content = utf8.decode(result.files.single.bytes!);
        } else {
          // En plataformas de escritorio o móviles, usamos File
          content = utf8.decode(result.files.single.bytes!);
        }

        setState(() {
          _fileContent = content;
          _fileName = result.files.single.name;
        });
      } else {
        setState(() {
          _fileContent = "No se seleccionó ningún archivo.";
          _fileName = "Ningún archivo seleccionado";
        });
      }
    } catch (e) {
      setState(() {
        _fileContent = "Error al leer el archivo: $e";
        _fileName = "Error";
      });
    }
  }

  // Función para traducir números a notas
  final Map<String, String> mapaNotas = {
    '1': 'Do',
    '2': 'Re',
    '3': 'Mi',
    '4': 'Fa',
    '5': 'Sol',
    '6': 'La',
    '7': 'Si',
  };

  // Función para parsear el texto con notas y ponerlas encima de la letra
  List<InlineSpan> _parseTextWithNotes(String text) {
    final regex = RegExp(r'•(.*?)•');
    final spans = <InlineSpan>[];

    int lastEnd = 0;

    for (final match in regex.allMatches(text)) {
      // Texto antes de la nota
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: text.substring(lastEnd, match.start)));
      }

      // Nota encontrada
      final noteContent = match.group(1)!;
      final noteNumber = noteContent.replaceAll(RegExp(r'[^0-9]'), '');
      final note = mapaNotas[noteNumber] ?? noteContent;

      // Crear un widget con la nota musical flotante sobre la palabra
      spans.add(WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Container(
          margin: EdgeInsets.only(bottom: 0), // Espacio entre el texto y la nota
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.yellow.shade200,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange),
          ),
          child: Text(
            note,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Colors.orange,
            ),
          ),
        ),
      ));

      lastEnd = match.end;
    }

    // Texto restante después del último match
    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd)));
    }

    return spans;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Canción con notas'),
        actions: [
          IconButton(
            icon: Icon(Icons.file_upload),
            onPressed: cargarArchivo,
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: cargarArchivo,
              child: Text('Cargar archivo'),
            ),
            SizedBox(height: 20),
            Text(
              "Archivo seleccionado: $_fileName",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Expanded(
              child: SingleChildScrollView(
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(color: Colors.black, fontSize: 18,),
                    children: _parseTextWithNotes(_fileContent),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
//FIN QUE FUNCIONA
*/


/*
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

void main() {
  runApp(MiAppMusical());
}

class MiAppMusical extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: CancionDesdeArchivo(),
    );
  }
}

class CancionDesdeArchivo extends StatefulWidget {
  @override
  State<CancionDesdeArchivo> createState() => _CancionDesdeArchivoState();
}

class _CancionDesdeArchivoState extends State<CancionDesdeArchivo> {
  String _fileContent = '';
  String _fileName = 'Ningún archivo seleccionado';

  // Método para cargar el archivo
  Future<void> cargarArchivo() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt'],
        withData: true, // IMPORTANTE para obtener los bytes en web
      );

      if (result != null && result.files.single.bytes != null) {
        String content;

        if (kIsWeb) {
          // En la web usamos los bytes
          content = utf8.decode(result.files.single.bytes!);
        } else {
          // En plataformas de escritorio o móviles, usamos File
          content = utf8.decode(result.files.single.bytes!);
        }

        setState(() {
          _fileContent = content;
          _fileName = result.files.single.name;
        });
      } else {
        setState(() {
          _fileContent = "No se seleccionó ningún archivo.";
          _fileName = "Ningún archivo seleccionado";
        });
      }
    } catch (e) {
      setState(() {
        _fileContent = "Error al leer el archivo: $e";
        _fileName = "Error";
      });
    }
  }

  // Función para parsear el texto y crear los widgets
  List<InlineSpan> _parseTextWithNotes(String text) {
    final regex = RegExp(r'•(.*?)•');
    final spans = <InlineSpan>[];

    int lastEnd = 0;

    for (final match in regex.allMatches(text)) {
      // Texto antes de la nota
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: text.substring(lastEnd, match.start)));
      }

      // Nota encontrada
      final note = match.group(1)!;
      spans.add(WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 4),
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.yellow.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.music_note, size: 16, color: Colors.orange),
              SizedBox(width: 4),
              Text(note, style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ));

      lastEnd = match.end;
    }

    // Texto restante después del último match
    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd)));
    }

    return spans;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Canción con notas'),
        actions: [
          IconButton(
            icon: Icon(Icons.file_upload),
            onPressed: cargarArchivo,
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: cargarArchivo,
              child: Text('Cargar archivo'),
            ),
            SizedBox(height: 20),
            Text(
              "Archivo seleccionado: $_fileName",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Expanded(
              child: SingleChildScrollView(
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(color: Colors.black, fontSize: 16),
                    children: _parseTextWithNotes(_fileContent),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
*/


/*
import 'dart:convert';
import 'package:flutter/foundation.dart'; // para kIsWeb
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io' as io; // para plataformas no web

void main() {
  runApp(MiAppMusical());
}

class MiAppMusical extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Musical',
      home: CancionDesdeArchivo(),
    );
  }
}

class CancionDesdeArchivo extends StatefulWidget {
  @override
  State<CancionDesdeArchivo> createState() => _CancionDesdeArchivoState();
}

class _CancionDesdeArchivoState extends State<CancionDesdeArchivo> {
  String _fileContent = '';
  String _fileName = '';

  Future<void> _pickAndReadFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt'],
        withData: true, // IMPORTANTE para obtener los bytes en web
      );

      if (result != null && result.files.single.bytes != null) {
        String content;

        if (kIsWeb) {
          // En la web usamos los bytes
          content = utf8.decode(result.files.single.bytes!);
        } else {
          // En plataformas de escritorio o móviles, usamos File
          final file = io.File(result.files.single.path!);
          content = await file.readAsString();
        }

        setState(() {
          _fileContent = content;
          _fileName = result.files.single.name;
        });
      } else {
        setState(() {
          _fileContent = "No se seleccionó ningún archivo.";
          _fileName = "Ningún archivo seleccionado";
        });
      }
    } catch (e) {
      setState(() {
        _fileContent = "Error al leer el archivo: $e";
        _fileName = "Error";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cargar Canción'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _pickAndReadFile,
              child: Text('Seleccionar archivo .txt'),
            ),
            SizedBox(height: 20),
            Text(
              'Archivo: $_fileName',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  _fileContent,
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

*/