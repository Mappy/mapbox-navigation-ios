import Foundation

public class MappyEventLogger: NSObject
{
    static func sendMessage(_ message: String)
    {
        NotificationCenter.default.post(name: .mappyEventLoggerDidSendMessage, object: self, userInfo: [
            MappyEventLogger.NotificationUserInfoKey.message: message
        ])
    }
}
