import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

Future<File> guardarJsonLocal(String contenido) async {
  final directorio = await getApplicationDocumentsDirectory();
  final archivo = File('${directorio.path}/himnos.json');
  return archivo.writeAsString(contenido);
}


Future<String?> leerJsonLocal() async {
  try {
    final directorio = await getApplicationDocumentsDirectory();
    final archivo = File('${directorio.path}/himnos.json');
    if (await archivo.exists()) {
      return await archivo.readAsString();
    }
  } catch (e) {
    print("Error leyendo archivo local: $e");
  }
  return null;
}


Future<void> actualizarJsonDesdeGithub() async {
  final urlGithub = Uri.parse(
      'https://raw.githubusercontent.com/Danel20/MusicaLXS/refs/heads/main/himnos.json');

  try {
    // 1. Leer datos locales
    final localString = await leerJsonLocal();
    Map<String, dynamic> localJson = {};
    if (localString != null) {
      localJson = jsonDecode(localString);
    }

    // 2. Descargar datos de GitHub
    final respuesta = await http.get(urlGithub);
    if (respuesta.statusCode == 200) {
      final remotoJson = jsonDecode(respuesta.body);

      // 3. Fusionar himnos (sin duplicar)
      final localHimnos = (localJson['himnos'] ?? []) as List<dynamic>;
      final remotoHimnos = (remotoJson['himnos'] ?? []) as List<dynamic>;

      // usamos un Set para evitar duplicados por "tema"
      final temasLocales = localHimnos
          .whereType<Map<String, dynamic>>()
          .map((h) => h['tema'])
          .toSet();

      for (var himno in remotoHimnos) {
        if (!temasLocales.contains(himno['tema'])) {
          localHimnos.add(himno);
        }
      }

      // reconstruir el JSON final
      final nuevoJson = {
        'categorias': remotoJson['categorias'],
        'fecha': remotoJson['fecha'],
        'himnos': localHimnos,
      };

      // 4. Guardar en local
      await guardarJsonLocal(jsonEncode(nuevoJson));
      print("JSON actualizado y guardado localmente ✅");
    } else {
      print('Error al obtener JSON remoto: ${respuesta.statusCode}');
    }
  } catch (e) {
    print("Error actualizando JSON: $e");
  }
}

void main() async {
  await actualizarJsonDesdeGithub();  // descarga y fusiona
  final datos = await leerJsonLocal(); // lee lo guardado
  print(datos); // aquí tienes el JSON listo
}