import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io' as io show File, Directory, Platform;

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:collection/collection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart' show rootBundle, HapticFeedback, PlatformException;


import 'package:miflutterapp0/globals/globals.dart';

// 👇 Este import SOLO se usa en web, por eso el ignore
// ignore: avoid_web_libraries_in_flutter
/*
import 'dart:html' 
    if (dart.library.io) 'html_stub.dart' as html;
*/

class _OpcionPrincipal {
  final IconData icono;
  final String texto;
  final Color color;

  _OpcionPrincipal({
    required this.icono,
    required this.texto,
    required this.color,
  });
}

// ESTE ES EL BOTÓN DE LA PANTALLA PRINCIPAL
class NeonGlowButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String label;
  final IconData icon;

  NeonGlowButton({
    Key? key,
    required this.onPressed,
    required this.label,
    required this.icon,
  }) : super(key: key);

  @override
  State<NeonGlowButton> createState() => _NeonGlowButtonState();
}

class _NeonGlowButtonState extends State<NeonGlowButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glow;
  late Animation<Color?> _colorAnimation;

  final List<Color> neonColors = [
    Colors.cyanAccent,
    Colors.pinkAccent,
    Colors.blueAccent,
    Colors.greenAccent,
    Colors.orangeAccent,
    Colors.purpleAccent,
  ];

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 5),
    )..repeat(reverse: true);

    _glow = Tween<double>(begin: 5.0, end: 20.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _colorAnimation = _controller.drive(
      TweenSequence<Color?>(
        List.generate(neonColors.length, (index) {
          final color = neonColors[index];
          final next = neonColors[(index + 1) % neonColors.length];
          return TweenSequenceItem(
            tween: ColorTween(begin: color, end: next),
            weight: 1.0,
          );
        }),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final currentColor = _colorAnimation.value ?? Colors.black;

        /*
        ESTO ES SI QUIERO USAR UN COLOR INVERTIDO
        final invertedColor = Color.fromARGB(
          currentColor.alpha,
          255 - currentColor.red,
          255 - currentColor.green,
          255 - currentColor.blue,
        );
        */
        
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: currentColor.withOpacity(0.9),
                blurRadius: _glow.value,
                spreadRadius: 1,
              ),
            ],
          ),
          child: ElevatedButton.icon(
            onPressed: widget.onPressed,
            icon: Icon(widget.icon, color: Colors.white, size: 16, shadows: [
              Shadow(
                offset: Offset(1, 1),
                blurRadius: 2.0,
                color: Colors.black,
              ),
              /*
              Shadow(
                offset: Offset(-1, -1),
                blurRadius: 2.0,
                color: Colors.black,
              ),
              Shadow(
                offset: Offset(1, -1),
                blurRadius: 2.0,
                color: Colors.black,
              ),
              Shadow(
                offset: Offset(-1, 1),
                blurRadius: 2.0,
                color: Colors.black,
              ),
              */
            ]),
            label: Text(
              widget.label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                shadows: [
                  Shadow(
                    offset: Offset(1, 1),
                    blurRadius: 2.0,
                    color: Colors.black,
                  ),
                  /*
                  Shadow(
                    offset: Offset(-1, -1),
                    blurRadius: 2.0,
                    color: Colors.black,
                  ),
                  Shadow(
                    offset: Offset(1, -1),
                    blurRadius: 2.0,
                    color: Colors.black,
                  ),
                  Shadow(
                    offset: Offset(-1, 1),
                    blurRadius: 2.0,
                    color: Colors.black,
                  ),
                  */
                ],
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              side: BorderSide(color: currentColor, width: 2),
              padding: EdgeInsets.symmetric(horizontal: 25, vertical: 15),
            ),
          ),
        );
      },
    );
  }
}