import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class CircleImageCropper extends StatefulWidget {
  final Uint8List imageBytes;

  const CircleImageCropper({super.key, required this.imageBytes});

  @override
  State<CircleImageCropper> createState() => _CircleImageCropperState();
}

class _CircleImageCropperState extends State<CircleImageCropper> {
  double _scale = 1.0;
  double _previousScale = 1.0;
  Offset _offset = Offset.zero;
  Offset _previousOffset = Offset.zero;
  ui.Image? _image;
  final GlobalKey _cropKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final codec = await ui.instantiateImageCodec(widget.imageBytes);
    final frame = await codec.getNextFrame();
    setState(() {
      _image = frame.image;
    });
  }

  Future<Uint8List> _cropImage() async {
    final RenderRepaintBoundary boundary =
        _cropKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
    final ByteData? byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: const EdgeInsets.all(10),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Profile photo',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Cropper Area
          Expanded(
            child: Center(
              child: _image == null
                  ? const CircularProgressIndicator()
                  : GestureDetector(
                      onScaleStart: (details) {
                        _previousScale = _scale;
                        _previousOffset = _offset;
                      },
                      onScaleUpdate: (details) {
                        setState(() {
                          _scale = (_previousScale * details.scale).clamp(1.0, 4.0);
                          _offset = _previousOffset + details.focalPointDelta;
                        });
                      },
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          RepaintBoundary(
                            key: _cropKey,
                            child: ClipOval(
                              child: Container(
                                width: 300,
                                height: 300,
                                color: Colors.grey[300],
                                child: Transform.translate(
                                  offset: _offset,
                                  child: Transform.scale(
                                    scale: _scale,
                                    child: RawImage(
                                      image: _image,
                                      fit: BoxFit.cover,
                                      width: 300,
                                      height: 300,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Circle overlay
                          Container(
                            width: 300,
                            height: 300,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),

          // Instruction text
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Drag to reposition photo',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),

          // Controls
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.black,
            child: Column(
              children: [
                // Zoom slider
                Row(
                  children: [
                    const Text(
                      'Zoom',
                      style: TextStyle(color: Colors.white),
                    ),
                    Expanded(
                      child: Slider(
                        value: _scale,
                        min: 1.0,
                        max: 4.0,
                        activeColor: const Color(0xFF4A90E2),
                        onChanged: (value) {
                          setState(() {
                            _scale = value;
                          });
                        },
                      ),
                    ),
                    Text(
                      _scale.toStringAsFixed(1),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Bottom buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Delete photo',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    Row(
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white),
                          ),
                          child: const Text('Change photo'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () async {
                            final croppedImage = await _cropImage();
                            if (context.mounted) {
                              Navigator.pop(context, croppedImage);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4A90E2),
                          ),
                          child: const Text('Apply'),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
