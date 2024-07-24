import 'package:dio/dio.dart';
import 'package:ownerchip_whitelabel/domain/common/backendPaginationResponse.dart';
import 'package:ownerchip_whitelabel/domain/creation/digitalTwinMetadata.dart';
import 'package:ownerchip_whitelabel/services/backend/backend.services.dart';
import 'package:ownerchip_whitelabel/services/backend/creation/payloads/updateDigitalTwinCreationMetadataStatusPayload.dart';
import 'package:retrofit/retrofit.dart';

part 'backendCreationService.g.dart';

@RestApi()
abstract class BackendCreationService {
  static BackendCreationService _instance = BackendCreationService();

  static BackendCreationService get instance => _instance;

  static void recreate(String? jwt) {
    _instance = BackendCreationService(
      jwt: jwt,
    );
  }

  factory BackendCreationService({
    String? jwt,
  }) {
    final dio = Backend.getBackendClient(
      jwt: jwt,
    );
    return _BackendCreationService(dio,
        baseUrl: "${dio.options.baseUrl}/creation");
  }

  @GET("/")
  Future<BackendPaginationResponse<DigitalTwinMetadata>?> getMyDigitalTwins(
    @Query("page") int page,
    @Query("status") List<String> status,
  );

  @POST("/{id}/minted")
  Future<void> mintDigitalTwin(
    @Path('id') String id,
    @Query("chipId") String chipId,
  );
}
