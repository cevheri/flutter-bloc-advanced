/// This file is used to set the environment
enum Environment { DEV, PROD }

/// This class is used to store all environment variables
///
/// It is used in the main-local.dart file to set the environment
class Constants {

  static Map<String, dynamic>? _config;
  static final Map<String, String> languages = {'en':'English','fr':'Francais','tr':'Türkçe'};
  static final String langStorageKey = 'locale';

  static void setEnvironment(Environment env) {
    switch (env) {
      case Environment.DEV:
        _config = _Config.devConstants;
        break;
      case Environment.PROD:
        _config = _Config.prodConstants;
        break;
    }
  }

  static get api {
    return _config![_Config.API];
  }
}

class _Config {
  static const API = "API";

  static Map<String, dynamic> devConstants = {
    API: "http://127.0.0.1:8080/api",
  };

  static Map<String, dynamic> prodConstants = {
    API: "https://production-server/api",
  };
}
