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

  Future<String> createVoucherETH({
    required Uint8List hBytes,
    required BigInt amountWei,
    required BigInt expiry,
    required Credentials creds,
  }) async {
    final zero = EthereumAddress.fromHex('0x0000000000000000000000000000000000000000');
    final data = _createF.encodeCall([hBytes, zero, amountWei, expiry]);

    return _client.sendTransaction(
      creds,
      Transaction(
        to: _contract.address,
        data: data,
        value: EtherAmount.inWei(amountWei),
      ),
      chainId: AppConfig.I.chainId,
    );
  }

  Future<String> redeem({required Uint8List secretBytes, required Credentials creds}) {
    final data = _redeemF.encodeCall([secretBytes]);
    return _client.sendTransaction(
      creds,
      Transaction(to: _contract.address, data: data),
      chainId: AppConfig.I.chainId,
    );
  }

  void dispose() => _client.dispose();

  Future<String> refund({
    required Uint8List hBytes,
    required Credentials creds,
  }) async {
    final refundF = _contract.function('refund');
    final data = refundF.encodeCall([hBytes]);
    return _client.sendTransaction(
      creds,
      Transaction(to: _contract.address, data: data),
      chainId: AppConfig.I.chainId,
    );
  }
}
