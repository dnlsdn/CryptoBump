# CryptoBump - Smart Contracts

Smart contracts for the CryptoBump tap-to-redeem crypto voucher system on **Base Sepolia** (testnet).

---

## 📋 Overview

**VoucherRedeemer** is a smart contract that allows users to:
1. **Create vouchers**: Lock ETH or ERC-20 tokens under a secret hash (`keccak256(secret)`)
2. **Redeem vouchers**: Anyone with the secret can claim the funds before expiry
3. **Refund vouchers**: Creator can reclaim funds after expiry if not redeemed

### Key Features
- ✅ Supports both native ETH and ERC-20 tokens
- ✅ Time-locked with expiry mechanism
- ✅ Reentrancy protection via OpenZeppelin
- ✅ Gas-optimized with custom errors
- ✅ 100% test coverage (14 tests passing)

---

## 🏗️ Project Structure

```
smart-contract/
├── contracts/
│   └── VoucherRedeemer.sol      # Main contract
├── test/
│   └── VoucherRedeemer.t.sol    # Solidity tests (Foundry)
├── scripts/
│   └── verify-setup.ts          # Setup verification script
├── ignition/modules/
│   └── VoucherRedeemer.ts       # Hardhat Ignition deployment
├── .env                         # Environment variables (gitignored)
├── hardhat.config.ts            # Hardhat configuration
└── package.json
```

---

## 🚀 Quick Start

### Prerequisites
- **Node.js 22+** (required by Hardhat 3)
- npm or pnpm
- Alchemy API key for Base Sepolia
- Burner wallet with Base Sepolia test ETH

### Installation

```bash
# Install dependencies
npm install

# Configure environment - edit .env with your credentials
nano .env
```

### Environment Setup

Edit `.env`:
```bash
BASE_SEPOLIA_RPC_URL=https://base-sepolia.g.alchemy.com/v2/YOUR_API_KEY
PRIVATE_KEY=0x...your_private_key...
```

---

## 🧪 Testing

Run the full test suite:

```bash
npm test
```

Expected output:
```
✔ test_CreateVoucher()
✔ test_Redeem()
✔ test_Refund()
✔ testFuzz_CreateAndRedeem(uint256,uint96) (runs: 256)
...

14 passing
```

---

## 🔍 Verify Setup

Before deploying, verify your setup:

```bash
npm run verify-setup
```

This checks:
- ✅ RPC connection to Base Sepolia (chainId: 84532)
- ✅ Wallet address and balance
- ✅ Gas prices

---

## 🚀 Deployment

Deploy to Base Sepolia testnet:

```bash
npm run deploy
```

**Important**: Get test ETH before deploying!
- Faucet: https://www.alchemy.com/faucets/base-sepolia

---

## 📝 Contract Interface

### Create Voucher

```solidity
function createVoucher(
    bytes32 h,           // keccak256(secret)
    address token,       // address(0) for ETH
    uint256 amount,      // Amount to lock
    uint64 expiry        // Expiry timestamp
) external payable
```

### Redeem Voucher

```solidity
function redeem(bytes memory secret) external
```

### Refund Voucher

```solidity
function refund(bytes32 h) external
```

---

## 🛠️ Available Scripts

| Command | Description |
|---------|-------------|
| `npm run verify-setup` | Verify RPC connection and wallet |
| `npm run compile` | Compile contracts |
| `npm test` | Run test suite |
| `npm run clean` | Clean build artifacts |
| `npm run deploy` | Deploy to Base Sepolia |

---

## 🔒 Security

- **ReentrancyGuard**: All state-changing functions protected
- **Checks-Effects-Interactions**: State updated before external calls
- **SafeERC20**: Safe token transfers via OpenZeppelin
- **Custom Errors**: Gas-efficient error handling

---

## 🌐 Network: Base Sepolia (Testnet)

- **ChainId**: 84532
- **RPC**: Via Alchemy
- **Explorer**: https://sepolia.basescan.org
- **Faucet**: https://www.alchemy.com/faucets/base-sepolia

---

## 📄 License

MIT
