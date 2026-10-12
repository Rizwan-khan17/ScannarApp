
import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

const Color _background = Color(0xFFF5F6FA);
const Color _primary = Color(0xFF246BFD);
const Color _dark = Color(0xFF171923);

class CameraScannerScreen extends StatefulWidget {
  const CameraScannerScreen({super.key});

  @override
  State<CameraScannerScreen> createState() =>
      _CameraScannerScreenState();
}

class _CameraScannerScreenState extends State<CameraScannerScreen> {
  List<File> _scans = [];
  List<File> _pdfFiles = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<Directory> _scanDirectory() async {
    final root = await getApplicationDocumentsDirectory();
    final directory = Directory('${root.path}/my_scans');

    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    return directory;
  }

  Future<void> _loadFiles() async {
    try {
      final directory = await _scanDirectory();
      final files = directory.listSync().whereType<File>().toList();

      final scans = files
          .where((f) => f.path.toLowerCase().endsWith('.jpg'))
          .toList()
        ..sort((a, b) => b.path.compareTo(a.path));

      final pdfs = files
          .where((f) => f.path.toLowerCase().endsWith('.pdf'))
          .toList()
        ..sort((a, b) => b.path.compareTo(a.path));

      if (!mounted) return;

      setState(() {
        _scans = scans;
        _pdfFiles = pdfs;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _message('Could not load saved scans: $e');
    }
  }

  Future<void> _openCamera() async {
    final result = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder: (_) => const _LiveScannerScreen(),
      ),
    );

    if (result != null) {
      await _loadFiles();
    }
  }

  Future<void> _deleteScan(File file) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete scan?'),
        content: const Text(
          'This will permanently remove this saved scan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    if (await file.exists()) {
      await file.delete();
    }

    await _loadFiles();
  }

  Future<void> _createPdf({List<File>? selectedFiles}) async {
    final files = selectedFiles ?? _scans;

    if (files.isEmpty) {
      _message('Scan at least one page first.');
      return;
    }

    try {
      _message('Creating PDF...');

      final document = pw.Document();

      for (final file in files) {
        final bytes = await file.readAsBytes();

        document.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(20),
            build: (context) {
              return pw.Center(
                child: pw.Image(
                  pw.MemoryImage(bytes),
                  fit: pw.BoxFit.contain,
                ),
              );
            },
          ),
        );
      }

      final directory = await _scanDirectory();
      final path =
          '${directory.path}/Document_${DateTime.now().millisecondsSinceEpoch}.pdf';

      await File(path).writeAsBytes(await document.save());

      await _loadFiles();

      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _PdfDetailsScreen(path: path),
        ),
      );
    } catch (e) {
      _message('PDF creation failed: $e');
    }
  }

  void _message(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        title: const Row(
          children: [
            Icon(Icons.document_scanner, color: _primary, size: 30),
            SizedBox(width: 10),
            Text(
              'Smart Scanner',
              style: TextStyle(
                color: _dark,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Create PDF from all scans',
            onPressed: _scans.isEmpty ? null : () => _createPdf(),
            icon: const Icon(Icons.picture_as_pdf),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCamera,
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.camera_alt),
        label: const Text('Scan document'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadFiles,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 110),
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF246BFD),
                    Color(0xFF6046E8),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.document_scanner_outlined,
                    color: Colors.white,
                    size: 42,
                  ),
                  SizedBox(height: 18),
                  Text(
                    'Paper to PDF',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Scan documents, adjust images and save your pages in one place.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        color: Colors.white,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Scan  •  Edit  •  Save PDF',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'My scans',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: _dark,
                    ),
                  ),
                ),
                Text(
                  '${_scans.length} pages',
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_scans.isEmpty)
              _emptyState(
                icon: Icons.document_scanner_outlined,
                title: 'No scans yet',
                subtitle:
                'Tap Scan document to capture your first page.',
              )
            else
              ..._scans.map(
                    (file) => _ScanTile(
                  file: file,
                  onDelete: () => _deleteScan(file),
                ),
              ),
            const SizedBox(height: 28),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Saved PDFs',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: _dark,
                    ),
                  ),
                ),
                Text(
                  '${_pdfFiles.length} files',
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_pdfFiles.isEmpty)
              _emptyState(
                icon: Icons.picture_as_pdf_outlined,
                title: 'No PDFs created',
                subtitle:
                'Scan one or more pages, then tap the PDF icon.',
              )
            else
              ..._pdfFiles.map(
                    (file) => ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 4,
                  ),
                  tileColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFFFE8E8),
                    child: Icon(
                      Icons.picture_as_pdf,
                      color: Colors.red,
                    ),
                  ),
                  title: Text(
                    file.uri.pathSegments.last,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: const Text('Saved on this device'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            _PdfDetailsScreen(path: file.path),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: Colors.black38),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black54,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanTile extends StatelessWidget {
  final File file;
  final VoidCallback onDelete;

  const _ScanTile({
    required this.file,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.file(
              file,
              width: 66,
              height: 82,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
              const Icon(Icons.broken_image, size: 60),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Scanned document',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  file.uri.pathSegments.last,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'JPG • Saved locally',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onDelete,
            tooltip: 'Delete scan',
            icon: const Icon(
              Icons.delete_outline,
              color: Colors.redAccent,
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------
// FULL-SCREEN CAMERA SCANNER
// ------------------------------------------------------------

class _LiveScannerScreen extends StatefulWidget {
  const _LiveScannerScreen();

  @override
  State<_LiveScannerScreen> createState() =>
      _LiveScannerScreenState();
}

class _LiveScannerScreenState extends State<_LiveScannerScreen> {
  CameraController? _controller;

  bool _initializing = true;
  bool _capturing = false;
  bool _torchOn = false;
  String? _error;

  String _ratioName = 'A4';

  final List<String> _sessionScans = [];

  final Map<String, double?> _ratios = {
    'Full': null,
    'A4': 0.707,
    '3:4': 0.75,
    '1:1': 1.0,
    '4:3': 1.333,
    '16:9': 1.778,
  };

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();

      if (cameras.isEmpty) {
        throw Exception('No camera is available.');
      }

      final backCamera = cameras.firstWhere(
            (camera) =>
        camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        backCamera,
        ResolutionPreset.max,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await controller.initialize();

      try {
        await controller.lockCaptureOrientation(
          DeviceOrientation.portraitUp,
        );
      } catch (_) {
        // Some devices may not support locking capture orientation.
      }

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _controller = controller;
        _initializing = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _initializing = false;
      });
    }
  }

  double? get _selectedRatio => _ratios[_ratioName];

  Future<void> _toggleFlash() async {
    final controller = _controller;
    if (controller == null) return;

    try {
      final next = !_torchOn;
      await controller.setFlashMode(
        next ? FlashMode.torch : FlashMode.off,
      );

      if (mounted) {
        setState(() => _torchOn = next);
      }
    } catch (e) {
      _showMessage('Flash unavailable: $e');
    }
  }

  Future<void> _capture() async {
    final controller = _controller;

    if (controller == null ||
        !controller.value.isInitialized ||
        _capturing) {
      return;
    }

    setState(() => _capturing = true);

    try {
      final photo = await controller.takePicture();
      final bytes = await File(photo.path).readAsBytes();

      if (!mounted) return;

      final editedBytes = await Navigator.push<Uint8List>(
        context,
        MaterialPageRoute(
          builder: (_) => _ScanEditScreen(
            imageBytes: bytes,
            ratioName: _ratioName,
            ratio: _selectedRatio,
          ),
        ),
      );

      if (editedBytes == null || !mounted) return;

      final root = await getApplicationDocumentsDirectory();
      final directory = Directory('${root.path}/my_scans');

      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      final file = File(
        '${directory.path}/scan_'
            '${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      await file.writeAsBytes(editedBytes);

      setState(() => _sessionScans.add(file.path));

      _showMessage('Page saved successfully.');
    } catch (e) {
      _showMessage('Could not capture document: $e');
    } finally {
      if (mounted) {
        setState(() => _capturing = false);
      }
    }
  }

  void _finishScanning() {
    Navigator.pop(context, _sessionScans);
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _initializing
            ? const Center(
          child: CircularProgressIndicator(
            color: Colors.white,
          ),
        )
            : _error != null
            ? Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              _error!,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        )
            : Stack(
          fit: StackFit.expand,
          children: [
            if (controller != null)
              Positioned.fill(
                child: _FullScreenCameraPreview(
                  controller: controller,
                ),
              ),
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.75),
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.8),
                      ],
                      stops: const [0, 0.24, 0.65, 1],
                    ),
                  ),
                ),
              ),
            ),
            Column(
              children: [
                _cameraTopBar(),
                _ratioSelector(),
                const Spacer(),
                _documentGuide(),
                const Spacer(),
                _cameraBottomBar(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _cameraTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
      child: Row(
        children: [
          _roundButton(
            icon: Icons.close,
            onTap: _finishScanning,
          ),
          const Expanded(
            child: Text(
              'Scan document',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 17,
              ),
            ),
          ),
          _roundButton(
            icon: _torchOn ? Icons.flash_on : Icons.flash_off,
            onTap: _toggleFlash,
          ),
        ],
      ),
    );
  }

  Widget _ratioSelector() {
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: _ratios.keys.map((name) {
          final selected = _ratioName == name;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(name),
              selected: selected,
              showCheckmark: false,
              selectedColor: _primary,
              backgroundColor: Colors.black54,
              labelStyle: TextStyle(
                color: selected ? Colors.white : Colors.white70,
                fontWeight:
                selected ? FontWeight.bold : FontWeight.normal,
              ),
              side: BorderSide(
                color: selected
                    ? _primary
                    : Colors.white.withValues(alpha: 0.35),
              ),
              onSelected: (_) {
                setState(() => _ratioName = name);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _documentGuide() {
    final ratio = _selectedRatio;

    return Center(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = MediaQuery.sizeOf(context).width * 0.84;
          final maxHeight = MediaQuery.sizeOf(context).height * 0.53;

          double width = maxWidth;
          double height = maxHeight;

          if (ratio != null) {
            if (width / height > ratio) {
              width = height * ratio;
            } else {
              height = width / ratio;
            }
          }

          return Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.9),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Stack(
              children: [
                _corner(Alignment.topLeft),
                _corner(Alignment.topRight),
                _corner(Alignment.bottomLeft),
                _corner(Alignment.bottomRight),
                const Center(
                  child: Text(
                    'Align document within frame',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      shadows: [
                        Shadow(
                          color: Colors.black,
                          blurRadius: 5,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _corner(Alignment alignment) {
    return Align(
      alignment: alignment,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          border: Border(
            top: alignment.y == -1
                ? const BorderSide(color: Color(0xFF66F0A8), width: 4)
                : BorderSide.none,
            bottom: alignment.y == 1
                ? const BorderSide(color: Color(0xFF66F0A8), width: 4)
                : BorderSide.none,
            left: alignment.x == -1
                ? const BorderSide(color: Color(0xFF66F0A8), width: 4)
                : BorderSide.none,
            right: alignment.x == 1
                ? const BorderSide(color: Color(0xFF66F0A8), width: 4)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _cameraBottomBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 64,
                child: _sessionScans.isEmpty
                    ? const SizedBox()
                    : GestureDetector(
                  onTap: () => _showThumbnails(),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(_sessionScans.last),
                          width: 52,
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        right: 0,
                        top: -7,
                        child: CircleAvatar(
                          radius: 10,
                          backgroundColor: _primary,
                          child: Text(
                            '${_sessionScans.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: GestureDetector(
                    onTap: _capturing ? null : _capture,
                    child: Container(
                      width: 78,
                      height: 78,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 4,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(5),
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: _capturing
                              ? const Padding(
                            padding: EdgeInsets.all(17),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                              : const SizedBox(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 64,
                child: _sessionScans.isEmpty
                    ? const SizedBox()
                    : IconButton(
                  onPressed: _finishScanning,
                  icon: const Icon(
                    Icons.check_circle,
                    color: Color(0xFF66F0A8),
                    size: 36,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _sessionScans.isEmpty
                ? 'Tap to scan'
                : '${_sessionScans.length} page(s) • Tap ✓ when finished',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  void _showThumbnails() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _dark,
      builder: (context) => SafeArea(
        child: SizedBox(
          height: 150,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(16),
            itemCount: _sessionScans.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(_sessionScans[index]),
                  width: 90,
                  fit: BoxFit.cover,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _roundButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.black45,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: Colors.white),
        ),
      ),
    );
  }
}

// Fill the available screen without stretching the camera image.
class _FullScreenCameraPreview extends StatelessWidget {
  final CameraController controller;

  const _FullScreenCameraPreview({
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final previewSize = controller.value.previewSize;

    if (previewSize == null) {
      return CameraPreview(controller);
    }

    return ClipRect(
      child: SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          alignment: Alignment.center,
          child: SizedBox(
            width: previewSize.height,
            height: previewSize.width,
            child: CameraPreview(controller),
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------
// SCAN EDITOR
// ------------------------------------------------------------

class _ScanEditScreen extends StatefulWidget {
  final Uint8List imageBytes;
  final String ratioName;
  final double? ratio;

  const _ScanEditScreen({
    required this.imageBytes,
    required this.ratioName,
    required this.ratio,
  });

  @override
  State<_ScanEditScreen> createState() => _ScanEditScreenState();
}

class _ScanEditScreenState extends State<_ScanEditScreen> {
  String _filter = 'Original';
  bool _saving = false;

  Uint8List _processImage() {
    final decoded = img.decodeImage(widget.imageBytes);

    if (decoded == null) {
      throw Exception('Could not decode captured photo.');
    }

    var result = img.copyRotate(decoded, angle: 0);

    // Center-crop to the selected aspect ratio.
    // Full preserves the complete photo.
    final ratio = widget.ratio;

    if (ratio != null) {
      final imageRatio = result.width / result.height;

      if (imageRatio > ratio) {
        final newWidth = (result.height * ratio).round();
        final x = (result.width - newWidth) ~/ 2;

        result = img.copyCrop(
          result,
          x: x,
          y: 0,
          width: newWidth,
          height: result.height,
        );
      } else if (imageRatio < ratio) {
        final newHeight = (result.width / ratio).round();
        final y = (result.height - newHeight) ~/ 2;

        result = img.copyCrop(
          result,
          x: 0,
          y: y,
          width: result.width,
          height: newHeight,
        );
      }
    }

    if (_filter == 'Grayscale') {
      result = img.grayscale(result);
    } else if (_filter == 'Black & White') {
      result = img.grayscale(result);

      for (final pixel in result) {
        final brightness = (pixel.r + pixel.g + pixel.b) / 3;
        final shade = brightness > 160 ? 255 : 0;
        pixel.setRgb(shade, shade, shade);
      }
    } else if (_filter == 'Enhanced') {
      result = img.adjustColor(
        result,
        contrast: 1.25,
        saturation: 0,
      );
    }

    return Uint8List.fromList(
      img.encodeJpg(result, quality: 95),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);

    try {
      final result = _processImage();

      if (!mounted) return;
      Navigator.pop(context, result);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not edit image: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Uint8List preview;

    try {
      preview = _processImage();
    } catch (_) {
      preview = widget.imageBytes;
    }

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        title: const Text('Adjust scan'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: const Text(
              'SAVE',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Image.memory(
                preview,
                key: ValueKey(
                  '$_filter${widget.ratioName}',
                ),
                fit: BoxFit.contain,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Choose scan filter',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _filterOption('Original', Icons.image_outlined),
                      _filterOption('Grayscale', Icons.tonality),
                      _filterOption(
                        'Black & White',
                        Icons.contrast,
                      ),
                      _filterOption('Enhanced', Icons.auto_fix_high),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: const Icon(Icons.check),
                    label: Text(
                      _saving ? 'Saving...' : 'Save this page',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterOption(String name, IconData icon) {
    final selected = _filter == name;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        avatar: Icon(
          icon,
          size: 18,
          color: selected ? Colors.white : _dark,
        ),
        label: Text(name),
        selected: selected,
        showCheckmark: false,
        selectedColor: _primary,
        labelStyle: TextStyle(
          color: selected ? Colors.white : _dark,
          fontSize: 12,
        ),
        onSelected: (_) => setState(() => _filter = name),
      ),
    );
  }
}

// ------------------------------------------------------------
// SAVED PDF DETAILS
// ------------------------------------------------------------

class _PdfDetailsScreen extends StatelessWidget {
  final String path;

  const _PdfDetailsScreen({
    required this.path,
  });

  @override
  Widget build(BuildContext context) {
    final file = File(path);

    return Scaffold(
      appBar: AppBar(title: const Text('Saved PDF')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.picture_as_pdf,
                color: Colors.red,
                size: 76,
              ),
              const SizedBox(height: 18),
              const Text(
                'PDF saved successfully',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              SelectableText(
                file.uri.pathSegments.last,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              SelectableText(
                file.path,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'The PDF is stored inside the app documents folder.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.home_outlined),
                label: const Text('Back to home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
