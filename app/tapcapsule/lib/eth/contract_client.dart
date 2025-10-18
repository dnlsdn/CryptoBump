import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:web3dart/web3dart.dart'; // un unico import
import '../config/app_config.dart';

/// Gestisce connessione, ABI e chiamate al contratto VoucherRedeemer.
class ContractClient {
  final Web3Client _client;
  final DeployedContract _contract;

  ContractClient._(this._client, this._contract);

  static Future<ContractClient> create() async {
    final cfg = AppConfig.I;

    if (cfg.contractAddress.isEmpty) {
      throw StateError('Config: CONTRACT_ADDRESS mancante (assets/config/app_config.local.json).');
    }

    final client = Web3Client(cfg.rpcUrl, http.Client());
    final abi = ContractAbi.fromJson(cfg.contractAbi, 'VoucherRedeemer');
    final addr = EthereumAddress.fromHex(cfg.contractAddress);

    final contract = DeployedContract(abi, addr);
    return ContractClient._(client, contract);
  }

  /// Crea il voucher con ETH nativo.
  Future<String> createVoucherETH({
    required Uint8List hBytes, // keccak(secret) (32 bytes)
    required BigInt amountWei, // importo in wei
    required BigInt expiry, // timestamp (sec)
    required Credentials creds, // qualsiasi signer (non per forza burner)
  }) async {
    final f = _contract.function('createVoucher');
    final zero = EthereumAddress.fromHex('0x0000000000000000000000000000000000000000');

    final data = f.encodeCall([hBytes, zero, amountWei, expiry]);

    final txHash = await _client.sendTransaction(
      creds,
      Transaction(
        to: _contract.address,
        data: data,
        value: EtherAmount.inWei(amountWei), // msg.value = amount
      ),
      chainId: AppConfig.I.chainId,
    );
    return txHash;
  }

  Future<int> getLatestBlock() => _client.getBlockNumber();

  void dispose() => _client.dispose();
}
