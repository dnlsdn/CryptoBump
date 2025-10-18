// lib/services/contract_client.dart
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:web3dart/web3dart.dart';
import '../config/app_config.dart';

class ContractClient {
  final Web3Client _client;
  final DeployedContract _contract;
  final ContractFunction _createF;
  final ContractFunction _redeemF;

  ContractClient._(this._client, this._contract, this._createF, this._redeemF);

  static Future<ContractClient> create() async {
    final cfg = AppConfig.I;
    if (cfg.contractAddress.isEmpty) {
      throw StateError('CONFIG: CONTRACT_ADDRESS mancante in assets/config/app_config.local.json');
    }
    final client = Web3Client(cfg.rpcUrl, http.Client());
    final abi = ContractAbi.fromJson(cfg.contractAbi, 'VoucherRedeemer');
    final addr = EthereumAddress.fromHex(cfg.contractAddress);
    final c = DeployedContract(abi, addr);
    return ContractClient._(client, c, c.function('createVoucher'), c.function('redeem'));
  }

  /// createVoucher(h, token=0x0, amount, expiry) con ETH nativo
  Future<String> createVoucherETH({
    required Uint8List hBytes, // keccak256(secret) (32 bytes)
    required BigInt amountWei, // importo in wei
    required BigInt expiry, // timestamp (secondi)
    required Credentials creds, // il tuo wallet di test (NON burner)
  }) async {
    final zero = EthereumAddress.fromHex('0x0000000000000000000000000000000000000000');
    final data = _createF.encodeCall([hBytes, zero, amountWei, expiry]);

    return _client.sendTransaction(
      creds,
      Transaction(
        to: _contract.address,
        data: data,
        value: EtherAmount.inWei(amountWei), // msg.value = amount
      ),
      chainId: AppConfig.I.chainId,
    );
  }

  /// redeem(secret)
  Future<String> redeem({required Uint8List secretBytes, required Credentials creds}) {
    final data = _redeemF.encodeCall([secretBytes]);
    return _client.sendTransaction(
      creds,
      Transaction(to: _contract.address, data: data),
      chainId: AppConfig.I.chainId,
    );
  }

  void dispose() => _client.dispose();
}
