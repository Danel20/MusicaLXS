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
import 'package:flutter/rendering.dart';
import 'package:miflutterapp0/globals/globals.dart';
import 'package:miflutterapp0/widgets/NeonGlowButton.dart';
import 'package:miflutterapp0/widgets/TabListas.dart';
import 'package:miflutterapp0/widgets/PantallaConTabs.dart';
import 'package:miflutterapp0/widgets/BusquedaHimnos.dart';
import 'package:miflutterapp0/widgets/ConfiguracionScreen.dart';
import 'package:miflutterapp0/widgets/FormateadorTextoScreen.dart';
import 'package:miflutterapp0/widgets/ConstruirListaHimnos.dart';
import 'package:universal_html/html.dart' as html;
import 'package:image/image.dart' as img0;
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
      themeMode1 = isDark ? ThemeMode.dark : ThemeMode.light;
      etiquetaColor = coloresEtiqueta1[colorIndex];
      textColor1 = colorIndex % 2 == 1 ? Colors.white : Colors.black;
    });
  }
  
  Future<void> cambiarTema(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tema_oscuro', mode == ThemeMode.dark);
    setState(() => themeMode1 = mode);
  }
  
  Future<void> cambiarColorEtiqueta(Color color) async {
    final prefs = await SharedPreferences.getInstance();
    final index = coloresEtiqueta1.indexOf(color);
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
      themeMode: themeMode1,
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
  late List<Color> coloresEtiqueta1;
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
    
    return Container(
      height: size.height,
      width: size.width,
      padding: EdgeInsets.all(30),
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/yoututosjeffewr325342.png'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(Colors.black45, BlendMode.darken),
        ),
      ),
      child: Center(child: Flex(
        // ESTO ES SI USARA COLUMN: mainAxisSize: MainAxisSize.min,
        direction: Axis.vertical,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
        Flexible(child: Image.asset("assets/icon/MusicaLXS_Negativo.png", fit: BoxFit.contain)),
        //width: 150, height:150,
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
          SlideInLeft(
            duration: Duration(milliseconds: 1000),
            delay: Duration(milliseconds: 1500),
            child: Text(
              'Donde lo musical es para tod@s, lo musical es para tí',
              style: TextStyle(
                fontSize: 20,
                color: Colors.white70,
              ), textAlign: TextAlign.center,
            ),
          ),
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
        ]))
    );
    
    
    
    /*
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
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image(image: AssetImage("assets/icon/MusicaLXS_Negativo.png"), width: 150, height:150,),
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
                  SizedBox(height: 20),
                  SlideInLeft(
                    duration: Duration(milliseconds: 1000),
                    delay: Duration(milliseconds: 1500),
                    child: Text(
                      'Donde lo musical es para tod@s, lo musical es para tí',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white70,
                      ), textAlign: TextAlign.center,
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
    */
  }
}

//ESTO FUNCIONA pero... Hay que cambiar lugar donde se guardan las imagenes
/*
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:convert' show base64Encode;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/rendering.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:universal_html/html.dart' as html;
import 'package:screenshot/screenshot.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final ScreenshotController screenshotController = ScreenshotController();
  Uint8List? _imageFile;

  var myLongWidget = Builder(builder: (context) {
    return Container(
      padding: const EdgeInsets.all(30.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blueAccent, width: 5.0),
        color: Colors.redAccent,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < 150; i++) Text("Tile Index $i"),
        ],
      ),
    );
  });

  Future<void> _requestPermissions() async {
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      await Permission.storage.request();
    }
  }

  Future<void> _captureLongWidget() async {
    await _requestPermissions();
    final capturedImage = await screenshotController.captureFromLongWidget(
      myLongWidget,
      delay: Duration(milliseconds: 1000),
      context: context,
    );

    if (capturedImage != null) {
      if (kIsWeb) {
        final base64Image = base64Encode(capturedImage);
        final anchor = html.AnchorElement(href: 'data:image/png;base64,$base64Image')
          ..download = 'captura${DateTime.now().year}${DateTime.now().month}${DateTime.now().day}_${DateTime.now().hour}${DateTime.now().minute}${DateTime.now().second}.png'
          ..click();
      } else {
        final result = await ImageGallerySaver.saveImage(capturedImage);
        if (result['isSuccess']) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Imagen guardada en la galería')));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al guardar la imagen')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Captura de Lista Grande')),
      body: Screenshot(
        controller: screenshotController,
        child: myLongWidget,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await _captureLongWidget();
        },
        child: Icon(Icons.camera, color: Colors.deepPurple),
      ),
    );
  }
}
*/