/// Centralized API configuration.
/// 
/// Change the [baseUrl] here once after deploying to Render,
/// and every service/page will automatically use the live URL.
class ApiConfig {
  // ============================================================
  //  🔧  SET YOUR RENDER URL HERE AFTER DEPLOYMENT
  // ============================================================
  // For local development (ADB reverse):
  //   static const String baseUrl = 'http://localhost:8080';
  //
  // For live Render deployment:
  //   static const String baseUrl = 'https://your-app-name.onrender.com';
  // ============================================================

  static const String baseUrl = 'https://real-time-chat-app-3spq.onrender.com';

  // REST API endpoints
  static const String usersUrl = '$baseUrl/api/users';
  static const String messagesUrl = '$baseUrl/api/messages';

  // WebSocket endpoint
  // Uses 'wss://' for HTTPS deployments, 'ws://' for local
  static String get wsUrl {
    if (baseUrl.startsWith('https')) {
      return 'wss://${baseUrl.replaceFirst('https://', '')}/ws';
    }
    return 'ws://${baseUrl.replaceFirst('http://', '')}/ws';
  }
}
