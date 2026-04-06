import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gal/gal.dart';
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';
import '../services/gps_service.dart';
import '../services/activity_service.dart';

/// Activity Photo Screen - Take photo with Strava-style overlay
class ActivityPhotoScreen extends StatefulWidget {
  final double distance;
  final String duration;
  final String pace;

  const ActivityPhotoScreen({
    super.key,
    required this.distance,
    required this.duration,
    required this.pace,
  });

  @override
  State<ActivityPhotoScreen> createState() => _ActivityPhotoScreenState();
}

class _ActivityPhotoScreenState extends State<ActivityPhotoScreen> {
  final ImagePicker _picker = ImagePicker();
  final GlobalKey _captureKey = GlobalKey();
  final ActivityService _activityService = ActivityService();

  File? _imageFile;
  bool _isCapturing = false;
  bool _showOverlay = true;

  // Overlay position and scale
  double _overlayX = 20;
  double _overlayY = 20;
  double _overlayScale = 1.0;
  
  // Camera settings
  final double _currentZoom = 1.0;
  bool _enableFlash = false;
  
  // Route coordinates for mini map
  List<LatLng> _routePoints = [];
  
  // Overlay color customization
  final Color _overlayColor = CupertinoColors.black;
  final Color _accentColor = CupertinoColors.systemOrange;

  @override
  void initState() {
    super.initState();
    _loadRoute();
  }

  void _loadRoute() {
    final coordinates = _activityService.coordinates;
    setState(() {
      _routePoints = GPSService.coordinatesToLatLng(coordinates);
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Add Photo'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Skip'),
        ),
        trailing: _imageFile != null
            ? CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _savePhoto,
                child: const Text(
                  'Save',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              )
            : null,
      ),
      child: SafeArea(
        child: _imageFile == null
            ? _buildImagePicker()
            : _buildPhotoEditor(),
      ),
    );
  }

  Widget _buildImagePicker() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Header with activity summary
          Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.symmetric(horizontal: 32),
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey6.resolveFrom(context),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildQuickStat('Distance', '${widget.distance.toStringAsFixed(2)} km'),
                    Container(width: 1, height: 40, color: CupertinoColors.separator),
                    _buildQuickStat('Duration', widget.duration),
                    Container(width: 1, height: 40, color: CupertinoColors.separator),
                    _buildQuickStat('Pace', '${widget.pace}/km'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          Text(
            'Add a photo to your activity',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.label.resolveFrom(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Take a photo to remember your run',
            style: TextStyle(
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
          const SizedBox(height: 32),
          
          // Camera controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Main camera button
              _buildImagePickerButton(
                icon: CupertinoIcons.camera_fill,
                label: 'Camera',
                onTap: () => _pickImage(ImageSource.camera),
                isPrimary: true,
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Gallery button
          CupertinoButton(
            onPressed: () => _pickImage(ImageSource.gallery),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  CupertinoIcons.photo_on_rectangle,
                  color: CupertinoColors.systemOrange,
                ),
                const SizedBox(width: 8),
                const Text('Choose from Gallery'),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Skip button
          CupertinoButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: Text(
              'Skip',
              style: TextStyle(
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
          ),
        ),
      ],
    );
  }

  Widget _buildCameraControl({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: isActive 
                  ? CupertinoColors.systemOrange.withValues(alpha: 0.2)
                  : CupertinoColors.systemGrey5.resolveFrom(context),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isActive 
                  ? CupertinoColors.systemOrange 
                  : CupertinoColors.systemGrey,
              size: 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleFlash() {
    setState(() {
      _enableFlash = !_enableFlash;
    });
  }

  Widget _buildImagePickerButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: isPrimary ? 90 : 80,
            height: isPrimary ? 90 : 80,
            decoration: BoxDecoration(
              gradient: isPrimary
                  ? const LinearGradient(
                      colors: [
                        CupertinoColors.systemOrange,
                        CupertinoColors.systemRed,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isPrimary 
                  ? null 
                  : CupertinoColors.systemOrange.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              boxShadow: isPrimary
                  ? [
                      BoxShadow(
                        color: CupertinoColors.systemOrange.withValues(alpha: 0.4),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              icon,
              size: isPrimary ? 40 : 36,
              color: isPrimary 
                  ? CupertinoColors.white 
                  : CupertinoColors.systemOrange,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontWeight: isPrimary ? FontWeight.bold : FontWeight.w500,
              color: isPrimary 
                  ? CupertinoColors.systemOrange 
                  : CupertinoColors.label.resolveFrom(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoEditor() {
    return Column(
      children: [
        // Photo with overlay
        Expanded(
          child: RepaintBoundary(
            key: _captureKey,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Image
                Image.file(
                  _imageFile!,
                  fit: BoxFit.cover,
                ),

                // Strava-style overlay (draggable)
                if (_showOverlay)
                  Positioned(
                    left: _overlayX,
                    top: _overlayY,
                    child: GestureDetector(
                      onPanUpdate: (details) {
                        setState(() {
                          _overlayX += details.delta.dx;
                          _overlayY += details.delta.dy;
                        });
                      },
                      child: Transform.scale(
                        scale: _overlayScale,
                        child: _buildStravaOverlay(),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // Bottom controls
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: CupertinoColors.systemBackground.resolveFrom(context),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Scale slider
              Row(
                children: [
                  const Icon(
                    CupertinoIcons.arrow_up_left_arrow_down_right,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  const Text('Size'),
                  Expanded(
                    child: CupertinoSlider(
                      value: _overlayScale,
                      min: 0.5,
                      max: 1.5,
                      onChanged: (value) {
                        setState(() {
                          _overlayScale = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: CupertinoButton(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      color: CupertinoColors.systemGrey5,
                      onPressed: _retakePhoto,
                      child: const Text(
                        'Retake',
                        style: TextStyle(
                          color: CupertinoColors.label,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CupertinoButton.filled(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      onPressed: _isCapturing ? null : _saveWithOverlay,
                      child: _isCapturing
                          ? const CupertinoActivityIndicator(
                              color: CupertinoColors.white,
                            )
                          : const Text('Save with Overlay'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStravaOverlay() {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.black.withOpacity(0.75),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Distance
          Row(
            children: [
              const Icon(
                CupertinoIcons.location_fill,
                color: CupertinoColors.systemOrange,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                '${widget.distance.toStringAsFixed(2)} km',
                style: const TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Duration
          Row(
            children: [
              const Icon(
                CupertinoIcons.timer,
                color: CupertinoColors.white,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                widget.duration,
                style: const TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Pace
          Row(
            children: [
              const Icon(
                CupertinoIcons.speedometer,
                color: CupertinoColors.white,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                '${widget.pace} /km',
                style: const TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Route polyline (no map)
          if (_routePoints.isNotEmpty)
            SizedBox(
              height: 60,
              child: CustomPaint(
                size: const Size(double.infinity, 60),
                painter: _RoutePolylinePainter(
                  points: _routePoints,
                  color: CupertinoColors.systemOrange,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      // Camera-specific options
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _imageFile = File(image.path);
        });
      }
    } catch (e) {
      // Handle error silently - user might have cancelled
    }
  }

  void _retakePhoto() {
    setState(() {
      _imageFile = null;
      _showOverlay = true;
      _overlayX = 20;
      _overlayY = 20;
      _overlayScale = 1.0;
    });
  }

  void _showSaveSuccessDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Photo Saved'),
        content: const Text('Your activity photo has been saved to the gallery!'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Continue'),
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(null);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _saveWithOverlay() async {
    setState(() {
      _isCapturing = true;
    });

    try {
      // Capture the widget with overlay
      final boundary = _captureKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) {
        setState(() {
          _isCapturing = false;
        });
        return;
      }

      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        setState(() {
          _isCapturing = false;
        });
        return;
      }

      final Uint8List pngBytes = byteData.buffer.asUint8List();

      // Save to app documents directory first
      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          'activity_photo_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(pngBytes);

      // Save to device gallery using Gal
      await Gal.putImage(file.path);

      setState(() {
        _isCapturing = false;
      });

      // Show success message
      if (mounted) {
        _showSaveSuccessDialog();
      }
    } catch (e) {
      setState(() {
        _isCapturing = false;
      });
    }
  }

  Future<void> _savePhoto() async {
    if (_imageFile == null) return;

    // Just save the original image without overlay
    final directory = await getApplicationDocumentsDirectory();
    final fileName =
        'activity_photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final savedFile = await _imageFile!.copy('${directory.path}/$fileName');

    if (mounted) {
      Navigator.of(context).pop(savedFile.path);
    }
  }
}

/// Custom painter for drawing just the polyline route (no map)
class _RoutePolylinePainter extends CustomPainter {
  final List<LatLng> points;
  final Color color;

  _RoutePolylinePainter({
    required this.points,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    // Find bounds
    double minLat = double.infinity;
    double maxLat = double.negativeInfinity;
    double minLng = double.infinity;
    double maxLng = double.negativeInfinity;

    for (var point in points) {
      minLat = point.latitude < minLat ? point.latitude : minLat;
      maxLat = point.latitude > maxLat ? point.latitude : maxLat;
      minLng = point.longitude < minLng ? point.longitude : minLng;
      maxLng = point.longitude > maxLng ? point.longitude : maxLng;
    }

    // Add padding
    final latPadding = (maxLat - minLat) * 0.1;
    final lngPadding = (maxLng - minLng) * 0.1;
    minLat -= latPadding;
    maxLat += latPadding;
    minLng -= lngPadding;
    maxLng += lngPadding;

    // Ensure we don't have zero range
    if (maxLat == minLat) {
      maxLat += 0.001;
      minLat -= 0.001;
    }
    if (maxLng == minLng) {
      maxLng += 0.001;
      minLng -= 0.001;
    }

    // Normalize points to canvas coordinates
    final latRange = maxLat - minLat;
    final lngRange = maxLng - minLng;
    
    // Handle edge cases where range is zero or invalid
    if (latRange == 0 || latRange.isNaN || latRange.isInfinite ||
        lngRange == 0 || lngRange.isNaN || lngRange.isInfinite) {
      return; // Cannot normalize points, skip drawing
    }
    
    final normalizedPoints = points.map((point) {
      final x = (point.longitude - minLng) / lngRange * size.width;
      final y = (size.height - (point.latitude - minLat) / latRange * size.height);
      return Offset(x, y);
    }).toList();

    // Draw the route line
    if (normalizedPoints.length > 1) {
      final paint = Paint()
        ..color = color
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      final path = ui.Path();
      path.moveTo(normalizedPoints[0].dx, normalizedPoints[0].dy);

      for (int i = 1; i < normalizedPoints.length; i++) {
        path.lineTo(normalizedPoints[i].dx, normalizedPoints[i].dy);
      }

      canvas.drawPath(path, paint);
    }

    // Draw start marker
    if (normalizedPoints.isNotEmpty) {
      final startPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      canvas.drawCircle(normalizedPoints.first, 6, startPaint);
    }

    // Draw end marker
    if (normalizedPoints.length > 1) {
      final endPaint = Paint()
        ..color = CupertinoColors.systemOrange
        ..style = PaintingStyle.fill;

      canvas.drawCircle(normalizedPoints.last, 6, endPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RoutePolylinePainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.color != color;
  }
}
