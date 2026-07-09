import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class ScannerView extends StatefulWidget {
  const ScannerView({super.key});

  @override
  State<ScannerView> createState() => _ScannerViewState();
}

class _ScannerViewState extends State<ScannerView> {
  CameraController? _cameraController;
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  bool _isProcessing = false;
  bool _isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    // Seleccionamos la cámara trasera principal
    _cameraController = CameraController(
      cameras.first,
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await _cameraController!.initialize();
      if (mounted) {
        setState(() => _isCameraInitialized = true);
      }
    } catch (e) {
      debugPrint("Error inicializando cámara: $e");
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _textRecognizer.close();
    super.dispose();
  }

  // Lógica de captura y reconocimiento de ISBN
  Future<void> _captureAndScan() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized || _isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      // Capturar la fotografía
      final XFile photo = await _cameraController!.takePicture();
      final inputImage = InputImage.fromFilePath(photo.path);

      // Procesar texto mediante Google ML Kit
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);

      // Expresión regular flexible para capturar formatos ISBN-10 e ISBN-13 (con o sin guiones)
      final RegExp isbnRegex = RegExp(
          r'\b(?:97[89][- ]?)?(?:\d[- ]?){9}[\dX]\b',
          caseSensitive: false
      );

      String? detectedIsbn;

      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          if (isbnRegex.hasMatch(line.text)) {
            final match = isbnRegex.firstMatch(line.text);
            if (match != null) {
              detectedIsbn = match.group(0);
              break;
            }
          }
        }
        if (detectedIsbn != null) break;
      }

      if (detectedIsbn != null) {
        // Limpiar espacios extras del string final si los hubiera
        if (mounted) Navigator.pop(context, detectedIsbn.trim());
      } else {
        setState(() => _isProcessing = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("No se detectó un ISBN válido. Intente enfocar mejor el código de barras o texto."),
              backgroundColor: Colors.amber,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      debugPrint("Error al escanear: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Escanear código ISBN"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // 1. Vista de cámara centrada y recortada de manera estética (No pantalla completa desproporcionada)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: AspectRatio(
                aspectRatio: _cameraController!.value.aspectRatio,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: CameraPreview(_cameraController!),
                ),
              ),
            ),
          ),

          // 2. Capa superior: Visor guía de escaneo
          IgnorePointer(
            child: Center(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.75,
                height: 160,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.indigo, width: 3),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.transparent,
                ),
              ),
            ),
          ),

          // 3. Texto informativo flotante
          Positioned(
            top: 40,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                "Enfoque el código de barras o el número de ISBN impreso dentro del recuadro central.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ),

          // 4. Indicador de carga
          if (_isProcessing)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Colors.indigo),
                      SizedBox(height: 16),
                      Text("Analizando imagen...", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      // 5. Botón de captura estilizado en la parte inferior
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.indigo,
        onPressed: _isProcessing ? null : _captureAndScan,
        icon: const Icon(Icons.camera_alt, color: Colors.white),
        label: const Text("Capturar y procesar", style: TextStyle(color: Colors.white)),
      ),
    );
  }
}