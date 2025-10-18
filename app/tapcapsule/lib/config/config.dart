/// Segnaposto per i riferimenti on-chain dell'app.
/// Non leggere questi valori in codice (ancora). Servono solo per stabilire dove andranno messi.
///
/// RPC_URL: endpoint del nodo (es. Base Sepolia su Alchemy/Infura).
/// CONTRACT_ADDRESS: indirizzo del contratto VoucherRedeemer su Base Sepolia.
/// CONTRACT_ABI: ABI JSON del contratto (stringa oppure percorso file).
class AppConfig {
  // Esempio: "https://base-sepolia.g.alchemy.com/v2/<API_KEY>"
  static const String RPC_URL = 'https://base-sepolia.g.alchemy.com/v2/nprInoeFE5Wcp2pV7_PUu';

  // Esempio: "0x1234...abcd" (quando Persona B fa il deploy)
  static const String CONTRACT_ADDRESS = '<PUT_CONTRACT_ADDRESS_HERE>';

  // Opzione A (semplice): ABI come stringa grezza (inserire più avanti).
  static const String CONTRACT_ABI = '<PUT_ABI_JSON_HERE>';

  // Opzione B (pulita): se preferisci, salveremo l’ABI in un file
  // "contracts/abi/VoucherRedeemer.json" e lo caricheremo in runtime.
  // Per ora basta questo segnaposto.
}
