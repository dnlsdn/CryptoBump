import Foundation
import MultipeerConnectivity
import Flutter

final class NearbyMultipeer: NSObject,
  MCSessionDelegate, MCNearbyServiceAdvertiserDelegate, MCNearbyServiceBrowserDelegate,
  FlutterStreamHandler {

  private let serviceType = "tapcapsule" // <= 15 char, lowercase
  private var peerID = MCPeerID(displayName: UIDevice.current.name)
  private var session: MCSession?
  private var advertiser: MCNearbyServiceAdvertiser?
  private var browser: MCNearbyServiceBrowser?

  private var eventSink: FlutterEventSink?

  // MARK: - Flutter wiring
  static func register(with messenger: FlutterBinaryMessenger) {
    let instance = NearbyMultipeer()
    let method = FlutterMethodChannel(name: "tapcapsule/nearby", binaryMessenger: messenger)
    let event = FlutterEventChannel(name: "tapcapsule/nearby/events", binaryMessenger: messenger)
    event.setStreamHandler(instance)

    method.setMethodCallHandler { call, result in
      switch call.method {
      case "start":
        guard let args = call.arguments as? [String: Any],
              let role = args["role"] as? String else { result(FlutterError(code: "bad_args", message: nil, details: nil)); return }
        instance.start(role: role)
        result(nil)
      case "stop":
        instance.stop()
        result(nil)
      case "sendJson":
        guard let args = call.arguments as? [String: Any],
              let json = args["json"] as? String else { result(FlutterError(code: "bad_args", message: nil, details: nil)); return }
        instance.send(json: json)
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    eventSink = events
    return nil
  }
  func onCancel(withArguments arguments: Any?) -> FlutterError? { eventSink = nil; return nil }

  // MARK: - Core
  private func start(role: String) {
    stop()

    peerID = MCPeerID(displayName: UIDevice.current.name)
    session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
    session?.delegate = self

    if role == "sender" {
      advertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: serviceType)
      advertiser?.delegate = self
      advertiser?.startAdvertisingPeer()
      emit(["type": "status", "value": "advertising"])
    } else {
      browser = MCNearbyServiceBrowser(peer: peerID, serviceType: serviceType)
      browser?.delegate = self
      browser?.startBrowsingForPeers()
      emit(["type": "status", "value": "browsing"])
    }
  }

  private func stop() {
    advertiser?.stopAdvertisingPeer()
    browser?.stopBrowsingForPeers()
    advertiser = nil; browser = nil

    session?.disconnect()
    session = nil
    emit(["type": "status", "value": "idle"])
  }

  private func send(json: String) {
    guard let s = session else { return }
    guard !s.connectedPeers.isEmpty else { return }
    let data = Data(json.utf8)
    do {
      try s.send(data, toPeers: s.connectedPeers, with: .reliable)
      emit(["type": "sent"])
    } catch {
      emit(["type": "error", "message": "send_failed"])
    }
  }

  private func emit(_ obj: [String: Any]) { eventSink?(obj) }

  // MARK: - Advertiser
  func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID,
                  withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
    invitationHandler(true, session)
  }

  // MARK: - Browser
  func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
    browser.invitePeer(peerID, to: session!, withContext: nil, timeout: 10)
  }
  func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {}

  // MARK: - Session
  func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
    switch state {
    case .connected: emit(["type": "connected", "peer": peerID.displayName])
    case .connecting: emit(["type": "status", "value": "connecting"])
    case .notConnected: emit(["type": "disconnected", "peer": peerID.displayName])
    @unknown default: break
    }
  }
  func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
    if let json = String(data: data, encoding: .utf8) {
      emit(["type": "payload", "json": json])
    }
  }

  // Unused delegates we must implement
  func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
  func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
  func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}
