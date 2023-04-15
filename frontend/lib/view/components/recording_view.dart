import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:frontend/repository/web3_repository.dart';
import 'package:pointycastle/block/aes_fast.dart';
import 'package:pointycastle/block/modes/cbc.dart';
import 'package:pointycastle/export.dart' as pc;
import 'package:pointycastle/paddings/pkcs7.dart';
import 'package:encrypt/encrypt.dart' as encryptLib;
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:universal_html/html.dart' as html;
import 'package:web3dart/crypto.dart';

class RecordingView extends StatefulWidget {
  final String sharedSecret;

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
        _audioElement!.src = html.Url.createObjectUrlFromBlob(html.Blob(_audioChunks, 'audio/wav'));
        html.document.body!.append(_audioElement!);
        print('recorded audio: ${_audioElement!.src.length} bytes');
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
    final key = widget.sharedSecret;
    print('Key: $key');
    // final keyBytes = hexToBytes(key);

    // Read audio chunk
    _recordedAudio = _audioChunks.isNotEmpty ? concatUint8List(_audioChunks) : null;
    if (null == _recordedAudio) {
      print('no audio data');
      return Uint8List(0);
    }
    print('Audio data: ${_recordedAudio!.length}');
    // 鍵とIVをencrypt.Keyおよびencrypt.IVに変換
    final keyObj = encryptLib.Key(hexToBytes(key));
    final ivBytes = encryptLib.IV.fromLength(16); // 128-bit IVを生成

    // AES暗号化
    final encrypter = encryptLib.Encrypter(encryptLib.AES(keyObj, mode: encryptLib.AESMode.cbc, padding: 'PKCS7'));
    final encryptedData = encrypter.encryptBytes(_recordedAudio!.toList(), iv: ivBytes);

    return Uint8List.fromList(ivBytes.bytes + encryptedData.bytes);
  }

  Future<Uint8List> _decryptAudioFile(Uint8List encryptedAudioData) async {
    if (encryptedAudioData == null) {
      throw ArgumentError('Encrypted audio data must not be null');
    }

    // Convert the shared secret to a 256-bit key
    final key = widget.sharedSecret;
    print('Key: $key');
    final keyBytes = hexToBytes(key);

    // 鍵とIVをencrypt.Keyおよびencrypt.IVに変換
    final keyObj = encryptLib.Key(keyBytes);
    final ivBytes = encryptLib.IV(encryptedAudioData.sublist(0, 16)); // 128-bit IVを生成

    // AES復号化
    final encrypter = encryptLib.Encrypter(encryptLib.AES(keyObj, mode: encryptLib.AESMode.cbc, padding: 'PKCS7'));
    final decryptedData = encrypter.decryptBytes(encryptLib.Encrypted(encryptedAudioData.sublist(16)), iv: ivBytes);

    // 復号化されたデータをUint8Listに変換
    return Uint8List.fromList(decryptedData);
  }

  Future<bool> _uploadToServer(String userAddress, String userPublicKey, Uint8List encryptedAudioData) async {
    String url = "http://127.0.0.1:5454/user/operation";
    Map<String, String> headers = {'content-type': 'application/json'};
    String body = json.encode({
      'user': userAddress,
      'publicKey': userPublicKey,
      'audio': base64Encode(encryptedAudioData),
    });
    print('Upload to server: $userAddress, $userPublicKey, ${encryptedAudioData.length}');

    http.Response resp = await http.post(Uri.parse(url), headers: headers, body: body);
    resp.statusCode == 200 ? print('Upload success') : print('Upload failed');
    return resp.statusCode == 200;
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
                // verify the encrypted audio file
                final decryptedAudio = await _decryptAudioFile(encryptedAudio);
                for (var i = 0; i < decryptedAudio.length; i++) {
                  if (decryptedAudio[i] != _recordedAudio![i]) {
                    throw Exception('Decrypted audio does not match the original audio');
                  }
                }

                downloadBlobData(decryptedAudio, 'recorded_audio.wav', 'audio/wav');
                // You can use the 'encryptedAudio' Uint8List for uploading the file
                print('Encrypted Audio Length: ${encryptedAudio.length}');
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('encrypt success')));

                if (await _uploadToServer(Web3Repository().currentAddress!, Web3Repository().publicKey!, encryptedAudio)) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('upload success')));
                }
              },
              child: Text('Encrypt and Upload'),
            ),
          ],
        ),
      ),
    );
  }

  //////////////////////////////////////////////////////////////////////////////////////////////////
  /// Helper functions
  void downloadBlobData(Uint8List data, String fileName, String mimeType) {
    // Uint8ListをBlobに変換
    final blob = html.Blob([data], mimeType);

    // Blobから一時的なダウンロードURLを作成
    final url = html.Url.createObjectUrlFromBlob(blob);

    // <a>タグを作成し、href属性に一時的なダウンロードURLを設定し、download属性にファイル名を設定
    final anchor = html.AnchorElement()
      ..href = url
      ..download = fileName
      ..style.display = 'none';

    // 作成した<a>タグをDOMに追加し、クリックイベントを発火させてダウンロードを開始
    html.document.body!.children.add(anchor);
    anchor.click();

    // ダウンロードが開始されたら、<a>タグと一時的なURLを削除
    html.document.body!.children.remove(anchor);
    html.Url.revokeObjectUrl(url);
  }

  void displayDownloadLink(Uint8List audioData, String fileName) {
    // Uint8ListをBlobに変換
    final blob = html.Blob([audioData], 'audio/wav');

    // Blobから一時的なダウンロードURLを作成
    final url = html.Url.createObjectUrlFromBlob(blob);

    // <a>タグを作成し、href属性に一時的なダウンロードURLを設定し、download属性にファイル名を設定
    final anchor = html.AnchorElement()
      ..href = url
      ..download = fileName
      ..text = 'Download $fileName';

    // 作成した<a>タグをDOMに追加
    html.document.body!.children.add(anchor);
  }
}
