import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'dart:async';
import 'dart:typed_data';

// ══════════════════════════════════════════════════
// THEME
// ══════════════════════════════════════════════════

class AppColors {
  static const darkGreen = Color(0xFF1B4332);
  static const midGreen = Color(0xFF00695C);
  static const lightTeal = Color(0xFFB2DFDB);
  static const bgLight = Color(0xFFF0F7F5);
  static const cardWhite = Color(0xFFFFFFFF);
  static const borderSoft = Color(0xFFE1F0ED);
  static const textMuted = Color(0xFF90A4AA);
  static const textDark = Color(0xFF1B4332);
  static const purple = Color(0xFF5B5BD6);
  static const purpleLight = Color(0xFFEEF0FF);
  static const amber = Color(0xFFF59E0B);
  static const amberLight = Color(0xFFFFF8E1);
  static const redAccent = Color(0xFFC9432B);
  static const redLight = Color(0xFFFFEBE8);
  static const blueAccent = Color(0xFF1565C0);
  static const blueLight = Color(0xFFE3F2FD);
}

// ══════════════════════════════════════════════════
// ENUMS
// ══════════════════════════════════════════════════

enum FootSide { left, right, both }
enum CameraPhase { side, top }

// ══════════════════════════════════════════════════
// FOOT DETECTOR
// ══════════════════════════════════════════════════

List _reshapeInput(Float32List flat, int h, int w, int c) {
  return [
    List.generate(
      h,
      (y) => List.generate(
        w,
        (x) => List.generate(c, (ch) => flat[(y * w + x) * c + ch]),
      ),
    )
  ];
}

class FootDetector {
  Interpreter? _interpreter;
  List<String> _labels = [];
  bool _isReady = false;
  static const int inputSize = 224;

  static const _footOnlyLabels = {
    'foot', 'feet', 'toe', 'toes', 'heel', 'ankle', 'sole',
    'barefoot', 'bare foot', 'bare_foot',
    'shoe', 'sneaker', 'boot', 'sandal', 'loafer', 'slipper',
    'sock', 'stocking', 'hosiery', 'clog', 'moccasin',
    'pump', 'stiletto', 'wedge', 'plantar', 'arch',
    'instep', 'nail', 'digit',
  };

  bool get isReady => _isReady;

  Future<void> init() async {
    try {
      _interpreter = await Interpreter.fromAsset(
        'assets/models/mobilenet_v1.tflite',
        options: InterpreterOptions()..threads = 2,
      );
      final raw =
          await rootBundle.loadString('assets/models/mobilenet_labels.txt');
      _labels = raw
          .split('\n')
          .map((l) => l.trim().toLowerCase())
          .where((l) => l.isNotEmpty)
          .toList();
      _isReady = true;
    } catch (e) {
      debugPrint('FootDetector init error: $e');
      _isReady = false;
    }
  }

  Future<double> detect(CameraImage cameraImage) async {
    if (!_isReady || _interpreter == null) return -1;
    try {
      final imgLib = _convertCameraImage(cameraImage);
      if (imgLib == null) return -1;
      final resized = img.copyResize(imgLib,
          width: inputSize,
          height: inputSize,
          interpolation: img.Interpolation.linear);
      final input = Float32List(inputSize * inputSize * 3);
      int idx = 0;
      for (int y = 0; y < inputSize; y++) {
        for (int x = 0; x < inputSize; x++) {
          final pixel = resized.getPixel(x, y);
          input[idx++] = (pixel.r / 127.5) - 1.0;
          input[idx++] = (pixel.g / 127.5) - 1.0;
          input[idx++] = (pixel.b / 127.5) - 1.0;
        }
      }
      final inputTensor = _reshapeInput(input, inputSize, inputSize, 3);
      final outputSize = _labels.isNotEmpty ? _labels.length : 1001;
      final outputBuffer = List<double>.filled(outputSize, 0.0);
      final outputTensor = [outputBuffer];
      _interpreter!.run(inputTensor, outputTensor);
      double footScore = 0;
      for (int i = 0; i < outputBuffer.length && i < _labels.length; i++) {
        final label = _labels[i];
        if (_footOnlyLabels.any((kw) => label.contains(kw))) {
          footScore += outputBuffer[i];
        }
      }
      return footScore.clamp(0.0, 1.0);
    } catch (e) {
      debugPrint('FootDetector detect error: $e');
      return -1;
    }
  }

  img.Image? _convertCameraImage(CameraImage cam) {
    try {
      if (cam.format.group == ImageFormatGroup.nv21) return _nv21ToImage(cam);
      if (cam.format.group == ImageFormatGroup.yuv420)
        return _yuv420ToImage(cam);
      if (cam.format.group == ImageFormatGroup.bgra8888)
        return _bgra8888ToImage(cam);
      return null;
    } catch (_) {
      return null;
    }
  }

  img.Image _nv21ToImage(CameraImage cam) {
    final w = cam.width, h = cam.height;
    final yPlane = cam.planes[0].bytes;
    final uvPlane = cam.planes[1].bytes;
    final out = img.Image(width: w, height: h);
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final yVal = yPlane[y * w + x];
        final uvIdx = (y ~/ 2) * (w ~/ 2 * 2) + (x ~/ 2) * 2;
        final v = uvPlane[uvIdx] - 128;
        final u = uvPlane[uvIdx + 1] - 128;
        out.setPixelRgb(
          x, y,
          (yVal + 1.402 * v).round().clamp(0, 255),
          (yVal - 0.344136 * u - 0.714136 * v).round().clamp(0, 255),
          (yVal + 1.772 * u).round().clamp(0, 255),
        );
      }
    }
    return out;
  }

  img.Image _yuv420ToImage(CameraImage cam) {
    final w = cam.width, h = cam.height;
    final yPlane = cam.planes[0].bytes;
    final uPlane = cam.planes[1].bytes;
    final vPlane = cam.planes[2].bytes;
    final uvRowStride = cam.planes[1].bytesPerRow;
    final uvPixelStride = cam.planes[1].bytesPerPixel ?? 1;
    final out = img.Image(width: w, height: h);
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final yVal = yPlane[y * cam.planes[0].bytesPerRow + x];
        final uvIdx = (y ~/ 2) * uvRowStride + (x ~/ 2) * uvPixelStride;
        final u = uPlane[uvIdx] - 128;
        final v = vPlane[uvIdx] - 128;
        out.setPixelRgb(
          x, y,
          (yVal + 1.402 * v).round().clamp(0, 255),
          (yVal - 0.344136 * u - 0.714136 * v).round().clamp(0, 255),
          (yVal + 1.772 * u).round().clamp(0, 255),
        );
      }
    }
    return out;
  }

  img.Image _bgra8888ToImage(CameraImage cam) {
    final w = cam.width, h = cam.height;
    final bytes = cam.planes[0].bytes;
    final out = img.Image(width: w, height: h);
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final idx = (y * cam.planes[0].bytesPerRow) + x * 4;
        out.setPixelRgb(x, y, bytes[idx + 2], bytes[idx + 1], bytes[idx]);
      }
    }
    return out;
  }

  void dispose() => _interpreter?.close();
}

// ══════════════════════════════════════════════════
// SCAN SCREEN
// ══════════════════════════════════════════════════

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.94, end: 1.0).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _openCamera({required FootSide side, bool fullScan = false}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CameraScreen(
          footSide: side,
          isFullScan: fullScan,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top Bar ──
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: const TextSpan(children: [
                              TextSpan(
                                  text: 'Step',
                                  style: TextStyle(
                                      color: AppColors.midGreen,
                                      fontSize: 26,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -1)),
                              TextSpan(
                                  text: 'Fit',
                                  style: TextStyle(
                                      color: AppColors.midGreen,
                                      fontSize: 26,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -1)),
                            ]),
                          ),
                          const Text('AI Foot Analysis',
                              style: TextStyle(
                                  color: AppColors.textMuted, fontSize: 11)),
                        ]),
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.cardWhite,
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: AppColors.lightTeal, width: 1.5),
                      ),
                      child: const Icon(Icons.notifications_outlined,
                          color: AppColors.midGreen, size: 20),
                    ),
                  ],
                ),
              ),

              // ── Hero Banner ──
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: AppColors.darkGreen,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Precision\nFit Engine',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    height: 1.1,
                                    letterSpacing: -0.8)),
                            const SizedBox(height: 8),
                            Text(
                              'Side scan + Top scan\nfor exact sizing',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 12,
                                  height: 1.5),
                            ),
                          ],
                        ),
                      ),
                      AnimatedBuilder(
                        animation: _pulseAnim,
                        builder: (context, _) => Transform.scale(
                          scale: _pulseAnim.value,
                          child: Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.midGreen.withOpacity(0.4),
                              border: Border.all(
                                  color: AppColors.lightTeal.withOpacity(0.3),
                                  width: 1.5),
                            ),
                            child: const Icon(Icons.directions_walk_rounded,
                                color: AppColors.lightTeal, size: 44),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Stat Cards ──
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(children: [
                  _StatCard(
                      icon: Icons.straighten_rounded,
                      label: 'Length',
                      color: AppColors.purple,
                      bgColor: AppColors.purpleLight),
                  const SizedBox(width: 10),
                  _StatCard(
                      icon: Icons.swap_horiz_rounded,
                      label: 'Width',
                      color: AppColors.midGreen,
                      bgColor: const Color(0xFFE8F5E9)),
                  const SizedBox(width: 10),
                  _StatCard(
                      icon: Icons.show_chart_rounded,
                      label: 'Arch',
                      color: AppColors.redAccent,
                      bgColor: AppColors.redLight),
                ]),
              ),

              // ── Section: Scan ──
              const _SectionHeader(
                  title: 'Start scanning',
                  barColor: AppColors.midGreen,
                  topPad: 28),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 4, 20, 14),
                child: Text(
                  'Side + Top scans together give the most accurate shoe size',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ),

              // ── Combined Scan Card ──
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                child: _CombinedScanCard(
                  onTap: () => _openCamera(side: FootSide.both, fullScan: true),
                ),
              ),

              // ── Scan Guide ──
              const _SectionHeader(
                  title: 'Scan guide',
                  barColor: AppColors.purple,
                  topPad: 20),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(children: const [
                  _GuideStep(
                      n: '01',
                      icon: Icons.wb_sunny_outlined,
                      title: 'Good lighting',
                      desc: 'Natural daylight or bright indoor light works best.',
                      color: AppColors.amber,
                      bg: AppColors.amberLight),
                  SizedBox(height: 8),
                  _GuideStep(
                      n: '02',
                      icon: Icons.crop_free_rounded,
                      title: 'Frame your foot',
                      desc: 'Keep your bare foot fully visible in the camera.',
                      color: AppColors.midGreen,
                      bg: Color(0xFFE8F5E9)),
                  SizedBox(height: 8),
                  _GuideStep(
                      n: '03',
                      icon: Icons.back_hand_outlined,
                      title: 'Hold steady',
                      desc: 'No blur = better measurements. 3s still is enough.',
                      color: AppColors.purple,
                      bg: AppColors.purpleLight),
                  SizedBox(height: 8),
                  _GuideStep(
                      n: '04',
                      icon: Icons.layers_outlined,
                      title: 'Flat surface',
                      desc: 'Hard floor only — avoid rugs or uneven surfaces.',
                      color: AppColors.redAccent,
                      bg: AppColors.redLight),
                  SizedBox(height: 8),
                  _GuideStep(
                      n: '05',
                      icon: Icons.accessibility_new_rounded,
                      title: 'Bare foot',
                      desc: 'Remove socks and shoes before scanning.',
                      color: AppColors.blueAccent,
                      bg: AppColors.blueLight),
                ]),
              ),

              // ── Pro Tip ──
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.darkGreen,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                          color: AppColors.midGreen.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.lightbulb_outline_rounded,
                          color: AppColors.lightTeal, size: 22),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Pro tip',
                                style: TextStyle(
                                    color: AppColors.lightTeal,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700)),
                            SizedBox(height: 4),
                            Text(
                              'Most people have slightly different foot sizes. Always scan both and use the larger measurement.',
                              style: TextStyle(
                                  color: Colors.white60,
                                  fontSize: 12,
                                  height: 1.5),
                            ),
                          ]),
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),

      // ── Bottom Nav ──
      bottomNavigationBar: Container(
        height: 68,
        decoration: const BoxDecoration(
          color: AppColors.cardWhite,
          border: Border(top: BorderSide(color: AppColors.borderSoft)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(icon: Icons.home_outlined, label: 'Home', isActive: false),
            _NavItem(icon: Icons.document_scanner_rounded, label: 'Scan', isActive: true),
            _NavItem(icon: Icons.bar_chart_rounded, label: 'Results', isActive: false),
            _NavItem(icon: Icons.person_outlined, label: 'Profile', isActive: false),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════
// COMBINED SCAN CARD
// ══════════════════════════════════════════════════

class _CombinedScanCard extends StatelessWidget {
  final VoidCallback onTap;
  const _CombinedScanCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.lightTeal, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.document_scanner_rounded,
                      color: AppColors.midGreen, size: 26),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Scan my foot',
                            style: TextStyle(
                                color: AppColors.textDark,
                                fontSize: 15,
                                fontWeight: FontWeight.w800)),
                        SizedBox(height: 4),
                        Text('Side view + Top view scan',
                            style: TextStyle(
                                color: AppColors.textMuted, fontSize: 12)),
                      ]),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.lightTeal, size: 22),
              ],
            ),
            const SizedBox(height: 14),
            Row(children: [
              _ScanPhaseBadge(
                  icon: Icons.view_sidebar_outlined,
                  label: 'Side view',
                  sub: 'Arch + Length',
                  color: AppColors.purple,
                  bg: AppColors.purpleLight),
              const SizedBox(width: 10),
              _ScanPhaseBadge(
                  icon: Icons.crop_portrait_rounded,
                  label: 'Top view',
                  sub: 'Width + Length',
                  color: AppColors.midGreen,
                  bg: const Color(0xFFE8F5E9)),
            ]),
          ],
        ),
      ),
    );
  }
}

class _ScanPhaseBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;
  final Color color;
  final Color bg;
  const _ScanPhaseBadge(
      {required this.icon,
      required this.label,
      required this.sub,
      required this.color,
      required this.bg});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
            color: bg, borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w800)),
            Text(sub,
                style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 9,
                    fontWeight: FontWeight.w600)),
          ]),
        ]),
      ),
    );
  }
}

// ══════════════════════════════════════════════════
// CAMERA SCREEN
// ══════════════════════════════════════════════════

class CameraScreen extends StatefulWidget {
  final FootSide footSide;
  final bool isFullScan;

  const CameraScreen({
    super.key,
    required this.footSide,
    this.isFullScan = false,
  });

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with TickerProviderStateMixin {
  CameraController? _controller;
  bool _isInitialized = false;
  bool _flashOn = false;

  final FootDetector _detector = FootDetector();
  bool _detectorReady = false;
  bool _isDetecting = false;
  bool _footDetected = false;
  double _aiConfidence = 0.0;
  double _smoothedConf = 0.0;
  String _statusMsg = 'Initializing AI…';

  bool _isScanning = false;
  double _scanProgress = 0;
  bool _manualOverride = false;

  CameraPhase _phase = CameraPhase.side;
  FootSide _currentSide = FootSide.left;
  bool _leftSideDone = false;
  bool _rightSideDone = false;
  bool _leftTopDone = false;
  bool _rightTopDone = false;

  late AnimationController _scanLineCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _cornerCtrl;
  late AnimationController _glowCtrl;

  late Animation<double> _scanLineAnim;
  late Animation<double> _pulseAnim;
  late Animation<double> _cornerAnim;
  late Animation<double> _glowAnim;

  static const double _threshold = 0.03;
  static const double _ema = 0.35;

  @override
  void initState() {
    super.initState();
    _currentSide =
        widget.footSide == FootSide.right ? FootSide.right : FootSide.left;

    _scanLineCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _cornerCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 4))
          ..repeat();
    _glowCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);

    _scanLineAnim = Tween<double>(begin: 0.15, end: 0.85)
        .animate(CurvedAnimation(parent: _scanLineCtrl, curve: Curves.easeInOut));
    _pulseAnim = Tween<double>(begin: 0.96, end: 1.04).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _cornerAnim = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _cornerCtrl, curve: Curves.linear));
    _glowAnim = Tween<double>(begin: 0.3, end: 0.8).animate(
        CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));

    _initAll();
  }

  Future<void> _initAll() async {
    await _detector.init();
    if (mounted) {
      setState(() {
        _detectorReady = _detector.isReady;
        _statusMsg = _prompt();
      });
    }
    await _initCamera();
  }

  String _prompt() {
    final sideStr = _currentSide == FootSide.left ? 'Left' : 'Right';
    if (_phase == CameraPhase.side) {
      return 'Show $sideStr foot from the side';
    } else {
      return 'Point camera down at $sideStr foot';
    }
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;
      _controller = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup:
            Platform.isIOS ? ImageFormatGroup.bgra8888 : ImageFormatGroup.nv21,
      );
      await _controller!.initialize();
      if (!mounted) return;
      setState(() => _isInitialized = true);
      _controller!.startImageStream(_onFrame);
    } catch (e) {
      debugPrint('Camera error: $e');
      if (mounted)
        setState(() => _statusMsg = 'Camera error — check permissions');
    }
  }

  Future<void> _toggleFlash() async {
    if (_controller == null || !_isInitialized) return;
    try {
      _flashOn = !_flashOn;
      await _controller!
          .setFlashMode(_flashOn ? FlashMode.torch : FlashMode.off);
      setState(() {});
    } catch (e) {
      debugPrint('Flash error: $e');
    }
  }

  void _onFrame(CameraImage image) async {
    if (_isDetecting || !_detectorReady || _isScanning) return;
    _isDetecting = true;
    final score = await _detector.detect(image);
    if (mounted) {
      setState(() {
        if (score >= 0) {
          _smoothedConf = _ema * score + (1 - _ema) * _smoothedConf;
          _aiConfidence = _smoothedConf;
          _footDetected = _smoothedConf >= _threshold;
          if (!_isScanning)
            _statusMsg = _footDetected ? 'Foot detected — tap to scan!' : _prompt();
        }
      });
    }
    _isDetecting = false;
  }

  @override
  void dispose() {
    _controller?.stopImageStream();
    _controller?.dispose();
    _detector.dispose();
    _scanLineCtrl.dispose();
    _pulseCtrl.dispose();
    _cornerCtrl.dispose();
    _glowCtrl.dispose();
    _controller?.setFlashMode(FlashMode.off).catchError((_) {});
    super.dispose();
  }

  bool get _canScan => _footDetected || _manualOverride;

  void _startScan() {
    if (!_canScan) {
      setState(() => _manualOverride = true);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Row(children: [
          Icon(Icons.info_outline_rounded, color: Colors.white, size: 18),
          SizedBox(width: 8),
          Expanded(child: Text('Manual mode — tap Scan again to proceed'))
        ]),
        backgroundColor: AppColors.purple,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ));
      return;
    }

    setState(() {
      _isScanning = true;
      _scanProgress = 0;
      _manualOverride = false;
    });
    _controller?.stopImageStream();

    Timer.periodic(const Duration(milliseconds: 40), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_scanProgress >= 100) {
        t.cancel();
        setState(() => _isScanning = false);
        _handleScanComplete();
      } else {
        setState(() => _scanProgress += 1.2);
      }
    });
  }

  void _handleScanComplete() {
    if (!widget.isFullScan) {
      _showResult();
      return;
    }

    final isBothFeet = widget.footSide == FootSide.both;

    if (_phase == CameraPhase.side) {
      if (isBothFeet) {
        if (_currentSide == FootSide.left && !_rightSideDone) {
          setState(() {
            _leftSideDone = true;
            _currentSide = FootSide.right;
            _resetDetection();
          });
          _controller?.startImageStream(_onFrame);
          return;
        } else {
          setState(() {
            _rightSideDone = true;
            _phase = CameraPhase.top;
            _currentSide = FootSide.left;
            _resetDetection();
          });
          _showPhaseTransitionSheet();
          return;
        }
      } else {
        setState(() {
          _phase = CameraPhase.top;
          _resetDetection();
        });
        _showPhaseTransitionSheet();
        return;
      }
    }

    if (_phase == CameraPhase.top) {
      if (isBothFeet) {
        if (_currentSide == FootSide.left && !_rightTopDone) {
          setState(() {
            _leftTopDone = true;
            _currentSide = FootSide.right;
            _resetDetection();
          });
          _controller?.startImageStream(_onFrame);
          return;
        } else {
          setState(() => _rightTopDone = true);
          _showResult();
          return;
        }
      } else {
        _showResult();
      }
    }
  }

  void _resetDetection() {
    _smoothedConf = 0;
    _aiConfidence = 0;
    _footDetected = false;
    _scanProgress = 0;
    _statusMsg = _prompt();
  }

  void _showPhaseTransitionSheet() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      backgroundColor: AppColors.cardWhite,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => _PhaseTransitionSheet(
        onContinue: () {
          Navigator.pop(context);
          _controller?.startImageStream(_onFrame);
        },
      ),
    );
  }

  void _showResult() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ResultDialog(
        isFullScan: widget.isFullScan,
        onScanAgain: () {
          Navigator.pop(context);
          setState(() {
            _phase = CameraPhase.side;
            _currentSide = widget.footSide == FootSide.right
                ? FootSide.right
                : FootSide.left;
            _leftSideDone = false;
            _rightSideDone = false;
            _leftTopDone = false;
            _rightTopDone = false;
            _manualOverride = false;
            _resetDetection();
          });
          _controller?.startImageStream(_onFrame);
        },
        onDone: () {
          Navigator.pop(context);
          Navigator.pop(context);
        },
      ),
    );
  }

  String get _progressLabel {
    if (!widget.isFullScan) {
      return _phase == CameraPhase.side ? 'Side view' : 'Top view';
    }
    final isBoth = widget.footSide == FootSide.both;
    if (_phase == CameraPhase.side) {
      return isBoth
          ? (_currentSide == FootSide.left ? 'Side — Left' : 'Side — Right')
          : 'Side view';
    } else {
      return isBoth
          ? (_currentSide == FootSide.left ? 'Top — Left' : 'Top — Right')
          : 'Top view';
    }
  }

  int get _totalSteps =>
      widget.isFullScan ? (widget.footSide == FootSide.both ? 4 : 2) : 1;

  int get _completedSteps {
    int done = 0;
    if (_leftSideDone) done++;
    if (_rightSideDone) done++;
    if (_leftTopDone) done++;
    if (_rightTopDone) done++;
    return done;
  }

  String get _sideLabel {
    if (widget.footSide == FootSide.both) {
      return _currentSide == FootSide.left ? 'Left' : 'Right';
    }
    return widget.footSide == FootSide.left ? 'Left' : 'Right';
  }

  String get _phaseLabel =>
      _phase == CameraPhase.side ? 'SIDE VIEW' : 'TOP VIEW';

  bool get isReady => _canScan;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.darkGreen,
      body: Stack(children: [
        if (_isInitialized && _controller != null)
          Positioned.fill(child: CameraPreview(_controller!))
        else
          Positioned.fill(
            child: Container(
              color: AppColors.darkGreen,
              child: Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(
                      color: AppColors.midGreen,
                      strokeWidth: 2,
                      backgroundColor: AppColors.midGreen.withOpacity(0.15),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Starting camera…',
                      style: TextStyle(
                          color: AppColors.lightTeal.withOpacity(0.4),
                          fontSize: 13,
                          letterSpacing: 0.5)),
                ]),
              ),
            ),
          ),

        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [
                  Colors.transparent,
                  AppColors.darkGreen.withOpacity(0.5),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 0, left: 0, right: 0, height: 200,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.darkGreen.withOpacity(0.85),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 0, left: 0, right: 0, height: 280,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  AppColors.darkGreen.withOpacity(0.95),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        Positioned.fill(
          child: _ScanFrame(
            isDetected: isReady,
            isScanning: _isScanning,
            scanLineAnim: _scanLineAnim,
            cornerAnim: _cornerAnim,
            glowAnim: _glowAnim,
            pulseAnim: _pulseAnim,
          ),
        ),

        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Row(
              children: [
                _TopBtn(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => Navigator.pop(context)),
                const Spacer(),
                RichText(
                  text: const TextSpan(children: [
                    TextSpan(
                        text: 'Step',
                        style: TextStyle(
                            color: AppColors.lightTeal,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5)),
                    TextSpan(
                        text: 'Fit',
                        style: TextStyle(
                            color: AppColors.lightTeal,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5)),
                  ]),
                ),
                const Spacer(),
                _TopBtn(
                    icon: _flashOn
                        ? Icons.flash_on_rounded
                        : Icons.flash_off_rounded,
                    active: _flashOn,
                    onTap: _toggleFlash),
              ],
            ),
          ),
        ),

        SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 68),
              child: _PhaseBadge(
                label: _phaseLabel,
                isDetected: isReady,
                isScanning: _isScanning,
                progress: _scanProgress,
              ),
            ),
          ),
        ),

        if (widget.isFullScan)
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 116),
                child: _FullScanStepBar(
                  totalSteps: _totalSteps,
                  completedSteps: _completedSteps,
                  currentPhase: _phase,
                  isBothFeet: widget.footSide == FootSide.both,
                  currentSide: _currentSide,
                  leftSideDone: _leftSideDone,
                  rightSideDone: _rightSideDone,
                  leftTopDone: _leftTopDone,
                  rightTopDone: _rightTopDone,
                ),
              ),
            ),
          ),

        Positioned(
          top: size.height * 0.38,
          left: 20,
          right: 20,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: isReady
                    ? AppColors.midGreen.withOpacity(0.25)
                    : AppColors.darkGreen.withOpacity(0.7),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                    color: isReady
                        ? AppColors.midGreen.withOpacity(0.6)
                        : AppColors.midGreen.withOpacity(0.3)),
              ),
              child: Text(_statusMsg,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: isReady
                          ? AppColors.lightTeal
                          : AppColors.lightTeal.withOpacity(0.6),
                      fontSize: 13,
                      fontWeight: FontWeight.w700)),
            ),
          ),
        ),

        Positioned(
          bottom: 190,
          left: 32,
          right: 32,
          child: _isScanning
              ? _ScanProgressBar(label: _progressLabel, progress: _scanProgress)
              : _ConfidenceBar(confidence: _aiConfidence, isReady: isReady),
        ),

        Positioned(
          bottom: 0, left: 0, right: 0,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!_isScanning)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                                isReady
                                    ? Icons.check_circle_rounded
                                    : Icons.radio_button_unchecked_rounded,
                                color: isReady
                                    ? AppColors.midGreen
                                    : AppColors.lightTeal.withOpacity(0.3),
                                size: 13),
                            const SizedBox(width: 6),
                            Text(
                              isReady
                                  ? '$_sideLabel foot detected'
                                  : 'No foot detected — tap to override',
                              style: TextStyle(
                                  color: isReady
                                      ? AppColors.lightTeal
                                      : AppColors.lightTeal.withOpacity(0.5),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600),
                            ),
                          ]),
                    ),
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: _isScanning ? null : _startScan,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isReady ? AppColors.midGreen : AppColors.darkGreen,
                        foregroundColor: isReady
                            ? Colors.white
                            : AppColors.lightTeal.withOpacity(0.7),
                        disabledBackgroundColor:
                            AppColors.midGreen.withOpacity(0.7),
                        disabledForegroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18)),
                        elevation: isReady ? 10 : 0,
                        shadowColor: AppColors.midGreen.withOpacity(0.4),
                      ),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _isScanning
                                  ? Icons.hourglass_top_rounded
                                  : isReady
                                      ? Icons.camera_alt_rounded
                                      : Icons.touch_app_rounded,
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _isScanning
                                  ? 'Scanning…'
                                  : isReady
                                      ? 'Scan $_sideLabel foot'
                                      : 'Tap to scan manually',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w800),
                            ),
                          ]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════
// HELPER WIDGETS
// ══════════════════════════════════════════════════

class _TopBtn extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  const _TopBtn({required this.icon, this.active = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.4),
          shape: BoxShape.circle,
        ),
        child: Icon(icon,
            color: active ? AppColors.amber : Colors.white, size: 20),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bgColor;
  const _StatCard(
      {required this.icon,
      required this.label,
      required this.color,
      required this.bgColor});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
            color: bgColor, borderRadius: BorderRadius.circular(14)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Color barColor;
  final double topPad;
  const _SectionHeader(
      {required this.title,
      required this.barColor,
      required this.topPad});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, topPad, 20, 0),
      child: Row(
        children: [
          Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: BorderRadius.circular(4))),
          const SizedBox(width: 10),
          Text(title,
              style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 16,
                  fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _GuideStep extends StatelessWidget {
  final String n;
  final IconData icon;
  final String title;
  final String desc;
  final Color color;
  final Color bg;
  const _GuideStep(
      {required this.n,
      required this.icon,
      required this.title,
      required this.desc,
      required this.color,
      required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Text(n,
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w900,
                  fontSize: 16)),
          const SizedBox(width: 14),
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 13)),
                const SizedBox(height: 2),
                Text(desc,
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 11)),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  const _NavItem(
      {required this.icon,
      required this.label,
      required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon,
            color:
                isActive ? AppColors.midGreen : AppColors.textMuted,
            size: 22),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(
                color: isActive
                    ? AppColors.midGreen
                    : AppColors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _ScanFrame extends StatelessWidget {
  final bool isDetected;
  final bool isScanning;
  final Animation<double> scanLineAnim;
  final Animation<double> cornerAnim;
  final Animation<double> glowAnim;
  final Animation<double> pulseAnim;

  const _ScanFrame(
      {required this.isDetected,
      required this.isScanning,
      required this.scanLineAnim,
      required this.cornerAnim,
      required this.glowAnim,
      required this.pulseAnim});

  @override
  Widget build(BuildContext context) {
    return const Center(
        child: Text('Scan Frame Overlay',
            style: TextStyle(color: Colors.white30)));
  }
}

class _PhaseBadge extends StatelessWidget {
  final String label;
  final bool isDetected;
  final bool isScanning;
  final double progress;
  const _PhaseBadge(
      {required this.label,
      required this.isDetected,
      required this.isScanning,
      required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 12)),
    );
  }
}

class _FullScanStepBar extends StatelessWidget {
  final int totalSteps;
  final int completedSteps;
  final CameraPhase currentPhase;
  final bool isBothFeet;
  final FootSide currentSide;
  final bool leftSideDone;
  final bool rightSideDone;
  final bool leftTopDone;
  final bool rightTopDone;

  const _FullScanStepBar(
      {required this.totalSteps,
      required this.completedSteps,
      required this.currentPhase,
      required this.isBothFeet,
      required this.currentSide,
      required this.leftSideDone,
      required this.rightSideDone,
      required this.leftTopDone,
      required this.rightTopDone});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalSteps, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: index < completedSteps
                ? AppColors.lightTeal
                : Colors.white24,
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }
}

class _ScanProgressBar extends StatelessWidget {
  final String label;
  final double progress;
  const _ScanProgressBar({required this.label, required this.progress});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 11)),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
              value: progress / 100,
              minHeight: 6,
              backgroundColor: Colors.white24,
              valueColor:
                  const AlwaysStoppedAnimation(AppColors.midGreen)),
        )
      ],
    );
  }
}

class _ConfidenceBar extends StatelessWidget {
  final double confidence;
  final bool isReady;
  const _ConfidenceBar({required this.confidence, required this.isReady});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Confidence: ${(confidence * 100).toStringAsFixed(1)}%',
            style: const TextStyle(color: Colors.white70, fontSize: 11)),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
              value: confidence,
              minHeight: 4,
              backgroundColor: Colors.white24,
              valueColor: AlwaysStoppedAnimation(
                  isReady ? AppColors.midGreen : Colors.amber)),
        )
      ],
    );
  }
}

class _PhaseTransitionSheet extends StatelessWidget {
  final VoidCallback onContinue;
  const _PhaseTransitionSheet({required this.onContinue});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Great job!',
              style:
                  TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          const Text("Now, let's scan from the top.",
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted)),
          const SizedBox(height: 24),
          SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                  onPressed: onContinue,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.midGreen),
                  child: const Text('Continue'))),
        ],
      ),
    );
  }
}

class _ResultDialog extends StatelessWidget {
  final bool isFullScan;
  final VoidCallback onScanAgain;
  final VoidCallback onDone;
  const _ResultDialog(
      {required this.isFullScan,
      required this.onScanAgain,
      required this.onDone});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Scan Complete!'),
      content: const Text(
          'Your foot measurements have been processed successfully.'),
      actions: [
        TextButton(
            onPressed: onScanAgain, child: const Text('Scan Again')),
        ElevatedButton(
            onPressed: onDone,
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.midGreen),
            child: const Text('Done')),
      ],
    );
  }
}