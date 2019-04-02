import Foundation

extension Notification.Name {
    public static let mappyEventLoggerDidSendMessage = MBMappyEventLoggerDidSendMessage
}

class MappyEventLogger: NSObject
{
    static func sendMessage(_ message: String)
    {
        NotificationCenter.default.post(name: .mappyEventLoggerDidSendMessage, object: self, userInfo: [
            MBMappyEventLoggerNotificationUserInfoKey.messageKey: message
        ])
    }
}
