//
//  models.swift
//  flutter_incoming_call
//
//  Created by Алексей Стуров on 30.08.2020.
//

import Foundation

class Config {
    
    let appName: String
    let includesCallsInRecents: Bool
    
    init(args: [String: Any]) {
        self.appName = args["appName"] as? String ?? ""
        self.includesCallsInRecents = args["includesCallsInRecents"] as? Bool ?? false
    }
}


class CallData {
    
    let uuid: String
    let handle: String
    let name: String
    let avatar: String?
    let handleType: String
    let hasVideo: Bool
    let vibration: Bool
    let ringtone: Bool
    let ringtonePath: String
    let duration: Int
    
    init(args: [String: Any]) {
        self.uuid = args["uuid"] as? String ?? ""
        self.handle = args["handle"] as? String ?? ""
        self.name = args["name"] as? String ?? ""
        self.avatar = args["avatar"] as? String ?? ""
        self.handleType = args["handleType"] as? String ?? ""
        self.hasVideo = args["hasVideo"] as? Bool ?? false
        self.vibration = args["vibration"] as? Bool ?? false
        self.ringtone = args["ringtone"] as? Bool ?? false
        self.ringtonePath = args["ringtonePath"] as? String ?? ""
        self.duration = args["duration"] as? Int ?? 30000
    }
}
