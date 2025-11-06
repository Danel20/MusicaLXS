import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

class DatosScreen extends StatefulWidget {
  @override
  _DatosScreenState createState() => _DatosScreenState();
}

class _DatosScreenState extends State<DatosScreen> {
  Future<Map<String, dynamic>> cargarDatos() async {
    final rawData = await rootBundle.loadString('himnos.json');
    return json.decode(rawData);
  }

Widget CadaHimnoWidget (String tema, String contenido, List categoria, final String nota){
  //CadaHimnoWidget(super.key, required this.tema, required this.contenido, required this.categoria, required this.nota);
  return Container(padding: EdgeInsets.symmetric(vertical: 10, horizontal:10), decoration: BoxDecoration(border: Border.all()),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(tema), Text(contenido), Row(children:[...categoria.map((a1) => Text(a1+ ' ')),]), Text(nota),
      ])
  );
}

void mostrarVentana(BuildContext context, String tema, String contenido, String autor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Ocupa toda la pantalla
      backgroundColor: Colors.transparent, // Hacemos transparente para personalizar
      builder: (_) => DialogoPantallaCompleta(tema: tema, contenido: contenido, autor: autor),
    );
  }

Widget CadaHimnoWidget1 (String tema, String contenido, String autor){
  //CadaHimnoWidget(super.key, required this.tema, required this.contenido, required this.categoria, required this.nota);
  return ListTile(title: Text(tema), onTap: () => mostrarVentana(context, tema, contenido, autor));
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Datos')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: cargarDatos(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return Center(child: CircularProgressIndicator());

          if (snapshot.hasError)
            return Center(child: Text('Error: ${snapshot.error}'));

          final data = snapshot.data!;
          //final personas = data['Personas'] as List<dynamic>;
          //final lugares = data['Lugares'] as List<dynamic>;
          
          final himnos = data['himnos'] as List<dynamic>;
          

          return ListView(
            padding: EdgeInsets.all(10),
            children: [
              Text("Himnos"),
               //...himnos.map((p) => CadaHimnoWidget(p['tema'], p['contenido'], p['categoria'], p['nota'])),
               ...himnos.map((p) => CadaHimnoWidget1(p['tema'],p['contenido'],p['autor'])),
              
              /*
              Text('Personas'),
              ...personas.map((p) => Text(p['Nombre'])),
              SizedBox(height: 20),
            
              Text('Lugares'),
              ...lugares.map((l) => Text(l['Pais'])),
              */
            ],
          );
        },
      ),
    );
  }
}

class DialogoPantallaCompleta extends StatelessWidget {
  final String tema;
  final String contenido;
  final String autor;

  const DialogoPantallaCompleta({
    required this.tema,
    required this.contenido,
    required this.autor
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height, // Pantalla completa
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface, // Color de fondo
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)), // Redondeo arriba
      ),
      child: Column(
        children: [
          AppBar(
            title: Text(tema, style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
            backgroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: Icon(Icons.close, color: Theme.of(context).colorScheme.onPrimary),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: ListView(children: [
                Text(
                  contenido,
                  style: TextStyle(color: Theme.of(context).colorScheme.scrim, fontSize: 18),
                ),
                SizedBox(height: 20),
                Text(
                  autor,
                  style: TextStyle(color: Theme.of(context).colorScheme.tertiary, fontSize: 12),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}