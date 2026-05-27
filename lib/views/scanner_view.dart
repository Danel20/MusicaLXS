import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScannerView extends StatelessWidget {
  const ScannerView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Escanear Código de Barras")),
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