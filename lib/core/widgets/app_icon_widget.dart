import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Widget to display app icon using package name
class AppIconWidget extends StatefulWidget {
  final String? packageName;
  final double size;

  const AppIconWidget({Key? key, required this.packageName, this.size = 40}) : super(key: key);

  @override
  State<AppIconWidget> createState() => _AppIconWidgetState();
}

class _AppIconWidgetState extends State<AppIconWidget> {
  static const platform = MethodChannel('com.example.packet_capture/methods');
  Uint8List? _iconBytes;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadIcon();
  }

  @override
  void didUpdateWidget(AppIconWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.packageName != widget.packageName) {
      _loadIcon();
    }
  }

  Future<void> _loadIcon() async {
    if (widget.packageName == null || widget.packageName!.isEmpty) {
      setState(() {
        _iconBytes = null;
        _isLoading = false;
      });
      return;
    }

    try {
      final Uint8List? bytes = await platform.invokeMethod('getAppIcon', {
        'packageName': widget.packageName,
      });

      if (mounted) {
        setState(() {
          _iconBytes = bytes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _iconBytes = null;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: Center(
          child: SizedBox(
            width: widget.size * 0.5,
            height: widget.size * 0.5,
            child: CircularProgressIndicator(strokeWidth: 2, color: theme.colorScheme.primary),
          ),
        ),
      );
    }

    if (_iconBytes != null && _iconBytes!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(
          _iconBytes!,
          width: widget.size,
          height: widget.size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildDefaultIcon(theme);
          },
        ),
      );
    }

    return _buildDefaultIcon(theme);
  }

  Widget _buildDefaultIcon(ThemeData theme) {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.apps_outlined,
        size: widget.size * 0.6,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
