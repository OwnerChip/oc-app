import 'package:dio/dio.dart';
import 'package:ownerchip_whitelabel/services/backend/backend.services.dart';
import 'package:ownerchip_whitelabel/services/backend/collection/payloads/sendCardLostPayload.dart';
import 'package:retrofit/http.dart';
import 'package:retrofit/retrofit.dart';

part 'backendCollectionService.g.dart';

@RestApi()
abstract class BackendCollectionService {
  static BackendCollectionService _instance = BackendCollectionService();

  static BackendCollectionService get instance => _instance;

  static void recreate(String? jwt) {
    _instance = BackendCollectionService(
      jwt: jwt,
    );
  }

  factory BackendCollectionService({
    String? jwt,
  }) {
    final dio = Backend.getBackendClient(
      jwt: jwt,
    );
    return _BackendCollectionService(dio,
        baseUrl: "${dio.options.baseUrl}/collection");
  }

  @GET("")
  Future<HttpResponse> getAllCollections();

  @POST("/{hex}/recovery")
  Future<void> recoverCollection({
    @Path("hex") required String hex,
    @Body() required SendCardLostPayload body,
  });
}
