/*
Widget formatearConNotas(String tema1, String texto, int tonoOffset, int index1) {
  final List<String> PalabrasParaBoldear = ["Tema", "TEMA", "CORO", "ESTROFA", "INTRO", "ESTRIBILLO", "PUENTE", "PRE-CORO", "("];
  final lineas = texto.split('\n');
  final lineasWidgets = <Widget>[];
  lineasWidgets.add(Text("${index1 + 1} ■ █ ${tema1} █ ■", style: TextStyle(fontSize: tam_fuente + 5, color: etiquetaColor, fontWeight: FontWeight.bold)));
  lineasWidgets.add(Text('Círculo de "${notasMusicales1[tonoOffset]}"', style: TextStyle(fontSize: tam_fuente + 3, color: etiquetaColor, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)));
  lineasWidgets.add(SizedBox(height: 10.0));
  
  for (final linea in lineas) {
    final regex = RegExp(r'?(.*?)?');
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
        comprobador1 ? "? ${linea.substring(lastIndex)}" : linea.substring(lastIndex),
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
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: lineasWidgets,
  );
}


ESTO ES PARA LOS TABS DEL MAIN.DART
(Refactorizado por ChatGPT)

class TabListas extends StatelessWidget {
  final List<TemaLista> listas;
  final void Function(int) onEliminar;
  final void Function(int) onEditar;

  const TabListas({
    Key? key,
    required this.listas,
    required this.onEliminar,
    required this.onEditar,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (listas.isEmpty) {
      return Center(child: Text("Todav铆a no tienes listas guardadas"));
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
          ),
        );
      },
    );
  }
}

class PantallaConTabs extends StatefulWidget {
  final Function(ThemeMode) cambiarTema;
  final Function(Color) cambiarColorEtiqueta;

  PantallaConTabs({
    required this.cambiarTema,
    required this.cambiarColorEtiqueta,
  });

  @override
  _PantallaConTabsState createState() => _PantallaConTabsState();
}

class _PantallaConTabsState extends State<PantallaConTabs>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<Map<String, dynamic>> adoracion = [];
  final List<Map<String, dynamic>> jubilo = [];
  final List<Map<String, dynamic>> himnario = [];

  // 馃敼 Gesti贸n de listas
  final storage = ListaStorage();
  List<TemaLista> listas = [];
  Set<String> seleccionados = {};
  bool modoSeleccion = false;

  // 馃敼 Fuente
  late double tam_fuente;

  // -------------------------
  // Ciclo de vida
  // -------------------------
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: tabs.length, vsync: this);
    cargarListas();
    cargarTamFuente();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // -------------------------
  // Persistencia
  // -------------------------
  Future<void> cargarListas() async {
    final data = await storage.leerListas();
    setState(() => listas = data);
  }

  Future<void> guardarListas() async {
    await storage.guardarListas(listas);
    await cargarListas();
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
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () async {
              final nuevaNota = notaController.text.trim().isEmpty
                  ? "Lista"
                  : notaController.text.trim();

              final nuevaLista = TemaLista(
                temas: seleccionados.toList(),
                nota: nuevaNota,
              );

              setState(() {
                listas.add(nuevaLista);
                seleccionados.clear();
                modoSeleccion = false;
              });

              await guardarListas();
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
    await guardarListas();
  }

  void editarListaModal(int index) {
    final lista = listas[index];
    final notaController = TextEditingController(text: lista.nota);
    final temasController =
        TextEditingController(text: lista.temas.join(', '));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: MediaQuery.of(context).viewInsets,
        child: Container(
          padding: EdgeInsets.all(16),
          child: Wrap(
            children: [
              Text("Editar Lista",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 12),
              TextField(
                controller: notaController,
                decoration: InputDecoration(labelText: "Nota"),
              ),
              SizedBox(height: 12),
              TextField(
                controller: temasController,
                decoration:
                    InputDecoration(labelText: "Temas (separados por coma)"),
              ),
              SizedBox(height: 16),
              ElevatedButton.icon(
                icon: Icon(Icons.save),
                label: Text("Guardar cambios"),
                onPressed: () async {
                  final nuevosTemas = temasController.text
                      .split(',')
                      .map((e) => e.trim())
                      .where((e) => e.isNotEmpty)
                      .toList();

                  setState(() {
                    listas[index] =
                        TemaLista(temas: nuevosTemas, nota: notaController.text);
                  });
                  await guardarListas();
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
  // Himnos
  // -------------------------
  void clasificarHimnos(List<dynamic> himnos) {
    adoracion.clear();
    jubilo.clear();
    himnario.clear();

    for (var himno in himnos) {
      final categorias = himno['categoria'] as List;
      if (categorias.contains("Adoraci贸n")) adoracion.add(himno);
      if (categorias.contains("J煤bilo")) jubilo.add(himno);
      if (categorias.contains("Himnario")) himnario.add(himno);
    }

    adoracion.sort((a, b) => a['tema'].compareTo(b['tema']));
    jubilo.sort((a, b) => a['tema'].compareTo(b['tema']));
    himnario.sort((a, b) => a['tema'].compareTo(b['tema']));
  }

  void mostrarVentana(
      BuildContext context, String tema, String contenido, String autor,
      {int tonoOffset = 0}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
    if (lista.isEmpty) {
      return Center(child: Text("No hay himnos disponibles en esta secci贸n"));
    }

    return ListView.builder(
      itemCount: lista.length,
      itemBuilder: (context, index) {
        final himno = lista[index];
        final seleccionado = seleccionados.contains(himno['tema']);

        return ListTile(
          title: Text(himno['tema']),
          trailing: modoSeleccion
              ? Icon(
                  seleccionado
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: seleccionado ? Colors.purple.shade700 : Colors.grey,
                )
              : Icon(Icons.chevron_right),
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
              mostrarVentana(context, himno['tema'], himno['contenido'],
                  himno['autor'],
                  tonoOffset: notasMusicales1.indexOf(himno['nota']));
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
                  label: Text("Guardar lista"),
                ),
                TextButton.icon(
                  onPressed: desactivarSeleccion,
                  icon: Icon(Icons.cancel),
                  label: Text("Cancelar selecci贸n"),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // -------------------------
  // Fuente
  // -------------------------
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

  // -------------------------
  // UI
  // -------------------------
  final List<Tab> tabs = const [
    Tab(icon: Icon(Icons.music_note, color: Colors.white), text: 'Adoraci贸n'),
    Tab(icon: Icon(Icons.celebration, color: Colors.white), text: 'J煤bilo'),
    Tab(icon: Icon(Icons.book, color: Colors.white), text: 'Himnario'),
    Tab(icon: Icon(Icons.list, color: Colors.white), text: 'Listas'),
    Tab(icon: Icon(Icons.search, color: Colors.white), text: 'Buscar'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.purple.shade700,
        title: TabBar(
          controller: _tabController,
          tabs: tabs,
          isScrollable: true,
          indicatorColor: Colors.amber,
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: cargarDatos(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return Center(
                child:
                    CircularProgressIndicator(color: Colors.purple.shade700));

          if (snapshot.hasError)
            return Center(child: Text("Error: ${snapshot.error}"));

          final data = snapshot.data!;
          final himnos = data['himnos'] as List<dynamic>;
          clasificarHimnos(himnos);

          return TabBarView(
            controller: _tabController,
            children: [
              _buildListaHimnos(adoracion),
              _buildListaHimnos(jubilo),
              _buildListaHimnos(himnario),
              // 馃敼 TabListas ahora solo recibe las listas y callbacks de CRUD
              TabListas(
                listas: listas,
                onEditar: editarListaModal,
                onEliminar: eliminarLista,
              ),
              BusquedaHimnos(
                himnos: himnos,
                cambiarTema: widget.cambiarTema,
                cambiarColorEtiqueta: widget.cambiarColorEtiqueta,
                cambiarFuente: cambiarFuente,
                tam_fuente: tam_fuente,
              ),
            ],
          );
        },
      ),
      floatingActionButton: modoSeleccion ? buildFabMenu() : null,
    );
  }
}



En este c贸digo, veo que cada vez que selecciono un himno (ya estando habilitado la selecci贸n), observo como que todo se recargara. O sea, todos los temas se recargaran.
S铆 馃憖, eso que describes es el comportamiento t铆pico de Flutter cuando usas setState en un ListView.builder:
cada vez que seleccionas/deseleccionas un himno, haces setState, y Flutter reconstruye toda la lista (no solo el 铆tem).

馃攷 Por qu茅 pasa

En tu _buildListaHimnos tienes algo como:
return ListView.builder(
  itemCount: lista.length,
  itemBuilder: (context, index) {
    final himno = lista[index];
    final seleccionado = seleccionados.contains(himno['tema']);
    return ListTile(
      title: Text(himno['tema']),
      trailing: modoSeleccion
          ? Icon(
              seleccionado
                  ? Icons.check_circle
                  : Icons.radio_button_unchecked,
              color: seleccionado ? Colors.purple.shade700 : Colors.grey,
            )
          : Icon(Icons.chevron_right),
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
          mostrarVentana(...);
        }
      },
    );
  },
);


Cada setState 鈫?reconstruye el ListView completo 鈫?efecto visual de "recargar".

鉁?Soluciones

Tienes varias opciones para evitar esa sensaci贸n:

1. StatefulWidget por 铆tem

En vez de que todo el ListView dependa de un solo setState, haces que cada ListTile sea un StatefulWidget independiente que administre su propio estado de selecci贸n.
As铆, al cambiar un 铆tem, solo se reconstruye ese 铆tem.

2. Usar ValueListenableBuilder o ChangeNotifier

Puedes guardar el Set<String> seleccionados en un ValueNotifier.

Cada 铆tem escucha solo a su propio valor (si est谩 en seleccionados o no).

As铆 evitas reconstruir la lista entera.

3. Usar ListView.builder con AutomaticKeepAliveClientMixin

Esto hace que los hijos no se descarten al hacer scroll o al redibujar 鈫?reduce el efecto de "recarga".
Ejemplo:

class TemaItem extends StatefulWidget {
  final String tema;
  final bool seleccionado;
  final Function() onTap;
  final Function() onLongPress;

  const TemaItem({
    Key? key,
    required this.tema,
    required this.seleccionado,
    required this.onTap,
    required this.onLongPress,
  }) : super(key: key);

  @override
  _TemaItemState createState() => _TemaItemState();
}

class _TemaItemState extends State<TemaItem>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context); // 馃憟 importante
    return ListTile(
      title: Text(widget.tema),
      trailing: Icon(
        widget.seleccionado ? Icons.check_circle : Icons.radio_button_unchecked,
        color: widget.seleccionado ? Colors.purple.shade700 : Colors.grey,
      ),
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
    );
  }

  @override
  bool get wantKeepAlive => true;
}


Y en _buildListaHimnos

return ListView.builder(
  itemCount: lista.length,
  itemBuilder: (context, index) {
    final himno = lista[index];
    final seleccionado = seleccionados.contains(himno['tema']);
    return TemaItem(
      tema: himno['tema'],
      seleccionado: seleccionado,
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
          mostrarVentana(
            context,
            himno['tema'],
            himno['contenido'],
            himno['autor'],
            tonoOffset: notasMusicales1.indexOf(himno['nota']),
          );
        }
      },
      onLongPress: () {
        setState(() {
          modoSeleccion = true;
          seleccionados.add(himno['tema']);
        });
      },
    );
  },
);
馃憠 Esto har谩 que solo se actualice el TemaItem afectado, y no todo el ListView.

驴Quieres que te prepare una versi贸n optimizada con la opci贸n 3 (AutomaticKeepAliveClientMixin) para integrarla directamente a tu PantallaConTabs?


*/
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io' as io show File;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

class DatosScreen extends StatefulWidget {
  final Function(ThemeMode) cambiarTema;
  final Function(Color) cambiarColorEtiqueta;
  final Color etiquetaColor;
  final Color textColor1;

  DatosScreen({
    required this.cambiarTema,
    required this.cambiarColorEtiqueta,
    required this.etiquetaColor,
    required this.textColor1,
  });
  
  @override
  State<DatosScreen> createState() => _DatosScreenState();
}

class _DatosScreenState extends State<DatosScreen> {
  String contenido1 = '';
  int tonoOffset = 0;
  late Color etiquetaColor;
  late Color textColor1;

  final List<String> notasIngles = [
    'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'
  ];
  
  static final List<Color> _coloresEtiqueta = [
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
  
  @override
  void initState() {
    super.initState();
    etiquetaColor = widget.etiquetaColor;
    textColor1 = widget.textColor1;
  }
  
  Future<void> cargarArchivo() async {
    try {
      final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt'],
      withData: true,
      );
      
      if (result != null && result.files.single.bytes != null) {
        String content;
        if (kIsWeb) {
          content = utf8.decode(result.files.single.bytes!);
        } else {
          final file = io.File(result.files.single.path!);
          content = await file.readAsString();
        }
        
        setState(() {
          contenido1 = content;
        });
      }
    } catch (e) {
      setState(() {
        contenido1 = "Error al leer el archivo: $e";
      });
    }
  }
  
  String notaConTono(int numero) {
    final indexOriginal = (numero - 1) % 12;
    final indexConOffset = (indexOriginal + tonoOffset) % 12;
    return notasIngles[(indexConOffset + 12) % 12];
  }
  
  Widget formatearConNotas(String texto) {
    final regex = RegExp(r'鈥?.*?)鈥?);
    final partes = <InlineSpan>[];
    int lastIndex = 0;
    
    for (final match in regex.allMatches(texto)) {
      final antes = texto.substring(lastIndex, match.start);
      if (antes.isNotEmpty) {
        partes.add(TextSpan(text: antes));
      }
      
      final contenidoNota = match.group(1) ?? '';
      final numero = int.tryParse(
        RegExp(r'\d+').firstMatch(contenidoNota)?.group(0) ?? '',
      );
      
      final nota = numero != null ? notaConTono(numero) : contenidoNota;
      
      partes.add(WidgetSpan(
        alignment: PlaceholderAlignment.bottom,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 20.00),
              child: Text(
                contenidoNota.replaceAll(RegExp(r'\d+'), ''),
                style: TextStyle(fontSize: 16),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: etiquetaColor,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(nota, style: TextStyle(color: textColor1, fontSize:15)),
            ),
          ],
        ),
      ));
      
      lastIndex = match.end;
    }
    
    if (lastIndex < texto.length) {
      partes.add(TextSpan(text: texto.substring(lastIndex)));
    }
    
    final isDarkMode = Theme.of(context).brightness = Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    
    return RichText(
      text: TextSpan(
        style: TextStyle(color: textColor, fontSize: 16),
        children: partes,
      ),
    );
  }
  
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
    final textoFormateado = formatearConNotas(contenido1);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    
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