import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:udp/udp.dart';

void main() {
  runApp(const TalkbackApp());
}

class TalkbackApp extends StatelessWidget {
  const TalkbackApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Talkback LAN',
      home: TalkbackPage(),
    );
  }
}

class TalkbackPage extends StatefulWidget {
  @override
  State<TalkbackPage> createState() => _TalkbackPageState();
}

class _TalkbackPageState extends State<TalkbackPage> {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  UDP? _udpSender;
  UDP? _udpReceiver;
  bool isTransmitting = false;
  bool isReceiving = false;
  static const int PORT = 50001;

  @override
  void initState() {
    super.initState();
    _player.openPlayer();
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    _player.closePlayer();
    _udpSender?.close();
    _udpReceiver?.close();
    super.dispose();
  }

  Future<void> startTransmitting() async {
    await Permission.microphone.request();
    if (!(await _recorder.isEncoderSupported(codec: Codec.pcm16))) {
      throw Exception("PCM16 not supported");
    }

    _udpSender = await UDP.bind(Endpoint.any(port: Port(0)));

    await _recorder.openRecorder();
    await _recorder.startRecorder(
      codec: Codec.pcm16,
      sampleRate: 16000,
      numChannels: 1,
      bitRate: 16000 * 2,
      toStream: (buffer) async {
        if (buffer != null) {
          _udpSender?.send(
            buffer,
            Endpoint.broadcast(port: Port(PORT)),
          );
        }
      },
    );

    setState(() => isTransmitting = true);
  }

  Future<void> stopTransmitting() async {
    await _recorder.stopRecorder();
    await _udpSender?.close();
    _udpSender = null;
    setState(() => isTransmitting = false);
  }

  Future<void> startReceiving() async {
    _udpReceiver = await UDP.bind(Endpoint.any(port: Port(PORT)));

    _udpReceiver?.asStream().listen((datagram) {
      if (datagram != null) {
        _player.startPlayer(
          fromDataBuffer: datagram.data,
          codec: Codec.pcm16,
          sampleRate: 16000,
          numChannels: 1,
        );
      }
    });

    setState(() => isReceiving = true);
  }

  Future<void> stopReceiving() async {
    await _udpReceiver?.close();
    _udpReceiver = null;
    setState(() => isReceiving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Talkback LAN'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            ElevatedButton.icon(
              icon: Icon(isTransmitting ? Icons.mic_off : Icons.mic),
              label: Text(isTransmitting ? 'Detener Transmisión' : 'Transmitir'),
              onPressed: () {
                isTransmitting ? stopTransmitting() : startTransmitting();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isTransmitting ? Colors.red : Colors.green,
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              icon: Icon(isReceiving ? Icons.hearing_disabled : Icons.headphones),
              label: Text(isReceiving ? 'Detener Recepción' : 'Escuchar'),
              onPressed: () {
                isReceiving ? stopReceiving() : startReceiving();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isReceiving ? Colors.red : Colors.blue,
              ),
            ),
            SizedBox(height: 40),
            Text(
              'Conecta todos los dispositivos a la misma red WiFi (zona portátil también funciona)',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
