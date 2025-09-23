import '../../../domain/use_cases/use_case.dart';
import '../entities/app_local_web_server.dart';
import '../repositories/web_server_repository.dart';

class WebServerStopUseCase extends UseCase<Future<void>, AppLocalWebServer> {
  WebServerStopUseCase(this._webServerRepository);

  final WebServerRepository _webServerRepository;

  @override
  Future<void> call(AppLocalWebServer parameter) {
    return _webServerRepository.stop(parameter);
  }
}
