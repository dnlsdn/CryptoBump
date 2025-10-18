# VoucherRedeemer — Project Notes

## Scopo
Contratto che blocca fondi associati all'hash di un segreto. Chi conosce il **secret** può incassare on-chain; il creatore può rimborsarsi dopo la scadenza.

## Interfaccia (MVP)
### Funzioni
- `createVoucher(bytes32 h, address token, uint256 amount, uint64 expiry)`
  - Blocca fondi. `token = address(0)` indica ETH nativo; altrimenti ERC-20.
- `redeem(bytes memory secret)`
  - Incassa a `msg.sender` se `keccak256(secret) == h` e il buono è valido.
- `refund(bytes32 h)`
  - Dopo `expiry`, il **creatore** può rientrare in possesso dei fondi se non già riscattato.

### Eventi
- `event VoucherCreated(bytes32 indexed h, address indexed creator, address token, uint256 amount, uint64 expiry);`
- `event VoucherRedeemed(bytes32 indexed h, address indexed redeemer);`
- `event VoucherRefunded(bytes32 indexed h);`

### Stato (bozza)
- `struct Voucher { address creator; address token; uint256 amount; uint64 expiry; bool redeemed; }`
- `mapping(bytes32 => Voucher) public vouchers;`

### Validazioni
- `createVoucher`: `amount > 0`, `expiry > block.timestamp`, `vouchers[h]` non esistente.
- `redeem`: `!redeemed`, `block.timestamp <= expiry`, hash match.
- `refund`: solo `creator`, `!redeemed`, `block.timestamp > expiry`.

### Sicurezza (da applicare nel codice)
- `ReentrancyGuard` + `SafeERC20` (OpenZeppelin).
- Invio ETH con `call{value: ...}` e controllo esito.
- Prevenire ri-uso del segreto (marcare `redeemed`).

## Parametri MVP (da confermare nello STEP 6)
- **Asset**: ETH di prova (Base Sepolia). `token = address(0)`.
- **Scadenza demo**: 24 ore (86400 secondi).
- **Hash**: `h = keccak256(secret)`.  
  Il `secret` sarà generato dall’app (16–32 byte casuali) e passato off-chain via prossimità.

## “Coordinate” per Persona A (UI/app)
- **Create**: genera `secret`, calcola `h`, chiama `createVoucher(h, address(0), amountWei, now+86400)`.
- **Bump/Send**: passa **secret** al destinatario (Multipeer).
- **Redeem**: il destinatario chiama `redeem(secret)`. (Gasless verrà aggiunto dopo con Paymaster).
- **Stati**: valido / usato / scaduto / rimborsato (via `vouchers[h]` e/o eventi).

> NOTA: qui sono solo specifiche. L’implementazione Solidity arriverà nello STEP successivo.
