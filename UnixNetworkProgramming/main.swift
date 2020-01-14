//
//  main.swift
//  UnixNetworkProgramming
//
//  Created by G on 2020/1/14.
//  Copyright © 2020 mangonob. All rights reserved.
//

import Foundation

extension Status {
    static let failed = Status(rawValue: 1)
}

// $ telnet time-a.nist.gov 13
// Output: Trying 129.6.15.28...

let address = SocketAddress(family: .inet, port: 13, value: "0.0.0.0")
do {
    let socket = try Socket()
    try socket.bind(address)
    try socket.listen()
    
    while true {
        let connection = try socket.accept()
        var tick = time(nil)
        if let time = ctime(&tick) {
            try connection.write(Data(bytes: time, count: strlen(time)))
        }
        try connection.close()
    }
} catch let catchedError {
    error(msg: catchedError.localizedDescription, status: .failed)
}
