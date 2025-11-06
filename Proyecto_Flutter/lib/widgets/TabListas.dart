import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:io' as io show File, Directory, Platform;
import 'package:flutter/rendering.dart';
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
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:screenshot/screenshot.dart';
import 'package:widgets_to_image/widgets_to_image.dart';
import 'package:miflutterapp0/globals/globals.dart';
import 'package:miflutterapp0/widgets/NeonGlowButton.dart';
import 'package:miflutterapp0/widgets/TabListas.dart';
import 'package:miflutterapp0/widgets/PantallaConTabs.dart';
import 'package:miflutterapp0/widgets/BusquedaHimnos.dart';
import 'package:miflutterapp0/widgets/ConfiguracionScreen.dart';
import 'package:miflutterapp0/widgets/FormateadorTextoScreen.dart';
import 'package:universal_html/html.dart' as html;
import 'package:image/image.dart' as img0;

// 👇 Este import SOLO se usa en web, por eso el ignore
// ignore: avoid_web_libraries_in_flutter
/*
import 'dart:html' 
    if (dart.library.io) 'html_stub.dart' as html;
*/

// ESTA ES PARA LA SECCIÓN DE LISTAS
class TabListas extends StatefulWidget {
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
  TabListasState createState() => TabListasState();
}

class TabListasState extends State<TabListas>{
  late List<dynamic> listas;
  late void Function(int) onEliminar;
  late void Function(int) onEditar;
  late Function(ThemeMode) cambiarTema;
  late Function(Color) cambiarColorEtiqueta;
  late List<dynamic> himnos;
  late Function(double) cambiarFuente;
  late double tam_fuente;
  
  void initState() {
	super.initState();
	listas = widget.listas;
	onEliminar = widget.onEliminar;
	onEditar = widget.onEditar;
	cambiarTema = widget.cambiarTema;
	cambiarColorEtiqueta = widget. cambiarColorEtiqueta;
	himnos = widget.himnos;
	cambiarFuente = widget.cambiarFuente;
	tam_fuente = widget.tam_fuente;
  }
  
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
                backgroundColor: Colors.white, // Hacemos transparente para personalizar
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (_) => DialogoPantallaCompleta_Listados(titulo: lista.nota, temas: lista.temas, himnos: himnosApp['himnos'], cambiarTema: cambiarTema, cambiarColorEtiqueta: cambiarColorEtiqueta, cambiarFuente: cambiarFuente, tam_fuente: tam_fuente),
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
  final GlobalKey _globalKey = GlobalKey();
  String contenido = '';
  late String titulo = widget.titulo;
  // late int tonoOffset;
  late double tam_fuente;
  late List<String> temas = widget.temas;
  late List<dynamic> himnos = widget.himnos;
  Map<int, int> tonoOffsetsPorSeccion = {};
  
  // ESTO ES PARA CAPTURA WIDGETS A IMAGEN
  final ScreenshotController screenshotController = ScreenshotController();
  Uint8List? _imageFile;
  
  Future<void> _requestPermissions0() async {
    var status0 = await Permission.storage.status;
    if (!status0.isGranted) {
      await Permission.storage.request();
    }
  }
  
  Future<void> _captureLongWidget0(myLongWidget) async {
    await _requestPermissions0();
    final capturedImage = await screenshotController.captureFromLongWidget(
      myLongWidget,
      pixelRatio: 1.0,
      delay: Duration(milliseconds: 1000),
      context: context,
    );
    if (capturedImage != null) {
      var fechahoy = DateTime.now();
      String fileName0 = 'Listado_${fechahoy.year}${fechahoy.month}${fechahoy.day}_${fechahoy.hour}${fechahoy.minute}${fechahoy.second}';
      if (kIsWeb) {
        final base64Image = base64Encode(capturedImage);
        final anchor = html.AnchorElement(href: 'data:image/png;base64,$base64Image')
          ..download = fileName0
          ..click();
      } else {
        final result = await ImageGallerySaver.saveImage(capturedImage, quality: 100, name: fileName0);
        if (result['isSuccess']) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Imagen guardada en la galería con nombre: $fileName0')));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al guardar la imagen')));
        }
      }
    }
  }
  // TERMINA LO DE CAPTURAR WIDGET A IMAGEN
  @override
  void initState() {
    super.initState();
    // tonoOffset = 0;
    tam_fuente = widget.tam_fuente;
  }
  
  final List<String> notasIngles = [
    'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'
  ];
  
  String notaConTono(int numero, int tonoOffset) {
    final indexOriginal = (numero - 1) % 12;
    final indexConOffset = (indexOriginal + tonoOffset) % 12;
    return notasIngles[(indexConOffset + 12) % 12];
  }


Widget formatearConNotas(String tema1, String texto, int tonoOffsetBase, int index1) {
  int tonoOffset = tonoOffsetsPorSeccion[index1] ?? tonoOffsetBase;
  final List<String> PalabrasParaBoldear = ["Tema", "TEMA", "CORO", "ESTROFA", "INTRO", "ESTRIBILLO", "PUENTE", "PRE-CORO", "(", "FINAL"];
  final lineas = texto.split('\n');
  final lineasWidgets = <Widget>[];
  lineasWidgets.add(Container(child: Text("${index1 + 1} ■ █ ${tema1} █ ■", style: TextStyle(fontSize: tam_fuente + 5, color: etiquetaColor, fontWeight: FontWeight.bold))));
  lineasWidgets.add(Container(padding: EdgeInsets.only(left:10), decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(50),), child: Row(children: [Text('Círculo de "${notasMusicales1[tonoOffset % 12]}"', style: TextStyle(fontSize: tam_fuente + 3, color: etiquetaColor, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)), SizedBox(width: 20.0),
  IconButton(icon: Icon(Icons.remove), color: etiquetaColor, onPressed: () => setState(() { tonoOffsetsPorSeccion[index1] = tonoOffset - 1;}) , tooltip: 'Bajar ½ Tono'),
  IconButton(icon: Icon(Icons.add), color: etiquetaColor, onPressed: () => setState(() { tonoOffsetsPorSeccion[index1] = tonoOffset + 1;}), tooltip: 'Subir ½ Tono'),
  ])));
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

      final nota = numero != null ? notaConTono(numero, tonoOffset) : '';
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
  return Container(padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2), child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: lineasWidgets,
  ));
}

  Future<void> captureAndSaveGlobalKeyWidget(BuildContext context) async {
    bool permisogarantizado1 = await requestStoragePermission();
    if (!permisogarantizado1) {
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Permiso denegado para guardar imágenes")),
      );
      return;
    }
    try {
      RenderRepaintBoundary boundary = _globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

      // Asegura renderizado completo
      await Future.delayed(Duration(milliseconds: 100));

      final image = await boundary.toImage(pixelRatio: 3.0); // Alta resolución
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final result = await ImageGallerySaver.saveImage(
        pngBytes,
        quality: 100,
        name: "captura_${DateTime.now().millisecondsSinceEpoch}",
      );

      final isSuccess = result['isSuccess'] ?? false;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isSuccess ? "Imagen guardada" : "Error al guardar imagen")),
      );
    } catch (e) {
      debugPrint("Error al capturar imagen: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al guardar la imagen.")),
      );
    }
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
                icon: Icon(Icons.camera_alt, color: textColor1),
                onPressed: () async {
                var misHimnos1 = List.generate(temas.length, (index1) {
                        try {
                          var TextoComprobado = himnos.firstWhere((item1) => item1['tema'] == temas[index1]);
                          int NotaTextoComprobado = notasMusicales1.indexOf(TextoComprobado['nota']);
                          tonoOffsetsPorSeccion.putIfAbsent(index1, () => NotaTextoComprobado);
                          return Row(mainAxisSize: MainAxisSize.min,children: [formatearConNotas(TextoComprobado['tema'], TextoComprobado['contenido'], NotaTextoComprobado, index1)]);
                        } catch (e) {
                          return Row(mainAxisSize: MainAxisSize.min,children: [Text("Tema ${temas[index1]} no encontrado")]);
                        }
                      });
                
                var misHimnos2 = Container(decoration: BoxDecoration(color: Colors.white), child: Column(mainAxisSize: MainAxisSize.max, children: misHimnos1));
                  
                  _captureLongWidget0(misHimnos2);
                    // await captureAndSaveGlobalKeyWidget(context);
                    /*
                    final controller = WidgetsToImageController();
                    final widgetToCapture = WidgetsToImage(
                      controller: controller,
                      child: Material(child: SingleChildScrollView(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: List.generate(temas.length, (index1) {
                          var TextoComprobado = himnos.firstWhere((item1) => item1['tema'] == temas[index1]);
                          int NotaTextoComprobado = tonoOffsetsPorSeccion[index1] ?? notasMusicales1.indexOf(TextoComprobado['nota']);
                          tonoOffsetsPorSeccion.putIfAbsent(index1, () => NotaTextoComprobado);
                          return formatearConNotas(TextoComprobado['tema'], TextoComprobado['contenido'], NotaTextoComprobado, index1);
                          })))));
                  

                  await captureAndSaveWidgetToGallery(
                    controller: controller,
                    widget: widgetToCapture,
                    context: context,
                  );
                  */
                },
              ),
            
              IconButton(
            icon: Icon(Icons.remove_circle_outline, color: textColor1),
             onPressed: () => setState(() {
        tonoOffsetsPorSeccion.updateAll((key, value) => value - 1);
      }), tooltip: 'Bajar ½ Tono',
          ),
          IconButton(
            icon: Icon(Icons.add_circle_outline, color: textColor1),
              onPressed: () => setState(() {
        tonoOffsetsPorSeccion.updateAll((key, value) => value + 1);
      }), tooltip: 'Subir ½ Tono',
          ),
              
              IconButton(
              icon: Icon(Icons.settings_outlined, color: textColor1),
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
                          etiquetaColor = coloresEtiqueta1[index];
                          textColor1 = index % 2 == 1 ? Colors.white : Colors.black;
                        });
                        etiquetaColor = coloresEtiqueta1[index];
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
                          int NotaTextoComprobado = notasMusicales1.indexOf(TextoComprobado['nota']);
                          tonoOffsetsPorSeccion.putIfAbsent(index1, () => NotaTextoComprobado);
                          return formatearConNotas(TextoComprobado['tema'], TextoComprobado['contenido'], NotaTextoComprobado, index1);
                        } catch (e) {
                          return Text("Tema ${temas[index1]} no encontrado");
                        }
                      }
                    ),
          ),
          /*
          Offstage(
            offstage: true, // Oculto en pantalla
            child: RepaintBoundary(
              key: _globalKey,
              child: Container(
                width: 1080, // ajusta al tamaño deseado
                padding: EdgeInsets.all(16),
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(temas.length, (index1) {
                          var TextoComprobado = himnos.firstWhere((item1) => item1['tema'] == temas[index1]);
                          int NotaTextoComprobado = tonoOffsetsPorSeccion[index1] ?? notasMusicales1.indexOf(TextoComprobado['nota']);
                          tonoOffsetsPorSeccion.putIfAbsent(index1, () => NotaTextoComprobado);
                          return formatearConNotas(TextoComprobado['tema'], TextoComprobado['contenido'], NotaTextoComprobado, index1);
                          }),
                ),
              ),
            ),
          ),
          */
        ],
      ),
    );
  }
}