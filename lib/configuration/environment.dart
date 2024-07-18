/// This file is used to set the environment
enum Environment { DEV, PROD, MOCK_SERVER, MOCK_JSON }

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
      case Environment.MOCK_SERVER:
        _config = _Config.mockServerConstants;
        break;
      case Environment.MOCK_JSON:
        _config = _Config.mockJsonConstants;
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

  static bool get isMockServer {
    return _config == _Config.mockServerConstants;
  }

  static bool get isMockJson {
    return _config == _Config.mockJsonConstants;
  }

  static get api {
    return _config![_Config.API];
  }
}

class _Config {
  static const API = "API";
  static Map<String, dynamic> mockServerConstants = {
    API: "https://virtserver.swaggerhub.com/cevheri/flutter-bloc-template/0.0.1/api",
  };

  static Map<String, dynamic> mockJsonConstants = {
    API: " assets/mock",
  };

  static Map<String, dynamic> devConstants = {
    API: "mock_data",
    //API: "http://localhost:8080/api",
  };

  static Map<String, dynamic> prodConstants = {
    API: "https://api.sekoyatech.com/api",
  };
}
