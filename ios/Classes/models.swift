//
//  models.swift
//  flutter_incoming_call
//
//  Created by Алексей Стуров on 30.08.2020.
//

import Foundation

class Config {
    
    let appName: String
    let duration: Int
    let ringtonePath: String?
    let iconName: String?
    let includesCallsInRecents: Bool
    let supportsVideo: Bool
    let maximumCallGroups: Int
    let maximumCallsPerCallGroup: Int
    
    init(args: [String: Any?]) {
        self.appName = args["appName"] as? String ?? ""
        self.ringtonePath = args["ringtonePath"] as? String
        self.iconName = args["iconName"] as? String
        self.supportsVideo = args["supportsVideo"] as? Bool ?? false
        self.includesCallsInRecents = args["includesCallsInRecents"] as? Bool ?? false
        self.maximumCallGroups = args["maximumCallGroups"] as? Int ?? 2
        self.maximumCallsPerCallGroup = args["maximumCallsPerCallGroup"] as? Int ?? 1
        self.duration = args["duration"] as? Int ?? 30000
    }
    
    func toMap() -> [String : Any] {
        var map = [
            "appName": appName,
            "supportsVideo": supportsVideo,
            "includesCallsInRecents": includesCallsInRecents,
            "maximumCallsPerCallGroup": maximumCallsPerCallGroup
        ] as [String : Any]
        if(ringtonePath != nil) {
            map["ringtonePath"] = ringtonePath
        }
        if(iconName != nil) {
            map["iconName"] = iconName
        }
        return map
    }
}


class CallData {
    
    let uuid: String
    let handle: String
    let name: String
    let avatar: String?
    let handleType: String
    let hasVideo: Bool
    
    init(args: [String: Any]) {
        self.uuid = args["uuid"] as? String ?? ""
        self.handle = args["handle"] as? String ?? ""
        self.name = args["name"] as? String ?? ""
        self.avatar = args["avatar"] as? String ?? ""
        self.handleType = args["handleType"] as? String ?? ""
        self.hasVideo = args["hasVideo"] as? Bool ?? false
    }
    
    func toMap() -> [String : Any] {
        return [
            "uuid": uuid,
            "name": name,
            "handle": handle,
            "avatar": avatar ?? "",
            "handleType": handleType,
            "hasVideo": hasVideo
        ]
    }
}

class ToggleHoldData {
    let uuid: String
    let hold: Bool
    
    init(_ uuid: String, _ hold: Bool) {
        self.uuid = uuid
        self.hold = hold
    }
    
    func toMap() -> [String : Any] {
        return [
            "uuid": uuid,
            "hold": hold,
        ]
    }
}

class ToggleMutedData {
    let uuid: String
    let muted: Bool
    
    init(_ uuid: String, _ muted: Bool) {
        self.uuid = uuid
        self.muted = muted
    }
    
    func toMap() -> [String : Any] {
        return [
            "uuid": uuid,
            "muted": muted,
        ]
    }
}

class ToggleDmtfData {
    let uuid: String
    let digits: String
    
    init(_ uuid: String, _ digits: String) {
        self.uuid = uuid
        self.digits = digits
    }
    
    func toMap() -> [String : Any] {
        return [
            "uuid": uuid,
            "digits": digits,
        ]
    }
}

class ToggleAudiosessionData {

    let activate: Bool
    
    init(_ activate: Bool) {
        self.activate = activate
    }
    
    func toMap() -> [String : Any] {
        return [
            "activate": activate,
        ]
    }
}
