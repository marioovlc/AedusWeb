import 'file_helper_stub.dart'
    if (dart.library.html) 'file_helper_web.dart' as platform;

void platformDownload(String content, String fileName) {
  platform.downloadFile(content, fileName);
}
