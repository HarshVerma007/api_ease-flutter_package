import 'package:flutter/foundation.dart';

class ApiCallController extends ChangeNotifier {
  VoidCallback? _fetchCallback;

  bool get isAttached => _fetchCallback != null;

  void attach(VoidCallback fetch) => _fetchCallback = fetch;

  void detach() => _fetchCallback = null;

  void fetch() => _fetchCallback?.call();

  void refresh() => fetch();

  @override
  void dispose() {
    _fetchCallback = null;
    super.dispose();
  }
}
