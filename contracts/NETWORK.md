# Rete di prova — Base Sepolia (testnet)

- **Nome rete**: Base Sepolia (testnet)
- **Chain ID**: `84532`
- **Symbol**: `ETH`
- **Block Explorer**: https://sepolia.basescan.org/

## Cos'è l'RPC URL?
È l'indirizzo del **nodo** a cui il nostro tool (Hardhat/Foundry/script) si collega per leggere/scrivere sulla rete. Esempio: `https://base-sepolia.g.alchemy.com/v2/<API_KEY>`.

## Dove prenderemo l'RPC URL?
Da un **RPC provider** (es. Alchemy/QuickNode/Infura/Tenderly).  
Creeremo un progetto “Base Sepolia” e useremo l’URL nel file `.env` (non pubblico).

## Variabili ambiente (bozza)
- `BASE_SEPOLIA_RPC_URL=<da_provider>`
- `PRIVATE_KEY=<chiave privata account di test>`  ← **non committare**
- (opz) `BASESCAN_API_KEY=<per verifica su explorer>`
