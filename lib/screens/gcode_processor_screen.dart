import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:makine/controller/gcode_processor_controller.dart';
import 'package:makine/utils/ui_helpers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class GCodeProcessorScreen extends StatefulWidget {
  final Map<String, dynamic>? initialGCodeData;
  final String machineIp;

  const GCodeProcessorScreen({
    super.key,
    this.initialGCodeData,
    required this.machineIp,
  });

  @override
  State<GCodeProcessorScreen> createState() => _GCodeProcessorScreenState();
}

class _GCodeProcessorScreenState extends State<GCodeProcessorScreen> {
  final GCodeProcessorController _controller = GCodeProcessorController();
  final Dio _dio = Dio();
  bool _isProcessing = false;
  bool _isUploading = false;
  bool _isExecuting = false;
  bool _uploadSuccessful = false;
  String? _ncContent;
  String? _ncFilePath;
  String? _fileName;
  String? _errorMessage;
  TextEditingController jsonInputController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GCode İşlemci'),
        actions: [
          if (_ncFilePath != null)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _shareNCFile,
              tooltip: 'NC Dosyasını Paylaş',
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Show processing indicator
            if (_isProcessing) ...[
              const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('GCode verileri işleniyor...'),
                  ],
                ),
              ),
            ],

            // Show upload indicator
            if (_isUploading) ...[
              const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Dosya yükleniyor...'),
                  ],
                ),
              ),
            ],

            // Show execution indicator
            if (_isExecuting) ...[
              const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Komut yürütülüyor...'),
                  ],
                ),
              ),
            ],

            // Show error message if any
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                color: Colors.red.shade100,
                width: double.infinity,
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red.shade900),
                ),
              ),
            ],

            // Show NC file information and content
            if (_ncFilePath != null && _ncContent != null) ...[
              const SizedBox(height: 24),
              const Text(
                'NC Dosyası Oluşturuldu',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('Dosya Yolu: $_ncFilePath'),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: SingleChildScrollView(
                    child: Text(_ncContent!),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.share, color: Colors.white),
                    label: const Text('Paylaş'),
                    onPressed: _shareNCFile,
                  ),
                  if (!_uploadSuccessful) ...[
                    ElevatedButton.icon(
                      icon: const Icon(Icons.upload_file, color: Colors.white),
                      label: const Text('Dosyayı Yükle'),
                      onPressed: _isUploading ? null : _uploadNCFile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                  if (_uploadSuccessful) ...[
                    ElevatedButton.icon(
                      icon: const Icon(Icons.play_arrow, color: Colors.white),
                      label: const Text('Başlat'),
                      onPressed: _isExecuting ? null : _executeCommand,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // If initial data provided, process it immediately
    if (widget.initialGCodeData != null) {
      _processInitialData();
    }
  }

  // Execute the command to run the NC file
  Future<void> _executeCommand() async {
    if (_fileName == null) return;

    setState(() {
      _isExecuting = true;
      _errorMessage = null;
    });

    try {
      // Send the command to run the NC file
      final response = await _dio.get(
        'http://${widget.machineIp}/command',
        queryParameters: {
          'cmd': '\$SD/Run=/$_fileName',
        },
        options: Options(
          headers: {
            'Accept': '*/*',
            'Accept-Language': 'tr,en-US;q=0.9,en;q=0.8,ja;q=0.7,de;q=0.6',
            'Connection': 'keep-alive',
            'Referer': 'http://192.168.1.85/',
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.0.0 Safari/537.36',
          },
          validateStatus: (status) => true,
        ),
      );

      setState(() {
        _isExecuting = false;
      });

      if (response.statusCode == 200) {
        UIHelpers.showSnackBar(
          context,
          message: 'Komut başarıyla yürütüldü',
          isError: false,
        );
      } else {
        _errorMessage = 'Komut yürütülürken hata: ${response.statusCode}';
        UIHelpers.showSnackBar(
          context,
          message: _errorMessage!,
          isError: true,
        );
      }
    } catch (e) {
      setState(() {
        _isExecuting = false;
        _errorMessage = 'Komut yürütülürken hata: $e';
      });
      UIHelpers.showSnackBar(
        context,
        message: _errorMessage!,
        isError: true,
      );
    }
  }

  // Method to handle additional operations after successful upload
  Future<void> _performPostUploadOperations() async {
    setState(() {
      _uploadSuccessful = true;
    });
  }

  Future<void> _processInitialData() async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final result =
          await _controller.processGCodeMapToNC(widget.initialGCodeData!);

      setState(() {
        _isProcessing = false;
        if (result['success']) {
          _ncContent = result['content'];
          // Save the NC content to a file
          _saveNCContentToFile();
        } else {
          _errorMessage = result['message'];
          UIHelpers.showSnackBar(context,
              message: _errorMessage ?? 'Dönüştürme başarısız', isError: true);
        }
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _errorMessage = 'GCode işlenirken hata: $e';
      });
      UIHelpers.showSnackBar(context, message: 'Hata: $e', isError: true);
    }
  }

  // Save NC content to a file
  Future<void> _saveNCContentToFile() async {
    if (_ncContent == null) return;

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final fileName = 'gcode_$timestamp.nc';

      // Get the documents directory
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$fileName';

      // Create the file
      final file = File(filePath);
      await file.writeAsString(_ncContent!);

      setState(() {
        _ncFilePath = filePath;
      });

      UIHelpers.showSnackBar(
        context,
        message: 'NC dosyası başarıyla oluşturuldu',
        isError: false,
      );
    } catch (e) {
      _errorMessage = 'Dosya kaydedilirken hata: $e';
      UIHelpers.showSnackBar(
        context,
        message: _errorMessage!,
        isError: true,
      );
    }
  }

  // Share the NC file
  Future<void> _shareNCFile() async {
    if (_ncFilePath != null) {
      try {
        await Share.shareXFiles([XFile(_ncFilePath!)],
            text: 'GCode NC Dosyası');
      } catch (e) {
        UIHelpers.showSnackBar(
          context,
          message: 'Dosya paylaşılırken hata: $e',
          isError: true,
        );
      }
    }
  }

  // Upload the NC file to the server
  Future<void> _uploadNCFile() async {
    if (_ncFilePath == null || _ncContent == null) return;

    setState(() {
      _isUploading = true;
      _errorMessage = null;
    });

    try {
      // Read file and get file information
      final file = File(_ncFilePath!);
      final fileContent = await file.readAsString();
      final fileSize = await file.length();
      _fileName = _ncFilePath!.split('/').last;
      final now = DateTime.now();
      final formattedDate =
          "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}T${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";

      // Create form data as shown in the image
      final formData = FormData.fromMap({
        'path': '/',
        '/${_fileName}S': fileSize.toString(),
        '/${_fileName}T': formattedDate,
        'myfiles':
            await MultipartFile.fromFile(_ncFilePath!, filename: _fileName),
      });

      // Send the file
      final response = await _dio.post(
        'http://${widget.machineIp}/upload',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          headers: {'Content-Type': 'multipart/form-data'},
          validateStatus: (status) => true,
        ),
      );

      setState(() {
        _isUploading = false;
      });

      if (response.statusCode == 200) {
        UIHelpers.showSnackBar(
          context,
          message: 'Dosya başarıyla yüklendi',
          isError: false,
        );

        // Perform additional operations after successful upload
        _performPostUploadOperations();
      } else {
        _errorMessage = 'Dosya yüklenirken hata: ${response.statusCode}';
        UIHelpers.showSnackBar(
          context,
          message: _errorMessage!,
          isError: true,
        );
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
        _errorMessage = 'Dosya yüklenirken hata: $e';
      });
      UIHelpers.showSnackBar(
        context,
        message: _errorMessage!,
        isError: true,
      );
    }
  }
}
