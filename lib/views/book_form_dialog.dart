import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import '../models/book_model.dart';
import '../services/data_service.dart';
import 'scanner_view.dart';

class BookFormDialog extends StatefulWidget {
  final Book? book;
  final List<Book> currentBooks;
  final List<String> databaseCategories;

  const BookFormDialog({
    super.key,
    this.book,
    required this.currentBooks,
    required this.databaseCategories
  });

  @override
  State<BookFormDialog> createState() => _BookFormDialogState();
}

class _BookFormDialogState extends State<BookFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _isbnC;
  late TextEditingController _titleC;
  late TextEditingController _categoryCustomC;
  late TextEditingController _cityC;
  late TextEditingController _deptC;
  late TextEditingController _countryC;
  late TextEditingController _editorialC;
  late TextEditingController _yearC;

  // Listas de controladores dinámicos para nombres y apellidos de autores
  List<TextEditingController> _firstNameControllers = [];
  List<TextEditingController> _lastNameControllers = [];

  String _categoryMode = 'Elegir';
  String? _selectedCategory;
  bool _isSearching = false;

  final List<String> _defaultCategories = [
    "Teología sistemática", "Teología", "Eclesiología", "Escatología", "Cristología",
    "Doctrina", "Apologética", "Pneumatología", "Misión integral", "Teología pentecostal",
    "Historia del cristianismo", "Historia de la Iglesia", "Diccionarios de teología",
    "Diccionarios bíblicos", "Hermenéutica", "Antiguo Testamento", "Nuevo Testamento",
    "Comentarios bíblicos", "Griego", "Biblias de estudio", "Metodología del aprendizaje",
    "Educación", "Educación teológica", "Escuela dominical", "Liderazgo", "Predicación",
    "Administración", "Ética", "Filosofía", "Sociología", "Psicología", "Matrimonio",
    "Familia", "Consejería", "Iglesia y ministerio", "Ministerio juvenil", "Ministerio infantil",
    "Vida cristiana", "Discipulado", "Evangelismo", "Enciclopedia", "Historia universal",
    "Historia de Guatemala", "Historia de Centroamérica", "Diccionarios de español",
    "Literatura clásica", "Obras de Wesley", "Enciclopedia bíblica", "Religiones",
    "Tesis de maestría", "Artículos de investigación", "Revistas académicas", "Realidad social",
    "Mujeres", "Iglesia de Dios", "Misionología"
  ];

  @override
  void initState() {
    super.initState();
    final b = widget.book;
    _isbnC = TextEditingController(text: b?.isbn);
    _titleC = TextEditingController(text: b?.title);
    _categoryCustomC = TextEditingController();
    _cityC = TextEditingController(text: b?.city);
    _deptC = TextEditingController(text: b?.department);
    _countryC = TextEditingController(text: b?.country);
    _editorialC = TextEditingController(text: b?.editorial);
    _yearC = TextEditingController(text: b?.year);

    List<Author> initialAuthors = [Author(firstName: '', lastName: '')];

    if (b != null) {
      initialAuthors = List.from(b.authors);
      final allCats = {..._defaultCategories, ...widget.databaseCategories};
      if (allCats.contains(b.category)) {
        _categoryMode = 'Elegir';
        _selectedCategory = b.category;
      } else {
        _categoryMode = 'Otro...';
        _categoryCustomC.text = b.category;
      }
    }

    // Inicializar los controladores de los autores
    for (var author in initialAuthors) {
      _firstNameControllers.add(TextEditingController(text: author.firstName));
      _lastNameControllers.add(TextEditingController(text: author.lastName));
    }
  }

  @override
  void dispose() {
    // Limpieza de controladores básicos
    _isbnC.dispose();
    _titleC.dispose();
    _categoryCustomC.dispose();
    _cityC.dispose();
    _deptC.dispose();
    _countryC.dispose();
    _editorialC.dispose();
    _yearC.dispose();
    // Limpieza de controladores dinámicos
    for (var c in _firstNameControllers) {
      c.dispose();
    }
    for (var c in _lastNameControllers) {
      c.dispose();
    }
    super.dispose();
  }

  String _normalize(String text) {
    return text.toLowerCase()
        .replaceAll('á', 'a').replaceAll('é', 'e')
        .replaceAll('í', 'i').replaceAll('ó', 'o')
        .replaceAll('ú', 'u').replaceAll('ñ', 'n');
  }

  // Verificación de duplicado ISBN e integración Multi-API
  Future<void> _processIsbn(String isbn) async {
    if (isbn.isEmpty) return;
    setState(() => _isSearching = true);

    // Verificar Duplicado Local/DB
    final duplicate = widget.currentBooks.where((b) => b.isbn == isbn && b.id != widget.book?.id);
    if (duplicate.isNotEmpty) {
      final existingBook = duplicate.first;
      bool keepChanges = await _showDuplicateDialog(existingBook);
      if (!keepChanges) {
        setState(() => _isSearching = false);
        return;
      }
    }

    // Consulta Multi-API
    final apiResults = await DataService.fetchFromMultipleApis(isbn);
    setState(() => _isSearching = false);

    if (mounted) {
      _showApiSelectionDialog(apiResults);
    }
  }

  Future<bool> _showDuplicateDialog(Book existing) async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("⚠️ ISBN Duplicado detectado"),
        content: Text("El ISBN ya pertenece al libro: '${existing.title}'. ¿Deseas continuar y sobreescribir u omitir cambios?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Omitir")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Continuar/Modificar")),
        ],
      ),
    ) ?? false;
  }

  // Función con tu lógica exacta para fragmentar los nombres de las APIs
  List<Author> _parseAuthorsFromApi(String rawAuthors) {
    if (rawAuthors.isEmpty) return [Author(firstName: '', lastName: '')];

    List<String> individualAuthors = rawAuthors.split(RegExp(r',\s*'));
    List<Author> parsedList = [];

    for (var authorName in individualAuthors) {
      List<String> words = authorName.trim().split(RegExp(r'\s+'));
      if (words.isEmpty || words[0].isEmpty) continue;

      if (words.length == 1) {
        parsedList.add(Author(firstName: words[0], lastName: ''));
      } else if (words.length == 2) {
        parsedList.add(Author(firstName: words[0], lastName: words[1]));
      } else if (words.length == 3) {
        parsedList.add(Author(firstName: words[0], lastName: '${words[1]} ${words[2]}'));
      } else if (words.length == 4) {
        parsedList.add(Author(firstName: '${words[0]} ${words[1]}', lastName: '${words[2]} ${words[3]}'));
      } else {
        parsedList.add(Author(
            firstName: '${words[0]} ${words[1]}',
            lastName: words.sublist(2).join(' ')
        ));
      }
    }
    return parsedList.isEmpty ? [Author(firstName: '', lastName: '')] : parsedList;
  }

  void _showApiSelectionDialog(Map<String, Map<String, String>> results) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Resultados en Fuentes Externas"),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: results.entries.map((entry) {
              final source = entry.key;
              final data = entry.value;
              final isEmpty = data.isEmpty;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(source, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                      const Divider(),
                      if (isEmpty)
                        const Text("No se encontró resultado para este ISBN.", style: TextStyle(fontStyle: FontStyle.italic))
                      else ...[
                        Text("Título: ${data['title']}"),
                        Text("Autor/es: ${data['author']}"),
                        Text("Editorial: ${data['editorial']}"),
                        Text("Año: ${data['year']}"),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton(
                            onPressed: () {
                              //1. Extraer los datos primero
                              final title = data['title'] ?? '';
                              final editorial = data['editorial'] ?? '';
                              final year = data['year'] ?? '';
                              List<Author> parsed = _parseAuthorsFromApi(data['author'] ?? '');

                              // 2. CERRAR el diálogo PRIMERO para desmontar el ListView de la API
                              Navigator.of(ctx).pop();

                              // 3. Actualizar el estado del formulario principal después de cerrar
                              Future.microtask(() {
                                if (!mounted) return;
                                setState(() {
                                  _titleC.text = title;
                                  _editorialC.text = editorial;
                                  _yearC.text = year;

                                  // Importante: Crear controladores nuevos
                                  _firstNameControllers = parsed.map((a) => TextEditingController(text: a.firstName)).toList();
                                  _lastNameControllers = parsed.map((a) => TextEditingController(text: a.lastName)).toList();
                                });
                              });
                            },
                            child: const Text("Aplicar"),
                          ),
                        )
                      ]
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cerrar"))],
      ),
    );
  }

  Widget _buildAutocompleteField(TextEditingController controller, String label, Iterable<String> Function(String) searchLogic) {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.length < 3) return const Iterable<String>.empty();
        return searchLogic(textEditingValue.text);
      },
      // Eliminamos el initialValue y el listener manual dentro del builder
      onSelected: (String selection) {
        controller.text = selection;
      },
      fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
        // Usar SchedulerBinding asegura que la actualización ocurra después del frame actual
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (controller.text != textController.text && textController.text.isEmpty) {
            textController.text = controller.text;
          }
        });

        return TextFormField(
          controller: textController,
          focusNode: focusNode,
          decoration: InputDecoration(labelText: label),
          onChanged: (val) {
            controller.text = val;
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeCategories = {..._defaultCategories, ...widget.databaseCategories}.toList()..sort();

    return AlertDialog(
      title: Text(widget.book == null ? "Agregar Libro" : "Editar Libro"),
      content: SizedBox(width: double.maxFinite, child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _isbnC,
                      decoration: const InputDecoration(labelText: "ISBN"),
                      keyboardType: TextInputType.number,
                      onFieldSubmitted: (value) => _processIsbn(value), // Captura el Enter perfectamente
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.search, color: Colors.indigo), onPressed: () => _processIsbn(_isbnC.text)),
                  IconButton(icon: const Icon(Icons.qr_code_scanner), onPressed: () async {
                    final res = await Navigator.push<String>(context, MaterialPageRoute(builder: (_) => const ScannerView()));
                    if (res != null) { _isbnC.text = res; _processIsbn(res); }
                  }),
                ],
              ),
              if (_isSearching) const LinearProgressIndicator(),

              // Título con Autocompletado
              _buildAutocompleteField(_titleC, "Título", (q) {
                return widget.currentBooks.map((b) => b.title)
                    .where((t) => _normalize(t).contains(_normalize(q))).toSet();
              }),

              const SizedBox(height: 10),
              const Align(alignment: Alignment.centerLeft, child: Text("Autores", style: TextStyle(fontWeight: FontWeight.bold))),

              // Segmento Dinámico de Multi-Autores conectado a sus Controladores
              // Segmento Dinámico de Multi-Autores
// Segmento Dinámico de Multi-Autores corregido para estabilidad en Web
              ...Iterable<int>.generate(_firstNameControllers.length).map((index) {
                // Verificamos que el índice aún sea válido antes de renderizar la fila
                if (index >= _firstNameControllers.length) return const SizedBox.shrink();

                return Row(
                  // Usamos una llave que dependa del objeto controlador, no del índice
                  key: ObjectKey(_firstNameControllers[index]),
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _firstNameControllers[index],
                        decoration: const InputDecoration(labelText: "Nombres"),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: TextFormField(
                        controller: _lastNameControllers[index],
                        decoration: const InputDecoration(labelText: "Apellidos"),
                      ),
                    ),
                    if (_firstNameControllers.length > 1)
                      IconButton(
                        icon: const Icon(Icons.remove_circle, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            // Eliminamos sin dispose inmediato para evitar error de renderizado
                            _firstNameControllers.removeAt(index);
                            _lastNameControllers.removeAt(index);
                          });
                        },
                      ),
                  ],
                );
              }).toList().toList(),

              TextButton.icon(
                icon: const Icon(Icons.add),
                label: const Text("Agregar Autor"),
                onPressed: () => setState(() {
                  _firstNameControllers.add(TextEditingController());
                  _lastNameControllers.add(TextEditingController());
                }),
              ),

              // Segmento de Categorías (Radio Buttons)
              const Divider(),
              Row(
                children: [
                  Radio<String>(
                    value: 'Elegir',
                    groupValue: _categoryMode,
                    onChanged: (v) => setState(() => _categoryMode = v!),
                  ),
                  const Text("Elegir"),
                  Radio<String>(
                    value: 'Otro...',
                    groupValue: _categoryMode,
                    onChanged: (v) => setState(() => _categoryMode = v!),
                  ),
                  const Text("Otro..."),
                ],
              ),
              _categoryMode == 'Elegir'
                  ? DropdownButtonFormField<String>(
                value: activeCategories.contains(_selectedCategory) ? _selectedCategory : null,
                decoration: const InputDecoration(labelText: "Seleccionar Categoría"),
                items: activeCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => _selectedCategory = v),
              )
                  : TextFormField(
                controller: _categoryCustomC,
                decoration: const InputDecoration(labelText: "Nueva Categoría"),
              ),
              const Divider(),

              // Campos Restantes con Autocompletado Contextual
              _buildAutocompleteField(_editorialC, "Editorial", (q) => widget.currentBooks.map((b) => b.editorial).where((e) => _normalize(e).contains(_normalize(q))).toSet()),
              _buildAutocompleteField(_yearC, "Año", (q) => widget.currentBooks.map((b) => b.year).where((y) => _normalize(y).contains(_normalize(q))).toSet()),
              _buildAutocompleteField(_cityC, "Ciudad", (q) => widget.currentBooks.map((b) => b.city).where((c) => _normalize(c).contains(_normalize(q))).toSet()),
              _buildAutocompleteField(_deptC, "Departamento", (q) => widget.currentBooks.map((b) => b.department).where((d) => _normalize(d).contains(_normalize(q))).toSet()),
              _buildAutocompleteField(_countryC, "País", (q) => widget.currentBooks.map((b) => b.country).where((p) => _normalize(p).contains(_normalize(q))).toSet()),
            ],
          ),
        ),
      )),
      actions: [
        if (widget.book != null)
          TextButton(
            onPressed: () async {
              await DataService.deleteBook(widget.book!.id!);
              if (mounted) Navigator.pop(context);
            },
            child: const Text("Eliminar", style: TextStyle(color: Colors.red)),
          ),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
        ElevatedButton(onPressed: _save, child: const Text("Guardar")),
      ],
    );
  }

  void _save() async {
    if (_formKey.currentState!.validate()) {
      String finalCategory = _categoryMode == 'Elegir' ? (_selectedCategory ?? '') : _categoryCustomC.text.trim();

      if (_categoryMode == 'Otro...' && finalCategory.isNotEmpty) {
        await DataService.saveCategory(finalCategory);
      }

      // Procesar la lista de autores recolectando los textos directamente de los controladores activos
      List<Author> finalAuthors = [];
      for (int i = 0; i < _firstNameControllers.length; i++) {
        final fName = _firstNameControllers[i].text.trim();
        final lName = _lastNameControllers[i].text.trim();
        if (fName.isNotEmpty || lName.isNotEmpty) {
          finalAuthors.add(Author(firstName: fName, lastName: lName));
        }
      }

      final b = Book(
        id: widget.book?.id,
        isbn: _isbnC.text,
        authors: finalAuthors,
        title: _titleC.text,
        category: finalCategory,
        city: _cityC.text,
        department: _deptC.text,
        country: _countryC.text,
        editorial: _editorialC.text,
        year: _yearC.text,
      );

      await DataService.upsertBook(b);
      if (mounted) Navigator.pop(context);
    }
  }
}