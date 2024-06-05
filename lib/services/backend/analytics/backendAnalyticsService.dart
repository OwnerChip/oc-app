import 'package:dio/dio.dart';
import 'package:ownerchip_whitelabel/services/backend/analytics/payloads/sendAnalyticsPayload.dart';
import 'package:ownerchip_whitelabel/services/backend/backend.services.dart';
import 'package:retrofit/http.dart';

part 'backendAnalyticsService.g.dart';

@RestApi()
abstract class BackendAnalyticsService {
  static BackendAnalyticsService _instance = BackendAnalyticsService();

  static BackendAnalyticsService get instance => _instance;

  static void recreate(String? jwt) {
    _instance = BackendAnalyticsService(
      jwt: jwt,
    );
  }

  factory BackendAnalyticsService({
    String? jwt,
  }) {
    final dio = Backend.getBackendClient(
      jwt: jwt,
    );
    return _BackendAnalyticsService(dio, baseUrl: dio.options.baseUrl);
  }

  @POST('/app/{packageName}/action')
  Future<void> sendAnalyticsEvent({
    @Body() required SendAnalyticsPayload payload,
    @Path('packageName') required String packageName,
  });
}
