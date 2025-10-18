# CryptoBump Smart Contract - Setup Guide

## 🚀 Quick Start

### 1. Configure Environment Variables

Edit the `.env` file in this directory:

```bash
# Open .env and fill in your values
nano .env
```

You need to add:

**BASE_SEPOLIA_RPC_URL**: Get from Alchemy Dashboard
- Go to: https://dashboard.alchemy.com
- Create new App: "CryptoBump"
- Chain: Base Sepolia
- Copy the HTTPS URL

**PRIVATE_KEY**: From your burner wallet
- Use MetaMask or any wallet
- Create a NEW account (burner wallet for testing)
- Export private key (must start with `0x`)
- ⚠️ NEVER use your main wallet for testing!

### 2. Get Test ETH

Your wallet needs Base Sepolia test ETH to deploy contracts:

- Faucet: https://www.alchemy.com/faucets/base-sepolia
- Alternative: https://docs.base.org/tools/network-faucets

### 3. Verify Setup

Run the verification script to check everything is configured correctly:

```bash
npm run verify-setup
```

This will check:
- ✓ RPC connection to Base Sepolia
- ✓ Network chainId (should be 84532)
- ✓ Your wallet address
- ✓ Your wallet balance
- ✓ Current gas prices

Expected output:
```
🔍 CryptoBump - Verifying Setup...

📡 Network Connection:
   ✓ Connected to chainId: 84532
   ✓ Base Sepolia confirmed!
   ✓ Latest block: 123456

💼 Wallet Info:
   ✓ Address: 0x...
   ✓ Balance: 0.5 ETH
   ✓ Wallet funded!

⛽ Gas Info:
   ✓ Gas Price: ...

✅ Setup verification complete!
```

### 4. Available Commands

```bash
# Verify setup (recommended first!)
npm run verify-setup

# Compile contracts
npm run compile

# Run tests
npm run test

# Clean build artifacts
npm run clean
```

---

## 🔒 Security Notes

- `.env` is already in `.gitignore` - NEVER commit it!
- Only use burner wallets with small amounts of test ETH
- Keep your main wallet private keys safe and separate

---

## 📚 Network Details

- **Network**: Base Sepolia (Testnet)
- **ChainId**: 84532
- **Explorer**: https://sepolia.basescan.org
- **RPC**: Via Alchemy

---

## ❓ Troubleshooting

### "Cannot connect to RPC"
- Check your `BASE_SEPOLIA_RPC_URL` in `.env`
- Make sure you copied the full URL from Alchemy
- Test the URL manually with curl (see main README.md)

### "Invalid private key"
- Make sure `PRIVATE_KEY` starts with `0x`
- Should be exactly 66 characters (0x + 64 hex chars)
- No spaces or quotes around the value

### "Insufficient funds"
- Get test ETH from Base Sepolia faucet
- Wait a few minutes for faucet transaction to confirm
- Run `npm run verify-setup` again to check balance

---

## 🎯 Next Steps

Once `npm run verify-setup` passes:
1. Proceed to STEP 2: Smart Contract Development
2. Create VoucherRedeemer.sol
3. Write tests
4. Deploy to Base Sepolia
