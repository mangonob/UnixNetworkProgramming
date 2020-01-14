//
//  Socket.swift
//  UnixNetworkProgramming
//
//  Created by G on 2020/1/14.
//  Copyright © 2020 mangonob. All rights reserved.
//

import Foundation

struct SocketDomain: RawRepresentable, Equatable {
    typealias RawValue = Int32
    var rawValue: Int32
    
    static let local = SocketDomain(rawValue: PF_LOCAL)
    static let unix = SocketDomain(rawValue: PF_UNIX)
    static let inet = SocketDomain(rawValue: PF_INET)
    static let route = SocketDomain(rawValue: PF_ROUTE)
    static let key = SocketDomain(rawValue: PF_KEY)
    static let inet6 = SocketDomain(rawValue: PF_INET6)
    static let system = SocketDomain(rawValue: PF_SYSTEM)
    static let ndrv = SocketDomain(rawValue: PF_NDRV)
}

struct SocketType: RawRepresentable, Equatable {
    typealias RawValue = Int32
    var rawValue: Int32
    
    static let stream = SocketType(rawValue: SOCK_STREAM)
    static let dgram = SocketType(rawValue: SOCK_DGRAM)
    static let raw = SocketType(rawValue: SOCK_RAW)
}

struct FileDescriptor: RawRepresentable {
    typealias RawValue = Int32
    var rawValue: Int32
    
    func write(message: String) throws {
        var message = message
        if Darwin.write(rawValue, &message, message.lengthOfBytes(using: .utf8)) < 0 {
            throw CLIError(reason: "write error.")
        }
    }
    
    func read(maxLength: Int) -> String? {
        var buffer = [UInt8](repeating: 0, count: maxLength)
        let readed = Darwin.read(rawValue, &buffer, maxLength)
        if readed > 0 {
            return String(bytes: buffer[0..<readed], encoding: .utf8)
        } else {
            return nil
        }
    }
    
    func close() throws {
        if Darwin.close(rawValue) < 0 {
            throw CLIError(reason: "close error.")
        }
    }
}

enum SocketAddressFamily {
    case inet
    case inet6
    
    var domain: SocketDomain {
        switch self {
        case .inet:
            return .inet
        case .inet6:
            return .inet6
        }
    }
}

struct SocketAddress {
    var family: SocketAddressFamily
    var port: UInt16?
    var value: String?
    
    fileprivate func address_in() throws -> Any {
        switch self.family {
        case .inet:
            var address_in = sockaddr_in()
            address_in.sin_family = sa_family_t(AF_INET)
            
            if let port = self.port {
                address_in.sin_port = in_port_t(port.bigEndian)
            }
            
            if var value = self.value?.cString(using: .utf8) {
                inet_pton(AF_INET, &value, &address_in.sin_addr)
            }
            
            return address_in
        case .inet6:
            var address_in = sockaddr_in6()
            address_in.sin6_family = sa_family_t(AF_INET6)
            
            if let port = self.port {
                address_in.sin6_port = in_port_t(port.bigEndian)
            }
            
            if var value = self.value?.cString(using: .utf8) {
                inet_pton(AF_INET6, &value, &address_in.sin6_addr)
            }
            
            return address_in
        }
    }
}

struct Connection {
    var address: SocketAddress?
    fileprivate var fileDescriptor: FileDescriptor?
    
    init(address: SocketAddress? = nil) {
        self.address = address
    }
    
    func close() throws {
        try fileDescriptor?.close()
    }
    
    func read(maxLength: Int = 4 * 1024) -> String? {
        return fileDescriptor?.read(maxLength: maxLength)
    }
    
    func write(message: String) throws {
        try fileDescriptor?.write(message: message)
    }
}

struct Socket: CustomStringConvertible {
    private let socketFileDescriptor: FileDescriptor
    
    var description: String {
        return "\(Socket.self): fd_\(socketFileDescriptor.rawValue)"
    }
    
    init(domain: SocketDomain = .inet, type: SocketType = .stream) throws {
        self.socketFileDescriptor = FileDescriptor(rawValue: socket(domain.rawValue, type.rawValue, 0))
        if socketFileDescriptor.rawValue < 0 {
            throw CLIError(reason: "socket error.")
        }
    }
    
    func connect(_ address: SocketAddress) throws -> Connection {
        var address_in = try address.address_in()
        if Darwin.connect(
            socketFileDescriptor.rawValue,
            UnsafePointer(&address_in).withMemoryRebound(to: sockaddr.self, capacity: 1) { $0 },
            socklen_t(MemoryLayout<sockaddr>.size)
            ) < 0 {
            throw CLIError(reason: "connection error.")
        }
        
        var connection = Connection()
        connection.fileDescriptor = socketFileDescriptor
        return connection
    }
    
    func bind(_ address: SocketAddress) throws {
        var address_in = try address.address_in()
        if Darwin.bind(
            socketFileDescriptor.rawValue,
            UnsafePointer(&address_in).withMemoryRebound(to: sockaddr.self, capacity: 1) { $0 },
            socklen_t(MemoryLayout<sockaddr>.size)
            ) < 0 {
            throw CLIError(reason: "bind error.")
        }
    }
    
    func listen(queueLength: Int32 = 2) throws {
        if Darwin.listen(socketFileDescriptor.rawValue, queueLength) < 0 {
            throw CLIError(reason: "listen error.")
        }
    }
    
    func accept() throws -> Connection {
        var address = sockaddr()
        var size = socklen_t(MemoryLayout<sockaddr>.size)
        let connectedFileDescriptor = FileDescriptor(rawValue: Darwin.accept(socketFileDescriptor.rawValue, &address, &size))
        if connectedFileDescriptor.rawValue < 0 {
            throw CLIError(reason: "accept error.")
        }
        
        var connection = Connection()
        connection.fileDescriptor = connectedFileDescriptor
        return connection
    }
    
    func close() throws {
        try socketFileDescriptor.close()
    }
}

