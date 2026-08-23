import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

void main() {
  runApp(const AVPlayerApp());
}

class AVPlayerApp extends StatelessWidget {
  const AVPlayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AVPlayer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF05070C),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4C4CFF),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const PlayerPage(),
    );
  }
}

class PlayerPage extends StatefulWidget {
  const PlayerPage({super.key});

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  VideoPlayerController? _controller;
  String? _fileName;
  String _subtitle = '';
  bool _loading = false;
  String _backendUrl = 'http://10.0.2.2:3000';

  Future<void> _openMedia() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'mp4', 'm4v', 'mov', 'webm', 'avi', 'mkv',
        'mp3', 'm4a', 'aac', 'wav', 'flac'
      ],
    );
    if (result == null || result.files.single.path == null) return;

    final path = result.files.single.path!;
    final old = _controller;
    final controller = VideoPlayerController.file(File(path));
    setState(() {
      _controller = controller;
      _fileName = result.files.single.name;
      _subtitle = '';
    });
    await old?.dispose();

    try {
      await controller.initialize();
      if (!mounted) return;
      setState(() {});
      await controller.play();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Format media tidak dapat diputar: $e')),
      );
    }
  }

  Future<void> _openSubtitle() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['srt', 'vtt'],
    );
    if (result == null || result.files.single.path == null) return;
    final text = await File(result.files.single.path!).readAsString();
    setState(() => _subtitle = _stripSrt(text));
  }

  String _stripSrt(String input) {
    final lines = input.replaceAll('\r', '').split('\n');
    final out = <String>[];
    for (final line in lines) {
      if (RegExp(r'^\d+$').hasMatch(line.trim())) continue;
      if (line.contains('-->')) continue;
      if (line.trim().isEmpty) {
        if (out.isNotEmpty && out.last.isNotEmpty) out.add('');
      } else {
        out.add(line.trim());
      }
    }
    return out.join('\n').trim();
  }

  Future<void> _aiSubtitle() async {
    if (_fileName == null) {
      _toast('Buka video/audio terlebih dahulu.');
      return;
    }
    setState(() => _loading = true);
    try {
      // Foundation endpoint. The included backend accepts multipart media.
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_backendUrl/subtitle'),
      );
      final controller = _controller;
      if (controller != null && controller.dataSourceType == DataSourceType.file) {
        final path = controller.dataSource;
        if (path != null && path.isNotEmpty) {
          request.files.add(await http.MultipartFile.fromPath('media', path));
        }
      }
      request.fields['target_language'] = 'id';
      final response = await request.send();
      final body = await response.stream.bytesToString();
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(body) as Map<String, dynamic>;
        setState(() => _subtitle = (data['subtitle'] ?? '').toString());
      } else {
        _toast('Backend AI belum tersedia (${response.statusCode}).');
      }
    } catch (_) {
      _toast('Tidak dapat terhubung ke backend AI.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _settings() async {
    final controller = TextEditingController(text: _backendUrl);
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('AI Backend'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'URL backend',
            hintText: 'http://192.168.1.10:3000',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              setState(() => _backendUrl = controller.text.trim());
              Navigator.pop(context);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _toast(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 12,
        title: Row(
          children: [
            Image.asset('assets/avplayer_logo.png', width: 42, height: 42),
            const SizedBox(width: 10),
            const Text('AVPlayer', style: TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
        actions: [
          IconButton(onPressed: _settings, icon: const Icon(Icons.settings)),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              color: Colors.black,
              child: c != null && c.value.isInitialized
                  ? Center(
                      child: AspectRatio(
                        aspectRatio: c.value.aspectRatio,
                        child: Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            VideoPlayer(c),
                            if (_subtitle.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(18, 8, 18, 42),
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: .72),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 7),
                                    child: Text(
                                      _subtitle,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            VideoProgressIndicator(c, allowScrubbing: true),
                          ],
                        ),
                      ),
                    )
                  : const Center(
                      child: Icon(Icons.play_circle_outline, size: 90, color: Colors.white24),
                    ),
            ),
          ),
          if (_fileName != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _fileName!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: _openMedia,
                  icon: const Icon(Icons.folder_open),
                  label: const Text('Buka Media'),
                ),
                OutlinedButton.icon(
                  onPressed: _openSubtitle,
                  icon: const Icon(Icons.subtitles),
                  label: const Text('SRT/VTT'),
                ),
                FilledButton.tonalIcon(
                  onPressed: _loading ? null : _aiSubtitle,
                  icon: _loading
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.auto_awesome),
                  label: const Text('AI Indonesia'),
                ),
                if (c != null)
                  IconButton.filledTonal(
                    onPressed: () => c.value.isPlaying ? c.pause() : c.play(),
                    icon: Icon(c.value.isPlaying ? Icons.pause : Icons.play_arrow),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
