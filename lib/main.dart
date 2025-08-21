import 'dart:math';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:video_player/video_player.dart';

void main() {
  runApp(VideokeApp());
}

class VideokeApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Videoke App',
      home: VideokeHome(),
    );
  }
}

class VideokeHome extends StatefulWidget {
  @override
  _VideokeHomeState createState() => _VideokeHomeState();
}

class _VideokeHomeState extends State<VideokeHome> {
  List<PlatformFile> selectedFiles = [];
  List<PlatformFile> reservationQueue = [];
  VideoPlayerController? _controller;
  int currentIndex = 0;
  TextEditingController codeController = TextEditingController();

  void pickFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: true,
    );
    if (result != null) {
      setState(() {
        selectedFiles = result.files;
        reservationQueue = List.from(selectedFiles);
        currentIndex = 0;
        _initializePlayer();
      });
    }
  }

  void _initializePlayer() {
    if (reservationQueue.isNotEmpty) {
      _controller?.dispose();
      _controller = VideoPlayerController.file(
        reservationQueue[currentIndex].path != null
            ? File(reservationQueue[currentIndex].path!)
            : File(""),
      )
        ..initialize().then((_) {
          setState(() {});
          _controller?.play();
        })
        ..setLooping(false)
        ..addListener(() {
          if (_controller!.value.position >= _controller!.value.duration &&
              !_controller!.value.isPlaying) {
            _showScore();
            _nextSong();
          }
        });
    }
  }

  void _showScore() {
    int score = Random().nextInt(101);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Your Score"),
        content: Text("You scored $score points!"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK"),
          )
        ],
      ),
    );
  }

  void _nextSong() {
    if (currentIndex < reservationQueue.length - 1) {
      setState(() {
        currentIndex++;
        _initializePlayer();
      });
    }
  }

  void _previousSong() {
    if (currentIndex > 0) {
      setState(() {
        currentIndex--;
        _initializePlayer();
      });
    }
  }

  void _skipSong() {
    _nextSong();
  }

  void _pauseOrPlay() {
    setState(() {
      if (_controller?.value.isPlaying ?? false) {
        _controller?.pause();
      } else {
        _controller?.play();
      }
    });
  }

  void _reserveSong(String code) {
    final match = selectedFiles.firstWhere(
      (file) => file.name.startsWith(code),
      orElse: () => PlatformFile(name: "", size: 0),
    );
    if (match.name.isNotEmpty) {
      setState(() {
        reservationQueue.add(match);
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Videoke App"),
      ),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: pickFiles,
            child: Text("Pick MP4 Files"),
          ),
          if (_controller != null && _controller!.value.isInitialized)
            AspectRatio(
              aspectRatio: _controller!.value.aspectRatio,
              child: VideoPlayer(_controller!),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(onPressed: _previousSong, icon: Icon(Icons.skip_previous)),
              IconButton(onPressed: _pauseOrPlay, icon: Icon(Icons.play_arrow)),
              IconButton(onPressed: _skipSong, icon: Icon(Icons.skip_next)),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: codeController,
              decoration: InputDecoration(
                labelText: "Enter 6-digit song code",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              maxLength: 6,
              onSubmitted: (value) {
                _reserveSong(value);
                codeController.clear();
              },
            ),
          ),
        ],
      ),
    );
  }
}
