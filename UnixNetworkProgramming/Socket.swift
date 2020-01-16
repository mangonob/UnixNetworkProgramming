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
    var port: UInt16 = 42
    var ipAddress: IPAddress
    
    init?(presentation: String, port: UInt16) {
        self.port = port
        if let ipAddress = IPAddress(presentation: presentation) {
            self.ipAddress = ipAddress
        } else {
            return nil
        }
    }

    fileprivate func sockAddress() -> sockaddr {
        var addr = sockaddr_in()
        addr.sin_family = sa_family_t(ipAddress.isV6 ? AF_INET6 : AF_INET)
        addr.sin_port = port.bigEndian
        ipAddress.data.copyBytes(
            to: UnsafeMutablePointer<UInt8>(OpaquePointer(UnsafePointer(&addr.sin_addr))),
            count: ipAddress.data.count
        )
        addr.sin_port = port.bigEndian
        return UnsafePointer(&addr).withMemoryRebound(to: sockaddr.self, capacity: 1) { $0.pointee }
    }
}

struct Connection {
    fileprivate var fileHandle: FileHandle
    
    init(fileHandle: FileHandle) {
        self.fileHandle = fileHandle
    }

    func readDataToEndOfFile() -> Data {
        return fileHandle.readDataToEndOfFile()
    }
    
    func readData(ofLength length: Int) -> Data {
        return fileHandle.readData(ofLength: length)
    }
    
    func write(_ data: Data) {
        fileHandle.write(data)
    }

    func close() {
        fileHandle.closeFile()
    }
}

struct Socket: CustomStringConvertible {
    private let socket: FileHandle
    
    var description: String {
        return "\(Socket.self): fd_\(socket.fileDescriptor)"
    }
    
    init(domain: SocketDomain = .inet, type: SocketType = .stream) {
        let fd = Darwin.socket(domain.rawValue, type.rawValue, 0)
        if fd < 0 {
            self.socket = FileHandle.nullDevice
        } else {
            self.socket = FileHandle(fileDescriptor: fd)
        }
    }
    
    func connect(_ address: SocketAddress) -> Connection? {
        var sockAddress = address.sockAddress()
        if Darwin.connect(
            socket.fileDescriptor,
            &sockAddress,
            socklen_t(MemoryLayout<sockaddr>.size)
            ) < 0 {
            return nil
        }
        
        return Connection(fileHandle: socket)
    }
    
    /**
     Bind socket to address.
     - Parameter address: Address to bind.
     - Returns: Is bind successed.
     */
    @discardableResult
    func bind(_ address: SocketAddress) -> Bool {
        var sockAddress = address.sockAddress()
        if Darwin.bind(
            socket.fileDescriptor,
            &sockAddress,
            socklen_t(MemoryLayout<sockaddr>.size)
            ) < 0 {
            return false
        }
        
        return true
    }
    
    @discardableResult
    func listen(queueLength: Int32 = 2) -> Bool {
        if Darwin.listen(socket.fileDescriptor, queueLength) < 0 {
            return false
        }
        
        return true
    }
    
    func accept() -> Connection? {
        var address = sockaddr()
        var size = socklen_t(MemoryLayout<sockaddr>.size)
        let conn_fd = Darwin.accept(socket.fileDescriptor, &address, &size)
        
        if conn_fd < 0 {
            return nil
        } else {
            return Connection(fileHandle: FileHandle(fileDescriptor: conn_fd))
        }
    }
    
    func close() {
        socket.closeFile()
    }
}

