Quiero una batería interactiva hecha en flutter. La pantalla principal debe tener 2 botones.
1. Batería interactiva (Debe contener una batería con cada elemento que al presionarlo genere el sonido correspondiente)
2. Aprende (Que contenga la misma batería interactiva pero que además, arriba aparezcan patrones de ritmos que al elegirlos, muestren en la bateria los golpes ilutrados en el patrón)

Genérame ese código.
ChatGPT dijo:

¡Genial! Vamos a crear una app de batería interactiva en Flutter con dos pantallas:
🥁 Funcionalidades:
Pantalla principal:

    Botón "Batería Interactiva"

    Botón "Aprende"

Pantalla "Batería Interactiva":

    Imagen de batería con zonas presionables (platillo, bombo, caja, etc.)

    Al presionar, suena el audio correspondiente.

Pantalla "Aprende":

    Misma batería interactiva

    Arriba: lista de ritmos predefinidos

    Al elegir uno: los golpes se ilustran en la batería (p.ej. parpadeos, animaciones)

📁 Archivos necesarios:

lib/
├── main.dart
├── screens/
│   ├── home_screen.dart
│   ├── drum_screen.dart
│   └── learn_screen.dart
├── widgets/
│   ├── drum_pad.dart
│   └── rhythm_selector.dart
assets/
├── images/
│   ├── drum_set.png
├── audio/
│   ├── kick.wav
│   ├── snare.wav
│   ├── hihat.wav
│   └── ...otros sonidos

🧱 Dependencias

En pubspec.yaml:

dependencies:
  flutter:
    sdk: flutter
  audioplayers: ^5.2.1
  flutter_animate: ^4.3.0

flutter:
  assets:
    - assets/audio/
    - assets/images/

✅ main.dart

import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const DrumApp());
}

class DrumApp extends StatelessWidget {
  const DrumApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Batería Interactiva',
      theme: ThemeData.dark(),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

✅ screens/home_screen.dart

import 'package:flutter/material.dart';
import 'drum_screen.dart';
import 'learn_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Batería Interactiva')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              child: const Text('Batería Interactiva'),
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const DrumScreen()));
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              child: const Text('Aprende'),
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const LearnScreen()));
              },
            ),
          ],
        ),
      ),
    );
  }
}

✅ widgets/drum_pad.dart

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class DrumPad extends StatelessWidget {
  final String label;
  final String sound;
  final double left;
  final double top;
  final double size;
  final bool highlight;

  const DrumPad({
    super.key,
    required this.label,
    required this.sound,
    required this.left,
    required this.top,
    this.size = 60,
    this.highlight = false,
  });

  void playSound() {
    final player = AudioPlayer();
    player.play(AssetSource('audio/$sound'));
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        onTap: playSound,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: highlight ? Colors.amber : Colors.white.withOpacity(0.1),
            border: Border.all(color: Colors.white),
          ),
          child: Center(child: Text(label, style: const TextStyle(fontSize: 12))),
        ),
      ),
    );
  }
}

✅ screens/drum_screen.dart

import 'package:flutter/material.dart';
import '../widgets/drum_pad.dart';

class DrumScreen extends StatelessWidget {
  const DrumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Batería Interactiva')),
      body: Stack(
        children: [
          Center(child: Image.asset('assets/images/drum_set.png')),
          // Posiciona pads sobre partes del instrumento
          DrumPad(label: 'Kick', sound: 'kick.wav', left: 160, top: 300),
          DrumPad(label: 'Snare', sound: 'snare.wav', left: 100, top: 240),
          DrumPad(label: 'Hi-Hat', sound: 'hihat.wav', left: 220, top: 180),
          // Añade más pads según necesites
        ],
      ),
    );
  }
}

✅ screens/learn_screen.dart

import 'package:flutter/material.dart';
import '../widgets/drum_pad.dart';

class Rhythm {
  final String name;
  final List<String> sequence; // Ej: ['Kick', 'Snare', 'Hi-Hat', 'Kick']

  Rhythm(this.name, this.sequence);
}

class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key});

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  Rhythm? selectedRhythm;
  final rhythms = [
    Rhythm('Ritmo 4/4 Básico', ['Kick', 'Hi-Hat', 'Snare', 'Hi-Hat']),
    Rhythm('Rock Básico', ['Kick', 'Kick', 'Snare', 'Hi-Hat']),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Aprende Ritmos')),
      body: Column(
        children: [
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: rhythms.length,
              itemBuilder: (context, index) {
                final rhythm = rhythms[index];
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    child: Text(rhythm.name),
                    onPressed: () {
                      setState(() {
                        selectedRhythm = rhythm;
                      });
                      playRhythm(rhythm);
                    },
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                Center(child: Image.asset('assets/images/drum_set.png')),
                DrumPad(
                  label: 'Kick',
                  sound: 'kick.wav',
                  left: 160,
                  top: 300,
                  highlight: selectedRhythm?.sequence.contains('Kick') ?? false,
                ),
                DrumPad(
                  label: 'Snare',
                  sound: 'snare.wav',
                  left: 100,
                  top: 240,
                  highlight: selectedRhythm?.sequence.contains('Snare') ?? false,
                ),
                DrumPad(
                  label: 'Hi-Hat',
                  sound: 'hihat.wav',
                  left: 220,
                  top: 180,
                  highlight: selectedRhythm?.sequence.contains('Hi-Hat') ?? false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void playRhythm(Rhythm rhythm) async {
    for (var hit in rhythm.sequence) {
      switch (hit) {
        case 'Kick':
          DrumPad(label: 'Kick', sound: 'kick.wav', left: 0, top: 0).playSound();
          break;
        case 'Snare':
          DrumPad(label: 'Snare', sound: 'snare.wav', left: 0, top: 0).playSound();
          break;
        case 'Hi-Hat':
          DrumPad(label: 'Hi-Hat', sound: 'hihat.wav', left: 0, top: 0).playSound();
          break;
      }
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }
}

🔉 Audios y 📷 Imágenes

Asegúrate de colocar tus audios en assets/audio/:

    kick.wav, snare.wav, hihat.wav, etc.

Y tu imagen base de batería en assets/images/drum_set.png.

¿Quieres que te empaquete todo esto en un .zip de proyecto completo o prefieres que agreguemos funcionalidades como grabación, metrónomo, o animaciones de luces?