import 'dart:async';

import '../../../lifecycle/domain/repositories/lifecycle_repository.dart';
import '../../../log_system/log_system.dart';
import '../../domain/entities/app_local_web_server.dart';
import '../../domain/entities/web_server_request.dart';
import '../../domain/entities/web_server_response.dart';
import '../../domain/repositories/web_server_repository.dart';
import '../data_sources/web_server_data_source.dart';

class WebServerRepositoryImpl implements WebServerRepository {
  factory WebServerRepositoryImpl(
    WebServerDataSource serverDataSource,
    LifecycleRepository lifecycleRepository,
  ) {
    final WebServerRepositoryImpl instance = WebServerRepositoryImpl._(
      serverDataSource,
    );

    lifecycleRepository.onDetach.listen(instance.onDetach);

    return instance;
  }

  WebServerRepositoryImpl._(this._serverDataSource);

  final WebServerDataSource _serverDataSource;
  final Set<AppLocalWebServer> _ports = <AppLocalWebServer>{};

  @override
  Future<void> start(
    AppLocalWebServer port,
    Map<String, Future<WebServerResponse> Function(WebServerRequest request)>
        routes,
  ) async {
    if (!_ports.contains(port)) {
      _ports.add(port);
      await _serverDataSource.start(port, routes);
    } else {
      LogSystem.error('Web servers: Port $port is already in use.');
    }
  }

  @override
  Future<void> stop(AppLocalWebServer port) async {
    if (_ports.contains(port)) {
      _ports.remove(port);
      await _serverDataSource.stop(port);
    }
  }

  Future<void> onDetach(void _) async {
    for (final AppLocalWebServer port in _ports) {
      await _serverDataSource.stop(port);
    }
  }
}
