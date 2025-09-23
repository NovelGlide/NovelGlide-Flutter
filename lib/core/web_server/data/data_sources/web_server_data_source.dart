import '../../domain/entities/app_local_web_server.dart';
import '../../domain/entities/web_server_request.dart';
import '../../domain/entities/web_server_response.dart';

abstract class WebServerDataSource {
  Future<void> start(
    AppLocalWebServer server,
    Map<String, Future<WebServerResponse> Function(WebServerRequest request)>
        routes,
  );

  Future<void> stop(AppLocalWebServer server);
}
