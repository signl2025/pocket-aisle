import 'dart:io';

//path package is for platform-agnotic file pathing
//scheduler is to ensure the video loads
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/scheduler.dart';

import '../apis/apis.dart';
import '../helpers/pref.dart';
import '../models/word_model.dart';

//builds the screen for the word
class WordScreen extends StatefulWidget {
  final WordModel word;
  final VoidCallback? onBack; //tracks where to go back to

  const WordScreen({super.key, required this.word, this.onBack});

  @override
  _WordScreenState createState() => _WordScreenState();
}

class _WordScreenState extends State<WordScreen> {
  //player is the media kit player, video controller is for video playback output
  late Player _player;
  VideoController? _controller;

  String? _videoPath;
  bool _isVideoAvailable = true;
  bool _isDownloading = false; 
  late String _videoFilePath;

  bool _isPlayerDisposed = false; 

  @override
  void initState() {
    super.initState();
    _player = Player();
    _initializeVideoPath();
    _autoDownloadVideo();
  }

  //initializes the video file path and checks if video is playable
  Future<void> _initializeVideoPath() async {
    _videoFilePath = p.join(
      await APIs.getVideoPathForPlatform(),
      widget.word.vFileName,
    );

    SchedulerBinding.instance.addPostFrameCallback((_) async {
      await _checkAndPlayVideo();
    });
  }

  //checks if video exists, if so play video
  Future<void> _checkAndPlayVideo() async {
    bool videoExists = await File(_videoFilePath).exists();
    if (videoExists) {
      _playVideo(_videoFilePath);
    } else {
      setState(() {
        _isVideoAvailable = false;
      });
    }
  }

  //plays video
  void _playVideo(String path) {
    setState(() {
      _videoPath = path;
      _isVideoAvailable = true;
    });

    //restarts the player if it was disposed
    if (_isPlayerDisposed) {
      _reinitializePlayer(); 
    }

    //sets controlller to the players controller?? redundancy, but might break so keep it
    _controller ??= VideoController(_player);

    SchedulerBinding.instance.addPostFrameCallback((_) {
      _player.open(Media(path)); 
    });
  }

  //reinitializes player
  void _reinitializePlayer() {
    _player = Player();
    _controller = VideoController(_player);
    _isPlayerDisposed = false; 
  }

  //file's internal function for when user presses download button
  Future<void> _manualDownloadVideo() async {
    setState(() {
      _isDownloading = true; 
    });

    //sets the manual download flag so it proceeds as expected
    APIs.setManualDownloadFlag();

    //downloads video for the word in this screen
    String result = await APIs.downloadWordVideo(widget.word.vFileName);

    //if downloading returns anything that has unique string indicating error
    if (result.contains("asdasdgewtwt")) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error downloading video"))); //show this if error
    } else { //otherise this and recheck the video
      setState(() {
        _videoPath = result;
        _isDownloading = false; 
        _isVideoAvailable = true;
      });
      _checkAndPlayVideo();
    }
  }

  //autodownload version of the above method, runs at start
  Future<void> _autoDownloadVideo() async {
    if(await Pref.isAutoDownloadEnabled){ //but only if autodownloaded is toggled on in settings
      setState(() {
        _isDownloading = true; 
      });

      String result = await APIs.downloadWordVideo(widget.word.vFileName);

      if (result.contains("asdasdgewtwt")) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error downloading video")));
      } else {
        setState(() {
          _videoPath = result;
          _isDownloading = false; 
          _isVideoAvailable = true;
        });
        _checkAndPlayVideo();
      }
    }
  }

  //requirement for media player
  @override
  void dispose() {
    _player.dispose();
    _isPlayerDisposed = true; 
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold( //contents of the word screen
      appBar: AppBar(
        title: Text(
          widget.word.word,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading:
            widget.onBack != null
                ? IconButton(
                  icon: Icon(Icons.arrow_back),
                  onPressed: widget.onBack,
                )
                : null,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Category: ${widget.word.category.join(', ')}",
                style: TextStyle(fontSize: 18, color: Colors.grey[700]),
              ),
              SizedBox(height: 10),
              Text(
                "Definition: ${widget.word.definition}",
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 20),

              if (_isVideoAvailable)
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child:
                      _videoPath == null || _controller == null
                          ? Center(
                            child: CircularProgressIndicator(),
                          ) 
                          : Video(controller: _controller!),
                )
              else
                Center(
                  child: Text(
                    "No video available, please download or connect to the internet with auto-download enabled",
                    style: TextStyle(fontSize: 18, color: Colors.red),
                  ),
                ),

              if (_isDownloading)
                Center(
                  child: CircularProgressIndicator(),
                ),
              if (!_isVideoAvailable && !_isDownloading)
                Center(
                  child: IconButton(
                    onPressed: _manualDownloadVideo, //if pressed, do the method here
                    icon: Icon(Icons.download),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
