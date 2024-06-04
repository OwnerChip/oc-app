import "package:dio/dio.dart";
import "package:ownerchip_whitelabel/services/backend/auth/payloads/getSessionExpirationPayload.dart";
import "package:ownerchip_whitelabel/services/backend/auth/payloads/validateSiwePayload.dart";
import "package:ownerchip_whitelabel/services/backend/backend.services.dart";
import "package:retrofit/retrofit.dart";

part "backendAuthService.g.dart";

@RestApi()
abstract class BackendAuthService {
  static final BackendAuthService _instance = BackendAuthService();

  static BackendAuthService get instance => _instance;

  factory BackendAuthService() {
    final dio = Backend.getBackendClient();
    return _BackendAuthService(dio, baseUrl: "${dio.options.baseUrl}/auth");
  }

  @GET("/")
  Future<String> getSessionId();

  @POST("/{expiration}")
  Future<String> getSessionExpiration({
    @Path("expiration") required int expiration,
    @Body() required GetSessionExpirationPayload payload,
  });

  @POST("/session/siwe")
  Future<String> validateSiwe({
    @Body() required ValidateSiwePayload body,
  });
}
