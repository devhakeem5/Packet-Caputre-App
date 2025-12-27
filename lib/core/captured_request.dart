class CapturedRequest {
  final String id;
  final String url;
  final String method;
  final int statusCode;
  final int size;
  final DateTime timestamp;

  CapturedRequest({
    required this.id,
    required this.url,
    required this.method,
    required this.statusCode,
    required this.size,
    required this.timestamp,
  });
}
