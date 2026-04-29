import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io' as io show File, Directory, Platform, FileSystemException;

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:collection/collection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';



import 'package:musicalxs/globals/globals.dart';
import 'package:musicalxs/widgets/NeonGlowButton.dart';
import 'package:musicalxs/widgets/TabListas.dart';
import 'package:musicalxs/widgets/PantallaConTabs.dart';
import 'package:musicalxs/widgets/BusquedaHimnos.dart';
import 'package:musicalxs/widgets/ConfiguracionScreen.dart';
import 'package:musicalxs/widgets/FormateadorTextoScreen.dart';

// Este import SOLO se usa en web, por eso el ignore
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
  Color rellenoColor1 = Colors.transparent;

  @override
  void initState() {
    super.initState();
    tam_fuente = widget.tam_fuente;
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [etiquetaColor, ObtenerColoresEtiqueta1Gradiente(etiquetaColor)],begin: Alignment.topLeft,end: Alignment.bottomRight,))),
        title: Row(children: [Icon(Icons.settings_outlined, color: textColor1), SizedBox(width: 10), Text('Configuración', style: TextStyle(color: textColor1, fontWeight: FontWeight.bold))]),
        leading: IconButton(icon: Icon(Icons.arrow_back, color: textColor1),onPressed: () {
          Navigator.pop(context, true); // Ahora devuelve true
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
                    gradient: LinearGradient(colors: etiquetaColor == color ? [color, ObtenerColoresEtiqueta1Gradiente(color)] : [Colors.white, Colors.white], begin: Alignment.topLeft,end: Alignment.bottomRight,),
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: etiquetaColor == color ? textColor1 : color, width: etiquetaColor == color ? 1.0 : 5.0),
                    boxShadow: [
                      BoxShadow(color: color, blurRadius: etiquetaColor == color ? 2 : 0, offset: Offset(0, etiquetaColor == color ? 2 : 0),),
                      BoxShadow(color: color, blurRadius: etiquetaColor == color ? 2 : 0, offset: Offset(0, etiquetaColor == color ? 2 : 0),),
                     ],
                  ),
                  // child: Center(child: Icon(Icons.check, color: textColor1, size: 20,),),
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
                        gradient: LinearGradient(colors: [etiquetaColor, ObtenerColoresEtiqueta1Gradiente(etiquetaColor)],begin: Alignment.topLeft,end: Alignment.bottomRight,),
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
              gradient: LinearGradient(colors: [etiquetaColor, ObtenerColoresEtiqueta1Gradiente(etiquetaColor)],begin: Alignment.topLeft,end: Alignment.bottomRight,),
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
      Row(
        // mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Icon(Icons.info, size: 18, color: Colors.blueGrey),
          SizedBox(width: 6),
          Text(
            "Versión de App: $versionLocal" ?? "Versión de App: No disponible",
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
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) {
              return AlertDialog(
                title: Text("Proceso de actualización"),
                content: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(child: Text("Conectando...")),
                      SizedBox(height: 16),
                      Center(child: CircularProgressIndicator(color: etiquetaColor)),
                    ],
                  ),
                ),
                actions: [],
              );
            },
          );
          
          
          String urlVersion = "https://raw.githubusercontent.com/Danel20/MusicaLXS/main/versionMusicaLXS.json";
          bool conectado = await hayConexionInternet(urlVersion);
          
          if (!conectado) {
            Navigator.pop(context);
            return showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => AlertDialog(
                title: Text("Error"),
                content: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [Text("No hay conexión a Internet. Intenta actualizar más tarde.")],
                  ),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: Text("OK")),
                ],
              ),
            );
          } else {
            String urlVersionNumber = await actualizarVersionDesdeGithubEnMemoria();
            // bool comprobarVersion1 = await actualizarVersionDesdeGithubEnMemoria();
            if (versionLocal == urlVersionNumber) {
              final mensajesHimnos = await actualizarJsonDesdeGithubEnMemoria();
              final mensajesListas = await actualizarListasDesdeGithubEnMemoria();
              
              Navigator.pop(context);
              
              showDialog(
                context: context,
                barrierDismissible: false,
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
              });
              if (state1 != null) {
                  state1.listas = List.from(listasApp);
                  state1.setState((){});
                }
            } else {
              Navigator.pop(context);
              return showDialog(
                context: context,
                barrierDismissible: false,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text("¡Nueva actualización disponible!"),
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Tu aplicación necesita ser actualizada para continuar. La versión actual de la app es diferente de la versión más reciente disponible.",
                          style: TextStyle(color: Colors.red),
                        ),
                        SizedBox(height: 16),
                        Text("Versión actual: $versionLocal"),
                        Text("Versión disponible: $urlVersionNumber"),
                        SizedBox(height: 16),
                        Text(
                          "Por favor, actualiza la aplicación para obtener las últimas mejoras y correcciones.",
                          style: TextStyle(color: Colors.blue),
                        ),
                        SizedBox(height: 16),
                        Text("Puedes descargar la nueva versión en el siguiente enlace:"),
                        TextButton(
                          onPressed: () {
                            // Abre el navegador para la descarga
                            launch('https://github.com/Danel20/MusicaLXS/releases/tag/release');
                          },
                          child: Text(
                            "Descargar actualización",
                            style: TextStyle(color: Colors.blue),
                          ),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text("Cerrar"),
                      ),
                    ],
                  );
                }
              );
            }
          }
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