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

    return CapturedRequest(
      id: UniqueKey().toString(),
      url: "http://${json['destIp']}:${json['destPort']}", // Constructing URL from IP/Port
      domain: json['domain'] as String? ?? json['destIp'] as String? ?? "Unknown",
      method: "CONNECT", // Default for raw packets
      protocol: json['protocol'] as String? ?? "TCP",
      statusCode: 200, // Placeholder as we don't inspect HTTP response codes in raw TCP
      requestSize: json['size'] as int? ?? 0,
      responseSize: 0,
      responseTime: 0,
      timestamp: timestamp,
      appName: json['appName'] as String?,
      appPackage: json['package'] as String?,
      headers: {},
    );
  }
}
