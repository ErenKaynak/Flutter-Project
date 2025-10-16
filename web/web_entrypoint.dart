import 'package:engineering_project/main.dart' as app;
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

void main() {
  // Use URL Strategy that removes the # from URLs
  setUrlStrategy(PathUrlStrategy());
  app.main();
}
