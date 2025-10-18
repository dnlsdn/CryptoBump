import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

/**
 * Hardhat Ignition module for deploying VoucherRedeemer
 *
 * Deploy with: npx hardhat ignition deploy ignition/modules/VoucherRedeemer.ts --network baseSepolia
 */
export default buildModule("VoucherRedeemer", (m) => {
  // Deploy VoucherRedeemer contract (no constructor parameters)
  const voucherRedeemer = m.contract("VoucherRedeemer");

  return { voucherRedeemer };
});
