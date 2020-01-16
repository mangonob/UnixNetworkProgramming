//
//  TimeServer.swift
//  UnixNetworkProgramming
//
//  Created by G on 2020/1/16.
//  Copyright © 2020 mangonob. All rights reserved.
//

import Cocoa

extension Status {
    fileprivate static let failed = Status(rawValue: 1)
    fileprivate static let badAddress = Status(rawValue: 2)
    fileprivate static let bindError = Status(rawValue: 3)
    fileprivate static let listenError = Status(rawValue: 4)
    fileprivate static let acceptError = Status(rawValue: 5)
}

class TimeServer: Routine {
    static func routine() {
        // $ telnet time-a.nist.gov 13
        // Output: Trying 129.6.15.28...
        
        guard let line = readLine(),
            let address = SocketAddress(presentation: line, port: 13) else {
                error(msg: "bad address.", status: .badAddress)
        }
        
        let socket = Socket(domain: address.ipAddress.isV6 ? .inet6 : .inet)
        
        if !socket.bind(address) {
            error(msg: "bind error.", status: .bindError)
        }
        
        if !socket.listen() {
            error(msg: "listen error.", status: .listenError)
        }
        
        while true {
            guard let connection = socket.accept() else {
                error(msg: "accept error.", status: .acceptError)
            }
            
            var tick = time(nil)
            if let time = ctime(&tick) {
                connection.write(Data(bytes: time, count: strlen(time)))
            }
            connection.close()
        }
    }
}

