import 'package:dio/dio.dart';
import 'package:ownerchip_whitelabel/domain/common/backendPaginationResponse.dart';
import 'package:ownerchip_whitelabel/domain/creation/digitalTwinAttachment.dart';
import 'package:ownerchip_whitelabel/domain/creation/digitalTwinMetadata.dart';
import 'package:ownerchip_whitelabel/services/backend/backend.services.dart';
import 'package:ownerchip_whitelabel/services/backend/creation/payloads/updateDigitalTwinCreationMetadataStatusPayload.dart';
import 'package:ownerchip_whitelabel/services/backend/creation/payloads/uploadDigitalTwinCreationAttachmentPayload.dart';
import 'package:retrofit/retrofit.dart';

import 'responses/uploadDigitalTwinCreationAttachmentResponse.dart';

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

  @POST("/{id}/burned")
  Future<void> burnDigitalTwin(
    @Path('id') String id,
    @Query("chipId") String chipId,
  );

  @POST("/{id}/attachment")
  Future<UploadDigitalTwinCreationAttachmentResponse?> prepareAttachmentUpload(
    @Path('id') String id,
    @Body() UploadDigitalTwinCreationAttachmentPayload payload,
  );

  @PUT("/{id}/attachment/{attachmentId}")
  Future<void> setAttachmentUploaded(
    @Path('id') String id,
    @Path('attachmentId') String attachmentId,
  );


  @GET("/token/{tokenId}")
  Future<DigitalTwinMetadata?> getDigitalTwinByTokenId(
    @Path('tokenId') String tokenId,
  );

  @GET("/{id}/attachment")
  Future<List<DigitalTwinAttachment>?> getDigitalTwinAttachments(
    @Path('id') String id,
  );

  @DELETE("/{id}/attachment/{attachmentId}")
  Future<void> deleteAttachmentMetadata(
    @Path('id') String id,
    @Path('attachmentId') String attachmentId,
  );

  @POST("/{id}/attachment/{attachmentId}")
  Future<void> updateAttachmentMetadata(
    @Path('id') String id,
    @Path('attachmentId') String attachmentId,
    @Body() UploadDigitalTwinCreationAttachmentPayload payload,
  );
}
