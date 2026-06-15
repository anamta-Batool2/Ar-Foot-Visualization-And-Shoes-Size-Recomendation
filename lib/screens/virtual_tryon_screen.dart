// virtual_try_on.dart
// ONE screen — Live AR camera with shoe overlay
// Packages needed in pubspec.yaml:
//   camera: ^0.10.5+9
//   image_picker: ^1.1.2
//
// AndroidManifest.xml mein add karo (android/app/src/main/AndroidManifest.xml):
//   <uses-permission android:name="android.permission.CAMERA"/>
//   <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
//   <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
//
// android/app/build.gradle mein:
//   minSdkVersion 21

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';

// ══════════════════════════════════════════════════
// COLORS
// ══════════════════════════════════════════════════

class _C {
  static const darkGreen   = Color(0xFF1B4332);
  static const midGreen    = Color(0xFF00695C);
  static const lightTeal   = Color(0xFFB2DFDB);
  static const bgLight     = Color(0xFFF0F7F5);
  static const cardWhite   = Color(0xFFFFFFFF);
  static const borderSoft  = Color(0xFFE1F0ED);
  static const textMuted   = Color(0xFF90A4AA);
  static const textDark    = Color(0xFF1B4332);
  static const purple      = Color(0xFF5B5BD6);
  static const purpleLight = Color(0xFFEEF0FF);
  static const amber       = Color(0xFFF59E0B);
  static const amberLight  = Color(0xFFFFF8E1);
}

// ══════════════════════════════════════════════════
// SHOE MODEL
// ══════════════════════════════════════════════════

class _Shoe {
  final String emoji;
  final String name;
  final String price;
  final Color accent;
  final Color accentLight;
  final List<String> sizes;
  const _Shoe({
    required this.emoji, required this.name, required this.price,
    required this.accent, required this.accentLight, required this.sizes,
  });
}

const List<_Shoe> _catalogue = [
  _Shoe(emoji: '👟', name: 'AirStep Pro',  price: '\$129',
        accent: _C.midGreen, accentLight: Color(0xFFE8F5E9),
        sizes: ['6','7','7.5','8','8.5','9','10','11']),
  _Shoe(emoji: '🥿', name: 'UrbanFlow',    price: '\$89',
        accent: _C.purple,   accentLight: _C.purpleLight,
        sizes: ['5','6','6.5','7','8','9']),
  _Shoe(emoji: '👠', name: 'ElevateFit',   price: '\$109',
        accent: Color(0xFFC9432B), accentLight: Color(0xFFFFEBE8),
        sizes: ['5','6','7','8','9']),
  _Shoe(emoji: '🥾', name: 'TrailBound',   price: '\$159',
        accent: _C.amber,    accentLight: _C.amberLight,
        sizes: ['7','8','9','10','11','12']),
  _Shoe(emoji: '👡', name: 'SoftStep',     price: '\$79',
        accent: Color(0xFF1565C0), accentLight: Color(0xFFE3F2FD),
        sizes: ['5','6','6.5','7','8']),
  _Shoe(emoji: '🩴', name: 'BreezeWalk',   price: '\$59',
        accent: _C.midGreen, accentLight: Color(0xFFE8F5E9),
        sizes: ['6','7','8','9','10','11']),
];

// ══════════════════════════════════════════════════
// ENTRY POINT HELPER
// Call this from main.dart:
//   final cameras = await availableCameras();
//   runApp(MyApp(cameras: cameras));
// ══════════════════════════════════════════════════

// ══════════════════════════════════════════════════
// MAIN SCREEN
// ══════════════════════════════════════════════════

class VirtualTryOnScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  const VirtualTryOnScreen({super.key, required this.cameras});

  @override
  State<VirtualTryOnScreen> createState() => _VirtualTryOnScreenState();
}

class _VirtualTryOnScreenState extends State<VirtualTryOnScreen>
    with WidgetsBindingObserver {

  // ── Shoe selection ──
  int   _shoeIndex  = 0;
  String? _size;

  // ── Mode: camera live | gallery photo ──
  bool  _isLiveCamera = false;
  File? _galleryImage;

  // ── Camera ──
  CameraController? _camCtrl;
  bool _camReady = false;

  // ── Try-on state (gallery mode) ──
  bool _processing    = false;
  bool _tryOnComplete = false;

  final ImagePicker _picker = ImagePicker();

  _Shoe get _shoe => _catalogue[_shoeIndex];

  // ─────────────────────────────────────────────
  // LIFECYCLE
  // ─────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_camCtrl == null || !_camCtrl!.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      _camCtrl!.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _camCtrl?.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  // CAMERA
  // ─────────────────────────────────────────────

  Future<void> _initCamera() async {
    if (widget.cameras.isEmpty) return;
    final ctrl = CameraController(
      widget.cameras.first,
      ResolutionPreset.high,
      enableAudio: false,
    );
    try {
      await ctrl.initialize();
      if (!mounted) return;
      setState(() {
        _camCtrl  = ctrl;
        _camReady = true;
      });
    } catch (e) {
      _snack('Camera permission denied. Settings se allow karein.', Colors.red);
    }
  }

  void _openLiveCamera() async {
    setState(() {
      _isLiveCamera   = true;
      _galleryImage   = null;
      _tryOnComplete  = false;
    });
    await _initCamera();
  }

  void _closeCamera() {
    _camCtrl?.dispose();
    _camCtrl  = null;
    _camReady = false;
    setState(() => _isLiveCamera = false);
  }

  // ─────────────────────────────────────────────
  // GALLERY
  // ─────────────────────────────────────────────

  Future<void> _pickGallery() async {
    final XFile? f = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (f != null && mounted) {
      _closeCamera();
      setState(() {
        _galleryImage  = File(f.path);
        _tryOnComplete = false;
        _processing    = false;
      });
    }
  }

  // ─────────────────────────────────────────────
  // TRY-ON (gallery mode)
  // ─────────────────────────────────────────────

  void _startTryOn() {
    if (_galleryImage == null) { _snack('Pehle foot photo upload karein', _C.midGreen); return; }
    if (_size == null)         { _snack('Size choose karein', _C.amber);                return; }
    setState(() => _processing = true);
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) setState(() { _processing = false; _tryOnComplete = true; });
    });
  }

  void _snack(String msg, Color bg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: bg,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  // ─────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bgLight,
      body: _isLiveCamera ? _buildARScreen() : _buildMainScreen(),
    );
  }

  // ══════════════════════════════════════════════
  // SCREEN A — LIVE AR CAMERA
  // ══════════════════════════════════════════════

  Widget _buildARScreen() {
    return Stack(
      children: [

        // ── Camera preview (full screen) ──
        if (_camReady && _camCtrl != null)
          Positioned.fill(child: CameraPreview(_camCtrl!))
        else
          Container(
            color: Colors.black,
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          ),

        // ── Shoe strip (left side) ──
        Positioned(
          left: 12,
          top: 0,
          bottom: 0,
          child: SafeArea(
            child: Center(
              child: Container(
                width: 76,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(_catalogue.length, (i) {
                    final selected = i == _shoeIndex;
                    return GestureDetector(
                      onTap: () => setState(() => _shoeIndex = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: selected
                              ? _catalogue[i].accent.withAlpha(200)
                              : Colors.white12,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: selected
                                ? Colors.white
                                : Colors.white24,
                            width: selected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(_catalogue[i].emoji,
                                style: const TextStyle(fontSize: 24)),
                            if (selected)
                              Text(
                                _catalogue[i].price,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700),
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ),

        // ── AR shoe overlay on foot ──
        Positioned(
          bottom: 80,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: Center(
              child: Column(
                children: [
                  // Guide text
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Apna foot screen ke nichay rakho 👇',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Shoe AR overlay
                  Text(_shoe.emoji, style: const TextStyle(fontSize: 100)),
                  // Shoe name badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: _shoe.accent.withAlpha(220),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_shoe.name}  •  ${_shoe.price}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // ── Top bar ──
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(90, 12, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Buy button
                ElevatedButton.icon(
                  onPressed: () {
                    _closeCamera();
                    _snack('${_shoe.name} cart mein add ho gaya!', _C.midGreen);
                  },
                  icon: const Icon(Icons.shopping_bag_outlined, size: 16),
                  label: Text('Buy ${_shoe.price}'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _C.darkGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                  ),
                ),
                const SizedBox(width: 10),
                // Close
                GestureDetector(
                  onTap: _closeCamera,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded,
                        color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Size selector (bottom) ──
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            top: false,
            child: Container(
              color: Colors.black54,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Size choose karo',
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _shoe.sizes.map((s) {
                        final sel = _size == s;
                        return GestureDetector(
                          onTap: () => setState(() => _size = s),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            margin: const EdgeInsets.only(right: 8),
                            width: 48,
                            height: 38,
                            decoration: BoxDecoration(
                              color: sel
                                  ? _shoe.accent
                                  : Colors.white12,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: sel ? Colors.white : Colors.white30,
                              ),
                            ),
                            child: Center(
                              child: Text(s,
                                  style: TextStyle(
                                      color: sel
                                          ? Colors.white
                                          : Colors.white70,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800)),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════
  // SCREEN B — MAIN (gallery + catalogue)
  // ══════════════════════════════════════════════

  Widget _buildMainScreen() {
    return SafeArea(
      child: Column(
        children: [
          _topBar(),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  _heroBanner(),
                  const SizedBox(height: 20),
                  _stepLabel('1', 'Shoe choose karo', _C.midGreen),
                  const SizedBox(height: 10),
                  _shoeCarousel(),
                  const SizedBox(height: 20),
                  _stepLabel('2', 'Foot photo upload karo', _C.purple),
                  const SizedBox(height: 10),
                  _footSection(),
                  const SizedBox(height: 20),
                  if (_galleryImage != null) ...[
                    _stepLabel('3', 'Size chunno', _shoe.accent),
                    const SizedBox(height: 10),
                    _sizeSelector(),
                    const SizedBox(height: 20),
                  ],
                  if (_tryOnComplete) ...[
                    _resultCard(),
                    const SizedBox(height: 16),
                  ],
                  _mainCta(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Top bar ──

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          _circleBtn(Icons.arrow_back_rounded, () => Navigator.pop(context)),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: const TextSpan(children: [
                  TextSpan(
                    text: 'Virtual ',
                    style: TextStyle(color: _C.darkGreen, fontSize: 20,
                        fontWeight: FontWeight.w900, letterSpacing: -0.5),
                  ),
                  TextSpan(
                    text: 'Try-On',
                    style: TextStyle(color: _C.midGreen, fontSize: 20,
                        fontWeight: FontWeight.w900, letterSpacing: -0.5),
                  ),
                ]),
              ),
              const Text('Shoes apne foot pe dekho',
                  style: TextStyle(color: _C.textMuted, fontSize: 11)),
            ],
          ),
          const Spacer(),
          _circleBtn(Icons.favorite_outline, () {}),
        ],
      ),
    );
  }

  // ── Hero banner ──

  Widget _heroBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _C.darkGreen,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Try Before\nYou Buy',
                      style: TextStyle(color: Colors.white, fontSize: 24,
                          fontWeight: FontWeight.w900, height: 1.15)),
                  const SizedBox(height: 8),
                  Text('AI shoes overlay karta hai\ntumhare foot photo pe',
                      style: TextStyle(color: Colors.white.withAlpha(150),
                          fontSize: 12, height: 1.5)),
                  const SizedBox(height: 14),
                  // Camera shortcut button
                  GestureDetector(
                    onTap: _openLiveCamera,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: _C.midGreen,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.camera_alt_rounded,
                              color: Colors.white, size: 14),
                          SizedBox(width: 6),
                          Text('Live Camera Try-On',
                              style: TextStyle(color: Colors.white,
                                  fontSize: 12, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Container(
                key: ValueKey(_shoeIndex),
                width: 88, height: 88,
                decoration: BoxDecoration(
                  color: _C.midGreen.withAlpha(76),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: _C.lightTeal.withAlpha(51), width: 1.5),
                ),
                child: Center(
                  child: Text(_shoe.emoji,
                      style: const TextStyle(fontSize: 44)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Step label ──

  Widget _stepLabel(String n, String title, Color c) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Container(
            width: 24, height: 24,
            decoration: BoxDecoration(color: c, shape: BoxShape.circle),
            child: Center(
              child: Text(n, style: const TextStyle(color: Colors.white,
                  fontSize: 12, fontWeight: FontWeight.w900)),
            ),
          ),
          const SizedBox(width: 10),
          Text(title, style: const TextStyle(color: _C.textDark,
              fontSize: 16, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  // ── Shoe carousel ──

  Widget _shoeCarousel() {
    return SizedBox(
      height: 148,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _catalogue.length,
        itemBuilder: (_, i) {
          final s = _catalogue[i];
          final sel = i == _shoeIndex;
          return GestureDetector(
            onTap: () => setState(() {
              _shoeIndex = i; _size = null; _tryOnComplete = false;
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 116,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: sel ? s.accentLight : _C.cardWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: sel ? s.accent : _C.borderSoft,
                    width: sel ? 2 : 1),
                boxShadow: sel
                    ? [BoxShadow(color: s.accent.withAlpha(51),
                        blurRadius: 12, offset: const Offset(0, 4))]
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Text(s.emoji,
                      style: const TextStyle(fontSize: 36))),
                  const SizedBox(height: 8),
                  Text(s.name, maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: sel ? s.accent : _C.textDark,
                          fontSize: 11, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(s.price, style: TextStyle(
                      color: sel ? s.accent : _C.textMuted,
                      fontSize: 11, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Foot photo section ──

  Widget _footSection() {
    final hasPhoto = _galleryImage != null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Main photo box
          GestureDetector(
            onTap: _pickGallery,
            child: Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: hasPhoto ? Colors.black : _C.cardWhite,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: hasPhoto ? _C.midGreen.withAlpha(120) : _C.borderSoft,
                  width: hasPhoto ? 2 : 1,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: hasPhoto ? _photoWithOverlay() : _emptyPhoto(),
            ),
          ),

          const SizedBox(height: 10),

          // Two buttons: Gallery | Live Camera
          Row(
            children: [
              Expanded(
                child: _actionBtn(
                  icon: Icons.photo_library_outlined,
                  label: 'Gallery',
                  color: _C.purple,
                  bg: _C.purpleLight,
                  onTap: _pickGallery,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _actionBtn(
                  icon: Icons.camera_alt_outlined,
                  label: 'Live Camera',
                  color: _C.midGreen,
                  bg: const Color(0xFFE8F5E9),
                  onTap: _openLiveCamera,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _photoWithOverlay() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.file(_galleryImage!, fit: BoxFit.cover),
        // Shoe overlay when done
        if (_tryOnComplete)
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    _shoe.accent.withAlpha(180),
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_shoe.emoji, style: const TextStyle(fontSize: 72)),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_shoe.name} · Size $_size',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ),
        // Processing spinner
        if (_processing)
          Container(
            color: Colors.black45,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: Colors.white),
                  const SizedBox(height: 12),
                  const Text('AI shoe apply kar raha hai…',
                      style: TextStyle(color: Colors.white, fontSize: 13)),
                ],
              ),
            ),
          ),
        // Change button
        Positioned(
          top: 10, right: 10,
          child: GestureDetector(
            onTap: _pickGallery,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(10)),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit_rounded, color: Colors.white, size: 12),
                  SizedBox(width: 4),
                  Text('Change', style: TextStyle(
                      color: Colors.white, fontSize: 11,
                      fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _emptyPhoto() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 60, height: 60,
          decoration: const BoxDecoration(
              color: Color(0xFFE8F5E9), shape: BoxShape.circle),
          child: const Icon(Icons.add_a_photo_outlined,
              color: _C.midGreen, size: 28),
        ),
        const SizedBox(height: 12),
        const Text('Foot photo upload karo',
            style: TextStyle(color: _C.textDark,
                fontSize: 14, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        const Text('Gallery ya Live Camera use karo',
            style: TextStyle(color: _C.textMuted, fontSize: 11)),
      ],
    );
  }

  // ── Size selector ──

  Widget _sizeSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Wrap(
        spacing: 8, runSpacing: 8,
        children: _shoe.sizes.map((s) {
          final sel = _size == s;
          return GestureDetector(
            onTap: () => setState(() { _size = s; _tryOnComplete = false; }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 56, height: 44,
              decoration: BoxDecoration(
                color: sel ? _shoe.accent : _C.cardWhite,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: sel ? _shoe.accent : _C.borderSoft,
                    width: sel ? 2 : 1),
                boxShadow: sel
                    ? [BoxShadow(color: _shoe.accent.withAlpha(71),
                        blurRadius: 8, offset: const Offset(0, 3))]
                    : null,
              ),
              child: Center(
                child: Text(s, style: TextStyle(
                    color: sel ? Colors.white : _C.textDark,
                    fontSize: 13, fontWeight: FontWeight.w800)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Result card ──

  Widget _resultCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _shoe.accentLight,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _shoe.accent.withAlpha(64)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.check_circle_rounded,
                    color: _shoe.accent, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Try-on complete!',
                          style: TextStyle(color: _C.textDark,
                              fontSize: 14, fontWeight: FontWeight.w800)),
                      Text('${_shoe.name} · Size $_size',
                          style: const TextStyle(
                              color: _C.textMuted, fontSize: 11)),
                    ],
                  ),
                ),
                Text(_shoe.price, style: TextStyle(
                    color: _shoe.accent, fontSize: 18,
                    fontWeight: FontWeight.w900)),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity, height: 46,
              child: ElevatedButton.icon(
                onPressed: () => _snack(
                    '${_shoe.name} Size $_size cart mein add!', _C.midGreen),
                icon: const Icon(Icons.shopping_bag_outlined, size: 18),
                label: Text('Buy ${_shoe.name} · ${_shoe.price}'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _C.darkGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Main CTA ──

  Widget _mainCta() {
    final ready = _galleryImage != null && _size != null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity, height: 60,
        child: ElevatedButton(
          onPressed: _processing ? null : _startTryOn,
          style: ElevatedButton.styleFrom(
            backgroundColor: ready ? _C.midGreen : _C.darkGreen,
            foregroundColor: ready ? Colors.white : _C.lightTeal.withAlpha(178),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18)),
            elevation: ready ? 10 : 0,
            shadowColor: _C.midGreen.withAlpha(100),
          ),
          child: _processing
              ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2)),
                    SizedBox(width: 12),
                    Text('AI apply kar raha hai…',
                        style: TextStyle(fontSize: 16,
                            fontWeight: FontWeight.w800)),
                  ])
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(ready
                        ? Icons.auto_fix_high_rounded
                        : Icons.touch_app_rounded, size: 22),
                    const SizedBox(width: 10),
                    Text(
                      ready
                          ? 'Try On ${_shoe.name}'
                          : 'Photo upload karo aur size chunno',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // ── Helpers ──

  Widget _circleBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42, height: 42,
        decoration: BoxDecoration(
          color: _C.cardWhite,
          shape: BoxShape.circle,
          border: Border.all(color: _C.lightTeal, width: 1.5),
        ),
        child: Icon(icon, color: _C.darkGreen, size: 20),
      ),
    );
  }

  Widget _actionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required Color bg,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withAlpha(80), width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(
                color: color, fontSize: 13, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}