import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:musicalxs/globals/globals.dart';
import 'package:musicalxs/widgets/NeonGlowButton.dart';
import 'package:musicalxs/widgets/PantallaConTabs.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await cargarDatos();
  await cargarListas();
  runApp(const MusicaLXS());
}

// PANTALLA PRINCIPAL
class MusicaLXS extends StatefulWidget {
  const MusicaLXS({super.key});

  @override
  State<MusicaLXS> createState() => _MusicaLXSState();
}

class _MusicaLXSState extends State<MusicaLXS> {
  @override
  void initState() {
    super.initState();
    _cargarPreferencias();
  }
  
  Future<void> _cargarPreferencias() async {
    final pref = await SharedPreferences.getInstance();
    final isDark = pref.getBool('tema_oscuro') ?? false;
    final colorIndex = pref.getInt('color_etiqueta') ?? 9;
    setState(() {
      themeMode1 = isDark ? ThemeMode.dark : ThemeMode.light;
      etiquetaColor = coloresEtiqueta1[colorIndex];
      textColor1 = colorIndex % 2 == 1 ? Colors.white : Colors.black;
    });
  }
  
  Future<void> cambiarTema(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tema_oscuro', mode == ThemeMode.dark);
    setState(() => themeMode1 = mode);
  }
  
  Future<void> cambiarColorEtiqueta(Color color) async {
    final prefs = await SharedPreferences.getInstance();
    final index = coloresEtiqueta1.indexOf(color);
    await prefs.setInt('color_etiqueta', index);
    setState(() {
      etiquetaColor = color;
      textColor1 = index % 2 == 1 ? Colors.white : Colors.black;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MusicaL XS',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode1,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: MusicaLXSApp(
        cambiarTema: cambiarTema, 
        cambiarColorEtiqueta: cambiarColorEtiqueta,
      ),
    );
  }
}

class MusicaLXSApp extends StatefulWidget {
  final Function(ThemeMode) cambiarTema;
  final Function(Color) cambiarColorEtiqueta;
  
  const MusicaLXSApp({
    super.key,
    required this.cambiarTema,
    required this.cambiarColorEtiqueta,
  });
  
  @override
  State<MusicaLXSApp> createState() => _MusicaLXSAppState();
}

class _MusicaLXSAppState extends State<MusicaLXSApp> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          heroSection(context),
        ],
      ),
    );
  }

  Widget heroSection(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Container(
      height: size.height,
      width: size.width,
      padding: const EdgeInsets.all(30),
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/yoututosjeffewr325342.png'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(Colors.black45, BlendMode.darken),
        ),
      ),
      child: Center(
        child: Flex(
          direction: Axis.vertical,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Flexible(
              child: Image(
                image: AssetImage("assets/icon/MusicaLXS_Negativo.png"), 
                width: 300, 
                height: 300, 
                fit: BoxFit.contain,
              )
            ),
            ZoomIn(
              duration: const Duration(milliseconds: 500),
              delay: const Duration(milliseconds: 1500),
              child: const Text(
                'Donde lo musical es para tod@s, lo musical es para tí',
                style: TextStyle(
                  fontFamily: 'FRSCRIPT',
                  fontSize: 36,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      offset: Offset(1.5, 1.5),
                      blurRadius: 2.0,
                      color: Colors.black,
                    ),
                  ],
                ), 
                textAlign: TextAlign.center,
              ),
            ),
            BounceInUp(
              duration: const Duration(milliseconds: 500),
              delay: const Duration(milliseconds: 2000),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.white, Colors.white],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.white,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: NeonGlowButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        transitionDuration: const Duration(milliseconds: 300),
                        pageBuilder: (context, animation, secondaryAnimation) =>
                          PantallaConTabs(
                            cambiarTema: widget.cambiarTema, 
                            cambiarColorEtiqueta: widget.cambiarColorEtiqueta,
                          ),
                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
                          final curved = CurvedAnimation(
                            parent: animation, 
                            curve: Curves.easeInOut,
                          );
                          return ScaleTransition(
                            scale: curved,
                            child: FadeTransition(
                              opacity: curved,
                              child: child,
                            ),
                          );
                        },
                      ),
                    );
                  },
                  icon: Icons.explore,
                  label: 'Explorar Himnos',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
