
import 'package:dio/dio.dart';
import 'package:ownerchip_whitelabel/domain/fcm/fcm_token.dart';
import 'package:ownerchip_whitelabel/services/backend/backend.services.dart';
import 'package:ownerchip_whitelabel/services/backend/fcm/payloads/saveFcmTokenPayload.dart';
import 'package:retrofit/http.dart';

part 'backendFcmService.g.dart';
@RestApi()
abstract class BackendFcmService {

  static BackendFcmService _instance = BackendFcmService();

  static BackendFcmService get instance => _instance;

  static void recreate(String? jwt) {
    _instance = BackendFcmService(
      jwt: jwt,
    );
  }

  factory BackendFcmService({
    String? jwt,
  }) {
    final dio = Backend.getBackendClient(
      jwt: jwt,
    );
    return _BackendFcmService(dio, baseUrl: "${dio.options.baseUrl}/fcm");
  }

  @POST("")
  Future<FCMToken> saveFcmToken({
    @Body() required SaveFCMTokenPayload body,
  });

  @DELETE("/{id}")
  Future<void> deleteFcmToken({
    @Path("id") required int id,
  });

}