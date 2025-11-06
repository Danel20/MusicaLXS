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
import 'package:universal_html/html.dart' as html;
import 'package:image/image.dart' as img0;

// 👇 Este import SOLO se usa en web, por eso el ignore
// ignore: avoid_web_libraries_in_flutter
/*
import 'dart:html' 
    if (dart.library.io) 'html_stub.dart' as html;
*/

class ConstruirListaHimnos extends StatefulWidget {
  final Function(ThemeMode) cambiarTema;
  final Function(Color) cambiarColorEtiqueta;
  final himnos;
  final Function(double) cambiarFuente;
  final double tam_fuente;
  
  ConstruirListaHimnos({
    super.key,
    required this.himnos,
    required this.cambiarColorEtiqueta,
    required this.cambiarTema,
    required this.cambiarFuente,
    required this.tam_fuente,
  });
  
  @override
  State<ConstruirListaHimnos> createState() => _ConstruirListaHimnosState();
}

class _ConstruirListaHimnosState extends State<ConstruirListaHimnos> {
  late List<Map<String, dynamic>> himnos;
  late double tam_fuente;
  
  @override
  void initState() {
    super.initState();
    himnos = widget.himnos;
    tam_fuente = widget.tam_fuente;
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


  // Gestión de listas
  Set<String> seleccionados = {};
  String nota = "C";
  bool modoSeleccion = false;

  final storage = ListaStorage();
  
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
              setState(() {});
              Navigator.pop(context);
            },
            child: Text("Guardar"),
          ),
        ],
      ),
    );
  }

  void eliminarLista(int index) async {
    listasApp.removeAt(index);
    await storage.guardarListas(listasApp);
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
				  listasApp[index] = TemaLista(temas: nuevosTemas, nota: notaController.text);
				  await guardarListasEnState();
                  setState(() {});
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
  
  Widget buildResultado(h) {
    String fragmento = '';
    /*
    if (modo == ModoBusqueda.todo && textoBusqueda.isNotEmpty) {
      final index = normalizar(h.contenido).indexOf(normalizar(textoBusqueda));
      if (index != -1) {
        final inicio = index - 50 >= 0 ? index - 50 : 0;
        final fin = (index + 50 < h.contenido.length) ? index + 50 : h.contenido.length;
        final originalFragmento = h.contenido.substring(inicio, fin);
        fragmento = limpiarTexto(originalFragmento);
      }
    }
    */
    
	/*
    return Card(
      child: ListTile(
        title: Text(h.tema),
        subtitle: fragmento.isNotEmpty ? Text('...$fragmento...') : null,
        onTap: () => mostrarVentana(context, h.tema, h.contenido, h.autor, tonoOffset: notasMusicales1.indexOf(h.nota)),
      ),
    );
	*/
	
	return TemaItemCard(
	  key: Key(h.tema),
	  tema: h.tema,
	  fragmento: fragmento.isNotEmpty ? "...${fragmento}..." : null,
	  seleccionado: seleccionados.contains(h.tema),
	  onLongPress: () {
		setState(() {
		  modoSeleccion = true;
		  seleccionados.add(h.tema);
		});
	  },
	  onTap: () {
		if (modoSeleccion) {
		  setState(() {
			if (seleccionados.contains(h.tema)) {
			  seleccionados.remove(h.tema);
			} else {
			  seleccionados.add(h.tema);
			}
		  });
		} else {
		  mostrarVentana(
			context,
			h.tema,
			h.contenido,
			h.autor,
			tonoOffset: notasMusicales1.indexOf(h.nota),
		  );
		}
	  },
	);

  }
  
  
  
  @override
  Widget build(BuildContext context) {
    final notas = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];

  return Scaffold(
    body: Padding(
      padding:  EdgeInsets.all(12),
      child: ListView.builder(
        itemCount: himnos.length,
        itemBuilder: (context, index) {
          final himno = himnos[index];
          final seleccionado = seleccionados.contains(himno['tema']);
          
          /*
          return TemaItemCard(
            key: Key(h['tema']),
            tema: h['tema'],
            fragmento: null,
            seleccionado: seleccionados.contains(h['tema']),
            onLongPress: () {
              setState(() {
                modoSeleccion = true;
                seleccionados.add(h['tema']);
              });
            },
            onTap: () {
              if (modoSeleccion) {
                setState(() {
                  if (seleccionados.contains(h['tema'])) {
                    seleccionados.remove(h['tema']);
                  } else {
                    seleccionados.add(h['tema']);
                  }
                });
              } else {
                mostrarVentana(
                  context,
                  h['tema'],
                  h['contenido'],
                  h['autor'],
                  tonoOffset: notasMusicales1.indexOf(h['nota']),
                );
              }
            },
          );
          */
          
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
          
        }
      ),
    ),
	floatingActionButton: modoSeleccion ? buildFabMenu() : null,
  );

  }
}