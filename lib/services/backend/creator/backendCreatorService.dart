import 'package:dio/dio.dart';
import 'package:ownerchip_whitelabel/services/backend/backend.services.dart';
import 'package:retrofit/retrofit.dart';

part 'backendCreatorService.g.dart';
@RestApi()
abstract class BackendCreatorService {
  static BackendCreatorService _instance = BackendCreatorService();

  static BackendCreatorService get instance => _instance;

  static void recreate(String? jwt) {
    _instance = BackendCreatorService(
      jwt: jwt,
    );
  }

  factory BackendCreatorService({
    String? jwt,
  }) {
    final dio = Backend.getBackendClient(
      jwt: jwt,
    );
    return _BackendCreatorService(dio,
        baseUrl: "${dio.options.baseUrl}/creator");
  }

  @GET("/{tokenId}")
  Future<HttpResponse> getCreatorData({
    @Path("tokenId") required String tokenId,
  });
}
