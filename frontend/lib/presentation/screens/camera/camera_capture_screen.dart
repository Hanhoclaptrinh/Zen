import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/constants/app_colors.dart';
import 'package:frontend/providers/app_providers.dart';
import 'package:frontend/presentation/screens/transaction/add_transaction_screen.dart';

class CameraCaptureScreen extends ConsumerStatefulWidget {
  final bool isActive;
  const CameraCaptureScreen({super.key, this.isActive = true});

  @override
  ConsumerState<CameraCaptureScreen> createState() =>
      _CameraCaptureScreenState();
}

class _CameraCaptureScreenState extends ConsumerState<CameraCaptureScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  bool _isInitializing = true;
  bool _isCapturing = false;
  XFile? _capturedFile;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.isActive) {
      _initializeCamera();
    }
  }

  @override
  void didUpdateWidget(CameraCaptureScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _initializeCamera();
    } else if (!widget.isActive && oldWidget.isActive) {
      _isInitializing = true;
      _controller?.dispose();
      _controller = null;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) return;

    if (state == AppLifecycleState.paused) {
      _isInitializing = true;
      _controller?.dispose();
      _controller = null;
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  // khoi tao camera
  Future<void> _initializeCamera() async {
    if (!widget.isActive) return;
    if (_controller != null) return;

    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    _controller = CameraController(
      cameras[0],
      ResolutionPreset.max, // do phan giai cao nhat
      enableAudio: false,
    );

    try {
      await _controller!.initialize();
    } catch (e) {
      debugPrint("Camera init error: $e");
    }

    if (mounted) {
      setState(() {
        _isInitializing = widget.isActive ? false : true;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    _controller = null;
    super.dispose();
  }

  // chup anh
  Future<void> _takePicture() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _isCapturing)
      return;

    try {
      final XFile image = await _controller!.takePicture();
      if (mounted) {
        setState(() {
          _capturedFile = image;
        });
      }
    } catch (e) {
      debugPrint("Take picture error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Lỗi khi chụp ảnh. Vui lòng thử lại."),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  // upload anh
  Future<void> _uploadAndNavigate() async {
    if (_capturedFile == null || _isCapturing) return;

    setState(() {
      _isCapturing = true;
    });

    // upload anh len cloudinary bang service
    try {
      final cloudinaryService = ref.read(cloudinaryServiceProvider);
      final imageUrl = await cloudinaryService.uploadFile(
        File(_capturedFile!.path),
      );

      if (mounted) {
        setState(() {
          _isCapturing = false;
          _capturedFile = null;
        });
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                AddTransactionScreen(initialImageUrl: imageUrl),
          ),
        );
      }
    } catch (e) {
      debugPrint("Upload error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Lỗi khi tải ảnh lên. Vui lòng thử lại."),
            backgroundColor: AppColors.danger,
          ),
        );
        setState(() {
          _isCapturing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            "Không thể khởi tạo máy ảnh",
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          SafeArea(
            child: Column(
              children: [
                const Spacer(),
                Center(
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.98,
                    height: MediaQuery.of(context).size.width * 0.98,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(48),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.5),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.05),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(46),
                      child: _capturedFile == null
                          ? _buildCameraView()
                          : Image.file(
                              File(_capturedFile!.path),
                              fit: BoxFit.cover,
                            ),
                    ),
                  ),
                ),
                const Spacer(),
                // preview controls
                Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: _capturedFile == null
                      ? _buildCameraControls()
                      : _buildPreviewControls(),
                ),
              ],
            ),
          ),

          // close button
          if (Navigator.canPop(context))
            Positioned(
              top: 40,
              left: 20,
              child: IconButton(
                icon: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 30,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCameraView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ClipRect(
          child: OverflowBox(
            alignment: Alignment.center,
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: constraints.maxWidth,
                height: constraints.maxWidth / _controller!.value.aspectRatio,
                child: CameraPreview(_controller!),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCameraControls() {
    return Column(
      children: [
        GestureDetector(
          onTap: _takePicture,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
            ),
            child: Center(
              child: Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          if (_isCapturing)
            const Padding(
              padding: EdgeInsets.only(bottom: 24),
              child: Text(
                "Đang lưu ảnh",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: _isCapturing
                      ? null
                      : () => setState(() => _capturedFile = null),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white70,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    "Chụp lại",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isCapturing ? null : _uploadAndNavigate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isCapturing
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "Gửi đi",
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
