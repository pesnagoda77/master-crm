import 'package:share_plus/share_plus.dart';

class ShareService {
  static Future<void> shareFile(String path, {String? subject}) async {
    await Share.shareXFiles(
      [XFile(path)],
      subject: subject,
    );
  }
}
