import 'package:ownerchip_whitelabel/services/backend/attachments/payloads/postAttachmentMetadataToBackendPayload.dart';
import 'package:ownerchip_whitelabel/services/backend/attachments/payloads/putAttachmentMetadataToBackendPayload.dart';
import 'package:ownerchip_whitelabel/services/backend/backend.services.dart';
import 'package:retrofit/retrofit.dart';
import "package:dio/dio.dart";

part 'backendAttachmentsService.g.dart';

@RestApi()
abstract class BackendAttachmentsService {
  static BackendAttachmentsService _instance = BackendAttachmentsService();

  static BackendAttachmentsService get instance => _instance;

  static String? _jwt;

  static String? get jwt => _jwt;

  static void recreate(String? jwt) {
    _jwt = jwt;
    _instance = BackendAttachmentsService(
      jwt: jwt,
    );
  }

  factory BackendAttachmentsService({
    String? jwt,
  }) {
    final dio = Backend.getBackendClient(
      jwt: jwt,
    );
    return _BackendAttachmentsService(dio,
        baseUrl: "${dio.options.baseUrl}/attachments");
  }

  @POST("/")
  Future<HttpResponse> postAttachmentMetadataToBackend({
    @Body() required PostAttachmentMetadataToBackendPayload payload,
  });

  @PUT("/")
  Future<String> putAttachmentMetadataToBackend({
    @Body() required PutAttachmentMetadataToBackendPayload payload,
  });

  @DELETE("/{uuid}")
  Future<HttpResponse> deleteAttachmentMetadataFromBackend({
    @Path("uuid") required String uuid,
    @Body() required Map<String, dynamic> auth,
  });

  @GET("/{uuid}/public")
  Future<HttpResponse> getPublicAttachmentsFromBackend({
    @Path("uuid") required String uuid,
  });

  @POST("/owner/view-all")
  Future<HttpResponse> getPublicAndPrivateAttachmentsFromBackend({
    @Body() required Map<String, dynamic> auth,
  });

  @DELETE("/")
  Future<HttpResponse> deleteAllAttachments({
    @Body() required Map<String, dynamic> auth,
  });
}
