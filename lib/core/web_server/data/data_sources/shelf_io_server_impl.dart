import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

import '../../../log_system/log_system.dart';
import '../../domain/entities/app_local_web_server.dart';
import '../../domain/entities/web_server_request.dart';
import '../../domain/entities/web_server_response.dart';
import 'web_server_data_source.dart';

class ShelfIoServerImpl implements WebServerDataSource {
  final Map<AppLocalWebServer, HttpServer> _servers =
      <AppLocalWebServer, HttpServer>{};

  @override
  Future<void> start(
    AppLocalWebServer server,
    Map<String, Future<WebServerResponse> Function(WebServerRequest request)>
        routes,
  ) async {
    final String host = server.host;
    final Handler handler = const Pipeline()
        .addMiddleware(logRequests())
        .addHandler(_routeMap(routes));
    _servers[server] = await shelf_io.serve(handler, host, server.port);
    _servers[server]?.autoCompress = true;
    LogSystem.info(
        'Shelf io: Server started on ${server.host}:${server.port}.');
  }

  Handler _routeMap(
    Map<String, Future<WebServerResponse> Function(WebServerRequest request)>
        routes,
  ) {
    return (Request request) async {
      final String path = request.url.path;
      if (routes.containsKey(path)) {
        final WebServerResponse responseBody = await routes[path]!.call(
          const WebServerRequest(),
        );

        // Convert to shelf response
        return Response.ok(
          responseBody.body,
          headers: responseBody.headers,
        );
      }
      return Response.notFound('Not Found');
    };
  }

  @override
  Future<void> stop(AppLocalWebServer server) async {
    if (_servers.containsKey(server)) {
      await _servers[server]?.close();
      _servers.remove(server);
      LogSystem.info('Shelf io: Server on port ${server.port} stopped.');
    }
  }
}
