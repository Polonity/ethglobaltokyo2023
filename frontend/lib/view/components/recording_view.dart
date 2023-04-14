import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:pointycastle/block/aes_fast.dart';
import 'package:pointycastle/block/modes/cbc.dart';
import 'package:pointycastle/export.dart' as pc;
import 'package:pointycastle/paddings/pkcs7.dart';
import 'package:encrypt/encrypt.dart' as encryptLib;

import 'package:universal_html/html.dart' as html;
import 'package:web3dart/crypto.dart';

class RecordingView extends StatefulWidget {
  final BigInt sharedSecret;

  RecordingView({Key? key, required this.sharedSecret}) : super(key: key);

  @override
  State<RecordingView> createState() => _RecordingViewState();
}

class _RecordingViewState extends State<RecordingView> {
  bool _isRecording = false;
  html.MediaRecorder? _mediaRecorder;
  List<Uint8List> _audioChunks = [];
  Uint8List? _recordedAudio;
  html.AudioElement? _audioElement;

  void _startRecording() async {
    _audioChunks.clear();
    final html.MediaStream mediaStream = await html.window.navigator.mediaDevices!.getUserMedia({'audio': true});
    _mediaRecorder = html.MediaRecorder(mediaStream);

    _mediaRecorder!.addEventListener('dataavailable', (html.Event e) async {
      print('dataavailable');
      final reader = html.FileReader();
      reader.readAsArrayBuffer((e as html.BlobEvent).data!);
      await reader.onLoadEnd.first;
      _audioChunks.add(reader.result as Uint8List);
    });

    _mediaRecorder!.addEventListener('stop', (html.Event e) async {
      print('stop recording');
      if (_audioElement != null) {
        // 以前のaudio要素をDOMから削除する
        _audioElement!.remove();
      }
      Future.delayed(Duration(seconds: 1), () {
        _audioElement = html.AudioElement();
        _audioElement!.src = html.Url.createObjectUrlFromBlob(html.Blob(_audioChunks, 'audio/webm'));
        html.document.body!.append(_audioElement!);
        print(_audioChunks);
      });
    });

    _mediaRecorder!.start();
    setState(() {
      _isRecording = true;
    });

    Future.delayed(Duration(seconds: 5), () {
      _stopRecording();
    });
  }

  Uint8List concatUint8List(List<Uint8List> listOfUint8Lists) {
    int totalLength = 0;
    for (var list in listOfUint8Lists) {
      totalLength += list.length;
    }

    Uint8List result = Uint8List(totalLength);
    int currentPosition = 0;

    for (var list in listOfUint8Lists) {
      result.setRange(currentPosition, currentPosition + list.length, list);
      currentPosition += list.length;
    }

    return result;
  }

  void _stopRecording() {
    _mediaRecorder!.stop();
    setState(() {
      _isRecording = false;
    });
  }

  void _playRecording() {
    _audioElement?.load();
    _audioElement?.play();
  }

  Future<Uint8List> _encryptAudioFile() async {
    // Convert the shared secret to a 256-bit key
    final key = widget.sharedSecret.toRadixString(16).padLeft(64, '0');
    print('Key: $key');
    final keyBytes = hexToBytes(key);

    // Read audio chunk
    _recordedAudio = _audioChunks.isNotEmpty ? concatUint8List(_audioChunks) : null;
    if (null == _recordedAudio) {
      print('no audio data');
      return Uint8List(0);
    }
    // 鍵とIVをencrypt.Keyおよびencrypt.IVに変換
    final keyObj = encryptLib.Key(hexToBytes(key));
    final ivBytes = encryptLib.IV.fromLength(16); // 128-bit IVを生成

    // AES暗号化
    final encrypter = encryptLib.Encrypter(encryptLib.AES(keyObj, mode: encryptLib.AESMode.cbc, padding: 'PKCS7'));
    final encryptedData = encrypter.encryptBytes(_recordedAudio!.toList(), iv: ivBytes);

    // // Encrypt the audio file
    // final iv = Uint8List.fromList(List.generate(16, (index) => 0)); // Use a zero IV for simplicity
    // final blockCipher = CBCBlockCipher(AESFastEngine())..init(true, pc.ParametersWithIV<pc.KeyParameter>(pc.KeyParameter(keyBytes), iv));
    // final paddingCipher = pc.PaddedBlockCipherImpl(PKCS7Padding(), blockCipher);
    // final encryptedBytes = paddingCipher.process(_recordedAudio);

    // Upload the encrypted audio file to a server
    // Here you can use your preferred method to upload the file
    // For example, using http package, dio package or any other method

    return Uint8List.fromList(encryptedData.bytes);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Audio Recorder'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _isRecording ? null : _startRecording,
              child: Text('Start Recording'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _playRecording,
              child: Text('Play Recording'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final encryptedAudio = await _encryptAudioFile();
                // You can use the 'encryptedAudio' Uint8List for uploading the file
                print('Encrypted Audio Length: ${encryptedAudio.length}');
              },
              child: Text('Encrypt and Upload'),
            ),
          ],
        ),
      ),
    );
  }
}
