import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
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
import 'package:flutter/services.dart' show rootBundle, HapticFeedback;

// 👇 Este import SOLO se usa en web, por eso el ignore
// ignore: avoid_web_libraries_in_flutter
/*
import 'dart:html' 
    if (dart.library.io) 'html_stub.dart' as html;
*/
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await cargarDatos();
  await cargarListas();
  runApp(MusicaLXS());
}


// PANTALLA PRINCIPAL
class MusicaLXS extends StatefulWidget {
  @override
  State<MusicaLXS> createState() => _MusicaLXSState();
}

ThemeMode _themeMode = ThemeMode.light;
Color etiquetaColor = Colors.purple.shade700;
Color textColor1 = Colors.white;
List<Color> _coloresEtiqueta = [
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

class _MusicaLXSState extends State<MusicaLXS> {
  @override
  void initState() {
    super.initState();
    _cargarPreferencias();
  }
  
  Future<void> _cargarPreferencias() async {
    final pref = await SharedPreferences.getInstance();
    final isDark = pref.getBool('tema_oscuro') ?? false;
    final colorIndex = pref.getInt('color_etiqueta') ?? 9;
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
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MusicaL XS',
      themeMode: _themeMode,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: MusicaLXSApp(cambiarTema: cambiarTema, cambiarColorEtiqueta: cambiarColorEtiqueta),
    );
  }
}

class MusicaLXSApp extends StatefulWidget {
  final Function(ThemeMode) cambiarTema;
  final Function(Color) cambiarColorEtiqueta;
  
  MusicaLXSApp({
    required this.cambiarTema,
    required this.cambiarColorEtiqueta,
  });
  
  @override
  State<MusicaLXSApp> createState() => _MusicaLXSAppState();
}

class _MusicaLXSAppState extends State<MusicaLXSApp> {
  /*
  ESTO ES PARA CREAR BOTONES DE OPCIONES EN PANTALLA PRINCIPAL
  final List<_OpcionPrincipal> opciones = [
    _OpcionPrincipal(
        icono: Icons.music_note, texto: 'Himnos', color: Colors.blueAccent),
    _OpcionPrincipal(
        icono: Icons.piano, texto: 'Música', color: Colors.deepPurple),
    _OpcionPrincipal(
        icono: Icons.favorite, texto: 'Batería', color: Colors.orange),
    _OpcionPrincipal(icono: Icons.book, texto: 'Letra', color: Colors.teal),
  ];
  */
  
  /*
  late Color etiquetaColor;
  late Color textColor1;
  late List<Color> _coloresEtiqueta;
  */
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: ListView(
          children: [
            heroSection(context),
            /*
            Padding(
              padding: EdgeInsets.all(12.0),
              child: GridView.count(
                shrinkWrap: true, // ✅ Esto es importante para que funcione dentro del ListView
                physics: NeverScrollableScrollPhysics(), // Evita scroll interno
                crossAxisCount: 2,
                mainAxisSpacing: 30,
                crossAxisSpacing: 30,
                children: List.generate(opciones.length, (index) {
                  final opcion = opciones[index];
                  return FadeInUp(
                    delay: Duration(milliseconds: 300 * index),
                    child: GestureDetector(
                      onTap: () {
                      // Acción por botón
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: opcion.color.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: opcion.color.withOpacity(0.4),
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(opcion.icono, size: 50, color: Colors.white),
                            SizedBox(height: 12),
                            Text(
                              opcion.texto,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            SizedBox(height: 20),
            */
          ],
        ),
      )
    );
  }

  Widget heroSection(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return SizedBox(
      height: size.height,
      width: size.width,
      child: Stack(
        children: [
          Container(
            height: size.height,
            width: size.width,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/yoututosjeffewr325342.png'),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(Colors.black45, BlendMode.darken),
              ),
            ),
          ),
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ZoomIn(
                    duration: Duration(milliseconds: 1000),
                    delay: Duration(milliseconds: 1000),
                    child: Text(
                      'MusicaL XS',
                      style: TextStyle(
                        fontSize: 26,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            offset: Offset(1.5, 1.5),
                            blurRadius: 2.0,
                            color: Colors.black,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  SlideInLeft(
                    duration: Duration(milliseconds: 1000),
                    delay: Duration(milliseconds: 1500),
                    child: Text(
                      'Donde lo musical es para tod@s,\nlo musical es para tí',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  BounceInUp(
                    duration: Duration(milliseconds: 1000),
                    delay: Duration(milliseconds: 2000),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.white, Colors.white],
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white,
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: NeonGlowButton(
                        onPressed: () {
                          // Usar esto para una vibración del teléfono: HapticFeedback.lightImpact();
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              transitionDuration: Duration(milliseconds: 800),
                              pageBuilder: (context, animation,
                              secondaryAnimation) =>
                                PantallaConTabs(cambiarTema: widget.cambiarTema, cambiarColorEtiqueta: widget.cambiarColorEtiqueta,), // ⬅️ tu pantalla de tabs
                                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                  final curved = CurvedAnimation(
                                    parent: animation, curve: Curves.easeInOut);
                                    /*
                                    return SlideTransition(
                                    position: Tween<Offset>(
                                      begin: Offset(1, 0), // empieza derecha
                                      end: Offset.zero, // termina en su lugar
                                      ).animate(curved),
                                      child: FadeTransition(
                                        opacity: curved,
                                        child: child,
                                      ),
                                    );
                                    */
                                  return ScaleTransition(
                                    scale: curved,
                                    child: FadeTransition(
                                      opacity: curved,
                                      child: child,
                                    ),
                                  );
                                },
                            ),
                          );
                        },
                        icon: Icons.explore,
                        label: 'Explorar Himnos',
                        /*
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        ),
                        */
                      ),
                    ),
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

class _OpcionPrincipal {
  final IconData icono;
  final String texto;
  final Color color;

  _OpcionPrincipal({
    required this.icono,
    required this.texto,
    required this.color,
  });
}

// ESTE ES EL BOTÓN DE LA PANTALLA PRINCIPAL
class NeonGlowButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String label;
  final IconData icon;

  NeonGlowButton({
    Key? key,
    required this.onPressed,
    required this.label,
    required this.icon,
  }) : super(key: key);

  @override
  State<NeonGlowButton> createState() => _NeonGlowButtonState();
}

class _NeonGlowButtonState extends State<NeonGlowButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glow;
  late Animation<Color?> _colorAnimation;

  final List<Color> neonColors = [
    Colors.cyanAccent,
    Colors.pinkAccent,
    Colors.blueAccent,
    Colors.greenAccent,
    Colors.orangeAccent,
    Colors.purpleAccent,
  ];

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 5),
    )..repeat(reverse: true);

    _glow = Tween<double>(begin: 5.0, end: 20.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _colorAnimation = _controller.drive(
      TweenSequence<Color?>(
        List.generate(neonColors.length, (index) {
          final color = neonColors[index];
          final next = neonColors[(index + 1) % neonColors.length];
          return TweenSequenceItem(
            tween: ColorTween(begin: color, end: next),
            weight: 1.0,
          );
        }),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final currentColor = _colorAnimation.value ?? Colors.black;

        /*
        ESTO ES SI QUIERO USAR UN COLOR INVERTIDO
        final invertedColor = Color.fromARGB(
          currentColor.alpha,
          255 - currentColor.red,
          255 - currentColor.green,
          255 - currentColor.blue,
        );
        */
        
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: currentColor.withOpacity(0.9),
                blurRadius: _glow.value,
                spreadRadius: 1,
              ),
            ],
          ),
          child: ElevatedButton.icon(
            onPressed: widget.onPressed,
            icon: Icon(widget.icon, color: Colors.white, size: 16, shadows: [
              Shadow(
                offset: Offset(1, 1),
                blurRadius: 2.0,
                color: Colors.black,
              ),
              /*
              Shadow(
                offset: Offset(-1, -1),
                blurRadius: 2.0,
                color: Colors.black,
              ),
              Shadow(
                offset: Offset(1, -1),
                blurRadius: 2.0,
                color: Colors.black,
              ),
              Shadow(
                offset: Offset(-1, 1),
                blurRadius: 2.0,
                color: Colors.black,
              ),
              */
            ]),
            label: Text(
              widget.label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                shadows: [
                  Shadow(
                    offset: Offset(1, 1),
                    blurRadius: 2.0,
                    color: Colors.black,
                  ),
                  /*
                  Shadow(
                    offset: Offset(-1, -1),
                    blurRadius: 2.0,
                    color: Colors.black,
                  ),
                  Shadow(
                    offset: Offset(1, -1),
                    blurRadius: 2.0,
                    color: Colors.black,
                  ),
                  Shadow(
                    offset: Offset(-1, 1),
                    blurRadius: 2.0,
                    color: Colors.black,
                  ),
                  */
                ],
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              side: BorderSide(color: currentColor, width: 2),
              padding: EdgeInsets.symmetric(horizontal: 25, vertical: 15),
            ),
          ),
        );
      },
    );
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


// ESTA ES PARA LA SECCIÓN DE LISTAS
class TabListas extends StatelessWidget {
  final List<dynamic> listas;
  final void Function(int) onEliminar;
  final void Function(int) onEditar;
  final Function(ThemeMode) cambiarTema;
  final Function(Color) cambiarColorEtiqueta;
  final List<dynamic> himnos;
  final Function(double) cambiarFuente;
  final double tam_fuente;
  

  const TabListas({
    Key? key,
    required this.himnos,
    required this.listas,
    required this.onEliminar,
    required this.onEditar,
    required this.cambiarColorEtiqueta,
    required this.cambiarTema,
    required this.cambiarFuente,
    required this.tam_fuente,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (listas.isEmpty) {
      return Center(child: Text("Todavía no tienes listas guardadas"));
    }

    return ListView.builder(
      itemCount: listas.length,
      itemBuilder: (context, index) {
        final lista = listas[index];
        return Card(
          margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ListTile(
            title: Text(lista.nota,
                style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
              lista.temas.join(', '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'editar') {
                  onEditar(index);
                } else if (value == 'eliminar') {
                  onEliminar(index);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'editar',
                  child: Row(
                    children: [
                      Icon(Icons.edit, color: Colors.blue),
                      SizedBox(width: 8),
                      Text("Editar"),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'eliminar',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text("Eliminar"),
                    ],
                  ),
                ),
              ],
            ),
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true, // Ocupa toda la pantalla
                backgroundColor: Colors.transparent, // Hacemos transparente para personalizar
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (_) => DialogoPantallaCompleta_Listados(titulo: lista.nota, temas: lista.temas, himnos: himnosApp, cambiarTema: cambiarTema, cambiarColorEtiqueta: cambiarColorEtiqueta, cambiarFuente: cambiarFuente, tam_fuente: tam_fuente),
              );
            },
          ),
        );
      },
    );
  }
}

class DialogoPantallaCompleta_Listados extends StatefulWidget {
  final String titulo;
  final List<String> temas;
  final List<dynamic> himnos;
  final Function(ThemeMode) cambiarTema;
  final Function(Color) cambiarColorEtiqueta;
  final Function(double) cambiarFuente;
  final double tam_fuente;
    
  DialogoPantallaCompleta_Listados({
    required this.titulo,
    required this.temas,
    required this.himnos,
    required this.cambiarTema,
    required this.cambiarColorEtiqueta,
    required this.cambiarFuente,
    required this.tam_fuente,
  });
  
  @override
  State<DialogoPantallaCompleta_Listados> createState() => _DialogoPantallaCompleta_ListadosState();
}

class _DialogoPantallaCompleta_ListadosState extends State<DialogoPantallaCompleta_Listados>{
  String contenido = '';
  late String titulo = widget.titulo;
  late int tonoOffset;
  late double tam_fuente;
  late List<String> temas = widget.temas;
  late List<dynamic> himnos = widget.himnos;
  @override
  void initState() {
    super.initState();
    tonoOffset = 0;
    tam_fuente = widget.tam_fuente;
  }
  
  final List<String> notasIngles = [
    'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'
  ];
  
  String notaConTono(int numero) {
    final indexOriginal = (numero - 1) % 12;
    final indexConOffset = (indexOriginal + tonoOffset) % 12;
    return notasIngles[(indexConOffset + 12) % 12];
  }

Widget formatearConNotas(String tema1, String texto, int tonoOffset, int index1) {
  final List<String> PalabrasParaBoldear = ["Tema", "TEMA", "CORO", "ESTROFA", "INTRO", "ESTRIBILLO", "PUENTE", "PRE-CORO", "(", "FINAL"];
  final lineas = texto.split('\n');
  final lineasWidgets = <Widget>[];
  lineasWidgets.add(Text("${index1 + 1} ■ █ ${tema1} █ ■", style: TextStyle(fontSize: tam_fuente + 5, color: etiquetaColor, fontWeight: FontWeight.bold)));
  lineasWidgets.add(Text('Círculo de "${notasMusicales1[tonoOffset]}"', style: TextStyle(fontSize: tam_fuente + 3, color: etiquetaColor, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)));
  lineasWidgets.add(SizedBox(height: 10.0));
  
  for (final linea in lineas) {
    final regex = RegExp(r'•(.*?)•');
    final widgets = <Widget>[];
    int lastIndex = 0;

    for (final match in regex.allMatches(linea)) {
      final antes = linea.substring(lastIndex, match.start);
      if (antes.isNotEmpty) {
        widgets.add(Text(
          antes,
          style: TextStyle(fontSize: tam_fuente, color: Colors.black),
        ));
      }

      final contenidoNota = match.group(1) ?? '';

      final numeroMatch = RegExp(r'\d+').firstMatch(contenidoNota);
      final numero = int.tryParse(numeroMatch?.group(0) ?? '');
      final indexNumero = numeroMatch?.start ?? 0;

      final prefijo = contenidoNota.substring(0, indexNumero);
      final contenidoExtra = contenidoNota.substring((numeroMatch?.end ?? 0));

      final nota = numero != null ? notaConTono(numero) : '';
      final notaFinal = '$nota$prefijo';

      final notaWidget = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 3, vertical: 2),
            margin: EdgeInsets.all(0.0),
            decoration: BoxDecoration(
              color: etiquetaColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              notaFinal,
              style: TextStyle(
                fontSize: tam_fuente,
                color: textColor1,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (contenidoExtra.isNotEmpty)
            /*Padding(
              padding: EdgeInsets.only(top: 2),
              child: */ Text(
                contenidoExtra,
                style: TextStyle(
                  fontSize: tam_fuente,
                  color: etiquetaColor,
                ),
              ),
          //  ),
        ],
      );

      widgets.add(Baseline(
        baseline: tam_fuente+1, // ajusta si necesario según fuente
        baselineType: TextBaseline.alphabetic,
        child: notaWidget,));

      lastIndex = match.end;
    }

    if (lastIndex < linea.length) {
      bool comprobador1 = false;
      for (String palabra1 in PalabrasParaBoldear) {
        if (linea.substring(lastIndex).contains(palabra1)) {
          comprobador1 = true;
        }
      }
      widgets.add(Text(
        comprobador1 ? "• ${linea.substring(lastIndex)}" : linea.substring(lastIndex),
        style: TextStyle(fontSize: comprobador1 ? tam_fuente + 3 : tam_fuente, color: Colors.black, fontWeight: comprobador1 ? FontWeight.bold : FontWeight.normal, fontStyle: comprobador1 ? FontStyle.italic : FontStyle.normal),
      ));
    }

    // Cada línea en un Row con Wrap para que se acomoden bien las notas y textos
    lineasWidgets.add(
      Padding(
        padding: EdgeInsets.only(bottom: 4), // espacio entre líneas
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.end,
          spacing: 2,
          runSpacing: 0,
          children: widgets,
        ),
      ),
    );
  }
  
  lineasWidgets.add(Divider(height: 20.0, color: etiquetaColor, indent: 5.0, endIndent: 5.0,));
  
  // Finalmente, juntas todas las líneas en una columna vertical
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: lineasWidgets,
  );
}


  
  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height, // Pantalla Completa
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)), // Redondeo arriba
      ),
      child: Column(
        children: [
          AppBar(
            title: Text(titulo, style: TextStyle(color: textColor1, fontWeight: FontWeight.bold)),
            backgroundColor: etiquetaColor,
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
            icon: Icon(Icons.remove_circle_outline, color: textColor1),
             onPressed: () => setState(() => tonoOffset--),
             tooltip: 'Bajar ½ Tono',
          ),
          IconButton(
            icon: Icon(Icons.add_circle_outline, color: textColor1),
              onPressed: () => setState(() => tonoOffset++),
              tooltip: 'Subir ½ Tono',
          ),
              
              IconButton(
              icon: Icon(Icons.menu, color: textColor1),
              onPressed: () async {
                final actualizado = await Navigator.push(
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
                        etiquetaColor = _coloresEtiqueta[index];
                        textColor1 = index % 2 == 1 ? Colors.white : Colors.black;
                      },
                      cambiarFuente: (tam) async {
                        await widget.cambiarFuente(tam);
                        /*
                        final prefs = await SharedPreferences.getInstance();
                        final tam_fuente1 = prefs.getDouble('tam_fuente') ?? 14;
                        */
                        setState(() => tam_fuente = tam);
                        tam_fuente = tam;
                      },
                      tam_fuente: tam_fuente,
                    ),
                  ),
                );
                if (actualizado == true) {
                  setState(() => listas = List.from(listasApp));
                }
              },
            ),
            
            IconButton(
                icon: Icon(Icons.close, color: textColor1),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          Expanded(
            child: ListView.builder(
                      itemCount: temas.length,
                      itemBuilder: (BuildContext context, int index1) {
                        try {
                          var TextoComprobado = himnos.firstWhere((item1) => item1['tema'] == temas[index1]);
                          return formatearConNotas(TextoComprobado['tema'], TextoComprobado['contenido'], tonoOffset = notasMusicales1.indexOf(TextoComprobado['nota']), index1);
                        } catch (e) {
                          return Text("Tema ${temas[index1]} no encontrado");
                        }
                      }
                    ),
          ),
        ],
      ),
    );
  }
}


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
        color: widget.seleccionado ? Colors.purple.shade700 : Colors.grey,
      ),
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class PantallaConTabs extends StatefulWidget {
  final Function(ThemeMode) cambiarTema;
  final Function(Color) cambiarColorEtiqueta;
  
  PantallaConTabs({
    required this.cambiarTema,
    required this.cambiarColorEtiqueta,
  });
  
  @override
  _PantallaConTabsState createState() => _PantallaConTabsState();
}

class _PantallaConTabsState extends State<PantallaConTabs> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<Map<String, dynamic>> adoracion = [];
  final List<Map<String, dynamic>> jubilo = [];
  final List<Map<String, dynamic>> himnario = [];

  List<TemaLista> _listas = [];

  List<TemaLista> get listas => _listas;

  set listas(List<TemaLista> nuevasListas) {
    setState(() {
      _listas = nuevasListas;
    });
  }

  // Gestión de listas
  Set<String> seleccionados = {};
  String nota = "C";
  bool modoSeleccion = false;
  late double tam_fuente;

  final storage = ListaStorage();

  final List<Tab> tabs = const [
    Tab(icon: Icon(Icons.music_note, color: Colors.white), text: 'Adoración'),
    Tab(icon: Icon(Icons.celebration, color: Colors.white), text: 'Júbilo'),
    Tab(icon: Icon(Icons.book, color: Colors.white), text: 'Himnario'),
    Tab(icon: Icon(Icons.text_fields, color: Colors.white), text: 'Listas'),
    Tab(icon: Icon(Icons.list, color: Colors.white), text: 'Formatear'),
    Tab(icon: Icon(Icons.search, color: Colors.white), text: 'Buscar'),
  ];

  // -------------------------
  // Ciclo de vida
  // -------------------------
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: tabs.length, vsync: this);
    cargarListasEnState();
    cargarTamFuente();
  }

  Future<void> cargarTamFuente() async {
    final pref = await SharedPreferences.getInstance();
    final tam_fuente1 = pref.getDouble('tam_fuente') ?? 14.0;
    setState(() => tam_fuente = tam_fuente1);
  }

  Future<void> cambiarFuente(double tam_fuente1) async {
    final pref = await SharedPreferences.getInstance();
    await pref.setDouble('tam_fuente', tam_fuente1);
    setState(() => tam_fuente = tam_fuente1);
  }

  void clasificarHimnos(List<dynamic> himnos) {
    adoracion.clear();
    jubilo.clear();
    himnario.clear();

    for (var himno in himnos) {
      final categorias = himno['categoria'] as List;
      if (categorias.contains("Adoración")) adoracion.add(himno);
      if (categorias.contains("Júbilo")) jubilo.add(himno);
      if (categorias.contains("Himnario")) himnario.add(himno);
    }

    adoracion.sort((a, b) => a['tema'].compareTo(b['tema']));
    jubilo.sort((a, b) => a['tema'].compareTo(b['tema']));
    himnario.sort((a, b) => a['tema'].compareTo(b['tema']));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // -------------------------
  // Persistencia
  // -------------------------
  Future<void> cargarListasEnState() async {
    final listasLocales = await storage.leerListas();
    if (listasLocales.isNotEmpty) {
      listasApp = listasLocales;
    } else {
      final rawData = await rootBundle.loadString('assets/MisListas.json');
      final data = json.decode(rawData);
      listasApp = (data['listas'] as List).map((e) => TemaLista.fromJson(e)).toList();
      await storage.guardarListas(listasApp);
    }
    setState(() => listas = List.from(listasApp));
  }

  Future<void> guardarListasEnState() async {
    listasApp = List.from(listas);
    await storage.guardarListas(listasApp);
    setState(() => listas = List.from(listasApp));
  }

  // -------------------------
  // CRUD
  // -------------------------
  void crearLista() {
    if (seleccionados.isEmpty) return;

    final notaController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Guardar lista"),
        content: TextField(
          controller: notaController,
          decoration: InputDecoration(labelText: "Nombre de la lista"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancelar")),
          ElevatedButton(
            onPressed: () async {
              final nuevaNota = notaController.text.trim().isEmpty ? "Lista" : notaController.text.trim();
              final nuevaLista = TemaLista(temas: seleccionados.toList(), nota: nuevaNota);
              setState(() {
                listas.add(nuevaLista);
                seleccionados.clear();
                modoSeleccion = false;
              });
              await guardarListasEnState();
              Navigator.pop(context);
            },
            child: Text("Guardar"),
          ),
        ],
      ),
    );
  }

  void eliminarLista(int index) async {
    listas.removeAt(index);
    await guardarListasEnState();
  }

  void editarListaModal(int index) {
    final lista = listas[index];
    final notaController = TextEditingController(text: lista.nota);
    final temasController = TextEditingController(text: lista.temas.join(', '));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: MediaQuery.of(context).viewInsets,
        child: Container(
          padding: EdgeInsets.all(16),
          child: Wrap(
            children: [
              Text("Editar Lista", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 12),
              TextField(controller: notaController, decoration: InputDecoration(labelText: "Nota")),
              SizedBox(height: 12),
              TextField(controller: temasController, decoration: InputDecoration(labelText: "Temas (separados por coma)")),
              SizedBox(height: 16),
              ElevatedButton.icon(
                icon: Icon(Icons.save),
                label: Text("Guardar cambios"),
                onPressed: () async {
                  final nuevosTemas = temasController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
                  setState(() => listas[index] = TemaLista(temas: nuevosTemas, nota: notaController.text));
                  await guardarListasEnState();
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void desactivarSeleccion() {
    setState(() {
      modoSeleccion = false;
      seleccionados.clear();
    });
  }

  // -------------------------
  // UI de himnos
  // -------------------------
  void mostrarVentana(BuildContext context, String tema, String contenido, String autor, {int tonoOffset = 0}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DialogoPantallaCompleta(
        tema: tema,
        contenido: contenido,
        autor: autor,
        tonoOffsetInicial: tonoOffset,
        cambiarTema: widget.cambiarTema,
        cambiarColorEtiqueta: widget.cambiarColorEtiqueta,
        cambiarFuente: cambiarFuente,
        tam_fuente: tam_fuente,
      ),
    );
  }

  Widget _buildListaHimnos(List<Map<String, dynamic>> lista) {
    if (lista.isEmpty) return Center(child: Text("No hay himnos disponibles en esta sección"));

    return ListView.builder(
      itemCount: lista.length,
      itemBuilder: (context, index) {
        final himno = lista[index];
        final seleccionado = seleccionados.contains(himno['tema']);

        return TemaItem(
          key: Key(himno['tema']),
          tema: himno['tema'],
          seleccionado: seleccionado,
          onLongPress: () {
            setState(() {
              modoSeleccion = true;
              seleccionados.add(himno['tema']);
            });
          },
          onTap: () {
            if (modoSeleccion) {
              setState(() {
                if (seleccionados.contains(himno['tema'])) {
                  seleccionados.remove(himno['tema']);
                } else {
                  seleccionados.add(himno['tema']);
                }
              });
            } else {
              mostrarVentana(context, himno['tema'], himno['contenido'], himno['autor'], tonoOffset: notasMusicales1.indexOf(himno['nota']));
            }
          },
        );
      },
    );
  }

  // -------------------------
  // FAB
  // -------------------------
  Widget buildFabMenu() {
    return FloatingActionButton(
      child: Icon(Icons.menu),
      onPressed: () {
        showModalBottomSheet(
          context: context,
          builder: (_) => Container(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton.icon(onPressed: crearLista, icon: Icon(Icons.save), label: Text("Guardar lista")),
                TextButton.icon(onPressed: desactivarSeleccion, icon: Icon(Icons.cancel), label: Text("Cancelar selección")),
              ],
            ),
          ),
        );
      },
    );
  }

  // -------------------------
  // Build principal
  // -------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: AppBar(
          titleSpacing: 0,
          backgroundColor: etiquetaColor,
          automaticallyImplyLeading: false,
          title: Row(
            children: [
              IconButton(icon: Icon(Icons.arrow_back, color: textColor1), onPressed: () => Navigator.pop(context)),
              Expanded(
                child: TabBar(
                  controller: _tabController,
                  tabs: tabs,
                  isScrollable: true,
                  indicatorColor: Colors.amber,
                  labelColor: textColor1,
                  unselectedLabelColor: Colors.white70,
                  labelStyle: TextStyle(fontWeight: FontWeight.bold),
                  unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal),
                ),
              ),
            ],
          ),
          actions: [
          IconButton(
              icon: Icon(Icons.menu, color: textColor1),
              onPressed: () async {
                final actualizado = await Navigator.push(
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
                        etiquetaColor = _coloresEtiqueta[index];
                        textColor1 = index % 2 == 1 ? Colors.white : Colors.black;
                      },
                      cambiarFuente: (tam) async {
                        await cambiarFuente(tam);
                        /*
                        final prefs = await SharedPreferences.getInstance();
                        final tam_fuente1 = prefs.getDouble('tam_fuente') ?? 14;
                        */
                        setState(() => tam_fuente = tam);
                        tam_fuente = tam;
                      },
                      tam_fuente: tam_fuente,
                    ),
                  ),
                );
                if (actualizado == true) {
                  setState(() => listas = List.from(listasApp));
                  await cargarListasEnState();
                }
              },
              
            ),],
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: cargarDatos(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator(color: etiquetaColor));
          if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));

          final data = snapshot.data!;
          final himnos = data['himnos'] as List<dynamic>;
          FechaDeHimnos = data['fecha'];
          clasificarHimnos(himnos);

          return TabBarView(
            controller: _tabController,
            children: [
              _buildListaHimnos(adoracion),
              _buildListaHimnos(jubilo),
              _buildListaHimnos(himnario),
              TabListas(
                himnos: himnosApp,
                listas: listasApp,
                onEditar: editarListaModal,
                onEliminar: eliminarLista,
                cambiarTema: widget.cambiarTema,
                cambiarColorEtiqueta: widget.cambiarColorEtiqueta,
                cambiarFuente: cambiarFuente,
                tam_fuente: tam_fuente,
              ),
              FormateadorTextoScreen(),
              BusquedaHimnos(
                himnos: himnosApp,
                cambiarTema: widget.cambiarTema,
                cambiarColorEtiqueta: widget.cambiarColorEtiqueta,
                cambiarFuente: cambiarFuente,
                tam_fuente: tam_fuente,
              ),
            ],
          );
        },
      ),
      floatingActionButton: modoSeleccion ? buildFabMenu() : null,
    );
  }
}


class DialogoPantallaCompleta extends StatefulWidget {
  final Function(ThemeMode) cambiarTema;
  final Function(Color) cambiarColorEtiqueta;
  final String tema;
  final contenido;
  final String autor;
  final int tonoOffsetInicial;
  final Function(double) cambiarFuente;
  final double tam_fuente;
  
  
  DialogoPantallaCompleta({
    required this.tema,
    required this.contenido,
    required this.autor,
    this.tonoOffsetInicial = 0,
    required this.cambiarTema,
    required this.cambiarColorEtiqueta,
    required this.cambiarFuente,
    required this.tam_fuente,
  });
  
  @override
  State<DialogoPantallaCompleta> createState() => _DialogoPantallaCompletaState();
}

class _DialogoPantallaCompletaState extends State<DialogoPantallaCompleta>{
  String contenido = '';
  late int tonoOffset;
  late double tam_fuente;
  
  @override
  void initState() {
    super.initState();
    tonoOffset = widget.tonoOffsetInicial;
    tam_fuente = widget.tam_fuente;
  }
  
  final List<String> notasIngles = [
    'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'
  ];
  
  String notaConTono(int numero) {
    final indexOriginal = (numero - 1) % 12;
    final indexConOffset = (indexOriginal + tonoOffset) % 12;
    return notasIngles[(indexConOffset + 12) % 12];
  }

Widget formatearConNotas(String texto, int tonoOffset) {
  final List<String> PalabrasParaBoldear = ["CORO", "ESTROFA", "INTRO", "ESTRIBILLO", "PUENTE", "PRE-CORO", "(", "FINAL"];
  final lineas = texto.split('\n');
  final lineasWidgets = <Widget>[];
  lineasWidgets.add(Text("■ █ ${widget.tema} █ ■", style: TextStyle(fontSize: tam_fuente + 5, color: etiquetaColor, fontWeight: FontWeight.bold)));
  lineasWidgets.add(Text('Círculo de "${notasMusicales1[tonoOffset]}"', style: TextStyle(fontSize: tam_fuente + 3, color: etiquetaColor, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)));
  lineasWidgets.add(SizedBox(height: 10.0));
  
  for (final linea in lineas) {
    final regex = RegExp(r'•(.*?)•');
    final widgets = <Widget>[];
    int lastIndex = 0;

    for (final match in regex.allMatches(linea)) {
      final antes = linea.substring(lastIndex, match.start);
      if (antes.isNotEmpty) {
        widgets.add(Text(
          antes,
          style: TextStyle(fontSize: tam_fuente, color: Colors.black),
        ));
      }

      final contenidoNota = match.group(1) ?? '';

      final numeroMatch = RegExp(r'\d+').firstMatch(contenidoNota);
      final numero = int.tryParse(numeroMatch?.group(0) ?? '');
      final indexNumero = numeroMatch?.start ?? 0;

      final prefijo = contenidoNota.substring(0, indexNumero);
      final contenidoExtra = contenidoNota.substring((numeroMatch?.end ?? 0));

      final nota = numero != null ? notaConTono(numero) : '';
      final notaFinal = '$nota$prefijo';

      final notaWidget = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 3, vertical: 2),
            margin: EdgeInsets.all(0.0),
            decoration: BoxDecoration(
              color: etiquetaColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              notaFinal,
              style: TextStyle(
                fontSize: tam_fuente,
                color: textColor1,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (contenidoExtra.isNotEmpty)
            /*Padding(
              padding: EdgeInsets.only(top: 2),
              child: */ Text(
                contenidoExtra,
                style: TextStyle(
                  fontSize: tam_fuente,
                  color: etiquetaColor,
                ),
              ),
          //  ),
        ],
      );

      widgets.add(Baseline(
        baseline: tam_fuente+1, // ajusta si necesario según fuente
        baselineType: TextBaseline.alphabetic,
        child: notaWidget,));

      lastIndex = match.end;
    }

    if (lastIndex < linea.length) {
      bool comprobador1 = false;
      for (String palabra1 in PalabrasParaBoldear) {
        if (linea.substring(lastIndex).contains(palabra1)) {
          comprobador1 = true;
        }
      }
      widgets.add(Text(
        comprobador1 ? "• ${linea.substring(lastIndex)}" : linea.substring(lastIndex),
        style: TextStyle(fontSize: comprobador1 ? tam_fuente + 3 : tam_fuente, color: Colors.black, fontWeight: comprobador1 ? FontWeight.bold : FontWeight.normal, fontStyle: comprobador1 ? FontStyle.italic : FontStyle.normal),
      ));
    }

    // Cada línea en un Row con Wrap para que se acomoden bien las notas y textos
    lineasWidgets.add(
      Padding(
        padding: EdgeInsets.only(bottom: 4), // espacio entre líneas
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.end,
          spacing: 2,
          runSpacing: 0,
          children: widgets,
        ),
      ),
    );
  }

  // Finalmente, juntas todas las líneas en una columna vertical
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: lineasWidgets,
  );
}


  
  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height, // Pantalla Completa
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)), // Redondeo arriba
      ),
      child: Column(
        children: [
          AppBar(
            title: Text(widget.tema, style: TextStyle(color: textColor1)),
            backgroundColor: etiquetaColor,
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
            icon: Icon(Icons.remove_circle_outline, color: textColor1),
             onPressed: () => setState(() => tonoOffset--),
             tooltip: 'Bajar ½ Tono',
          ),
          IconButton(
            icon: Icon(Icons.add_circle_outline, color: textColor1),
              onPressed: () => setState(() => tonoOffset++),
              tooltip: 'Subir ½ Tono',
          ),
              
              IconButton(
              icon: Icon(Icons.menu, color: textColor1),
              onPressed: () async {
                final actualizado = await Navigator.push(
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
                        etiquetaColor = _coloresEtiqueta[index];
                        textColor1 = index % 2 == 1 ? Colors.white : Colors.black;
                      },
                      cambiarFuente: (tam) async {
                        await widget.cambiarFuente(tam);
                        /*
                        final prefs = await SharedPreferences.getInstance();
                        final tam_fuente1 = prefs.getDouble('tam_fuente') ?? 14;
                        */
                        setState(() => tam_fuente = tam);
                        tam_fuente = tam;
                      },
                      tam_fuente: tam_fuente,
                    ),
                  ),
                );
                if (actualizado == true) {
                  setState(() => listas = List.from(listasApp));
                }
              },
            ),
            
            IconButton(
                icon: Icon(Icons.close, color: textColor1),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(6),
              child: ListView(
                children: [
                  Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      formatearConNotas(widget.contenido, tonoOffset),
                      SizedBox(height: 20),
                      Text(
                        "Autor: ${widget.autor}",
                        style: TextStyle(color: Colors.black, fontSize: 12),
                      ),
                    ],
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

class BusquedaHimnos extends StatefulWidget {
  final Function(ThemeMode) cambiarTema;
  final Function(Color) cambiarColorEtiqueta;
  final himnos;
  final Function(double) cambiarFuente;
  final double tam_fuente;
  
  BusquedaHimnos({
    super.key,
    required this.himnos,
    required this.cambiarColorEtiqueta,
    required this.cambiarTema,
    required this.cambiarFuente,
    required this.tam_fuente,
  });
  
  @override
  State<BusquedaHimnos> createState() => _BusquedaHimnosState();
}

class _BusquedaHimnosState extends State<BusquedaHimnos> {
  late List<Himno> himnos;
  late List<String> todasCategorias;
  late double tam_fuente;
  
  @override
  void initState() {
    super.initState();
    himnos = widget.himnos.map<Himno>((h) => Himno.fromJson(h)).toList();
    tam_fuente = widget.tam_fuente;
    
    final categorias = <String>{};
    for (var h in himnos) {
      categorias.addAll(List<String>.from(h.categoria));
    }
    todasCategorias = categorias.toList()
      ..sort((a,b) => a.toLowerCase().compareTo(b.toLowerCase()));
  }
  
  void mostrarVentana(BuildContext context, String tema, String contenido, String autor, {int tonoOffset = 0,}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Ocupa toda la pantalla
      backgroundColor: Colors.transparent, // Hacemos transparente para personalizar
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (_) => DialogoPantallaCompleta(tema: tema, contenido: contenido, autor:autor, tonoOffsetInicial: tonoOffset, cambiarTema: widget.cambiarTema, cambiarColorEtiqueta: widget.cambiarColorEtiqueta, cambiarFuente: widget.cambiarFuente, tam_fuente: tam_fuente),
    );
  }
  
  
  ModoBusqueda modo = ModoBusqueda.todo;
  String textoBusqueda = '';
  String notaSeleccionada = '';
  Set<String> categoriasSeleccionadas = {};

  // Función para quitar tildes y convertir a minúsculas
  String normalizar(String texto) {
    const acentos = 'áéíóúÁÉÍÓÚ';
    const sinAcento = 'aeiouAEIOU';
    return limpiarTexto(texto.toLowerCase().split('').map((c) {
      final i = acentos.indexOf(c);
      return i != -1 ? sinAcento[i] : c.toLowerCase();
    }).join());
  }

  List<Himno> get himnosFiltrados {
  switch (modo) {
    case ModoBusqueda.todo:
      if (textoBusqueda.isEmpty) return himnos;
      final t = normalizar(textoBusqueda);
      return himnos.where((h) {
        final tema = normalizar(h.tema);
        final contenido = normalizar(h.contenido);
        return tema.contains(t) || contenido.contains(t);
      }).toList();

    case ModoBusqueda.nota:
      if (notaSeleccionada.isEmpty) return himnos;
      return himnos.where((h) => h.nota.toUpperCase() == notaSeleccionada.toUpperCase()).toList();

    case ModoBusqueda.categoria:
      return himnos.where((h) {
        final coincideCategoria = categoriasSeleccionadas.isEmpty ||
            h.categoria.any((cat) => categoriasSeleccionadas.contains(cat));
        final coincideNota = notaSeleccionada.isEmpty ||
            h.nota.toUpperCase() == notaSeleccionada.toUpperCase();
        return coincideCategoria && coincideNota;
      }).toList();
  }
}


  Widget buildFiltroCategorias() {
    Map<String, int> conteos = {
      for (var cat in todasCategorias)
        cat: himnos.where((h) => h.categoria.contains(cat)).length,
    };

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: todasCategorias.map((categoria) {
        final isSelected = categoriasSeleccionadas.contains(categoria);
        final count = conteos[categoria] ?? 0;
        return FilterChip(
          label: Text('$categoria ($count)'),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                categoriasSeleccionadas.add(categoria);
              } else {
                categoriasSeleccionadas.remove(categoria);
              }
            });
          },
        );
      }).toList(),
    );
  }
  
  String limpiarTexto(String texto) {
  return texto
    .replaceAllMapped(RegExp(r'•[^•\d]*\d+'), (m) {
      // Si la coincidencia termina antes del siguiente "•", devolvemos lo que sigue después del número
      final match = m.group(0)!;
      final resto = match.replaceFirst(RegExp(r'^•[^•\d]*\d+'), '');
      return resto;
    })
    .replaceAll('•', '') // luego quitamos los "•" que quedan sueltos
    .replaceAll('\n', '-')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();
  }



  
  Widget buildResultado(Himno h) {
    String fragmento = '';
    if (modo == ModoBusqueda.todo && textoBusqueda.isNotEmpty) {
      final index = normalizar(h.contenido).indexOf(normalizar(textoBusqueda));
      if (index != -1) {
        final inicio = index - 50 >= 0 ? index - 50 : 0;
        final fin = (index + 50 < h.contenido.length) ? index + 50 : h.contenido.length;
        final originalFragmento = h.contenido.substring(inicio, fin);
        fragmento = limpiarTexto(originalFragmento);
      }
    }
    return Card(
      child: ListTile(
        title: Text(h.tema),
        subtitle: fragmento.isNotEmpty ? Text('...$fragmento...') : null,
        onTap: () => mostrarVentana(context, h.tema, h.contenido, h.autor, tonoOffset: notasMusicales1.indexOf(h.nota)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notas = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];

  return Scaffold(
    body: Padding(
      padding:  EdgeInsets.all(12),
      child: ListView(
        children: [
          DropdownButton<ModoBusqueda>(
            value: modo,
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  modo = value;
                  textoBusqueda = '';
                  notaSeleccionada = '';
                  categoriasSeleccionadas.clear();
                });
              }
            },
            items: [
              DropdownMenuItem(value: ModoBusqueda.todo, child: Text("Buscar en todo")),
              DropdownMenuItem(value: ModoBusqueda.nota, child: Text("Buscar por nota")),
              DropdownMenuItem(value: ModoBusqueda.categoria, child: Text("Buscar por categoría")),
            ],
          ),
          SizedBox(height: 8),
          if (modo == ModoBusqueda.todo)
            TextField(
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: "Buscar tema o contenido...",
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  textoBusqueda = value;
                });
              },
            ),
          if (modo == ModoBusqueda.nota)
            DropdownButton<String>(
              value: notaSeleccionada.isNotEmpty ? notaSeleccionada : null,
              hint: Text("Selecciona una nota"),
              onChanged: (value) {
                setState(() {
                  notaSeleccionada = value ?? '';
                });
              },
              items: notas.map((n) => DropdownMenuItem(value: n, child: Text(n))).toList(),
            ),
          if (modo == ModoBusqueda.categoria) ...[
            buildFiltroCategorias(),
            SizedBox(height: 8),
            DropdownButton<String>(
              value: notaSeleccionada.isNotEmpty ? notaSeleccionada : null,
              hint: Text("Filtrar por nota (opcional)"),
              onChanged: (value) {
                setState(() {
                  notaSeleccionada = value ?? '';
                });
              },
              items: notas.map((n) => DropdownMenuItem(value: n, child: Text(n))).toList(),
            ),
          ],
          SizedBox(height: 16),
          ...himnosFiltrados.map(buildResultado).toList(),
        ],
      ),
    ),
  );

  }
}

class ConfiguracionScreen extends StatefulWidget {
  final Function(ThemeMode) cambiarTema;
  final Function(Color) cambiarColorEtiqueta;
  final Function(double) cambiarFuente;
  final double tam_fuente;
  
  ConfiguracionScreen({
    required this.cambiarTema,
    required this.cambiarColorEtiqueta,
    required this.cambiarFuente,
    required this.tam_fuente,
  });
  
  @override
  State<ConfiguracionScreen> createState() => _ConfiguracionScreenState();
}

class _ConfiguracionScreenState extends State<ConfiguracionScreen> {
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
  late double tam_fuente;
  
  @override
  void initState() {
    super.initState();
    tam_fuente = widget.tam_fuente;
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Configuración', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(icon: Icon(Icons.arrow_back),onPressed: () {
          Navigator.pop(context, true); // 👈 Ahora devuelve true
        },),),
      body: SingleChildScrollView(child: Padding(
        padding: EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tema', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Row(
              children: [
                TextButton(
                  onPressed: () => widget.cambiarTema(ThemeMode.light),
                  child: Text('Claro'),
                ),
                TextButton(
                  onPressed: () => widget.cambiarTema(ThemeMode.dark),
                  child: Text('Oscuro'),
                ),
              ],
            ),
            SizedBox(height: 18),
            Text('Color de etiquetas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Wrap(
              spacing: 5,
              children: colores.asMap().entries.map((entry) {
                final index = entry.key;
                final color = entry.value;
                return GestureDetector(
                onTap: () {
                widget.cambiarColorEtiqueta(color);
                setState(() {
                  etiquetaColor = color; textColor1 = index % 2 == 1 ? Colors.white : Colors.black; }); },
                child: Container(
                  width: 40,
                  height: 40,
                  margin: EdgeInsets.all(2.0),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: etiquetaColor == color ? textColor1 : Colors.black54, width: 1.5),
                    boxShadow: [
                      BoxShadow(color: color, blurRadius: etiquetaColor == color ? 3 : 0, offset: Offset(0, etiquetaColor == color ? 3 : 0),),
                      BoxShadow(color: color, blurRadius: etiquetaColor == color ? 3 : 0, offset: Offset(0, etiquetaColor == color ? 3 : 0),),                     
                     ],
                  ),
                  child: Center(child: Text(etiquetaColor == color ? "•" : "", style: TextStyle(color: textColor1, fontSize: 20)),),
                ),
              );}).toList(),
            ),
            SizedBox(height: 18),
            Text('Tamaño de Fuente', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Slider(
                value: tam_fuente,
                min: 12,
                max: 24,
                divisions: 12,
                label: "$tam_fuente",
                activeColor: etiquetaColor,
                onChanged: (value) { widget.cambiarFuente(value); setState(() => tam_fuente = value); },
              ),
            
            SizedBox(height: 18),
            Container(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.end,
                  spacing: 2,
                  runSpacing: 0,
                  children: [
                  Text("Este", style: TextStyle(fontSize: tam_fuente)),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 3, vertical: 2),
                      margin: EdgeInsets.all(0.0),
                      decoration: BoxDecoration(
                        color: etiquetaColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text("C",style: TextStyle(fontSize: tam_fuente, color: textColor1,fontWeight: FontWeight.bold,),
                      ),
                    ),
                    Text("es",style: TextStyle(fontSize: tam_fuente,color: etiquetaColor,),),],),
                    Text("un ejemplo del", style: TextStyle(fontSize: tam_fuente,)),
          
          Column(
          mainAxisSize: MainAxisSize.min,
          children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 3, vertical: 2),
            margin: EdgeInsets.all(0.0),
            decoration: BoxDecoration(
              color: etiquetaColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              "Am7",
              style: TextStyle(
                fontSize: tam_fuente,
                color: textColor1,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Text("con", style: TextStyle(
                  fontSize: tam_fuente,
                  color: etiquetaColor,
                ),
              ),],),
          
          Text("tenido.", style: TextStyle(fontSize: tam_fuente,)),
          ],
        ),
      ),
      SizedBox(height: 40),
      Row(
        // mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Icon(Icons.update, size: 18, color: Colors.blueGrey),
          SizedBox(width: 6),
          Text(
            "Fecha de Actualización: $FechaDeHimnos" ?? "Fecha de Actualización: No disponible",
            style: TextStyle(
              fontSize: 14,
              color: Colors.blueGrey,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
      SizedBox(height: 20),
      ElevatedButton.icon(
        onPressed: () async {
          final mensajesHimnos = await actualizarJsonDesdeGithubEnMemoria();
          final mensajesListas = await actualizarListasDesdeGithubEnMemoria();
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: Text("Proceso de actualización"),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...mensajesHimnos.map((m) => Text(m)),
                    ...mensajesListas.map((m) => Text(m)),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: Text("OK")),
              ],
            ),
          );
          final state1 = context.findAncestorStateOfType<_PantallaConTabsState>();
          setState(() {
            FechaDeHimnos = himnosApp['fecha'] ?? "No disponible";
            if (state1 != null) {
              state1.listas = List.from(listasApp);
            }
          });
          
        },
        icon: Icon(Icons.refresh, color: etiquetaColor),
        label: Text("Actualizar himnos", style: TextStyle(color: etiquetaColor)),
      ),


          ],
        ),
      ),),
    );
  }
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

/*
Future<bool> hayConexionInternet1() async {
  // Selección de URL según modo
  final String url = "https://raw.githubusercontent.com/Danel20/MusicaLXS/main/MisListas.json";

  if (kIsWeb) {
    // Verificación rápida del navegador
    if (!(html.window.navigator.onLine ?? false)) return false;

    // Confirmación con "ping" al recurso
    try {
      final respuesta = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 3));
      return respuesta.statusCode == 200;
    } catch (_) {
      return false;
    }
  } else {
    // Android/iOS/desktop
    final resultado = await Connectivity().checkConnectivity();
    if (resultado == ConnectivityResult.none) return false;

    try {
      final respuesta = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 3));
      return respuesta.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
*/
/* ESTO ES PARA SUBIR EL ARCHIVO */

// Aquí debes tener tus variables globales como etiquetas y colores
Color etiquetaColorx = Colors.blue;
Color textColor1x = Colors.white;
List<String> notasMusicales1x = ['C','C#','D','D#','E','F','F#','G','G#','A','A#','B'];

class FormateadorTextoScreen extends StatefulWidget {
  @override
  _FormateadorTextoScreenState createState() => _FormateadorTextoScreenState();
}

class _FormateadorTextoScreenState extends State<FormateadorTextoScreen> {
  final TextEditingController _controller = TextEditingController();
  int tonoOffsetx = 0;
  double tam_fuentex = 16;
  Widget contenidofinal = Text('');
  
  String notaConTono(int numero) {
    final indexOriginal = (numero - 1) % 12;
    final indexConOffset = (indexOriginal + tonoOffsetx) % 12;
    return notasMusicales1[(indexConOffset + 12) % 12];
  }

  Widget formatearConNotas(String titulo, String texto, int tonoOffsetx) {
    final List<String> PalabrasParaBoldear = ["Tema", "TEMA", "CORO", "ESTROFA", "INTRO", "ESTRIBILLO", "PUENTE", "PRE-CORO", "(", "FINAL"];
    final lineas = texto.replaceAll(r'\n','\n').replaceAll(r'\/','\/').split('\n');
    final lineasWidgets = <Widget>[];
    lineasWidgets.add(Text("$titulo", style: TextStyle(fontSize: tam_fuentex + 5, color: etiquetaColor, fontWeight: FontWeight.bold)));
    lineasWidgets.add(SizedBox(height: 10.0));

    for (final linea in lineas) {
      final regex = RegExp(r'•(.*?)•');
      final widgets = <Widget>[];
      int lastIndex = 0;

      for (final match in regex.allMatches(linea)) {
        final antes = linea.substring(lastIndex, match.start);
        if (antes.isNotEmpty) {
          widgets.add(Text(antes, style: TextStyle(fontSize: tam_fuentex, color: Colors.black)));
        }

        final contenidoNota = match.group(1) ?? '';
        final numeroMatch = RegExp(r'\d+').firstMatch(contenidoNota);
        final numero = int.tryParse(numeroMatch?.group(0) ?? '');
        final indexNumero = numeroMatch?.start ?? 0;
        final prefijo = contenidoNota.substring(0, indexNumero);
        final contenidoExtra = contenidoNota.substring((numeroMatch?.end ?? 0));
        final nota = numero != null ? notaConTono(numero) : '';
        final notaFinal = '$nota$prefijo';

        final notaWidget = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 3, vertical: 2),
              decoration: BoxDecoration(color: etiquetaColor, borderRadius: BorderRadius.circular(6)),
              child: Text(notaFinal, style: TextStyle(fontSize: tam_fuentex, color: textColor1, fontWeight: FontWeight.bold)),
            ),
            if (contenidoExtra.isNotEmpty)
              Text(contenidoExtra, style: TextStyle(fontSize: tam_fuentex, color: etiquetaColor)),
          ],
        );
        widgets.add(Baseline(
          baseline: tam_fuentex + 1,
          baselineType: TextBaseline.alphabetic,
          child: notaWidget,
        ));
        lastIndex = match.end;
      }

      if (lastIndex < linea.length) {
        bool comprobador1 = false;
        for (String palabra1 in PalabrasParaBoldear) {
          if (linea.substring(lastIndex).contains(palabra1)) {
            comprobador1 = true;
          }
        }
        widgets.add(Text(
          comprobador1 ? "• ${linea.substring(lastIndex)}" : linea.substring(lastIndex),
          style: TextStyle(
            fontSize: comprobador1 ? tam_fuentex + 3 : tam_fuentex,
            color: Colors.black,
            fontWeight: comprobador1 ? FontWeight.bold : FontWeight.normal,
            fontStyle: comprobador1 ? FontStyle.italic : FontStyle.normal,
          ),
        ));
      }

      lineasWidgets.add(Padding(
        padding: EdgeInsets.only(bottom: 4),
        child: Wrap(crossAxisAlignment: WrapCrossAlignment.end, spacing: 2, runSpacing: 0, children: widgets),
      ));
    }

    lineasWidgets.add(Divider(height: 20.0, color: etiquetaColor, indent: 5.0, endIndent: 5.0));

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: lineasWidgets);
  }
  
  Future<void> _pickAndReadFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt'],
      );

      if (result != null && result.files.single.path != null) {
        final file1 = io.File(result.files.single.path!);
        String content1 = await file1.readAsString();

        setState(() {
          contenidofinal = formatearConNotas("Texto Formateado", content1, tonoOffsetx);
        });
      }
    } catch (e) {
      setState(() {
        contenidofinal = Text("Error al leer el archivo: $e");
      });
    }
  }
  late String ElContenido1;
  List<String> OpcionesIntercambio = ["Pegar texto", "Usar archivo .txt"];
  Widget get Opcion_s1 { return Expanded(child: SingleChildScrollView(child: Padding(padding: EdgeInsets.all(12),child: Column(children: [TextField(controller: _controller,maxLines: null,decoration: InputDecoration(hintText: "Escribe o pega tu texto aquí...",border: OutlineInputBorder(),),),ElevatedButton(onPressed: () { setState(() { ElContenido1 = _controller.text; contenidofinal = formatearConNotas("Texto Formateado", ElContenido1, tonoOffsetx); }); }, child: Text("Formatear")),SingleChildScrollView(child: contenidofinal),])),)); }
  Widget get Opcion_s2 { return Expanded(child: Column(children: [ElevatedButton(onPressed: () async { try { FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom,allowedExtensions: ['txt'],allowMultiple: false,); if (result != null) { String content1 = ""; if (result.files.single.bytes != null) { content1 = utf8.decode(result.files.single.bytes!); } else if (result.files.single.path != null) { final file1 = io.File(result.files.single.path!); content1 = await file1.readAsString(); } setState(() { ElContenido1 = content1; contenidofinal = formatearConNotas("Texto Formateado", ElContenido1, tonoOffsetx); }); } } catch (e) { setState(() { contenidofinal = Text("Error al leer el archivo: $e"); }); }},child: const Text("Seleccionar archivo .txt"),),const SizedBox(height: 20),Expanded(child: SingleChildScrollView(child: Container(padding: const EdgeInsets.all(12),decoration: BoxDecoration(border: Border.all(color: Colors.grey),borderRadius: BorderRadius.circular(8),),child: contenidofinal,),),),],)); }
  
  int OpcionIntercambio_S = 0;

  @override
  Widget build(BuildContext context) {
    Widget Opcion_s3 = OpcionIntercambio_S == 0 ? Opcion_s1 : Opcion_s2;
    return Scaffold(
      appBar: AppBar(title: Text("Formatear de Texto"), backgroundColor: Colors.transparent, automaticallyImplyLeading: false, actions: [
          IconButton(
            icon: Icon(Icons.remove_circle_outline),
             onPressed: () => setState(() { tonoOffsetx--; contenidofinal = formatearConNotas("Texto Formateado", ElContenido1, tonoOffsetx); }),
             tooltip: 'Bajar ½ Tono',
          ),
          IconButton(
            icon: Icon(Icons.add_circle_outline),
              onPressed: () => setState(() { tonoOffsetx++; contenidofinal = formatearConNotas("Texto Formateado", ElContenido1, tonoOffsetx); }),
              tooltip: 'Subir ½ Tono',
          ),],
          
      bottom: PreferredSize(preferredSize: Size.fromHeight(20.0),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Row(
          children: List.generate(OpcionesIntercambio.length, (index_s) => ChoiceChip(shape: BeveledRectangleBorder(
           borderRadius: index_s == 0 ? BorderRadius.only(topLeft: Radius.circular(10.0), bottomLeft: Radius.circular(10.0)) : BorderRadius.only(topRight: Radius.circular(10.0), bottomRight: Radius.circular(10.0))), label: Text(OpcionesIntercambio[index_s]),  selected: OpcionIntercambio_S == index_s, onSelected: (_) { setState(() { OpcionIntercambio_S = index_s; }); },),),),],),),),
      body: Column(
          children: [Opcion_s3],
        ),
      );
    
  }
}

/*
Para arreglar lo de compilación final
¡Ah, ahora lo veo con claridad! 😅

El problema no es tu lógica de conexión ni kIsWeb, sino que sigues importando dart:html directamente:
import 'dart:html' as html;

Cuando Flutter compila para Android/iOS/desktop, el compilador no encuentra esa librería, y por eso te salen todos esos errores de Undefined name 'window' y Invalid depfile.
Cómo arreglarlo usando Opción 1: Import condicional

    Crea un stub para móviles (o cualquier plataforma que no sea web).
    Por ejemplo, crea un archivo html_stub.dart:
// html_stub.dart
class NavigatorStub {
  final bool onLine = true;
}

class WindowStub {
  final NavigatorStub navigator = NavigatorStub();
}

final WindowStub window = WindowStub();

    Modifica tu import de dart:html así:

// main.dart
import 'dart:html' 
    if (dart.library.io) 'html_stub.dart' as html;

    Esto significa:

        En web, usa dart:html real.

        En móviles/desktop, usa el stub que definimos arriba.

    Mantén tu uso de kIsWeb como lo tienes en tus funciones:

Future<bool> hayConexionInternet(String url) async {
  if (kIsWeb) {
    if (!(html.window.navigator.onLine ?? false)) return false;
    try {
      final respuesta = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 3));
      return respuesta.statusCode == 200;
    } catch (_) {
      return false;
    }
  } else {
    final resultado = await Connectivity().checkConnectivity();
    if (resultado == ConnectivityResult.none) return false;

    try {
      final respuesta = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 3));
      return respuesta.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}

✅ Con esto:

    Flutter Web sigue usando html.window.navigator.onLine.

    Flutter Android/iOS no falla, porque el stub simula la propiedad onLine.

    Ya no tendrás errores de compilación ni de Undefined name 'window'.

Si quieres, puedo hacerte una versión lista de tus dos funciones (hayConexionInternet y hayConexionInternet1) ya adaptadas al import condicional, lista para pegar en tu main.dart sin errores.

*/