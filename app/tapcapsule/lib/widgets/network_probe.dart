import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:web3dart/web3dart.dart';
import '../config/app_config.dart';

class NetworkProbe extends StatefulWidget {
  const NetworkProbe({super.key});

  @override
  State<NetworkProbe> createState() => _NetworkProbeState();
}

class _NetworkProbeState extends State<NetworkProbe> {
  late final Web3Client _client;
  Future<_ProbeResult>? _future;

  @override
  void initState() {
    super.initState();
    final cfg = AppConfig.I;
    _client = Web3Client(cfg.rpcUrl, http.Client());
    _future = _probe(cfg.chainId);
  }

  Future<_ProbeResult> _probe(int expectedChainId) async {
    try {
      final block = await _client.getBlockNumber();
      // getChainId -> BigInt
      final chainId = (await _client.getChainId()).toInt();
      final ok = chainId == expectedChainId;
      return _ProbeResult(ok: ok, blockNumber: block, chainId: chainId, error: null);
    } catch (e) {
      return _ProbeResult(ok: false, blockNumber: null, chainId: null, error: e.toString());
    }
  }

  @override
  void dispose() {
    _client.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_ProbeResult>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const _Tile(
            icon: Icons.hourglass_bottom,
            title: 'Connessione in corso…',
            subtitle: 'Controllo RPC e chainId…',
          );
        }
        final r = snap.data;
        if (r == null || !r.ok) {
          return _Tile(
            icon: Icons.error_outline,
            title: 'Connessione fallita',
            subtitle: r?.error ?? 'RPC non raggiungibile',
            color: Theme.of(context).colorScheme.error,
          );
        }
        return _Tile(
          icon: Icons.check_circle,
          title: 'Connesso a Base Sepolia',
          subtitle: 'chainId=${r.chainId} • latest block=${r.blockNumber}',
          color: Theme.of(context).colorScheme.primary,
        );
      },
    );
  }
}

class _ProbeResult {
  final bool ok;
  final int? blockNumber;
  final int? chainId;
  final String? error;
  _ProbeResult({required this.ok, this.blockNumber, this.chainId, this.error});
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? color;

  const _Tile({required this.icon, required this.title, this.subtitle, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return Card(
      child: ListTile(
        leading: Icon(icon, color: c),
        title: Text(title),
        subtitle: subtitle != null ? Text(subtitle!) : null,
      ),
    );
  }
}
