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
import 'package:flutter/services.dart' show rootBundle, HapticFeedback, PlatformException;


import 'package:miflutterapp0/globals/globals.dart';
import 'package:miflutterapp0/widgets/NeonGlowButton.dart';
import 'package:miflutterapp0/widgets/TabListas.dart';
import 'package:miflutterapp0/widgets/PantallaConTabs.dart';
import 'package:miflutterapp0/widgets/BusquedaHimnos.dart';
import 'package:miflutterapp0/widgets/ConfiguracionScreen.dart';
import 'package:miflutterapp0/widgets/FormateadorTextoScreen.dart';

// 👇 Este import SOLO se usa en web, por eso el ignore
// ignore: avoid_web_libraries_in_flutter
/*
import 'dart:html' 
    if (dart.library.io) 'html_stub.dart' as html;
*/

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
        title: Row(children: [Icon(Icons.settings_outlined), SizedBox(width: 10), Text('Configuración', style: TextStyle(fontWeight: FontWeight.bold))]),
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
          final state1 = context.findAncestorStateOfType<PantallaConTabsState>();
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