import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:cross_file/cross_file.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// get ipfsGatewayClient
Dio getIpfsGatewayClient(bool api) {
  if (api) {
    return Dio(BaseOptions(
        baseUrl: dotenv.get('IPFS_GATEWAY_API'),
        headers: {"Authorization": "Bearer ${dotenv.get('IPFS_API_KEY')}"}));
  } else {
    return Dio(BaseOptions(baseUrl: dotenv.get('IPFS_GATEWAY')));
  }
}

Dio getAlternativeIpfsGatewayClient() {
  return Dio(BaseOptions(baseUrl: dotenv.get('IPFS_ALTERNATIVE_GATEWAY')));
}

/// retrieve cid from IPFS link
String getCidFromIpfsLink(String ipfsLink) {
  return ipfsLink.toString().replaceFirst(r'ipfs://', '');
}

/// upload xfile and return CID
Future<String> uploadFileToIPFS(XFile xfile, String fileMimeType) async {
  File file = File(xfile.path);
  String fileName = file.path.split('/').last;
  FormData formData = FormData.fromMap(
    {
      "file": await MultipartFile.fromFile(file.path,
          filename: fileName, contentType: MediaType.parse(fileMimeType)),
      "pinataMetadata": {"fileMimeType": fileMimeType}
    },
  );
  var ipfs = getIpfsGatewayClient(true);
  Response response = await ipfs.post(dotenv.get('IPFS_PIN_COMMAND'),
      data: formData, onSendProgress: (int sent, int total) {
    print('$sent / $total'); // TODO: pass to progress bar
  });
  print(response.data);
  return response.data[dotenv.get('IPFS_CID_RESPONSE_PATH')];
}

/// download a file from IPFS
Future<void> downloadMetadataFileFromIPFS(
    String cid, String savePath, bool retry) async {
  try {
    // get filename
    var ipfs = (!retry)
        ? getIpfsGatewayClient(false)
        : getAlternativeIpfsGatewayClient();
    Response response = await ipfs.get(
      cid,
      options: Options(
          responseType: ResponseType.json,
          followRedirects: false,
          validateStatus: (status) {
            return status! < 500;
          }),
    );
    File metadataFile = File(savePath);
    await metadataFile.writeAsString(json.encode(response.data), flush: true);
  } catch (e) {
    print("ERROR while downloading metadata file from IPFS: $e");
    // RETRY using alternative IPFS gateway
    await downloadMetadataFileFromIPFS(cid, savePath, true);
  }
}

/// download an image file from IPFS and return file path
Future<Map<String, String>> downloadImageFileFromIPFS(String cid) async {
  try {
    var ipfs = getIpfsGatewayClient(false);
    Response response = await ipfs.get(
      cid,
      options: Options(
          responseType: ResponseType.bytes,
          followRedirects: false,
          validateStatus: (status) {
            return status! < 500;
          }),
    );

    final Directory directory = Directory.systemTemp;
    final File imageFile = File("${directory.path}/$cid");
    await imageFile.writeAsBytes(response.data);
    final String imagePath = imageFile.path;
    String imageUri = "${dotenv.get('IPFS_GATEWAY')}$cid";
    Map<String, String> result = {"imagePath": imagePath, "imageUri": imageUri};
    return result;
  } catch (e) {
    print("ERROR while downloading image file from IPFS...");
    print(e);
    return {};
  }
}
