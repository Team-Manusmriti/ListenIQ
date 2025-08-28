import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class CameraPreviewWidget extends StatefulWidget {
  final CameraController? controller;
  final VoidCallback? onTap;
  final bool showOverlay;
  final Widget? overlay;

  const CameraPreviewWidget({
    Key? key,
    required this.controller,
    this.onTap,
    this.showOverlay = true,
    this.overlay,
  }) : super(key: key);

  @override
  _CameraPreviewWidgetState createState() => _CameraPreviewWidgetState();
}

class _CameraPreviewWidgetState extends State<CameraPreviewWidget> {
  @override
  Widget build(BuildContext context) {
    if (widget.controller?.value.isInitialized != true) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text(
                'Initializing Camera...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: widget.onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Camera preview
          ClipRect(
            child: Transform.scale(
              scale: _calculateScale(),
              child: Center(
                child: AspectRatio(
                  aspectRatio: widget.controller!.value.aspectRatio,
                  child: CameraPreview(widget.controller!),
                ),
              ),
            ),
          ),

          // Overlay
          if (widget.showOverlay && widget.overlay != null) widget.overlay!,

          // Focus indicator
          if (_showFocusIndicator)
            Positioned(
              left: _focusPoint.dx - 50,
              top: _focusPoint.dy - 50,
              child: _buildFocusIndicator(),
            ),
        ],
      ),
    );
  }

  double _calculateScale() {
    if (widget.controller == null) return 1.0;

    final screenSize = MediaQuery.of(context).size;
    final cameraAspectRatio = widget.controller!.value.aspectRatio;
    final screenAspectRatio = screenSize.width / screenSize.height;

    if (cameraAspectRatio < screenAspectRatio) {
      return screenAspectRatio / cameraAspectRatio;
    } else {
      return 1.0;
    }
  }

  bool _showFocusIndicator = false;
  Offset _focusPoint = Offset.zero;

  Widget _buildFocusIndicator() {
    return AnimatedOpacity(
      opacity: _showFocusIndicator ? 1.0 : 0.0,
      duration: Duration(milliseconds: 300),
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white, width: 2),
          borderRadius: BorderRadius.circular(50),
        ),
        child: Icon(Icons.center_focus_strong, color: Colors.white, size: 30),
      ),
    );
  }

  Future<void> _onTapFocus(TapDownDetails details) async {
    if (widget.controller?.value.isInitialized != true) return;

    setState(() {
      _focusPoint = details.localPosition;
      _showFocusIndicator = true;
    });

    try {
      await widget.controller!.setFocusPoint(details.localPosition);
      await widget.controller!.setExposurePoint(details.localPosition);
    } catch (e) {
      print('Focus error: $e');
    }

    Future.delayed(Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showFocusIndicator = false;
        });
      }
    });
  }
}
