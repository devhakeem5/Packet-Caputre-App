import 'package:flutter/material.dart';

class CapturedRequest {
  final String id;
  final String url;
  final String domain;
  final String method;
  final String protocol;
  final int statusCode;
  final int requestSize;
  final int responseSize;
  final int responseTime;
  final DateTime timestamp;
  final String? appName;
  final String? appPackage;
  final bool isDecrypted;
  final Map<String, String> headers;
  final bool isSystemApp;

  CapturedRequest({
    required this.id,
    required this.url,
    required this.domain,
    required this.method,
    required this.protocol,
    required this.statusCode,
    required this.requestSize,
    required this.responseSize,
    required this.responseTime,
    required this.timestamp,
    this.appName,
    this.appPackage,
    this.headers = const {},
    required this.isDecrypted,
    this.isSystemApp = false,
  });

  factory CapturedRequest.fromJson(Map<dynamic, dynamic> json) {
    final timestamp = json['timestamp'] != null
        ? DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int)
        : DateTime.now();

    final protocol = json['protocol'] as String? ?? "TCP";
    final method = json['method'] as String? ?? protocol;
    final direction = json['direction'] as String? ?? "outgoing";
    final destIp = json['destIp'] as String? ?? "Unknown";
    final srcIp = json['srcIp'] as String? ?? "Unknown";
    final destPort = json['destPort'] as int? ?? 0;
    final srcPort = json['srcPort'] as int? ?? 0;

    // Use payloadSize if available, otherwise fall back to size
    final payloadSize = json['payloadSize'] as int? ?? json['size'] as int? ?? 0;

    // Use the URL provided by the proxy server if available, otherwise construct from IP
    final url =
        json['url'] as String? ??
        (direction == "incoming"
            ? "${protocol.toLowerCase()}://$srcIp:$srcPort"
            : "${protocol.toLowerCase()}://$destIp:$destPort");

    final domain = json['domain'] as String? ?? (direction == "incoming" ? srcIp : destIp);

    final headersMap = (json['headers'] as Map<dynamic, dynamic>?)?.cast<String, String>() ?? {};

    // Determine decryption status
    // 1. Explicit flag from native
    // 2. HTTP is always decrypted
    // 3. Or implied by presence of headers or body
    final bool isDecrypted =
        json['isDecrypted'] as bool? ??
        (protocol == "HTTP" ||
            headersMap.isNotEmpty ||
            json['requestBody'] != null ||
            json['responseBody'] != null);

    return CapturedRequest(
      id: UniqueKey().toString(),
      url: url,
      domain: domain,
      method: method,
      protocol: protocol,
      statusCode: json['statusCode'] as int? ?? 200, // Default to 200 if not provided
      requestSize: direction == "outgoing" ? payloadSize : 0,
      responseSize: direction == "incoming" ? payloadSize : 0,
      responseTime: json['responseTime'] as int? ?? 0,
      timestamp: timestamp,
      appName: json['appName'] as String? ?? "Unknown App",
      appPackage: json['package'] as String? ?? "unknown",
      headers: headersMap,
      isDecrypted: isDecrypted,
      isSystemApp: json['isSystemApp'] as bool? ?? false,
    );
  }
}
