import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';

class CertificateManager {
  static const _caCertKey = 'packet_capture_ca_cert';
  static const _caPrivateKeyKey = 'packet_capture_ca_private_key';

  static const _assetCertPath = 'assets/images/ca.crt';
  static const _assetKeyPath = 'assets/images/ca.key';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  /// Called on app startup
  Future<void> init() async {
    final exists = await caExists();
    if (!exists) {
      await _loadFromAssets();
    }
  }

  /// Checks if CA cert + key are stored
  Future<bool> caExists() async {
    final cert = await _storage.read(key: _caCertKey);
    final key = await _storage.read(key: _caPrivateKeyKey);
    return cert != null && key != null;
  }

  /// Loads CA certificate + private key from assets
  Future<void> _loadFromAssets() async {
    final certPem = await rootBundle.loadString(_assetCertPath);
    final keyPem = await rootBundle.loadString(_assetKeyPath);

    await _storage.write(key: _caCertKey, value: certPem);
    await _storage.write(key: _caPrivateKeyKey, value: keyPem);
  }

  Future<Uint8List?> getCertificateBytes() async {
    final data = await _storage.read(key: _caCertKey);
    if (data == null) return null;
    return base64Decode(data);
  }

  /// Returns CA certificate PEM
  Future<String?> getCertificateContent() async {
    return await _storage.read(key: _caCertKey);
  }

  /// Returns CA private key PEM (DO NOT expose in UI)
  Future<String?> getPrivateKey() async {
    return await _storage.read(key: _caPrivateKeyKey);
  }

  /// Writes certificate to Downloads for manual installation
  Future<File?> exportCertificateToDownloads() async {
    final certPem = await rootBundle.loadString(_assetCertPath);

    final dir = Directory('/storage/emulated/0/Download');
    if (!await dir.exists()) return null;

    final file = File('${dir.path}/packet_capture_ca.crt');
    await file.writeAsString(certPem, flush: true);

    return file;
  }

  /// UI helper
  Future<void> shareCertificate() async {
    final file = await exportCertificateToDownloads();

    if (file != null) {
      Get.showSnackbar(
        const GetSnackBar(
          title: 'Certificate Ready',
          message: 'Certificate saved to Downloads folder',
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  /// Logical verification only (real verification comes in MITM phase)
  Future<bool> verifyInstallation() async {
    // At this phase we only verify presence.
    // Real trust verification requires HTTPS interception.
    final exists = await caExists();
    if (!exists) {
      Get.showSnackbar(
        const GetSnackBar(
          title: 'Certificate Not Found',
          message: 'Please install the CA certificate first',
          duration: Duration(seconds: 3),
        ),
      );
      return false;
    }

    // Try to open security settings for certificate installation
    try {
      await const MethodChannel(
        'com.example.packet_capture/methods',
      ).invokeMethod('openSecuritySettings');
    } catch (e) {
      // Ignore if not implemented
    }

    Get.showSnackbar(
      const GetSnackBar(
        title: 'Certificate Verification',
        message:
            'Please ensure the CA certificate is installed in Security > Encryption & credentials > Install certificate',
        duration: Duration(seconds: 5),
      ),
    );

    return true;
  }

  /// Clears stored certificate + key
  Future<void> clearCertificate() async {
    await _storage.delete(key: _caCertKey);
    await _storage.delete(key: _caPrivateKeyKey);
  }
}
