import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';

// --- ¡ACCIÓN REQUERIDA! Pega tus claves de Supabase aquí ---
const String supabaseUrl = 'https://cowlzvzzaxtnwcndewvk.supabase.co';
const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNvd2x6dnp6YXh0bndjbmRld3ZrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTY2Njc1NTQsImV4cCI6MjA3MjI0MzU1NH0.Euexl0MFiOdskByfRKf2in5iZ14gVA_iTs4lokIAKCA';

Future<void> main() async {
  // Necesario para asegurar que los Widgets estén listos
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa Supabase antes de correr la app
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );
  runApp(const MonkeyTvApp());
}

// Obtén la instancia de Supabase para usarla en la app
final supabase = Supabase.instance.client;

class MonkeyTvApp extends StatelessWidget {
  const MonkeyTvApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Monkey TV',
      theme: ThemeData.dark(),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Future que obtendrá los datos de la tabla 'canales'
  // y también traerá el 'nombre' de la tabla 'categorias' relacionada
  final _future = supabase
      .from('canales')
      .select('*, categorias(nombre)');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Monkey TV')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No hay canales. Añade algunos en tu panel de Supabase."));
          }

          final canales = snapshot.data!;
          return GridView.builder(
            padding: const EdgeInsets.all(8.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.75,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: canales.length,
            itemBuilder: (context, index) {
              final canal = canales[index];
              final categoria = canal['categorias'];

              return GestureDetector(
                onTap: () {
                  if (canal['stream_url'] != null) {
                     Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => VideoPlayerScreen(streamUrl: canal['stream_url']),
                      ),
                    );
                  }
                },
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Image.network(
                          canal['logo_url'],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.tv_off, size: 40, color: Colors.grey),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6.0),
                        color: Colors.black.withOpacity(0.5),
                        child: Column(
                          children: [
                            Text(
                              canal['nombre'],
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (categoria != null)
                            Text(
                              categoria['nombre'],
                              style: TextStyle(color: Colors.grey.shade400, fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// La pantalla del reproductor de video (no necesita cambios)
class VideoPlayerScreen extends StatefulWidget {
  final String streamUrl;
  const VideoPlayerScreen({super.key, required this.streamUrl});
  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;
  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.streamUrl))
      ..initialize().then((_) => setState(() {}));
    _controller.play();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: _controller.value.isInitialized
            ? AspectRatio(aspectRatio: _controller.value.aspectRatio, child: VideoPlayer(_controller))
            : const CircularProgressIndicator(),
      ),
    );
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}