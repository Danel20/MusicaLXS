import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() => runApp(MyApp());

/// MODELO DE LISTA
class TemaLista {
  List<String> temas;
  String nota;

  TemaLista({required this.temas, required this.nota});

  Map<String, dynamic> toJson() => {
        'temas': temas,
        'nota': nota,
      };

  factory TemaLista.fromJson(Map<String, dynamic> json) => TemaLista(
        temas: List<String>.from(json['temas']),
        nota: json['nota'],
      );
}

/// CONTROLADOR DE ARCHIVO JSON
class ListaStorage {
  Future<String> get _filePath async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/listas.json';
  }

  Future<List<TemaLista>> leerListas() async {
    final path = await _filePath;
    final file = File(path);
    if (!await file.exists()) return [];
    final data = json.decode(await file.readAsString());
    return (data['listas'] as List).map((e) => TemaLista.fromJson(e)).toList();
  }

  Future<void> guardarListas(List<TemaLista> listas) async {
    final path = await _filePath;
    final file = File(path);
    final data = {'listas': listas.map((e) => e.toJson()).toList()};
    await file.writeAsString(json.encode(data));
  }
}

/// APP PRINCIPAL
class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int selectedIndex = 0;

  final pages = [CrearListaPage(), VerListasPage()];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestor de Listas',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: Scaffold(
        body: pages[selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: selectedIndex,
          onTap: (index) => setState(() => selectedIndex = index),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.add_box), label: "Crear Lista"),
            BottomNavigationBarItem(icon: Icon(Icons.list), label: "Ver Listas"),
          ],
        ),
      ),
    );
  }
}

/// PANTALLA PARA CREAR LISTAS
class CrearListaPage extends StatefulWidget {
  @override
  _CrearListaPageState createState() => _CrearListaPageState();
}

class _CrearListaPageState extends State<CrearListaPage> {
  final temasDisponibles = ['Tema A', 'Tema B', 'Tema C', 'Tema D', 'Tema E'];

  bool modoSeleccion = false;
  Set<String> seleccionados = {};
  String nota = "C";

  void activarSeleccion(String tema) {
    setState(() {
      modoSeleccion = true;
      seleccionados.add(tema);
    });
  }

  void desactivarSeleccion() {
    setState(() {
      modoSeleccion = false;
      seleccionados.clear();
    });
  }

  void toggleSeleccion(String tema) {
    setState(() {
      if (seleccionados.contains(tema)) {
        seleccionados.remove(tema);
      } else {
        seleccionados.add(tema);
      }
    });
  }

  void crearLista() async {
    if (seleccionados.isEmpty) return;

    final nuevaLista = TemaLista(temas: seleccionados.toList(), nota: nota);
    final storage = ListaStorage();
    final actuales = await storage.leerListas();
    actuales.add(nuevaLista);
    await storage.guardarListas(actuales);

    desactivarSeleccion();
  }

  void mostrarDetalleTema(String tema) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Container(
        padding: EdgeInsets.all(16),
        height: 200,
        child: Center(
          child: Text("Detalles de $tema", style: TextStyle(fontSize: 18)),
        ),
      ),
    );
  }

  Widget buildTemaItem(String tema) {
    bool seleccionado = seleccionados.contains(tema);

    return GestureDetector(
      onLongPress: () => activarSeleccion(tema),
      child: InkWell(
        onTap: () {
          if (modoSeleccion) {
            toggleSeleccion(tema);
          } else {
            mostrarDetalleTema(tema);
          }
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(
              color: seleccionado ? Colors.blue : Colors.grey.shade300,
              width: seleccionado ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(10),
            color: seleccionado ? Colors.blue.shade50 : Colors.white,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(tema, style: TextStyle(fontSize: 16)),
              if (modoSeleccion)
                Icon(
                  seleccionado ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: seleccionado ? Colors.blue : Colors.grey,
                )
            ],
          ),
        ),
      ),
    );
  }

  Widget buildFabMenu() {
    return FloatingActionButton(
      child: Icon(Icons.menu),
      onPressed: () {
        showModalBottomSheet(
          context: context,
          builder: (_) => Container(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton.icon(
                  onPressed: crearLista,
                  icon: Icon(Icons.save),
                  label: Text("Crear lista con seleccionados"),
                ),
                TextButton.icon(
                  onPressed: desactivarSeleccion,
                  icon: Icon(Icons.cancel),
                  label: Text("Cancelar selección"),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Seleccionar Temas"),
        actions: [
          if (modoSeleccion)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(child: Text("${seleccionados.length} seleccionados")),
            ),
        ],
      ),
      body: ListView.builder(
        itemCount: temasDisponibles.length,
        itemBuilder: (_, i) => buildTemaItem(temasDisponibles[i]),
      ),
      floatingActionButton: modoSeleccion ? buildFabMenu() : null,
    );
  }
}

/// PANTALLA PARA VER Y GESTIONAR LISTAS
class VerListasPage extends StatefulWidget {
  @override
  _VerListasPageState createState() => _VerListasPageState();
}

class _VerListasPageState extends State<VerListasPage> {
  final storage = ListaStorage();
  List<TemaLista> listas = [];

  @override
  void initState() {
    super.initState();
    cargarListas();
  }

  Future<void> cargarListas() async {
    final data = await storage.leerListas();
    setState(() {
      listas = data;
    });
  }

  Future<void> guardarCambios() async {
    await storage.guardarListas(listas);
    setState(() {});
  }

  void eliminarLista(int index) async {
    listas.removeAt(index);
    await guardarCambios();
  }

  void editarListaModal(int index) {
    final lista = listas[index];
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
              TextField(
                controller: notaController,
                decoration: InputDecoration(labelText: "Nota (ej: A, B, C...)"),
              ),
              SizedBox(height: 12),
              TextField(
                controller: temasController,
                decoration: InputDecoration(labelText: "Temas (separados por coma)"),
              ),
              SizedBox(height: 16),
              ElevatedButton.icon(
                icon: Icon(Icons.save),
                label: Text("Guardar cambios"),
                onPressed: () {
                  final nuevosTemas = temasController.text
                      .split(',')
                      .map((e) => e.trim())
                      .where((e) => e.isNotEmpty)
                      .toList();
                  final nuevaNota = notaController.text.trim();

                  setState(() {
                    listas[index] = TemaLista(temas: nuevosTemas, nota: nuevaNota);
                  });
                  guardarCambios();
                  Navigator.pop(context);
                },
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget buildListaItem(int index) {
    final lista = listas[index];

    return Dismissible(
      key: Key('lista_$index'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => eliminarLista(index),
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.symmetric(horizontal: 20),
        color: Colors.red,
        child: Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
        margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        elevation: 3,
        child: ExpansionTile(
          title: Text("Nota: ${lista.nota}"),
          subtitle: Text("${lista.temas.length} temas"),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: lista.temas.map((tema) => Text("- $tema")).toList(),
              ),
            ),
            ButtonBar(
              children: [
                TextButton.icon(
                  onPressed: () => editarListaModal(index),
                  icon: Icon(Icons.edit),
                  label: Text("Editar"),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Listas Guardadas")),
      body: listas.isEmpty
          ? Center(child: Text("No hay listas guardadas aún"))
          : ListView.builder(
              itemCount: listas.length,
              itemBuilder: (_, index) => buildListaItem(index),
            ),
    );
  }
}


/*
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class ListaStorage {
  Future<String> get _filePath async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/listas.json';
  }

  Future<List<TemaLista>> leerListas() async {
    final path = await _filePath;
    final file = File(path);

    if (!await file.exists()) return [];

    final content = await file.readAsString();
    final data = json.decode(content);
    return (data['listas'] as List)
        .map((item) => TemaLista.fromJson(item))
        .toList();
  }

  Future<void> guardarListas(List<TemaLista> listas) async {
    final path = await _filePath;
    final file = File(path);
    final data = {'listas': listas.map((e) => e.toJson()).toList()};
    await file.writeAsString(json.encode(data));
  }
}

class TemaLista {
  List<String> temas;
  String nota;

  TemaLista({required this.temas, required this.nota});

  Map<String, dynamic> toJson() => {
        'temas': temas,
        'nota': nota,
      };

  factory TemaLista.fromJson(Map<String, dynamic> json) => TemaLista(
        temas: List<String>.from(json['temas']),
        nota: json['nota'],
      );
}

class CrearListaPage extends StatefulWidget {
  @override
  _CrearListaPageState createState() => _CrearListaPageState();
}

class _CrearListaPageState extends State<CrearListaPage> {
  final temasDisponibles = ['Tema A', 'Tema B', 'Tema C', 'Tema D', 'Tema E'];

  bool modoSeleccion = false;
  Set<String> seleccionados = {};
  String nota = "C";

  void activarSeleccion(String tema) {
    setState(() {
      modoSeleccion = true;
      seleccionados.add(tema);
    });
  }

  void desactivarSeleccion() {
    setState(() {
      modoSeleccion = false;
      seleccionados.clear();
    });
  }

  void toggleSeleccion(String tema) {
    setState(() {
      if (seleccionados.contains(tema)) {
        seleccionados.remove(tema);
      } else {
        seleccionados.add(tema);
      }
    });
  }

  void crearLista() async {
    if (seleccionados.isEmpty) return;

    final nuevaLista = TemaLista(temas: seleccionados.toList(), nota: nota);
    final storage = ListaStorage();
    final actuales = await storage.leerListas();
    actuales.add(nuevaLista);
    await storage.guardarListas(actuales);

    desactivarSeleccion();
  }

  void mostrarDetalleTema(String tema) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Container(
        padding: EdgeInsets.all(16),
        height: 200,
        child: Center(
          child: Text("Detalles de $tema", style: TextStyle(fontSize: 18)),
        ),
      ),
    );
  }

  Widget buildTemaItem(String tema) {
    bool seleccionado = seleccionados.contains(tema);

    return GestureDetector(
      onLongPress: () => activarSeleccion(tema),
      child: InkWell(
        onTap: () {
          if (modoSeleccion) {
            toggleSeleccion(tema);
          } else {
            mostrarDetalleTema(tema);
          }
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(
              color: seleccionado ? Colors.blue : Colors.grey.shade300,
              width: seleccionado ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(10),
            color: seleccionado ? Colors.blue.shade50 : Colors.white,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(tema, style: TextStyle(fontSize: 16)),
              if (modoSeleccion)
                Icon(
                  seleccionado ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: seleccionado ? Colors.blue : Colors.grey,
                )
            ],
          ),
        ),
      ),
    );
  }

  Widget buildFabMenu() {
    return FloatingActionButton(
      child: Icon(Icons.menu),
      onPressed: () {
        showModalBottomSheet(
          context: context,
          builder: (_) => Container(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton.icon(
                  onPressed: crearLista,
                  icon: Icon(Icons.save),
                  label: Text("Crear lista con seleccionados"),
                ),
                TextButton.icon(
                  onPressed: desactivarSeleccion,
                  icon: Icon(Icons.cancel),
                  label: Text("Cancelar selección"),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Temas"),
        actions: [
          if (modoSeleccion)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(child: Text("${seleccionados.length} seleccionados")),
            ),
        ],
      ),
      body: ListView.builder(
        itemCount: temasDisponibles.length,
        itemBuilder: (_, i) => buildTemaItem(temasDisponibles[i]),
      ),
      floatingActionButton: modoSeleccion ? buildFabMenu() : null,
    );
  }
}


class VerListasPage extends StatefulWidget {
  @override
  _VerListasPageState createState() => _VerListasPageState();
}

class _VerListasPageState extends State<VerListasPage> {
  final storage = ListaStorage();
  List<TemaLista> listas = [];

  @override
  void initState() {
    super.initState();
    cargarListas();
  }

  Future<void> cargarListas() async {
    final data = await storage.leerListas();
    setState(() {
      listas = data;
    });
  }

  Future<void> guardarCambios() async {
    await storage.guardarListas(listas);
    setState(() {});
  }

  void eliminarLista(int index) async {
    listas.removeAt(index);
    await guardarCambios();
  }

  void editarListaModal(int index) {
    final lista = listas[index];
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
              TextField(
                controller: notaController,
                decoration: InputDecoration(labelText: "Nota (ej: A, B, C...)"),
              ),
              SizedBox(height: 12),
              TextField(
                controller: temasController,
                decoration: InputDecoration(labelText: "Temas (separados por coma)"),
              ),
              SizedBox(height: 16),
              ElevatedButton.icon(
                icon: Icon(Icons.save),
                label: Text("Guardar cambios"),
                onPressed: () {
                  final nuevosTemas = temasController.text
                      .split(',')
                      .map((e) => e.trim())
                      .where((e) => e.isNotEmpty)
                      .toList();
                  final nuevaNota = notaController.text.trim();

                  setState(() {
                    listas[index] = TemaLista(temas: nuevosTemas, nota: nuevaNota);
                  });
                  guardarCambios();
                  Navigator.pop(context);
                },
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget buildListaItem(int index) {
    final lista = listas[index];

    return Dismissible(
      key: Key('lista_$index'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => eliminarLista(index),
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.symmetric(horizontal: 20),
        color: Colors.red,
        child: Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
        margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        elevation: 3,
        child: ExpansionTile(
          title: Text("Nota: ${lista.nota}"),
          subtitle: Text("${lista.temas.length} temas"),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: lista.temas.map((tema) => Text("- $tema")).toList(),
              ),
            ),
            ButtonBar(
              children: [
                TextButton.icon(
                  onPressed: () => editarListaModal(index),
                  icon: Icon(Icons.edit),
                  label: Text("Editar"),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Listas Guardadas")),
      body: listas.isEmpty
          ? Center(child: Text("No hay listas guardadas aún"))
          : ListView.builder(
              itemCount: listas.length,
              itemBuilder: (_, index) => buildListaItem(index),
            ),
    );
  }
}
*/