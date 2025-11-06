/*
Manual básico: Elementos visuales en Flutter
*/

import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Manual Flutter UI',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: Scaffold(
        appBar: AppBar(title: Text('Ejemplo de Elementos Visuales')),
        body: ElementosVisuales(),
      ),
    );
  }
}

class ElementosVisuales extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Texto
          Text('Texto simple',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 10),

          // Botón
          ElevatedButton(
            onPressed: () => print('Botón presionado'),
            child: Text('Presióname'),
          ),
          SizedBox(height: 10),

          // Imagen desde red
          Image.network(
              'https://flutter.dev/images/flutter-logo-sharing.png',
              height: 100),
          SizedBox(height: 10),

          // Icono
          Icon(Icons.favorite, color: Colors.red, size: 40),
          SizedBox(height: 10),

          // Campo de texto
          TextField(
            decoration: InputDecoration(
              labelText: 'Escribe algo',
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 10),

          // Switch
          Row(
            children: [
              Text('Activar opción'),
              Switch(value: true, onChanged: (val) {}),
            ],
          ),
          SizedBox(height: 10),

          // Slider
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Deslizador'),
              Slider(
                value: 50,
                min: 0,
                max: 100,
                divisions: 10,
                label: '50',
                onChanged: (value) {},
              ),
            ],
          ),
          SizedBox(height: 10),

          // Contenedor con estilo
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('Caja decorada'),
          ),
        ],
      ),
    );
  }
}

/*
Resumen de elementos usados:
- Text: muestra texto
- ElevatedButton: botón con acción
- Image.network: imagen desde internet
- Icon: íconos visuales
- TextField: campo de entrada de texto
- Switch: interruptor on/off
- Slider: deslizador de valores
- Container: caja para agrupar/estilizar

Para dar estilo se usa TextStyle, BoxDecoration, padding, margin, etc.
Para funcionalidad se usan propiedades como onPressed, onChanged, etc.
*/

Padding(
        padding: EdgeInsets.only(bottom: 4), // espacio entre líneas
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.end,
          spacing: 2,
          runSpacing: 0,
          children: [
          Text("Este"),
          
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
              C,
              style: TextStyle(
                fontSize: tam_fuente,
                color: textColor1,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Text("es",style: TextStyle(
                  fontSize: tam_fuente,
                  color: etiquetaColor,
                ),
              ),],),
              
          Text("un ejemplo del"),
          
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
              Am7,
              style: TextStyle(
                fontSize: tam_fuente,
                color: textColor1,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Text("cont",style: TextStyle(
                  fontSize: tam_fuente,
                  color: etiquetaColor,
                ),
              ),],),
          
          Text("tenido."),
          ],
        ),
      ),
