import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'views/home_screen.dart';

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