//
//  MappyLogger.swift
//  MapboxNavigation
//
//  Created by Jean-Baptiste Quesney on 15/06/2021.
//  Copyright © 2021 Mapbox. All rights reserved.
//

import Foundation
import os.log

fileprivate struct TextLog: TextOutputStream {

    /// Appends the given string to the stream.
    mutating func write(_ string: String) {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .allDomainsMask)
        let documentDirectoryPath = paths.first!
        let log = documentDirectoryPath.appendingPathComponent("log.txt")

        do {
            let handle = try FileHandle(forWritingTo: log)
            handle.seekToEndOfFile()
            handle.write(string.data(using: .utf8)!)
            handle.closeFile()
        } catch {
            print(error.localizedDescription)
            do {
                try string.data(using: .utf8)?.write(to: log)
            } catch {
                print(error.localizedDescription)
            }
        }
    }

}

public struct MappyLogger {

    private static var textLog = TextLog()
    private static var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter
    }()

    private static func log(_ message: String) {
        textLog.write("\(dateFormatter.string(from: Date())) \(message)\n")
    }

    public static func logNavServiceEvent(_ message: String) {
        let text = "[Service] \(message)"
        self.log(text)
    }

    public static func logDistanceEvent(_ message: String) {
        let text = "[Distance] \(message)"
        self.log(text)
    }

    public static func logUserInterfaceEvent(_ message: String) {
        let text = "[UI] \(message)"
        self.log(text)
    }

//    private static let subsystem = "com.mappy.test"

//    public static let serviceEvents: Logger = {
//		let logger = Logger(subsystem: subsystem, category: "service_events")
//        return logger
//    }()
//
//    public static let distanceRemaining: Logger = {
//        let logger = Logger(subsystem: subsystem, category: "distance_remaining")
//        return logger
//    }()
//
//    public static let userInterface: Logger = {
//        let logger = Logger(subsystem: subsystem, category: "user_interface")
//        return logger
//    }()

}
