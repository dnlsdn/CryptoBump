# Come Continuare

Guida pratica per riprendere il lavoro su TapCapsule.

---

## Setup Veloce (Se Riparti da Zero)

### 1. Installa Dipendenze
```bash
cd smart-contract
npm install

# Usa Node.js 22+
nvm use 22
```

### 2. Configura .env
Crea `smart-contract/.env`:
```
BASE_SEPOLIA_RPC_URL=https://base-sepolia.g.alchemy.com/v2/TUO_API_KEY
PRIVATE_KEY=0x...
```

### 3. Verifica Setup
```bash
npm run verify-setup
```

Se tutto ok, sei pronto!

---

## Comandi Principali

### Smart Contract

```bash
cd smart-contract

# Compila
npm run compile

# Test (importante!)
npm test

# Deploy nuovo contratto (se serve)
npm run deploy

# Pulisci artifacts
npm run clean
```

### Flutter App

```bash
cd app/tapcapsule

# Installa dipendenze
flutter pub get

# Run app
flutter run

# Build iOS
flutter build ios
```

---

## Prossimi Step

### 1. Integrare Contratto in Flutter

**Aggiungi dependencies** in `pubspec.yaml`:
```yaml
dependencies:
  web3dart: ^2.7.0
  http: ^1.1.0
```

**Carica config**:
```dart
// Leggi config/addresses.json
final contractAddress = "0xA0bbf7730C9065830c51d2A57b2C0A98d3876bD1";

// Leggi config/abi.json
final abi = await rootBundle.loadString('config/abi.json');
```

**Connetti al contratto**:
```dart
final client = Web3Client(rpcUrl, http.Client());
final contract = DeployedContract(
  ContractAbi.fromJson(abi, 'VoucherRedeemer'),
  EthereumAddress.fromHex(contractAddress),
);
```

### 2. Implementa Create Voucher

```dart
// Genera secret (32 byte random)
final secret = generateRandomBytes(32);
final h = keccak256(secret);

// Chiama createVoucher
final tx = await contract.createVoucher(
  h,
  EthereumAddress.zero, // ETH
  BigInt.from(1000000000000000), // 0.001 ETH
  expiryTimestamp,
);
```

### 3. Multipeer Connectivity (iOS)

Crea bridge Swift per passare il secret:
- File: `ios/Runner/MultipeerManager.swift`
- Usa `MCSession` per proximity
- Passa byte[] del secret tra device

### 4. Implementa Redeem

```dart
// Ricevi secret via Multipeer
await contract.redeem(secretBytes);
```

---

## Testing del Contratto

### Locale (Hardhat Network)
```bash
npm test
```

### Su Base Sepolia (Live)

**Via Hardhat Console**:
```bash
npx hardhat console --network baseSepolia
```

```javascript
const contract = await ethers.getContractAt(
  "VoucherRedeemer",
  "0xA0bbf7730C9065830c51d2A57b2C0A98d3876bD1"
);

// Test create
const secret = ethers.randomBytes(32);
const h = ethers.keccak256(secret);
await contract.createVoucher(
  h,
  ethers.ZeroAddress,
  ethers.parseEther("0.001"),
  Math.floor(Date.now() / 1000) + 86400,
  { value: ethers.parseEther("0.001") }
);

// Test redeem
await contract.redeem(secret);
```

**Via BaseScan**:
1. Vai su https://sepolia.basescan.org/address/0xA0bbf7730C9065830c51d2A57b2C0A98d3876bD1
2. Tab "Contract" → "Write Contract"
3. Connetti wallet
4. Chiama funzioni

---

## Modificare il Contratto

### Se Devi Cambiare VoucherRedeemer.sol

1. **Edita** `contracts/VoucherRedeemer.sol`
2. **Testa**:
   ```bash
   npm test
   ```
3. **Deploy nuovo contratto**:
   ```bash
   npm run deploy
   ```
4. **Aggiorna** `config/addresses.json` con nuovo indirizzo
5. **Aggiorna** `config/abi.json`:
   ```bash
   npm run compile
   # Poi copia da artifacts/...
   ```

**IMPORTANTE**: Il contratto vecchio resta sulla blockchain (immutabile). Devi usare il nuovo indirizzo nell'app.

---

## Troubleshooting Comune

### "Insufficient funds"
```bash
# Controlla balance
npm run verify-setup

# Prendi test ETH
# https://www.alchemy.com/faucets/base-sepolia
```

### "Transaction underpriced"
Gas troppo basso. Base Sepolia è cheap, non dovrebbe succedere.

### "Voucher already exists"
Ogni secret genera un hash unico. Usa secret diversi per ogni voucher.

### "Voucher expired"
Check timestamp. Expiry deve essere > `block.timestamp`.

### Test falliscono
```bash
npm run clean
npm run compile
npm test
```

---

## Deploy su Mainnet (QUANDO PRONTO!)

**NON FARLO ORA! Solo testnet per ora.**

Quando pronto:
1. **Audit** del contratto
2. **Test** estensivo su testnet
3. Wallet con ETH vero
4. Config per Base Mainnet (chainId 8453)
5. Deploy:
   ```bash
   # Aggiungi network in hardhat.config.ts
   npm run deploy --network baseMainnet
   ```

**Costo stimato**: ~$5-10 per deploy.

---

## Risorse Utili

### Docs
- Hardhat: https://hardhat.org
- Base: https://docs.base.org
- web3dart: https://pub.dev/packages/web3dart
- OpenZeppelin: https://docs.openzeppelin.com

### Tools
- BaseScan Explorer: https://sepolia.basescan.org
- Alchemy Dashboard: https://dashboard.alchemy.com
- Base Faucet: https://www.alchemy.com/faucets/base-sepolia

### Repository Docs
- `/smart-contract/README.md` - Tech details
- `/smart-contract/SETUP.md` - Setup dettagliato
- `/docs/WHAT-WE-BUILT.md` - Overview progetto

---

## Quick Reference

### Contract Address
```
0xA0bbf7730C9065830c51d2A57b2C0A98d3876bD1
```

### Network
- Name: Base Sepolia
- ChainID: 84532
- RPC: Via Alchemy
- Explorer: https://sepolia.basescan.org

### Key Files
- Config: `config/addresses.json`, `config/abi.json`
- Contract: `smart-contract/contracts/VoucherRedeemer.sol`
- Tests: `smart-contract/test/VoucherRedeemer.t.sol`
- Secrets: `smart-contract/.env` (gitignored!)

---

**Tutto chiaro. Vai e buildi.** 🚀
