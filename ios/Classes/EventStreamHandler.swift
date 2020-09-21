//
//  EventStreamHandler.swift
//  flutter_incoming_call
//
//  Created by Aleksei Sturov on 31.08.2020.
//

class EventStreamHandler: FlutterStreamHandler {
    
    private var eventSink: FlutterEventSink?
    
    public func send(_ event: String, _ body: [String: Any]) {
        let data: [String : Any] = [
            "event": event,
            "body": body
        ]
        eventSink?(data)
    }
    
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }
    
}
