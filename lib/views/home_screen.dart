import 'package:flutter/material.dart';
import '../models/book_model.dart';
import '../services/data_service.dart';
import 'book_form_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  String? _selAuthor, _selEditorial, _selCountry;
  int? _yearStart, _yearEnd;
  bool _showFilters = false;

  List<Book> _applyFilters(List<Book> books) {
    return books.where((b) {
      final matchesSearch = b.contains(_searchQuery);
      final matchesAuthor = _selAuthor == null || b.authors.any((a) => a.fullName == _selAuthor);
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

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Book>>(
      stream: DataService.booksStream,
      builder: (context, booksSnapshot) {
        final allBooks = booksSnapshot.data ?? [];
        final filtered = _applyFilters(allBooks);

        // Generación de filtros dinámicos basados en la data real
        final authors = allBooks.expand((b) => b.authors.map((a) => a.fullName)).where((s) => s.isNotEmpty).toSet().toList()..sort();
        final editorials = allBooks.map((b) => b.editorial).where((s) => s.isNotEmpty).toSet().toList()..sort();
        final countries = allBooks.map((b) => b.country).where((s) => s.isNotEmpty).toSet().toList()..sort();
        final years = allBooks.map((b) => int.tryParse(b.year.replaceAll(RegExp(r'\D'), ''))).whereType<int>().toSet().toList()..sort();

        return StreamBuilder<List<String>>(
          stream: DataService.categoriesStream,
          builder: (context, catsSnapshot) {
            final customCategories = catsSnapshot.data ?? [];

            return Scaffold(
              appBar: AppBar(
                title: const Text('BibliotecXS SEBIPCA', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                backgroundColor: Colors.indigo,
                actions: [
                  IconButton(
                    icon: Icon(_showFilters ? Icons.filter_list_off : Icons.filter_list, color: Colors.white),
                    onPressed: () => setState(() => _showFilters = !_showFilters),
                  ),
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
                            hintText: "Buscar en tiempo real...",
                            prefixIcon: const Icon(Icons.search),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                          onChanged: (val) => setState(() => _searchQuery = val),
                        ),
                      ),
                      if (_showFilters) _buildFiltersSection(authors, editorials, countries, years),
                    ],
                  ),
                ),
              ),
              body: booksSnapshot.connectionState == ConnectionState.waiting
                  ? const Center(child: CircularProgressIndicator())
                  : filtered.isEmpty
                  ? const Center(child: Text("No se encontraron registros."))
                  : ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final book = filtered[index];
                  return Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      title: Text(book.title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                      subtitle: Text("${book.authors.map((a) => a.fullName).join(', ')} • ${book.editorial} (${book.year})"),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _openBookDialog(allBooks, customCategories, book),
                      ),
                    ),
                  );
                },
              ),
              floatingActionButton: FloatingActionButton(
                backgroundColor: Colors.indigo,
                child: const Icon(Icons.add, color: Colors.white),
                onPressed: () => _openBookDialog(allBooks, customCategories),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFiltersSection(List<String> authors, List<String> editorials, List<String> countries, List<int> years) {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.indigo[50],
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _dropdown(authors, _selAuthor, "Autor", (v) => setState(() => _selAuthor = v))),
              const SizedBox(width: 8),
              Expanded(child: _dropdown(editorials, _selEditorial, "Editorial", (v) => setState(() => _selEditorial = v))),
            ],
          ),
          Row(
            children: [
              Expanded(child: _dropdown(countries, _selCountry, "País", (v) => setState(() => _selCountry = v))),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  children: [
                    Expanded(child: _dropdown(years.map((e) => e.toString()).toList(), _yearStart?.toString(), "Desde", (v) => setState(() => _yearStart = int.tryParse(v ?? '')))),
                    const Text(" - "),
                    Expanded(child: _dropdown(years.map((e) => e.toString()).toList(), _yearEnd?.toString(), "Hasta", (v) => setState(() => _yearEnd = int.tryParse(v ?? '')))),
                  ],
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _dropdown(List<String> items, String? current, String label, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      value: current,
      decoration: InputDecoration(labelText: label),
      items: [const DropdownMenuItem(value: null, child: Text("Todos")), ...items.map((e) => DropdownMenuItem(value: e, child: Text(e, overflow: TextOverflow.ellipsis)))],
      onChanged: onChanged,
    );
  }

  void _openBookDialog(List<Book> currentBooks, List<String> databaseCategories, [Book? book]) {
    showDialog(
      context: context,
      builder: (context) => BookFormDialog(book: book, currentBooks: currentBooks, databaseCategories: databaseCategories),
    );
  }
}