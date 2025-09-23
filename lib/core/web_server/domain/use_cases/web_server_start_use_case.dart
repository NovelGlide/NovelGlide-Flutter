import 'package:equatable/equatable.dart';

import '../../../domain/use_cases/use_case.dart';
import '../entities/app_local_web_server.dart';
import '../entities/web_server_request.dart';
import '../entities/web_server_response.dart';
import '../repositories/web_server_repository.dart';

class WebServerStartUseCaseParam extends Equatable {
  const WebServerStartUseCaseParam({
    required this.server,
    required this.routes,
  });

  final AppLocalWebServer server;
  final Map<String,
      Future<WebServerResponse> Function(WebServerRequest request)> routes;

  @override
  List<Object?> get props => <Object?>[
        server,
        routes,
      ];
}

class WebServerStartUseCase
    extends UseCase<Future<void>, WebServerStartUseCaseParam> {
  WebServerStartUseCase(this._webServerRepository);

  final WebServerRepository _webServerRepository;

  @override
  Future<void> call(WebServerStartUseCaseParam parameter) {
    return _webServerRepository.start(parameter.server, parameter.routes);
  }
}
