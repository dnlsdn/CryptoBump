/**
 * TapCapsule - Setup Verification Script
 *
 * This script verifies:
 * 1. RPC connection to Base Sepolia
 * 2. Private key format
 * 3. Wallet address and balance
 * 4. Network chainId
 *
 * Run: npx hardhat run scripts/verify-setup.ts --network baseSepolia
 */

import { JsonRpcProvider, Wallet, formatEther } from "ethers";
import * as dotenv from "dotenv";

// Load .env
dotenv.config();

async function main() {
  console.log("\n🔍 TapCapsule - Verifying Setup...\n");

  try {
    // Read directly from environment variables
    const rpcUrl = process.env.BASE_SEPOLIA_RPC_URL;
    const privateKey = process.env.PRIVATE_KEY;

    if (!rpcUrl || !privateKey) {
      throw new Error("Missing BASE_SEPOLIA_RPC_URL or PRIVATE_KEY in .env file");
    }

    console.log(`📍 Using network: baseSepolia\n`);

    // Create provider
    const provider = new JsonRpcProvider(rpcUrl);

    // Create wallet from private key
    const wallet = new Wallet(privateKey, provider);
    const address = wallet.address;

    // 1. Check network connection
    console.log("📡 Network Connection:");
    const network = await provider.getNetwork();
    console.log(`   ✓ Connected to chainId: ${network.chainId}`);

    if (network.chainId !== 84532n) {
      console.log(`   ⚠️  WARNING: Expected Base Sepolia (84532), got ${network.chainId}`);
    } else {
      console.log(`   ✓ Base Sepolia confirmed!`);
    }

    // 2. Check block number (confirms RPC is working)
    const blockNumber = await provider.getBlockNumber();
    console.log(`   ✓ Latest block: ${blockNumber}`);

    // 3. Check wallet address
    console.log("\n💼 Wallet Info:");
    console.log(`   ✓ Address: ${address}`);

    // 4. Check balance
    const balance = await provider.getBalance(address);
    const balanceInEth = formatEther(balance);
    console.log(`   ✓ Balance: ${balanceInEth} ETH`);

    if (balance === 0n) {
      console.log(`   ⚠️  WARNING: Wallet has no funds!`);
      console.log(`   🚰 Get test ETH from: https://www.alchemy.com/faucets/base-sepolia`);
    } else {
      console.log(`   ✓ Wallet funded!`);
    }

    // 5. Estimate gas price
    const feeData = await provider.getFeeData();
    console.log("\n⛽ Gas Info:");
    console.log(`   ✓ Gas Price: ${feeData.gasPrice ? formatEther(feeData.gasPrice) : 'N/A'} ETH (wei)`);

    console.log("\n✅ Setup verification complete!");
    console.log("\n📋 Next steps:");
    console.log("   1. If balance is 0, get test ETH from Base Sepolia faucet");
    console.log("   2. Deploy VoucherRedeemer contract: npm run deploy");
    console.log("   3. Test contract interaction\n");

  } catch (error: any) {
    console.error("\n❌ Setup verification failed!");

    if (error.code === "INVALID_ARGUMENT") {
      console.error("   Error: Invalid private key format in .env");
      console.error("   Make sure PRIVATE_KEY starts with 0x and is 64 hex characters");
    } else if (error.code === "NETWORK_ERROR") {
      console.error("   Error: Cannot connect to RPC");
      console.error("   Check BASE_SEPOLIA_RPC_URL in .env");
    } else {
      console.error(`   Error: ${error.message}`);
    }

    process.exit(1);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
