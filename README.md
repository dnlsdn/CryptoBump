# TapCapsule

**Tap-to-redeem crypto vouchers with iPhone-to-iPhone proximity.**  
Create a voucher (e.g., 0.001 test ETH), “bump” phones to share a **secret** offline, and the recipient redeems **on Base Sepolia**. Redeem can be made **gasless** later via a Paymaster.

---

## TL;DR

- **Chain:** Base Sepolia (testnet)  
- **Voucher model:** lock funds under `keccak256(secret)`; redeem with `secret`  
- **App:** Flutter (iOS), proximity via Multipeer Connectivity (optional Nearby Interaction haptics)  
- **Identity UX (later):** ENS name/avatar  
- **Optional add-ons:** iExec Web3Mail receipt; 1inch swap; Moonbeam (Polkadot EVM) redeploy

---

## Repository Layout

TapCapsule/  
├─ README.md ← you are here  
├─ contracts/ ← smart-contract notes & (soon) code  
│  ├─ CONTRACT-NOTES.md  
│  ├─ NETWORK.md  
│  └─ abi/  
├─ app/  
│  └─ tapcapsule/ ← Flutter app (iOS first)  
├─ config/  
│  └─ config.tapcapsule.json  
└─ docs/

---

## Phase 1 Outcome (what’s already set up)

- A test wallet (MetaMask) with Base Sepolia in the network list  
- Test ETH on **Base Sepolia**  
- **RPC provider** project (Alchemy) and a local `.env` with:

    BASE_SEPOLIA_RPC_URL="https://base-sepolia.g.alchemy.com/v2/<API_KEY>"
    PRIVATE_KEY="0x<64-hex-characters>"

  `.env` is **ignored** by Git; do not commit secrets.

- Contract planning notes in `contracts/CONTRACT-NOTES.md`  
- Network notes in `contracts/NETWORK.md`  
- This README with everything the client app needs to integrate

---

## Addresses & Config (test)

- **Network:** Base Sepolia (testnet) — **chainId 84532**  
- **Explorer:** https://sepolia.basescan.org/  
- **Test Account (Dev/B):** `0xe83e93283bED5fC7fA5CaBF9cE444f0bF4503845`

### Environment (local only — do not commit)

Create `TapCapsule/.env`:

    BASE_SEPOLIA_RPC_URL="https://base-sepolia.g.alchemy.com/v2/<API_KEY>"
    PRIVATE_KEY="0x<your-private-key-64-hex>"

Optional template (`.env.example`):

    BASE_SEPOLIA_RPC_URL=<paste your Base Sepolia RPC URL here>
    PRIVATE_KEY=<0x...your private key...>

### Quick Checks

Verify RPC hits Base Sepolia:

    source .env
    curl -s -X POST -H "Content-Type: application/json" \
      --data '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}' \
      "$BASE_SEPOLIA_RPC_URL"
    # expected: {"result":"0x14a34"}  → 0x14a34 = 84532

Verify PRIVATE_KEY matches your address (Node.js + ethers v6):

    mkdir -p /tmp/pkcheck && cd /tmp/pkcheck
    npm init -y >/dev/null
    npm i ethers@6 dotenv >/dev/null
    DOTENV_CONFIG_PATH="/path/to/TapCapsule/.env" \
    node --input-type=module -e 'import "dotenv/config"; import { Wallet } from "ethers"; const pk=process.env.PRIVATE_KEY; if(!/^0x[0-9a-fA-F]{64}$/.test(pk)) throw new Error("Bad PRIVATE_KEY"); console.log(new Wallet(pk).address)'

---

## Smart Contract Plan (MVP)

**Contract name:** `VoucherRedeemer`  
**Goal:** Lock funds tied to the hash of a secret (`h = keccak256(secret)`). Whoever knows the `secret` can redeem to `msg.sender`. If unused past expiry, creator can refund.

### Interface (draft)

- `createVoucher(bytes32 h, address token, uint256 amount, uint64 expiry)`  
  - `token = address(0)` → native ETH; otherwise ERC-20
- `redeem(bytes secret)`  
  - pays to `msg.sender` if `keccak256(secret) == h` and not expired/redeemed
- `refund(bytes32 h)`  
  - after expiry, creator can recover if not redeemed

### Events

    event VoucherCreated(bytes32 indexed h, address indexed creator, address token, uint256 amount, uint64 expiry);
    event VoucherRedeemed(bytes32 indexed h, address indexed redeemer);
    event VoucherRefunded(bytes32 indexed h);

### Storage (draft)

    struct Voucher { address creator; address token; uint256 amount; uint64 expiry; bool redeemed; }
    mapping(bytes32 => Voucher) public vouchers;

### Validations

- `amount > 0`  
- `expiry > block.timestamp`  
- `vouchers[h]` must not exist (unique secret hash)  
- `redeem`: `!redeemed`, `block.timestamp <= expiry`, hash matches  
- `refund`: only creator, `!redeemed`, `block.timestamp > expiry`

### Security

- Use OpenZeppelin `ReentrancyGuard`, `SafeERC20`  
- Send ETH via `call{value: ...}` and check return  
- Mark `redeemed` before external transfers

---

## MVP Parameters (Decided — 2025-10-18)

- **Asset:** test **ETH** on Base Sepolia (`token = address(0)`)  
- **Default amount:** `0.001 ETH` (editable in UI) → `1_000_000_000_000_000` wei  
- **Expiry:** `24h` (`86400` seconds from `block.timestamp` at creation)  
- **Secret & Hash:** app generates 32 random bytes off-chain; `h = keccak256(secret)`  
- **Gasless (roadmap):** make **`redeem` gasless** with a Paymaster; `createVoucher` can remain non-gasless for demo

---

## App Integration Notes (Flutter client)

**Create screen**
1. Generate `secret` (32 random bytes)  
2. Compute `h = keccak256(secret)`  
3. Call `createVoucher(h, address(0), amountWei, block.timestamp + 86400)`

**Bump to send**  
- Use Multipeer Connectivity (Swift bridge) to transmit `secret` device-to-device  
- Optional: Nearby Interaction for close-range haptics

**Redeem screen**  
- Receive `secret`  
- Display ENS (creator name + avatar) once ENS is integrated  
- Call `redeem(secret)` on Base Sepolia (later: via Paymaster → gasless UX)

**History / Receipt**  
- Listen to contract events for local history  
- Optional: iExec Web3Mail to send a private receipt (“You redeemed X, tx: …”) without exposing email publicly

---

## Development (high level)

### Prerequisites

- Node.js LTS (for contracts tooling)  
- Flutter SDK (for the app under `app/tapcapsule`)  
- A wallet with Base Sepolia added + test ETH (faucet)

### Flutter (iOS)

    cd app/tapcapsule
    flutter pub get
    flutter run

*(iOS: open Xcode once if needed to set signing; this app uses a burner key internally for demo.)*

---

## Roadmap (24h hackathon plan, condensed)

1. **Phase 1 — Setup & Skeletons**: Wallet, Base Sepolia, faucet, RPC, `/contracts` notes ✅  
2. **Phase 2 — Proximity iPhone↔iPhone**: Swift bridge (Multipeer), bump UX, optional NI haptics  
3. **Phase 3 — Contract + Gasless + ENS**: Implement `VoucherRedeemer`, deploy to Base Sepolia, Paymaster for gasless redeem, ENS resolve  
4. **Phase 4 — Polish & Test**: clear states; BaseScan links; 60–90s demo video  
5. **Phase 5 — Extras**: iExec Web3Mail; optional 1inch; optional Moonbeam redeploy & network toggle

---

## Security & Ops

- Never commit secrets (`.env`, private keys, API keys).  
- Burner accounts only for demos. Rotate keys if exposed.  
- Validate all contract assumptions with tests before mainnet plans.

