//
//  IPAddress.swift
//  UnixNetworkProgramming
//
//  Created by G on 2020/1/16.
//  Copyright © 2020 mangonob. All rights reserved.
//

import Cocoa

struct IPAddress: CustomStringConvertible {
    var data: Data
    var isV6: Bool
    
    static let any = IPAddress(presentation: "0.0.0.0")!
    static let localhost = IPAddress(presentation: "127.0.0.1")!

    init?(presentation: String) {
        isV6 = presentation.contains(":")
        
        guard var ip = presentation.cString(using: .utf8) else {
            fatalError("bad ip address presentation.")
        }
        
        var buffer = [UInt8].init(repeating: 0, count: isV6 ? 16 : 4)

        if inet_pton(isV6 ? AF_INET6 : AF_INET, &ip, &buffer) <= 0 {
            return nil
        }
        
        data = Data(buffer)
    }
    
    var description: String {
        return "\(data.map {$0})@\(isV6 ? "V6" : "V4")"
    }
}
