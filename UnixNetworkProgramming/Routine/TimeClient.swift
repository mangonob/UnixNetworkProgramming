//
//  TimeClient.swift
//  UnixNetworkProgramming
//
//  Created by G on 2020/1/16.
//  Copyright © 2020 mangonob. All rights reserved.
//

import Cocoa

extension Status {
    fileprivate static let failed = Status(rawValue: 1)
    fileprivate static let badAddress = Status(rawValue: 2)
    fileprivate static let connectionError = Status(rawValue: 3)
}

class TimeClient: Routine {
    static func routine() {
        // $ telnet time-a.nist.gov 13
        // Output: Trying 129.6.15.28...
        
        guard let line = readLine(),
            let address = SocketAddress(presentation: line, port: 13) else {
                error(msg: "bad address.", status: .badAddress)
        }
        
        let socket = Socket()
        
        guard let connection = socket.connect(address) else {
            error(msg: "connection error.", status: .connectionError)
        }
        
        let readed = connection.readDataToEndOfFile()
        if let content = String(data: readed, encoding: .utf8) {
            print(content)
        }
        connection.close()
    }
}

