//
//  Utilities.swift
//  UnixNetworkProgramming
//
//  Created by G on 2020/1/14.
//  Copyright © 2020 mangonob. All rights reserved.
//

import Foundation

struct Status: RawRepresentable {
    typealias RawValue = Int32
    var rawValue: Int32
    
    static let success = Status(rawValue: 0)
}

struct CLIError: LocalizedError {
    var reason: String?

    var errorDescription: String? {
        return reason ?? "\(CLIError.self): <noreason>"
    }
}

/**
 Write error message, and exit routine if needed.
 - Parameter msg: Error message.
 - Parameter status: Exit code with call exit(status).
 */
func error(msg: String, status: Status = .success) -> Never {
    perror(msg)
    exit(status)
}

/**
 Exit with status.
 - Parameter status: exit status.
 */
func exit(_ status: Status) -> Never {
    exit(status.rawValue)
}
