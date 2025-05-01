//
//  DeviceType.swift
//  i2048
//
//  Created by Rishi Singh on 27/01/25.
//

#if os(iOS)
import UIKit
#endif

enum DeviceType {
    case iPhone, iPad, mac, unknown
    
    static var current: DeviceType {
        #if os(iOS)
        switch UIDevice.current.userInterfaceIdiom {
        case .phone:
            return .iPhone
        case .pad:
            return .iPad
        default:
            return .unknown
        }
        #elseif os(macOS)
        return .mac
        #else
        return .unknown
        #endif
    }
    
    static var isIphone: Bool {
        DeviceType.current == DeviceType.iPhone
    }
}
