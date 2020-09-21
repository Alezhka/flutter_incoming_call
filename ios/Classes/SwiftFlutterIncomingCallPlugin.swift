import Flutter
import UIKit
import CallKit
import AVFoundation
import NotificationCenter

public class SwiftFlutterIncomingCallPlugin: NSObject, FlutterPlugin, CXProviderDelegate {
    
    private static let EVENT_CALL_STARTED = "call_started"
    private static let EVENT_CALL_ACCEPT = "call_accept"
    private static let EVENT_CALL_DECLINE = "call_decline"
    private static let EVENT_CALL_MISSED = "call_missed"
    
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
            if let myArgs = args as? [String: Any] {
                config = Config(args: myArgs)
            }
            callKeepCallController = CXCallController()
            initCallKitProvider(config!)
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
                reportNewIncomingCall(callData: callData, fromPushKit: false)
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
    
    func reportNewIncomingCall(callData: CallData, fromPushKit: Bool) {
        print("reportNewIncomingCall")
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(callData.duration)) {
            self.callEndTimeout(callData)
        }
        
        let uuidString = callData.uuid.lowercased()
        callsData[uuidString] = callData
        
        let uuid = UUID(uuidString: callData.uuid)!
        let handleType = getHandleType(callData.handleType)
        
        let callUpdate = CXCallUpdate()
        callUpdate.remoteHandle = CXHandle(type: handleType, value: callData.handle)
        callUpdate.supportsDTMF = true
        callUpdate.supportsHolding = true
        callUpdate.supportsGrouping = true
        callUpdate.supportsUngrouping = true
        callUpdate.hasVideo = callData.hasVideo
        callUpdate.localizedCallerName = callData.name
        
        initCallKitProvider(config!)
        
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
        if(callsAttended[callData.uuid] == true) {
            endCallWithUUID(callData.uuid, 2)
            
            sendEvent(SwiftFlutterIncomingCallPlugin.EVENT_CALL_MISSED, callData)
        }
    }
    
    func initCallKitProvider(_ config: Config) {
        if (SwiftFlutterIncomingCallPlugin.sharedProvider == nil) {
            SwiftFlutterIncomingCallPlugin.sharedProvider = CXProvider(configuration: getProviderConfiguration(config))
        }
    }
    

    func getProviderConfiguration(_ config: Config) -> CXProviderConfiguration {
        let providerConfiguration = CXProviderConfiguration(localizedName: config.appName)
        providerConfiguration.supportsVideo = true
        providerConfiguration.maximumCallGroups = 2
        providerConfiguration.maximumCallsPerCallGroup = 1
    
        providerConfiguration.supportedHandleTypes = [
            CXHandle.HandleType.generic,
            CXHandle.HandleType.emailAddress,
            CXHandle.HandleType.phoneNumber
        ]
        
        if #available(iOS 11.0, *) {
            if (config.includesCallsInRecents) {
                providerConfiguration.includesCallsInRecents = config.includesCallsInRecents
            }
        }
        
        /*
        let image = UIImage(named: callData.avatar!)
        providerConfiguration.iconTemplateImageData = image!.pngData()
         
        providerConfiguration.ringtoneSound = callData.ringtonePath
        */
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
            try audioSession.setCategory(AVAudioSession.Category.playAndRecord, options: AVAudioSession.CategoryOptions.allowBluetooth)
            try audioSession.setMode(AVAudioSession.Mode.voiceChat)

            try audioSession.setPreferredSampleRate(44100.0)
            try audioSession.setPreferredIOBufferDuration(0.005)
            try audioSession.setActive(true)
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
    
    func sendEvent(_ event: String, _ callData: CallData) {
        let body = [
            "uuid": callData.uuid,
            "name": callData.name,
            "handle": callData.handle,
            "avatar": callData.avatar
        ]
        eventStreamHandler?.send(event, body as [String : Any])
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
            sendEvent(SwiftFlutterIncomingCallPlugin.EVENT_CALL_STARTED, callData)
        }
        action.fulfill()
    }

    public func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        configureAudioSession()
        let uuidString = action.callUUID.uuidString.lowercased()
        
        if let callData = callsData[uuidString] {
            sendEvent(SwiftFlutterIncomingCallPlugin.EVENT_CALL_ACCEPT, callData)
        }
        callsAttended[uuidString] = true
        
        action.fulfill()
    }

    public func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        let uuidString = action.callUUID.uuidString.lowercased()
        if(callsAttended[uuidString] == true) {
            if let callData = callsData[uuidString] {
                sendEvent(SwiftFlutterIncomingCallPlugin.EVENT_CALL_MISSED, callData)
            }
        }
    
        if let callData = callsData[uuidString] {
            sendEvent(SwiftFlutterIncomingCallPlugin.EVENT_CALL_DECLINE, callData)
        }
        
        callsAttended.removeValue(forKey: uuidString)
        callsData.removeValue(forKey: uuidString)
        
        action.fulfill()
    }

    public func provider(_ provider: CXProvider, perform action: CXSetHeldCallAction) {
        // [self sendEventWithName:RNVoipCallDidToggleHoldAction body:@{ @"hold": @(action.onHold), @"callUUID": [action.callUUID.UUIDString lowercaseString] }];
        action.fulfill()
    }

    public func provider(_ provider: CXProvider, perform action: CXSetMutedCallAction) {
        // [self sendEventWithName:RNVoipCallDidPerformSetMutedCallAction body:@{ @"muted": @(action.muted), @"callUUID": [action.callUUID.UUIDString lowercaseString] }];
        action.fulfill()
    }

    public func provider(_ provider: CXProvider, perform action: CXPlayDTMFCallAction) {
        // [self sendEventWithName:RNVoipCallPerformPlayDTMFCallAction body:@{ @"digits": action.digits, @"callUUID": [action.callUUID.UUIDString lowercaseString] }];
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
        // [self sendEventWithName:RNVoipCallDidActivateAudioSession body:nil];
    }

    public func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
        // [self sendEventWithName:RNVoipCallDidDeactivateAudioSession body:nil];
    }
    
}
