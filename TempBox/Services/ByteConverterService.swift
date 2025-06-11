//
//  ByteConverterService.swift
//  TempBox
//
//  Created by Rishi Singh on 25/09/23.
//

import Foundation

enum SizeUnit { case TB, GB, MB, KB, B }

class ByteConverterService {
    private var bytes: Double = 0.0
    private var bits: Int = 0
    
    init(bytes: Double) {
        self.bytes = bytes
        self.bits = Int(ceil(bytes * 8.0))
    }
    
    init(bits: Int) {
        self.bits = bits
        self.bytes = Double(bits / 8)
    }

    private func withPrecision(value: Double, precision: Int = 2) -> Double {
        let valueArr: [Character] = Array(String(value))
        var endingIndex = 0
        if let indexOfDecimal = valueArr.firstIndex(of: ".") {
            endingIndex = indexOfDecimal + (precision + 1)
        } else {
            endingIndex = 4
        }

        if (valueArr.count < endingIndex) {
            return value
        } else {
            if let withPrecision = Double(String(valueArr[...endingIndex])) {
                return withPrecision
            }
            return value
        }
    }
    
    var kiloBytes: Double {
        get { return bytes / 1000 }
    }
    
    var magaBytes: Double {
        get { return bytes / 1000000 }
    }
    
    var gigaBytes: Double {
        get { return bytes / 1000000000 }
    }
    
    var teraBytes: Double {
        get { return bytes / 1000000000000 }
    }
    
    var petaBytes: Double {
        get { return bytes / 1E+15 }
    }
    
    func asBytes(precision: Int = 2) -> Double {
        return withPrecision(value: bytes, precision: precision)
    }
    
    static func fromBytes(value: Double) -> ByteConverterService {
        return TempBox.ByteConverterService(bytes: value)
    }
    
    static func fromBits(value: Int) -> ByteConverterService {
        return TempBox.ByteConverterService(bits: value)
    }
    
    static func fromKibiBytes(value: Double) -> ByteConverterService {
        return TempBox.ByteConverterService(bytes: value * 1024.0)
    }
    
    static func fromMebiBytes(value: Double) -> ByteConverterService {
        return TempBox.ByteConverterService(bytes: value * 1048576.0)
    }
    
    static func fromGibiBytes(value: Double) -> ByteConverterService {
        return TempBox.ByteConverterService(bytes: value * 1073741824.0)
    }
    
    static func fromTebiBytes(value: Double) -> ByteConverterService {
            return TempBox.ByteConverterService(bytes: value * 1099511627776.0)
        }

    static func fromPebiBytes(value: Double) -> ByteConverterService {
        return TempBox.ByteConverterService(bytes: value * 1125899906842624.0)
    }
    
    static func fromKiloBytes(value: Double) -> ByteConverterService {
        return TempBox.ByteConverterService(bytes: value * 1000.0)
    }
    
    static func fromMegaBytes(value: Double) -> ByteConverterService {
        return TempBox.ByteConverterService(bytes: value * 1000000.0)
    }
    
    static func fromGigaBytes(value: Double) -> ByteConverterService {
        return TempBox.ByteConverterService(bytes: value * 1000000000.0)
    }
    
    static func fromTeraBytes(value: Double) -> ByteConverterService {
        return TempBox.ByteConverterService(bytes: value * 1000000000000.0)
    }
    
    static func fromPetaBytes(value: Double) -> ByteConverterService {
        return TempBox.ByteConverterService(bytes: value * 1E+15)
    }
    
    func add(value: ByteConverterService) -> ByteConverterService {
        self + value
    }
    
    func subtract(value: ByteConverterService) -> ByteConverterService {
        self - value
    }
    
//    static func addBytes(value: Double) -> ByteConverterService {
//        let otherService = fromBytes(value: value)
//        return self + otherService
//    }
//
//    static func addKiloBytes(value: Double) -> ByteConverterService {
//        self + self.fromKiloBytes(value: value)
//    }
//
//    static func addMegaBytes(value: Double) -> ByteConverterService {
//        self + self.fromMegaBytes(value: value)
//    }
//
//    static func addGigaBytes(value: Double) -> ByteConverterService {
//        self + self.fromGibiBytes(value: value)
//    }
//
//    static func addTeraBytes(value: Double) -> ByteConverterService {
//        self + self.fromTeraBytes(value: value)
//    }
//
//    static func addPetaBytes(value: Double) -> ByteConverterService {
//        self + self.fromPetaBytes(value: value)
//    }
//
//    static func addKibiBytes(value: Double) -> ByteConverterService {
//        self + self.fromKibiBytes(value: value)
//    }
//
//    static func addMebiBytes(value: Double) -> ByteConverterService {
//        self + self.fromMebiBytes(value: value)
//    }
//
//    static func addGibiBytes(value: Double) -> ByteConverterService {
//        self + self.fromGibiBytes(value: value)
//    }
//
//    static func addTebiBytes(value: Double) -> ByteConverterService {
//        self + self.fromTebiBytes(value: value)
//    }
//
//    static func addPebiBytes(value: Double) -> ByteConverterService {
//        self + self.fromPebiBytes(value: value)
//    }
    
    static func +(left: ByteConverterService, right: ByteConverterService) -> ByteConverterService {
        return TempBox.ByteConverterService(bytes: left.bytes + right.bytes)
    }
    
    static func -(left: ByteConverterService, right: ByteConverterService) -> ByteConverterService {
        return TempBox.ByteConverterService(bytes: left.bytes - right.bytes)
    }
    
    static func >(left: ByteConverterService, right: ByteConverterService) -> Bool {
        return left.bits > right.bits
    }
    
    static func <(left: ByteConverterService, right: ByteConverterService) -> Bool {
        return left.bits < right.bits
    }
    
    static func <=(left: ByteConverterService, right: ByteConverterService) -> Bool {
        return left.bits <= right.bits
    }
    
    static func >=(left: ByteConverterService, right: ByteConverterService) -> Bool {
        return left.bits >= right.bits
    }
    
    static func compare(left: ByteConverterService, right: ByteConverterService) -> Int {
        if left.bits < right.bits {
            return -1
        } else if left.bits == right.bits {
            return 0
        } else {
            return 1
        }
    }
    
    static func isEqual(left: ByteConverterService, right: ByteConverterService) -> Bool {
        return left.bits == right.bits
    }
    
    func compareTo(value: ByteConverterService) -> Int {
        if self.bits < value.bits {
            return -1
        } else if self.bits == value.bits {
            return 0
        } else {
            return 1
        }
    }
    
    func isEqual(value: ByteConverterService) -> Bool {
        return self.bits == value.bits
    }

    func toHumanReadable(unit: SizeUnit, precision: Int = 2) -> String {
    switch (unit) {
      case SizeUnit.TB:
        return "\(withPrecision(value: teraBytes, precision: precision)) TB"
      case SizeUnit.GB:
        return "\(withPrecision(value: gigaBytes, precision: precision)) GB"
      case SizeUnit.MB:
        return "\(withPrecision(value: magaBytes, precision: precision)) MB"
      case SizeUnit.KB:
        return "\(withPrecision(value: kiloBytes, precision: precision)) KB"
      case SizeUnit.B:
        return "\(asBytes(precision: precision)) B"
    }
  }
}
