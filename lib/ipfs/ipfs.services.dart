import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:cross_file/cross_file.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/**
 * get ipfsGatewayClient
 */
Dio getIpfsGatewayClient() {
  String ipfsGategway = dotenv.get('IPFS_GATEWAY');
  String ipfsGategwayApiKey = dotenv.get('IPFS_API_KEY');
  return Dio(BaseOptions(
      baseUrl: ipfsGategway,
      headers: {"Authorization": "Bearer $ipfsGategwayApiKey"}));
}

/**
 * retrieve cid from IPFS link
 */
String getCidFromIpfsLink(String ipfsLink) {
  return ipfsLink.toString().replaceFirst(r'ipfs://', '');
}

/**
 * upload xfile and return CID
 */
Future<String> uploadFileToIPFS(XFile xfile) async {
  File file = File(xfile.path);
  String fileName = file.path.split('/').last;
  FormData formData = FormData.fromMap({
    "file": await MultipartFile.fromFile(file.path, filename: fileName),
  });
  var ipfs = getIpfsGatewayClient();
  Response response = await ipfs.post("upload/", data: formData,
      onSendProgress: (int sent, int total) {
    print('$sent / $total');
  });
  return response.data['value']['cid'];
}

/**
 * download a file from IPFS
 */
Future downloadFileFromIPFS(String cid, String savePath) async {
  var ipfs = getIpfsGatewayClient();
  try {
    Response response = await ipfs.get(
      cid,
      options: Options(
          responseType: ResponseType.bytes,
          followRedirects: false,
          validateStatus: (status) {
            return status! < 500;
          }),
    );
    File file = File(savePath);
    var raf = file.openSync(mode: FileMode.write);
    raf.writeFromSync(response.data);
    await raf.close();
  } catch (e) {
    print(e);
  }
}
