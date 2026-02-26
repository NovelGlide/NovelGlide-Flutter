import '../entities/app_local_web_server.dart';
import '../entities/web_server_request.dart';
import '../entities/web_server_response.dart';

abstract class WebServerRepository {
  Future<void> start(
    AppLocalWebServer server,
    Map<String, Future<WebServerResponse> Function(WebServerRequest request)>
        routes,
  );

  Future<void> stop(AppLocalWebServer server);
}
