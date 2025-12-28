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
  final Map<String, String> headers;

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
    
    // Construct URL based on direction
    final url = direction == "incoming"
        ? "${protocol.toLowerCase()}://$srcIp:$srcPort"
        : "${protocol.toLowerCase()}://$destIp:$destPort";
    
    final domain = json['domain'] as String? ?? 
        (direction == "incoming" ? srcIp : destIp);

    return CapturedRequest(
      id: UniqueKey().toString(),
      url: url,
      domain: domain,
      method: method,
      protocol: protocol,
      statusCode: 200, // Placeholder as we don't inspect HTTP response codes in raw TCP
      requestSize: direction == "outgoing" ? payloadSize : 0,
      responseSize: direction == "incoming" ? payloadSize : 0,
      responseTime: 0,
      timestamp: timestamp,
      appName: json['appName'] as String? ?? "Unknown App",
      appPackage: json['package'] as String? ?? "unknown",
      headers: {},
    );
  }
}
