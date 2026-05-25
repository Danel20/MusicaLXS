import 'dart:convert';
import 'dart:io' show File, Platform;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// Configuración de Supabase
const String supabaseUrl = 'https://yhmasnxfrzzbqdhgqbhj.supabase.co';
const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlobWFzbnhmcnp6YnFkaGdxYmhqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU3NjYwNzUsImV4cCI6MjA5MTM0MjA3NX0.n-5TUpfB11thBVsa9m--4qAeKBVSdOkd8IuHZs9rBsM';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  runApp(const BibliotecXSApp());
}

class BibliotecXSApp extends StatelessWidget {
  const BibliotecXSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BibliotecXS SEBIPCA',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo, primary: Colors.indigo),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

// Modelo de Libro con soporte para búsqueda global
class Book {
  String? id;
  String isbn;
  String author;
  String title;
  String category;
  String city;
  String department;
  String country;
  String editorial;
  String year;

  Book({
    this.id,
    required this.isbn,
    required this.author,
    required this.title,
    required this.category,
    required this.city,
    required this.department,
    required this.country,
    required this.editorial,
    required this.year,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'isbn': isbn, 'author': author, 'title': title, 'category': category,
    'city': city, 'department': department, 'country': country, 'editorial': editorial, 'year': year,
  };

  factory Book.fromJson(Map<String, dynamic> json) => Book(
    id: json['id']?.toString(),
    isbn: json['isbn'] ?? '',
    author: json['author'] ?? '',
    title: json['title'] ?? '',
    category: json['category'] ?? '',
    city: json['city'] ?? '',
    department: json['department'] ?? '',
    country: json['country'] ?? '',
    editorial: json['editorial'] ?? '',
    year: json['year']?.toString() ?? '',
  );

  bool contains(String query) {
    final q = query.toLowerCase();
    return title.toLowerCase().contains(q) ||
        author.toLowerCase().contains(q) ||
        isbn.toLowerCase().contains(q) ||
        editorial.toLowerCase().contains(q) ||
        category.toLowerCase().contains(q) ||
        year.toLowerCase().contains(q) ||
        country.toLowerCase().contains(q) ||
        city.toLowerCase().contains(q);
  }
}

// Servicios de Datos
class DataService {
  static final client = Supabase.instance.client;

  static Future<void> saveLocalBackup(List<Book> books) async {
    if (kIsWeb) return;
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/books_backup.json');
      await file.writeAsString(jsonEncode(books.map((b) => b.toJson()).toList()));
    } catch (e) { debugPrint("Error backup: $e"); }
  }

  static Future<List<Book>> getLocalBackup() async {
    if (kIsWeb) return [];
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/books_backup.json');
      if (await file.exists()) {
        final content = await file.readAsString();
        final List list = jsonDecode(content);
        return list.map((item) => Book.fromJson(item)).toList();
      }
    } catch (e) { debugPrint("Error backup: $e"); }
    return [];
  }

  static Future<List<Book>> fetchBooks() async {
    final response = await client.from('books').select().order('title');
    final books = (response as List).map((b) => Book.fromJson(b)).toList();
    await saveLocalBackup(books);
    return books;
  }

  static Future<void> upsertBook(Book book) async {
    final data = book.toJson();
    if (book.id == null) data.remove('id');
    await client.from('books').upsert(data);
  }

  static Future<void> deleteBook(String id) async {
    await client.from('books').delete().match({'id': id});
  }

  static Future<Map<String, String>?> fetchBookByIsbn(String isbn) async {
    try {
      final url = Uri.parse('https://openlibrary.org/api/books?bibkeys=ISBN:$isbn&format=json&jscmd=data');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data.containsKey('ISBN:$isbn')) {
          final b = data['ISBN:$isbn'];
          return {
            'title': b['title'] ?? '',
            'author': (b['authors'] as List?)?.map((a) => a['name']).join(', ') ?? '',
            'editorial': (b['publishers'] as List?)?.map((p) => p['name']).join(', ') ?? '',
            'year': b['publish_date'] ?? '',
          };
        }
      }
    } catch (e) { debugPrint("Error ISBN API: $e"); }
    return null;
  }
}

// Pantalla Principal
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Book> _allBooks = [];
  bool _isLoading = true;
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  // Filtros
  String? _selAuthor, _selEditorial, _selCountry;
  int? _yearStart, _yearEnd;
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      _allBooks = await DataService.fetchBooks();
    } catch (e) {
      _allBooks = await DataService.getLocalBackup();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sin conexión, cargando datos locales.")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Book> get _filteredBooks {
    return _allBooks.where((b) {
      final matchesSearch = b.contains(_searchQuery);
      final matchesAuthor = _selAuthor == null || b.author == _selAuthor;
      final matchesEditorial = _selEditorial == null || b.editorial == _selEditorial;
      final matchesCountry = _selCountry == null || b.country == _selCountry;

      bool matchesYear = true;
      final bookYear = int.tryParse(b.year.replaceAll(RegExp(r'\D'), ''));
      if (bookYear != null) {
        if (_yearStart != null && bookYear < _yearStart!) matchesYear = false;
        if (_yearEnd != null && bookYear > _yearEnd!) matchesYear = false;
      } else if (_yearStart != null || _yearEnd != null) {
        matchesYear = false;
      }

      return matchesSearch && matchesAuthor && matchesEditorial && matchesCountry && matchesYear;
    }).toList();
  }

  // Listas únicas para dropdowns
  List<String> get _authors => _allBooks.map((b) => b.author).where((s) => s.isNotEmpty).toSet().toList()..sort();
  List<String> get _editorials => _allBooks.map((b) => b.editorial).where((s) => s.isNotEmpty).toSet().toList()..sort();
  List<String> get _countries => _allBooks.map((b) => b.country).where((s) => s.isNotEmpty).toSet().toList()..sort();
  List<int> get _years => _allBooks.map((b) => int.tryParse(b.year.replaceAll(RegExp(r'\D'), ''))).whereType<int>().toSet().toList()..sort();

  void _clearFilters() {
    setState(() {
      _searchQuery = ""; _searchController.clear();
      _selAuthor = null; _selEditorial = null; _selCountry = null;
      _yearStart = null; _yearEnd = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredBooks;

    return Scaffold(
      appBar: AppBar(
        title: const Text('BibliotecXS SEBIPCA', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: Icon(_showFilters ? Icons.filter_list_off : Icons.filter_list, color: Colors.white),
            onPressed: () => setState(() => _showFilters = !_showFilters),
            tooltip: "Mostrar/Ocultar Filtros",
          ),
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _loadData),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(_showFilters ? 220 : 70),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "Buscar en todos los campos...",
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty ? IconButton(icon: const Icon(Icons.clear), onPressed: () {
                      setState(() { _searchQuery = ""; _searchController.clear(); });
                    }) : null,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  onSubmitted: (val) => setState(() => _searchQuery = val),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),
              if (_showFilters) _buildFiltersSection(),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : filtered.isEmpty
          ? const Center(child: Text("No se encontraron libros con esos criterios."))
          : ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final book = filtered[index];
          return Card(
            elevation: 3,
            margin: const EdgeInsets.symmetric(vertical: 6),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(book.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.indigo))),
                      IconButton(icon: const Icon(Icons.edit, color: Colors.grey), onPressed: () => _openBookDialog(book)),
                    ],
                  ),
                  const Divider(),
                  _rowInfo(Icons.person, "Autor", book.author),
                  _rowInfo(Icons.business, "Editorial", book.editorial),
                  _rowInfo(Icons.calendar_today, "Año", book.year),
                  _rowInfo(Icons.tag, "ISBN", book.isbn),
                  _rowInfo(Icons.category, "Categoría", book.category),
                  _rowInfo(Icons.location_on, "Lugar", "${book.city}, ${book.department}, ${book.country}"),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openBookDialog(),
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      color: Colors.indigo[50],
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _filterDropdown(_authors, _selAuthor, "Autor", (v) => setState(() => _selAuthor = v))),
              const SizedBox(width: 8),
              Expanded(child: _filterDropdown(_editorials, _selEditorial, "Editorial", (v) => setState(() => _selEditorial = v))),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _filterDropdown(_countries, _selCountry, "País", (v) => setState(() => _selCountry = v))),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  children: [
                    Expanded(child: _yearDropdown(_years, _yearStart, "Desde", (v) => setState(() => _yearStart = v))),
                    const Text(" - "),
                    Expanded(child: _yearDropdown(_years, _yearEnd, "Hasta", (v) => setState(() => _yearEnd = v))),
                  ],
                ),
              ),
            ],
          ),
          TextButton(onPressed: _clearFilters, child: const Text("Limpiar Filtros", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  Widget _filterDropdown(List<String> items, String? current, String label, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      value: current,
      decoration: InputDecoration(labelText: label, contentPadding: const EdgeInsets.symmetric(horizontal: 8), border: const OutlineInputBorder()),
      items: [
        const DropdownMenuItem(value: null, child: Text("Cualquiera")),
        ...items.map((e) => DropdownMenuItem(value: e, child: Text(e, overflow: TextOverflow.ellipsis))),
      ],
      onChanged: onChanged,
    );
  }

  Widget _yearDropdown(List<int> items, int? current, String label, ValueChanged<int?> onChanged) {
    return DropdownButtonFormField<int>(
      value: current,
      decoration: InputDecoration(labelText: label, contentPadding: const EdgeInsets.symmetric(horizontal: 4), border: const OutlineInputBorder()),
      items: [
        const DropdownMenuItem(value: null, child: Text("---")),
        ...items.map((e) => DropdownMenuItem(value: e, child: Text(e.toString()))),
      ],
      onChanged: onChanged,
    );
  }

  Widget _rowInfo(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.indigo[300]),
          const SizedBox(width: 8),
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  void _openBookDialog([Book? book]) {
    showDialog(
      context: context,
      builder: (context) => BookFormDialog(book: book, onSave: _loadData),
    );
  }
}

// Diálogo de Formulario
class BookFormDialog extends StatefulWidget {
  final Book? book;
  final VoidCallback onSave;
  const BookFormDialog({super.key, this.book, required this.onSave});
  @override
  State<BookFormDialog> createState() => _BookFormDialogState();
}

class _BookFormDialogState extends State<BookFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _isbnC, _authorC, _titleC, _categoryC, _cityC, _deptC, _countryC, _editorialC, _yearC;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    final b = widget.book;
    _isbnC = TextEditingController(text: b?.isbn);
    _authorC = TextEditingController(text: b?.author);
    _titleC = TextEditingController(text: b?.title);
    _categoryC = TextEditingController(text: b?.category);
    _cityC = TextEditingController(text: b?.city);
    _deptC = TextEditingController(text: b?.department);
    _countryC = TextEditingController(text: b?.country);
    _editorialC = TextEditingController(text: b?.editorial);
    _yearC = TextEditingController(text: b?.year);
  }

  Future<void> _searchIsbn(String isbn) async {
    if (isbn.isEmpty) return;
    setState(() => _isSearching = true);
    final data = await DataService.fetchBookByIsbn(isbn);
    if (data != null) {
      _titleC.text = data['title'] ?? '';
      _authorC.text = data['author'] ?? '';
      _editorialC.text = data['editorial'] ?? '';
      _yearC.text = data['year'] ?? '';
    }
    setState(() => _isSearching = false);
  }

  Future<void> _scanBarcode() async {
    final isbn = await Navigator.push<String>(context, MaterialPageRoute(builder: (_) => const ScannerView()));
    if (isbn != null) { _isbnC.text = isbn; _searchIsbn(isbn); }
  }

  Future<void> _scanOcr() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);
    if (image == null) return;
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("OCR no disponible en Web.")));
      return;
    }
    final inputImage = InputImage.fromFilePath(image.path);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
    for (TextBlock block in recognizedText.blocks) {
      for (TextLine line in block.lines) {
        final text = line.text.replaceAll(RegExp(r'\D'), '');
        if (text.length == 13 || text.length == 10) { _isbnC.text = text; _searchIsbn(text); break; }
      }
    }
    textRecognizer.close();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.book == null ? "Agregar Libro" : "Editar Libro"),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(child: _buildField(_isbnC, "ISBN", true)),
                  IconButton(icon: const Icon(Icons.search, color: Colors.indigo), onPressed: () => _searchIsbn(_isbnC.text), tooltip: "Buscar manual"),
                  IconButton(icon: const Icon(Icons.qr_code_scanner), onPressed: _scanBarcode),
                  IconButton(icon: const Icon(Icons.camera_alt), onPressed: _scanOcr),
                ],
              ),
              if (_isSearching) const LinearProgressIndicator(),
              _buildField(_titleC, "Título"),
              _buildField(_authorC, "Autor"),
              _buildField(_categoryC, "Categoría"),
              _buildField(_editorialC, "Editorial"),
              _buildField(_yearC, "Año"),
              const Divider(),
              _buildField(_cityC, "Ciudad"),
              _buildField(_deptC, "Departamento"),
              _buildField(_countryC, "País"),
            ],
          ),
        ),
      ),
      actions: [
        if (widget.book != null)
          TextButton(onPressed: () async {
            await DataService.deleteBook(widget.book!.id!);
            widget.onSave(); Navigator.pop(context);
          }, child: const Text("Eliminar", style: TextStyle(color: Colors.red))),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
        ElevatedButton(onPressed: _save, child: const Text("Guardar")),
      ],
    );
  }

  Widget _buildField(TextEditingController controller, String label, [bool isNumber = false]) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(labelText: label),
      // validator: (v) => v!.isEmpty ? "Requerido" : null,
    );
  }

  void _save() async {
    if (_formKey.currentState!.validate()) {
      final b = Book(id: widget.book?.id, isbn: _isbnC.text, author: _authorC.text, title: _titleC.text, category: _categoryC.text, city: _cityC.text, department: _deptC.text, country: _countryC.text, editorial: _editorialC.text, year: _yearC.text);
      await DataService.upsertBook(b);
      widget.onSave(); Navigator.pop(context);
    }
  }
}

// Vista de Escaneo
class ScannerView extends StatelessWidget {
  const ScannerView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Escanear")),
      body: MobileScanner(
        onDetect: (capture) {
          if (capture.barcodes.isNotEmpty && capture.barcodes.first.rawValue != null) {
            Navigator.pop(context, capture.barcodes.first.rawValue);
          }
        },
      ),
    );
  }
}
