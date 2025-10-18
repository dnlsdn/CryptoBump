import hre from "hardhat";

async function main() {
  console.log("=== Debugging HRE in Hardhat 3 ===\n");

  console.log("hre.network.name:", hre.network.name);
  console.log("hre.network.config:", hre.network.config);
  console.log("\nhre keys:", Object.keys(hre));
  console.log("\nhre.config.networks:", hre.config.networks);
  console.log("\nhre.config.networks.baseSepolia:", hre.config.networks.baseSepolia);
}

main().catch(console.error);
