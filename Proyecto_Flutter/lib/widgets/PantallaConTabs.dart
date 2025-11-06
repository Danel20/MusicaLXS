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

// Este import SOLO se usa en web, por eso el ignore
// ignore: avoid_web_libraries_in_flutter
/*
import 'dart:html' 
    if (dart.library.io) 'html_stub.dart' as html;
*/

class PantallaConTabs extends StatefulWidget {
  final Function(ThemeMode) cambiarTema;
  final Function(Color) cambiarColorEtiqueta;
  
  PantallaConTabs({
    required this.cambiarTema,
    required this.cambiarColorEtiqueta,
  });
  
  @override
  PantallaConTabsState createState() => PantallaConTabsState();
}

class PantallaConTabsState extends State<PantallaConTabs> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<Map<String, dynamic>> adoracion = [];
  final List<Map<String, dynamic>> jubilo = [];
  final List<Map<String, dynamic>> himnario = [];

  List<TemaLista> get listas => listasApp;
  
  set listas(List<TemaLista> nuevaLista) {
  listasApp = nuevaLista; // listasApp es la variable global
  setState(() {});
}
  int listasKey = 0;
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
    Tab(icon: Icon(Icons.search, color: Colors.white), text: 'Buscar'),
    Tab(icon: Icon(Icons.list, color: Colors.white), text: 'Formatear'),
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
    // setState(() => listas = List.from(listasApp));
    setState(() {});
  }

  Future<void> guardarListasEnState() async {
    // listasApp = List.from(listas);
    await storage.guardarListas(listasApp);
    // setState(() => listas = List.from(listasApp));
    setState(() {});
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
              listasApp.add(nuevaLista);
              seleccionados.clear();
              modoSeleccion = false;
              await storage.guardarListas(listasApp);
              await guardarListasEnState();
              // setState(() {});
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
    setState(() {});
  }

  void editarListaModal(int index) {
    final lista = listasApp[index];
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
                icon: Icon(Icons.save, color: etiquetaColor),
                label: Text("Guardar cambios", style: TextStyle(color: etiquetaColor)),
                onPressed: () async {
                  final nuevosTemas = temasController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
                  setState(() => listasApp[index] = TemaLista(temas: nuevosTemas, nota: notaController.text));
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
      child: Icon(Icons.menu, color: etiquetaColor),
      onPressed: () {
        showModalBottomSheet(
          context: context,
          builder: (_) => Container(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton.icon(onPressed: crearLista, icon: Icon(Icons.save, color: etiquetaColor), label: Text("Guardar lista", style: TextStyle(color: etiquetaColor))),
                TextButton.icon(onPressed: desactivarSeleccion, icon: Icon(Icons.cancel, color: etiquetaColor), label: Text("Cancelar selección", style: TextStyle(color: etiquetaColor))),
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
                  await cargarListasEnState();
                  // setState(() => listas = List.from(listasApp));
                  setState(() { listasKey++; });
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
              /*
              _buildListaHimnos(adoracion),
              _buildListaHimnos(jubilo),
              _buildListaHimnos(himnario),
              */
              ConstruirListaHimnos(himnos: adoracion,cambiarTema: widget.cambiarTema,cambiarColorEtiqueta: widget.cambiarColorEtiqueta,cambiarFuente: cambiarFuente,tam_fuente: tam_fuente,),
              ConstruirListaHimnos(himnos: jubilo,cambiarTema: widget.cambiarTema,cambiarColorEtiqueta: widget.cambiarColorEtiqueta,cambiarFuente: cambiarFuente,tam_fuente: tam_fuente,),
              ConstruirListaHimnos(himnos: himnario,cambiarTema: widget.cambiarTema,cambiarColorEtiqueta: widget.cambiarColorEtiqueta,cambiarFuente: cambiarFuente,tam_fuente: tam_fuente,),
              TabListas(
                key: ValueKey(listasKey),
                himnos: himnosApp['himnos'],
                listas: listasApp,
                onEditar: editarListaModal,
                onEliminar: eliminarLista,
                cambiarTema: widget.cambiarTema,
                cambiarColorEtiqueta: widget.cambiarColorEtiqueta,
                cambiarFuente: cambiarFuente,
                tam_fuente: tam_fuente,
              ),
              BusquedaHimnos(
                himnos: himnosApp['himnos'],
                cambiarTema: widget.cambiarTema,
                cambiarColorEtiqueta: widget.cambiarColorEtiqueta,
                cambiarFuente: cambiarFuente,
                tam_fuente: tam_fuente,
              ),
              FormateadorTextoScreen(),
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
  lineasWidgets.add(Text('Círculo de "${notasMusicales1[tonoOffset % 12]}"', style: TextStyle(fontSize: tam_fuente + 3, color: etiquetaColor, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)));
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