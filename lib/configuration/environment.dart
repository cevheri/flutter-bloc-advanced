/// This file is used to set the environment
enum Environment { DEV, PROD }

/// This class is used to store all environment variables
///
/// It is used in the main_local.dart file to set the environment
class ProfileConstants {
  static Map<String, dynamic>? _config;

  static void setEnvironment(Environment env) {
    switch (env) {
      case Environment.DEV:
        _config = _Config.devConstants;
        break;
      case Environment.PROD:
        _config = _Config.prodConstants;
        break;
      default:
        _config = _Config.devConstants;
    }
  }

  static bool get isProduction {
    return _config == _Config.prodConstants;
  }
  static bool get isDevelopment {
    return _config == _Config.devConstants;
  }

  static get api {
    return _config![_Config.API];
  }
}

class _Config {
  static const API = "API";

  static Map<String, dynamic> devConstants = {
    API: "mock_data",
    //API: "http://192.168.1.1:8081/api",
  };

  static Map<String, dynamic> prodConstants = {
    API: "mock_data",
    //API: "http://192.168.1.1:8081/api",
  };
}
