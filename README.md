# CryptoBump

**Tap-to-redeem crypto vouchers with iPhone proximity.**

Bump two iPhones → send crypto. Simple.

---

## What It Does

1. **Create** - Lock 0.001 ETH in a smart contract
2. **Bump** - Touch phones to pass a secret
3. **Redeem** - Recipient claims the money

All on-chain. Base Sepolia testnet.

---

## Status

✅ **Smart contract deployed and working**
- Contract: `0xA0bbf7730C9065830c51d2A57b2C0A98d3876bD1`
- Network: Base Sepolia (ChainID 84532)
- Tested: 14 tests passing

⏳ **App integration** - Next step

---

## Quick Links

📖 **[What We Built](docs/WHAT-WE-BUILT.md)** - Complete overview
🚀 **[How to Continue](docs/HOW-TO-CONTINUE.md)** - Setup & next steps
💻 **[Smart Contract Docs](smart-contract/README.md)** - Technical details

---

## Project Structure

```
CryptoBump/
├── smart-contract/       # Solidity + Hardhat
│   ├── contracts/VoucherRedeemer.sol
│   └── test/VoucherRedeemer.t.sol
├── app/CryptoBump/      # Flutter app (iOS)
├── config/
│   ├── addresses.json   # Deployed contract address
│   └── abi.json        # Contract ABI
└── docs/               # Documentation
```

---

## Tech Stack

- **Blockchain**: Base Sepolia (L2)
- **Smart Contracts**: Solidity 0.8.28
- **Framework**: Hardhat 3 + OpenZeppelin
- **App**: Flutter (iOS)
- **Proximity**: Multipeer Connectivity

## Getting Started

```bash
# 1. Setup smart contracts
cd smart-contract
npm install
npm run verify-setup

# 2. Run tests
npm test

# 3. Flutter app
cd ../app/CryptoBump
flutter pub get
flutter run
```

**Full setup guide**: [docs/HOW-TO-CONTINUE.md](docs/HOW-TO-CONTINUE.md)

---

## Network Info

- **Network**: Base Sepolia (Testnet)
- **ChainID**: 84532
- **Explorer**: https://sepolia.basescan.org
- **Contract**: `0xA0bbf7730C9065830c51d2A57b2C0A98d3876bD1`

**Get test ETH**: https://www.alchemy.com/faucets/base-sepolia

---

## License

MIT

