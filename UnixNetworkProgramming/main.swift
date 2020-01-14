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

let address = SocketAddress(family: .inet, port: 13, value: readLine())
do {
    let socket = try Socket()
    let connection = try socket.connect(address)
    if let readed = connection.read() {
        print(readed)
    }
} catch let catchedError {
    error(msg: catchedError.localizedDescription, status: .failed)
}
