import 'package:dio/dio.dart';
import 'package:ownerchip_whitelabel/services/backend/backend.services.dart';
import 'package:retrofit/http.dart';
import 'package:retrofit/retrofit.dart';

import 'payloads/sendAnalyticsPayload.dart';

part 'backendAppService.g.dart';

@RestApi()
abstract class BackendAppService {
  static BackendAppService _instance = BackendAppService();

  static BackendAppService get instance => _instance;

  static void recreate(String? jwt) {
    _instance = BackendAppService(
      jwt: jwt,
    );
  }

  factory BackendAppService({
    String? jwt,
  }) {
    final dio = Backend.getBackendClient(
      jwt: jwt,
    );
    return _BackendAppService(dio, baseUrl: "${dio.options.baseUrl}/app");
  }

  @POST('/{packageName}/action')
  Future<void> sendAnalyticsEvent({
    @Body() required SendAnalyticsPayload payload,
    @Path('packageName') required String packageName,
  });

  @GET("/{packageName}")
  // TODO: Define the return type after json_serialization PR is merged
  Future<HttpResponse> getAppCollections({
    @Path("packageName") required String packageName,
  });

}
