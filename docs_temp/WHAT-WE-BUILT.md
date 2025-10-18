# Cosa Abbiamo Fatto

## Il Progetto

**TapCapsule** = App per mandare crypto "bumpando" due iPhone.

### Come Funziona
1. Persona A crea un voucher (es. 0.001 ETH)
2. Due telefoni si toccano → passa un "secret"
3. Persona B usa il secret per riscuotere i soldi

**Tutto on-chain su Base Sepolia (testnet).**

---

## Smart Contract Deployato

### VoucherRedeemer.sol
- **Indirizzo**: `0xA0bbf7730C9065830c51d2A57b2C0A98d3876bD1`
- **Network**: Base Sepolia (ChainID 84532)
- **Explorer**: https://sepolia.basescan.org/address/0xA0bbf7730C9065830c51d2A57b2C0A98d3876bD1

### Cosa Fa
- `createVoucher()` - Blocca ETH sotto hash di un secret
- `redeem()` - Chi ha il secret può riscuotere
- `refund()` - Dopo 24h, il creatore può riprendersi i soldi se non riscattati

### Sicurezza
- OpenZeppelin ReentrancyGuard
- SafeERC20 per token
- Testato (14 test, tutti passing)

---

## Struttura Progetto

```
TapCapsule/
├── smart-contract/        # Contratti Solidity + Hardhat
│   ├── contracts/
│   │   └── VoucherRedeemer.sol
│   ├── test/
│   │   └── VoucherRedeemer.t.sol
│   └── .env               # API keys (MAI committare)
│
├── app/tapcapsule/        # App Flutter (iOS)
│   └── lib/
│
├── config/
│   ├── addresses.json     # Indirizzo contratto deployato
│   └── abi.json          # ABI per chiamare il contratto
│
└── docs/                  # Questa roba
```

---

## Setup Fatto

### Smart Contract
- ✅ Hardhat 3 configurato
- ✅ OpenZeppelin installato
- ✅ Base Sepolia network setup
- ✅ Alchemy RPC configurato
- ✅ Test completi (Foundry/Solidity)
- ✅ Deploy script funzionante
- ✅ Contratto deployato su Base Sepolia

### Comandi Utili
```bash
cd smart-contract

# Verifica setup (RPC, wallet, balance)
npm run verify-setup

# Compila contratti
npm run compile

# Esegui test
npm test

# Deploy (già fatto!)
npm run deploy
```

---

## File Importanti

### Config
- `config/addresses.json` - Indirizzo contratto per l'app
- `config/abi.json` - ABI per chiamare funzioni
- `smart-contract/.env` - API keys (gitignored)

### Contratto
- `smart-contract/contracts/VoucherRedeemer.sol` - Il contratto
- `smart-contract/test/VoucherRedeemer.t.sol` - Test Solidity

### Docs
- `smart-contract/README.md` - Tech docs Hardhat/test
- `smart-contract/SETUP.md` - Setup ambiente sviluppo

---

## Tecnologie

- **Blockchain**: Base Sepolia (L2 di Ethereum)
- **Smart Contracts**: Solidity 0.8.28
- **Framework**: Hardhat 3
- **Testing**: Foundry (integrato in Hardhat 3)
- **Security**: OpenZeppelin
- **RPC**: Alchemy
- **App**: Flutter (iOS)
- **Proximity**: Multipeer Connectivity (iOS)

---

## Dati Deployment

- **Data**: 18 Ottobre 2025
- **Network**: Base Sepolia Testnet
- **Contract**: `0xA0bbf7730C9065830c51d2A57b2C0A98d3876bD1`
- **Deployed da**: `0x59a0eE0f739e0B932263d3F62D039E39fc2D11d6`

---

## Costi

**Testnet (Base Sepolia)**:
- Deploy: ~0.002 ETH di test (gratis dal faucet)
- Create voucher: ~0.00006 ETH (~$0.001)
- Redeem: ~0.00004 ETH (~$0.0007)

**Base è economico!** Gas molto più basso di Ethereum.

---

## Cosa Manca (Roadmap)

### Per MVP
- [ ] App Flutter che chiama il contratto
- [ ] Multipeer Connectivity per passare il secret
- [ ] UI/UX per create/redeem

### Nice to Have
- [ ] Gasless redeem (Paymaster)
- [ ] ENS per mostrare nome mittente
- [ ] Supporto ERC-20 token (oltre a ETH)
- [ ] Web3Mail per ricevute

### Per Produzione
- [ ] Deploy su Base Mainnet
- [ ] Security audit
- [ ] Gas optimization

---

**Tutto qui. Semplice.**
