import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:frontend/presentation/screens/transaction/add_transaction_screen.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:frontend/core/constants/app_colors.dart';

class CameraOCRScreen extends StatefulWidget {
  final bool isActive;
  const CameraOCRScreen({super.key, this.isActive = true});

  @override
  State<CameraOCRScreen> createState() => _CameraOCRScreenState();
}

class _CameraOCRScreenState extends State<CameraOCRScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  final TextRecognizer _textRecognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );
  bool _isProcessing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.isActive) {
      _initializeCamera();
    }
  }

  @override
  void didUpdateWidget(CameraOCRScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _initializeCamera();
    } else if (!widget.isActive && oldWidget.isActive) {
      _isInitialized = false;
      _controller?.dispose();
      _controller = null;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    _controller = null;
    _textRecognizer.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _controller;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.paused) {
      _isInitialized = false;
      _controller?.dispose();
      _controller = null;
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  // khởi tạo camera
  Future<void> _initializeCamera() async {
    if (!widget.isActive) return;
    if (_controller != null) return; // Already initializing or initialized

    try {
      _cameras = await availableCameras().timeout(const Duration(seconds: 5));
      if (_cameras != null && _cameras!.isNotEmpty) {
        final controller = CameraController(
          _cameras![0],
          ResolutionPreset.high,
          enableAudio: false,
          imageFormatGroup: ImageFormatGroup.jpeg,
        );
        _controller = controller;

        await controller.initialize().timeout(const Duration(seconds: 5));

        if (!mounted || !widget.isActive) {
          await controller.dispose();
          _controller = null;
          return;
        }

        setState(() {
          _isInitialized = true;
          _isFlashOn = false;
        });
      } else {
        setState(() {
          _errorMessage = "Không tìm thấy máy ảnh nào trên thiết bị này.";
        });
      }
    } catch (e) {
      debugPrint("Lỗi khởi tạo máy ảnh: $e");
      setState(() {
        _errorMessage = "Lỗi khi khởi tạo máy ảnh";
        _isFlashOn = false;
      });
    }
  }

  // scan text
  // sử dụng tool google mlkit để nhận diện văn bản
  Future<void> _scanText() async {
    if (!_isInitialized || _controller == null || _isProcessing) return;

    setState(() => _isProcessing = true);
    try {
      final image = await _controller!.takePicture();
      final inputImage = InputImage.fromFilePath(image.path);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      if (mounted) {
        _showResultDialog(recognizedText.text);
      }
    } catch (e) {
      debugPrint("Lỗi khi quét văn bản: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Lỗi khi quét văn bản"),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  double? _parseAmount(String text) {
    // regex khi nhận được giá trị số
    final RegExp regExp = RegExp(r'(\d{1,3}([,. ]\d{3})*|\d+)');
    final Iterable<RegExpMatch> matches = regExp.allMatches(text);

    double maxAmount = 0;
    for (final match in matches) {
      String clean = match.group(0)!.replaceAll(RegExp(r'[,. ]'), '');
      double? val = double.tryParse(clean);
      if (val != null && val > maxAmount) {
        // capping giá trị số
        // tránh giá trị quá lớn
        if (val < 100000000) {
          maxAmount = val;
        }
      }
    }
    return maxAmount > 0 ? maxAmount : null;
  }

  // show dialog kết quả quét
  void _showResultDialog(String text) {
    final amount = _parseAmount(text);
    final note = text.length > 50 ? "${text.substring(0, 47)}..." : text;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Kết quả quét"),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (amount != null) ...[
                  Text(
                    "Số tiền: ${amount.toStringAsFixed(0)}đ",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                const Text(
                  "Văn bản gốc:",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  text.isEmpty
                      ? "Không tìm thấy văn bản nào để nhận diện."
                      : text,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Đóng", style: TextStyle(color: Colors.grey)),
          ),
          if (text.isNotEmpty)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddTransactionScreen(
                      // gán giá trị số tiền và ghi chú vào form
                      initialAmount: amount,
                      initialNote: note.replaceAll("\n", " "),
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
              ),
              child: const Text("Sử dụng"),
            ),
        ],
      ),
    );
  }

  // mo flash
  bool _isFlashOn = false;

  void _toggleFlash() async {
    if (!_isInitialized || _controller == null) return;

    try {
      if (_isFlashOn) {
        await _controller!.setFlashMode(FlashMode.off);
      } else {
        await _controller!.setFlashMode(FlashMode.torch);
      }
      setState(() {
        _isFlashOn = !_isFlashOn;
      });
    } catch (e) {
      debugPrint("Lỗi khi điều chỉnh đèn flash: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.redAccent,
                  size: 64,
                ),
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _errorMessage = null;
                      _isInitialized = false;
                    });
                    _initializeCamera();
                  },
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text("Thử lại"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!_isInitialized || _controller == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text("Đang mở máy ảnh", style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Center(child: CameraPreview(_controller!)),
          SafeArea(
            child: Column(
              children: [
                const Spacer(),
                if (_isProcessing)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 20),
                    child: CircularProgressIndicator(color: Colors.blueAccent),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  decoration: const BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _ActionButton(
                        icon: Icons.image_outlined,
                        label: "Album",
                        onPressed: () {
                          // logic pick img from gallery
                        },
                      ),
                      _ActionButton(
                        icon: Icons.document_scanner_rounded,
                        label: "Quét",
                        onPressed: _scanText,
                        size: 80,
                        isPrimary: true,
                      ),
                      _ActionButton(
                        icon: _isFlashOn
                            ? Icons.flash_on_rounded
                            : Icons.flash_off_rounded,
                        label: "Flash",
                        onPressed: _toggleFlash,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final double size;
  final bool isPrimary;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.size = 56,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onPressed,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: isPrimary ? Colors.blueAccent : Colors.white12,
              shape: BoxShape.circle,
              border: Border.all(
                color: isPrimary ? Colors.white : Colors.white30,
                width: 2,
              ),
            ),
            child: Icon(icon, color: Colors.white, size: size * 0.5),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: isPrimary ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
