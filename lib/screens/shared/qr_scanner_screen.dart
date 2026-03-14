import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:go_router/go_router.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController cameraController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  bool _torchOn = false;
  bool _frontCamera = false;
  bool _hasScanned = false;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return; // prevent multiple scans

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        _hasScanned = true;
        cameraController.stop();
        context.pop(barcode.rawValue);
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan Book QR'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          // Torch toggle
          IconButton(
            icon: Icon(
              _torchOn ? Icons.flash_on : Icons.flash_off,
              color: _torchOn ? Colors.yellow : Colors.grey,
            ),
            iconSize: 32.0,
            onPressed: () {
              cameraController.toggleTorch();
              setState(() => _torchOn = !_torchOn);
            },
          ),
          // Camera flip
          IconButton(
            icon: Icon(
              _frontCamera ? Icons.camera_front : Icons.camera_rear,
              color: Colors.white,
            ),
            iconSize: 32.0,
            onPressed: () {
              cameraController.switchCamera();
              setState(() => _frontCamera = !_frontCamera);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera view
          MobileScanner(controller: cameraController, onDetect: _onDetect),

          // Overlay with scan frame
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: [
                  // Corner decorations
                  _corner(Alignment.topLeft),
                  _corner(Alignment.topRight),
                  _corner(Alignment.bottomLeft),
                  _corner(Alignment.bottomRight),
                ],
              ),
            ),
          ),

          // Instructions
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Column(
              children: [
                const Icon(
                  Icons.qr_code_scanner,
                  color: Colors.white54,
                  size: 28,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Point camera at the book\'s QR code',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: () => context.pop(),
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Colors.white54,
                    size: 18,
                  ),
                  label: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Decorative corner widget for scan frame
  Widget _corner(Alignment alignment) {
    const double size = 24;
    const double thickness = 3;
    const color = Colors.green;

    return Align(
      alignment: alignment,
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _CornerPainter(
            alignment: alignment,
            color: color,
            thickness: thickness,
          ),
        ),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final Alignment alignment;
  final Color color;
  final double thickness;

  const _CornerPainter({
    required this.alignment,
    required this.color,
    required this.thickness,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final isLeft = alignment.x < 0;
    final isTop = alignment.y < 0;

    final double x = isLeft ? 0 : size.width;
    final double y = isTop ? 0 : size.height;

    // Horizontal line
    canvas.drawLine(
      Offset(x, y),
      Offset(isLeft ? size.width * 0.6 : size.width * 0.4, y),
      paint,
    );

    // Vertical line
    canvas.drawLine(
      Offset(x, y),
      Offset(x, isTop ? size.height * 0.6 : size.height * 0.4),
      paint,
    );
  }

  @override
  bool shouldRepaint(_CornerPainter old) => false;
}
