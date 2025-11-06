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


/* ESTO ES PARA SUBIR EL ARCHIVO */
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
