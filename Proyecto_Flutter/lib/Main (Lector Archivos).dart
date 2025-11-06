import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lector de Archivos',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _fileContent = "Aquí se mostrará el contenido del archivo";
  String _fileName = "Ningún archivo seleccionado";
  TextEditingController _inputController = TextEditingController();
  String _textOutput = "";

  Future<void> _pickAndReadFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final content = await file.readAsString();
        setState(() {
          _fileContent = content;
          _fileName = result.files.single.name;
        });
      } else {
        setState(() {
          _fileContent = "No se seleccionó ningún archivo.";
          _fileName = "Ningún archivo seleccionado";
        });
      }
    } catch (e) {
      setState(() {
        _fileContent = "Error al leer el archivo: $e";
        _fileName = "Error";
      });
    }
  }

  void _mostrarTextoEscrito() {
    setState(() {
      _textOutput = _inputController.text;
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Lector de Archivos"),
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              child: Text("Menú de Navegación"),
              decoration: BoxDecoration(color: Colors.blue),
            ),
            ListTile(
              title: Text("Opción 1"),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              title: Text("Opción 2"),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _pickAndReadFile,
              child: Text("Seleccionar archivo .txt"),
            ),
            SizedBox(height: 10),
            Text(
              "Archivo seleccionado: $_fileName",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    border: Border.all(),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _fileContent,
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ),
            Divider(),
            TextField(
              controller: _inputController,
              decoration: InputDecoration(
                labelText: "Escribe algo",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _mostrarTextoEscrito,
              child: Text("Mostrar texto escrito"),
            ),
            SizedBox(height: 10),
            Text(
              _textOutput,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

/*
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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(
            title: Text('Mi Flutter App 0',
                style: TextStyle(
                    fontSize: 20,
                    color: Colors.deepPurple,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2)),
            backgroundColor: Theme.of(context).colorScheme.inversePrimary),
        body: PaginaPrincipal(),
      ),
    );
  }
}

class MiElemento0 extends StatelessWidget {
	MiElemento0({super.key, required this.nombre, required this.descripcion, required this.precio, required this.imagen});
	String nombre;
	String descripcion;
	int precio;
	String imagen;

	Widget build(BuildContext context) {
		return Container(padding:EdgeInsets.all(2), height:120, child: Card(
			child: Row(
				mainAxisAlignment: MainAxisAlignment.spaceEvenly,
				children: <Widget>[
					Image.asset(this.imagen),
					Expanded(child: Container(
						padding: EdgeInsets.all(5),
						child: Column(
							mainAxisAlignment: MainAxisAlignment.spaceEvenly,
							children: <Widget>[
								Text(this.nombre, style: TextStyle(fontWeight: FontWeight.bold)),
								Text(this.descripcion),
								Text("Precio: "+this.precio.toString()),
								],
							)
						))
					]
				)));
	}
}

class PaginaPrincipal extends StatelessWidget {

	@override
	Widget build(BuildContext context) {
		return ListView(
			shrinkWrap: true,
			padding: EdgeInsets.fromLTRB(2.0, 10.0, 2.0, 10.0),
			children: <Widget>[
//for(var a=1;a<=5;a++){MiElemento0(nombre:"Test "+a,descripcion:"Esta es la descripción de mi elemento "+a, precio:40*a, imagen:"yoututosjeffewr325342.png");}
				MiElemento0(nombre:"Test1", descripcion:"Esta es la descripción de mi Test1", precio:300, imagen:"yoututosjeffewr325342.png"),
				MiElemento0(nombre:"Test2", descripcion:"Esta es la descripción de mi Test2", precio:100, imagen:"yoututosjeffewr325342.png"),
				MiElemento0(nombre:"Test3", descripcion:"Esta es la descripción de mi Test3", precio:600, imagen:"yoututosjeffewr325342.png"),
				MiElemento0(nombre:"Test4", descripcion:"Esta es la descripción de mi Test4", precio:700, imagen:"yoututosjeffewr325342.png"),
				MiElemento0(nombre:"Test5", descripcion:"Esta es la descripción de mi Test5", precio:4200, imagen:"yoututosjeffewr325342.png"),
			],
		);
	}
}
*/
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
