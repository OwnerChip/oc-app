import "package:dio/dio.dart";
import "package:ownerchip_whitelabel/services/backend/auth/payloads/getSessionExpirationPayload.dart";
import "package:ownerchip_whitelabel/services/backend/auth/payloads/validateSiwePayload.dart";
import "package:ownerchip_whitelabel/services/backend/auth/responses/getMeResponse.dart";
import "package:ownerchip_whitelabel/services/backend/backend.services.dart";
import "package:retrofit/retrofit.dart";

import "responses/userAccountDeletionRequestResponse.dart";

part "backendAuthService.g.dart";

@RestApi()
abstract class BackendAuthService {
  static BackendAuthService _instance = BackendAuthService();

  static BackendAuthService get instance => _instance;

  static recreate(String? jwt) {
    _instance = BackendAuthService(
      jwt: jwt,
    );
  }

  factory BackendAuthService({
    String? jwt,
  }) {
    final dio = Backend.getBackendClient(
      jwt: jwt,
    );
    return _BackendAuthService(dio, baseUrl: "${dio.options.baseUrl}/auth");
  }

  @GET("/")
  Future<String> getSessionId();

  @POST("/")
  Future<String> validateSiwe({
    @Body() required ValidateSiwePayload body,
  });

  @POST("/session/guest")
  Future<String> createGuestSession();

  @GET("/session/terminate")
  Future<void> terminateSession();

  @GET("/me")
  Future<GetMeResponse?> getMe({
    @Header("Authorization") required String authorization,
  });

  @GET("/deletionRequest")
  Future<UserAccountDeletionRequestResponse?> getDeletionRequest();

  @POST("/deletionRequest")
  Future<UserAccountDeletionRequestResponse?> createDeletionRequest();

  @DELETE("/deletionRequest")
  Future<HttpResponse> cancelDeletionRequest();
}
