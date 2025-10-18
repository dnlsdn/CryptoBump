import type { HardhatUserConfig } from "hardhat/config";

import "@nomicfoundation/hardhat-toolbox-mocha-ethers";
import hardhatIgnitionEthers from "@nomicfoundation/hardhat-ignition-ethers";
import * as dotenv from "dotenv";

// Load .env file
dotenv.config();

const config: HardhatUserConfig = {
  plugins: [hardhatIgnitionEthers],
  solidity: {
    profiles: {
      default: {
        version: "0.8.28",
      },
      production: {
        version: "0.8.28",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
    },
  },
  networks: {
    hardhatMainnet: {
      type: "edr-simulated",
      chainType: "l1",
    },
    hardhatOp: {
      type: "edr-simulated",
      chainType: "op",
    },
    // Base Sepolia Testnet (chainId: 84532)
    // Used for TapCapsule demo deployment
    baseSepolia: {
      type: "http",
      chainType: "op",
      url: process.env.BASE_SEPOLIA_RPC_URL || "",
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
      chainId: 84532,
    },
  },
};

export default config;
