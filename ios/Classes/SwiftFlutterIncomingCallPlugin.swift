import Flutter
import UIKit
import CallKit
import AVFoundation
import NotificationCenter

public class SwiftFlutterIncomingCallPlugin: NSObject, FlutterPlugin, CXProviderDelegate {
    
    private static let SETTINGS_KEY = "FlutterIncomingCallSettings"
    
    private static let EVENT_CALL_STARTED = "call_started"
    private static let EVENT_CALL_ACCEPT = "call_accept"
    private static let EVENT_CALL_DECLINE = "call_decline"
    private static let EVENT_CALL_MISSED = "call_missed"
    private static let EVENT_TOGGLE_HOLD = "toggle_hold"
    private static let EVENT_TOGGLE_MUTE = "toggle_mute"
    private static let EVENT_TOGGLE_DMTF = "toggle_dmtf"
    private static let EVENT_TOGGLE_AUDIOSESSION = "toggle_audiosession"
    
    static var sharedProvider: CXProvider? = nil
    
    private var channel: FlutterMethodChannel? = nil
    private var eventChannel: FlutterEventChannel? = nil
    
    private var eventStreamHandler: EventStreamHandler? = nil
    
    private var config: Config? = nil
    private var osVersion: OperatingSystemVersion? = nil
    private var callKeepProvider: CXProvider? = nil
    
    private var callKeepCallController: CXCallController? = nil
    
    private var callsData: [String: CallData] = [:]
    private var callsAttended: [String: Bool] = [:]
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = SwiftFlutterIncomingCallPlugin()
        instance.channel = FlutterMethodChannel(name: "flutter_incoming_call", binaryMessenger: registrar.messenger())
        instance.eventChannel = FlutterEventChannel(name: "flutter_incoming_call_events", binaryMessenger: registrar.messenger())
        registrar.addMethodCallDelegate(instance, channel: instance.channel!)
        instance.eventStreamHandler = EventStreamHandler()
        instance.eventChannel?.setStreamHandler(instance.eventStreamHandler as? FlutterStreamHandler & NSObjectProtocol)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "configure":
            guard let args = call.arguments else {
                result(nil)
                return
            }
            if let myArgs = args as? [String: Any?] {
                config = Config(args: myArgs)
                saveConfig(config!)
            }
            callKeepCallController = CXCallController()
            initCallKitProvider()
            osVersion = ProcessInfo().operatingSystemVersion
            self.callKeepProvider = SwiftFlutterIncomingCallPlugin.sharedProvider!
            self.callKeepProvider?.setDelegate(self, queue: nil)
            
            result(nil)
            break
        case "displayIncomingCall":
            guard let args = call.arguments else {
                result(nil)
                return
            }
            if let myArgs = args as? [String: Any] {
                let callData = CallData(args: myArgs)
                reportNewIncomingCall(callData, fromPushKit: false)
            }
            result(nil)
            break
        case "endCall":
            guard let args = call.arguments else {
                result(nil)
                return
            }
            if let myArgs = args as? [String: Any] {
                let uuid = UUID(uuidString: myArgs["uuid"] as! String)!
                let endCallAction = CXEndCallAction(call: uuid)
                let transaction = CXTransaction(action: endCallAction)
                requestTransaction(transaction)
            }
            result(nil)
            break
        case "endAllCalls":
            guard let calls = callKeepCallController?.callObserver.calls else {
                result(nil)
                return
            }
            
            for call in calls {
                let endCallAction = CXEndCallAction(call: call.uuid)
                let transaction = CXTransaction(action: endCallAction)
                requestTransaction(transaction)
            }
            result(nil)
            break
            default:
                result(FlutterMethodNotImplemented)
        }
    }
    
    func reportNewIncomingCall(_ callData: CallData, fromPushKit: Bool) {
        print("reportNewIncomingCall")
        loadConfigIfNeed()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(config!.duration)) {
            self.callEndTimeout(callData)
        }
        
        let uuidString = callData.uuid.lowercased()
        callsData[uuidString] = callData
        
        let uuid = UUID(uuidString: callData.uuid)!
        var handle: CXHandle?
        if (callData.handleType != nil && callData.handle != nil) {
            handle = CXHandle(type: getHandleType(callData.handleType!), value: callData.handle!)
        }
        
        let callUpdate = CXCallUpdate()
        callUpdate.remoteHandle = handle
        callUpdate.supportsDTMF = callData.supportsDTMF
        callUpdate.supportsHolding = callData.supportsHolding
        callUpdate.supportsGrouping = callData.supportsGrouping
        callUpdate.supportsUngrouping = callData.supportsUngrouping
        callUpdate.hasVideo = callData.hasVideo
        callUpdate.localizedCallerName = callData.name
        
        initCallKitProvider()
        
        SwiftFlutterIncomingCallPlugin.sharedProvider?.reportNewIncomingCall(with: uuid, update: callUpdate) { error in
            if (error == nil) {
                // Workaround per https://forums.developer.apple.com/message/169511
                if (self.lessThanIos10_2()) {
                    self.configureAudioSession()
                }
            }
        }
    }
    
    func endCallWithUUID(_ uuidString: String, _ reason: Int) {
        let uuid = UUID(uuidString: uuidString)!
        switch (reason) {
            case 1:
                SwiftFlutterIncomingCallPlugin.sharedProvider?.reportCall(with: uuid, endedAt: Date(), reason: CXCallEndedReason.failed)
                break
            case 2, 6:
                SwiftFlutterIncomingCallPlugin.sharedProvider?.reportCall(with: uuid, endedAt: Date(), reason: CXCallEndedReason.remoteEnded)
                break;
            case 3:
                SwiftFlutterIncomingCallPlugin.sharedProvider?.reportCall(with: uuid, endedAt: Date(), reason: CXCallEndedReason.unanswered)
                break;
            case 4:
                SwiftFlutterIncomingCallPlugin.sharedProvider?.reportCall(with: uuid, endedAt: Date(), reason: CXCallEndedReason.answeredElsewhere)
                break;
            case 5:
                SwiftFlutterIncomingCallPlugin.sharedProvider?.reportCall(with: uuid, endedAt: Date(), reason: CXCallEndedReason.declinedElsewhere)
                break;
            default:
                break;
        }
    }
    
    func callEndTimeout(_ callData: CallData) {
        if(!(self.callsAttended[callData.uuid] ?? false)) {
            endCallWithUUID(callData.uuid, 2)
            
            sendEvent(SwiftFlutterIncomingCallPlugin.EVENT_CALL_MISSED, callData.toMap())
        }
    }
    
    func initCallKitProvider() {
        loadConfigIfNeed()
        
        if (SwiftFlutterIncomingCallPlugin.sharedProvider == nil) {
            SwiftFlutterIncomingCallPlugin.sharedProvider = CXProvider(configuration: getProviderConfiguration(config!))
        }
    }
    
    func loadConfigIfNeed() {
        if(config == nil) {
            let settings = UserDefaults.standard.object(forKey: SwiftFlutterIncomingCallPlugin.SETTINGS_KEY) as? [String : Any?] ?? [:]
            config = Config(args: settings)
        }
    }
    
    func saveConfig(_ config: Config) {
        UserDefaults.standard.set(config.toMap(), forKey: SwiftFlutterIncomingCallPlugin.SETTINGS_KEY)
        UserDefaults.standard.synchronize()
    }

    func getProviderConfiguration(_ config: Config) -> CXProviderConfiguration {
        let providerConfiguration = CXProviderConfiguration(localizedName: config.appName)
        
        providerConfiguration.supportsVideo = config.supportsVideo
        providerConfiguration.maximumCallGroups = config.maximumCallGroups
        providerConfiguration.maximumCallsPerCallGroup = config.maximumCallsPerCallGroup
    
        providerConfiguration.supportedHandleTypes = [
            CXHandle.HandleType.generic,
            CXHandle.HandleType.emailAddress,
            CXHandle.HandleType.phoneNumber
        ]
        
        if #available(iOS 11.0, *) {
            providerConfiguration.includesCallsInRecents = config.includesCallsInRecents
        }
        
        if(config.iconName != nil) {
            if let image = UIImage(named: config.iconName!) {
                providerConfiguration.iconTemplateImageData = image.pngData()
            } else {
                print("Unable to load flutter_incoming_call icon \(config.iconName!).");
            }
        }
        if(config.ringtonePath != nil) {
            providerConfiguration.ringtoneSound = config.ringtonePath!
        }
        return providerConfiguration
    }
    
    func getHandleType(_ handleType: String) -> CXHandle.HandleType {
        var type = CXHandle.HandleType.generic
        switch(handleType) {
            case "generic":
                type = CXHandle.HandleType.generic
                break
            case "number":
                type = CXHandle.HandleType.phoneNumber;
                break
            case "email":
                type = CXHandle.HandleType.emailAddress;
                break
        default:
            type = CXHandle.HandleType.generic;
        }
        return type
    }
    

    func lessThanIos10_2() -> Bool {
        if(osVersion == nil) {
            return true
        } else if (osVersion!.majorVersion < 10) {
            return true
        } else if (osVersion!.majorVersion > 10) {
            return false
        } else {
            return osVersion!.minorVersion < 2
        }
    }
    
    func configureAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            if (config?.avSessionSetCategory ?? true) { try audioSession.setCategory(AVAudioSession.Category.playAndRecord, options: AVAudioSession.CategoryOptions.allowBluetooth) }
            if (config?.avSessionSetMode ?? true) { try audioSession.setMode(AVAudioSession.Mode.voiceChat) }
            if (config?.avSessionSetPreferredSampleRate ?? true) { try audioSession.setPreferredSampleRate(44100.0) }
            if (config?.avSessionSetPreferredIOBufferDuration ?? true) { try audioSession.setPreferredIOBufferDuration(0.005) }
            if (config?.avSessionSetActive ?? true) { try audioSession.setActive(true) }
        } catch {
            print("Error messing with audio session: \(error)")
        }
    }
    

    func requestTransaction(_ transaction: CXTransaction) {
        if (callKeepCallController == nil) {
            callKeepCallController = CXCallController()
        }
        callKeepCallController?.request(transaction) { error in
            if (error != nil) {
                print("Error requesting transaction (%@): (%@)", transaction.actions, error!)
                return
            }
            
            if let startCallAction = transaction.actions.first as? CXStartCallAction {
                let callUpdate = CXCallUpdate()
                callUpdate.remoteHandle = startCallAction.handle;
                callUpdate.hasVideo = startCallAction.isVideo;
                callUpdate.localizedCallerName = startCallAction.contactIdentifier;
                callUpdate.supportsDTMF = true
                callUpdate.supportsHolding = true
                callUpdate.supportsGrouping = true
                callUpdate.supportsUngrouping = true
                self.callKeepProvider?.reportCall(with: startCallAction.callUUID, updated: callUpdate)
            }
        }
    }
    
    func sendEvent(_ event: String, _ body: [String : Any]) {
        eventStreamHandler?.send(event, body)
    }
    
    // MARK: CXProviderDelegate
    
    public func providerDidReset(_ provider: CXProvider) {
        //this means something big changed, so tell the JS. The JS should
        //probably respond by hanging up all calls.
        // [self sendEventWithName:RNVoipCallProviderReset body:nil];
    }
    
    public func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        configureAudioSession()
        
        let uuidString = action.callUUID.uuidString.lowercased()
        if let callData = callsData[uuidString] {
            sendEvent(SwiftFlutterIncomingCallPlugin.EVENT_CALL_STARTED, callData.toMap())
        }
        action.fulfill()
    }

    public func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        configureAudioSession()
        let uuidString = action.callUUID.uuidString.lowercased()
        
        if let callData = callsData[uuidString] {
            sendEvent(SwiftFlutterIncomingCallPlugin.EVENT_CALL_ACCEPT, callData.toMap())
        }
        callsAttended[uuidString] = true
        
        action.fulfill()
    }

    public func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        let uuidString = action.callUUID.uuidString.lowercased()
        if(callsAttended[uuidString] == true) {
            if let callData = callsData[uuidString] {
                sendEvent(SwiftFlutterIncomingCallPlugin.EVENT_CALL_MISSED, callData.toMap())
            }
        }
    
        if let callData = callsData[uuidString] {
            sendEvent(SwiftFlutterIncomingCallPlugin.EVENT_CALL_DECLINE, callData.toMap())
        }
        
        callsAttended.removeValue(forKey: uuidString)
        callsData.removeValue(forKey: uuidString)
        
        action.fulfill()
    }

    public func provider(_ provider: CXProvider, perform action: CXSetHeldCallAction) {
        let uuidString = action.callUUID.uuidString.lowercased()
        let holdData = ToggleHoldData(uuidString, action.isOnHold)
        sendEvent(SwiftFlutterIncomingCallPlugin.EVENT_TOGGLE_HOLD, holdData.toMap())
        
        action.fulfill()
    }

    public func provider(_ provider: CXProvider, perform action: CXSetMutedCallAction) {
        let uuidString = action.callUUID.uuidString.lowercased()
        let mutedData = ToggleMutedData(uuidString, action.isMuted)
        sendEvent(SwiftFlutterIncomingCallPlugin.EVENT_TOGGLE_MUTE, mutedData.toMap())
        
        action.fulfill()
    }

    public func provider(_ provider: CXProvider, perform action: CXPlayDTMFCallAction) {
        let uuidString = action.callUUID.uuidString.lowercased()
        let dmtfData = ToggleDmtfData(uuidString, action.digits)
        sendEvent(SwiftFlutterIncomingCallPlugin.EVENT_TOGGLE_DMTF, dmtfData.toMap())
        
        action.fulfill()
    }
    
    public func provider(_ provider: CXProvider, timedOutPerforming action: CXAction) {
        
    }
    
    public func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        let userInfo = [
            AVAudioSessionInterruptionTypeKey: AVAudioSession.InterruptionType.ended,
            AVAudioSessionInterruptionOptionKey: AVAudioSession.InterruptionOptions.shouldResume
        ] as [String : Any]
        NotificationCenter.default.post(
            name: NSNotification.Name(rawValue: AVAudioSessionInterruptionTypeKey),
            object: nil,
            userInfo: userInfo)
        configureAudioSession()
        
        let audiosessionData = ToggleAudiosessionData(true)
        sendEvent(SwiftFlutterIncomingCallPlugin.EVENT_TOGGLE_AUDIOSESSION, audiosessionData.toMap())
    }

    public func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
        let audiosessionData = ToggleAudiosessionData(false)
        sendEvent(SwiftFlutterIncomingCallPlugin.EVENT_TOGGLE_AUDIOSESSION, audiosessionData.toMap())
    }
    
}
