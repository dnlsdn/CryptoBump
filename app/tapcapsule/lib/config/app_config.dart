import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

class AppConfig {
  final String rpcUrl;
  final String contractAddress;
  final String contractAbi;
  final int chainId;
  final String explorerBaseUrl;
  final String? burnerPrivateKey;
  final bool demoNearby;

  AppConfig({
    required this.rpcUrl,
    required this.contractAddress,
    required this.contractAbi,
    required this.chainId,
    required this.explorerBaseUrl,
    this.burnerPrivateKey,
    this.demoNearby = false,
  });

  static AppConfig? _instance;
  static AppConfig get I {
    if (_instance == null) {
      throw StateError('AppConfig not initialized. Call AppConfig.load() in main().');
    }
    return _instance!;
  }

  static Future<void> load() async {
    String confJson;
    try {
      confJson = await rootBundle.loadString('assets/config/app_config.local.json');
    } catch (_) {
      try {
        confJson = await rootBundle.loadString('assets/config/app_config.sample.json');
      } catch (_) {
        confJson = await rootBundle.loadString('assets/config/app_config.example.json');
      }
    }
    final Map<String, dynamic> conf = jsonDecode(confJson);

    String abiString;
    if (conf['CONTRACT_ABI_INLINE'] != null) {
      abiString = jsonEncode(conf['CONTRACT_ABI_INLINE']);
    } else {
      final abiPath = (conf['CONTRACT_ABI_PATH'] as String?) ?? 'assets/config/abi.json';
      abiString = await rootBundle.loadString(abiPath);
    }

    _instance = AppConfig(
      rpcUrl: conf['RPC_URL'] as String,
      contractAddress: (conf['CONTRACT_ADDRESS'] as String?) ?? '',
      contractAbi: abiString,
      chainId: (conf['CHAIN_ID'] as num?)?.toInt() ?? 84532,
      explorerBaseUrl: (conf['EXPLORER_BASE_URL'] as String?) ?? '',
      burnerPrivateKey: conf['BURNER_PRIVATE_KEY'] as String?,
      demoNearby: (conf['DEMO_NEARBY'] as bool?) ?? false,
    );

    if (kDebugMode) {
      debugPrint('[AppConfig] chainId=${_instance!.chainId} explorer=${_instance!.explorerBaseUrl}');
    }
  }
}
