//
//  ByteConverterServiceTests.swift
//  TempBoxTests
//

import XCTest
@testable import TempBox

final class ByteConverterServiceTests: XCTestCase {

    // MARK: - Init from bytes

    func testInitBytes_storesCorrectly() {
        let svc = ByteConverterService(bytes: 1000)
        XCTAssertEqual(svc.kiloBytes, 1.0, accuracy: 0.0001)
    }

    func testInitKiloBytes_convertsCorrectly() {
        let svc = ByteConverterService(kiloBytes: 1)
        XCTAssertEqual(svc.asBytes(), 1000, accuracy: 0.01)
    }

    func testInitBits_convertsToBytes() {
        // 8000 bits = 1000 bytes
        let svc = ByteConverterService(bits: 8000)
        XCTAssertEqual(svc.kiloBytes, 1.0, accuracy: 0.01)
    }

    // MARK: - Computed unit properties

    func testKiloBytes() {
        let svc = ByteConverterService(bytes: 2000)
        XCTAssertEqual(svc.kiloBytes, 2.0, accuracy: 0.0001)
    }

    func testMegaBytes() {
        let svc = ByteConverterService(bytes: 1_000_000)
        XCTAssertEqual(svc.magaBytes, 1.0, accuracy: 0.0001)
    }

    func testGigaBytes() {
        let svc = ByteConverterService(bytes: 1_000_000_000)
        XCTAssertEqual(svc.gigaBytes, 1.0, accuracy: 0.0001)
    }

    func testTeraBytes() {
        let svc = ByteConverterService(bytes: 1_000_000_000_000)
        XCTAssertEqual(svc.teraBytes, 1.0, accuracy: 0.0001)
    }

    func testPetaBytes() {
        let svc = ByteConverterService(bytes: 1e15)
        XCTAssertEqual(svc.petaBytes, 1.0, accuracy: 0.0001)
    }

    // MARK: - Factory methods (SI)

    func testFromBytes() {
        let svc = ByteConverterService.fromBytes(value: 500)
        XCTAssertEqual(svc.asBytes(), 500, accuracy: 0.01)
    }

    func testFromKiloBytes() {
        let svc = ByteConverterService.fromKiloBytes(value: 1)
        XCTAssertEqual(svc.asBytes(), 1000, accuracy: 0.01)
    }

    func testFromMegaBytes() {
        let svc = ByteConverterService.fromMegaBytes(value: 1)
        XCTAssertEqual(svc.magaBytes, 1.0, accuracy: 0.0001)
    }

    func testFromGigaBytes() {
        let svc = ByteConverterService.fromGigaBytes(value: 1)
        XCTAssertEqual(svc.gigaBytes, 1.0, accuracy: 0.0001)
    }

    func testFromTeraBytes() {
        let svc = ByteConverterService.fromTeraBytes(value: 1)
        XCTAssertEqual(svc.teraBytes, 1.0, accuracy: 0.0001)
    }

    func testFromPetaBytes() {
        let svc = ByteConverterService.fromPetaBytes(value: 1)
        XCTAssertEqual(svc.petaBytes, 1.0, accuracy: 0.0001)
    }

    // MARK: - Factory methods (binary / IEC)

    func testFromKibiBytes() {
        let svc = ByteConverterService.fromKibiBytes(value: 1)
        XCTAssertEqual(svc.asBytes(), 1024, accuracy: 0.01)
    }

    func testFromMebiBytes() {
        let svc = ByteConverterService.fromMebiBytes(value: 1)
        XCTAssertEqual(svc.asBytes(), 1_048_576, accuracy: 0.01)
    }

    func testFromGibiBytes() {
        let svc = ByteConverterService.fromGibiBytes(value: 1)
        XCTAssertEqual(svc.asBytes(), 1_073_741_824, accuracy: 1)
    }

    func testFromTebiBytes() {
        let svc = ByteConverterService.fromTebiBytes(value: 1)
        XCTAssertEqual(svc.asBytes(), 1_099_511_627_776, accuracy: 1)
    }

    func testFromBits() {
        let svc = ByteConverterService.fromBits(value: 8)
        XCTAssertEqual(svc.asBytes(), 1, accuracy: 0.01)
    }

    // MARK: - asBytes precision

    func testAsBytes_defaultPrecision() {
        let svc = ByteConverterService(bytes: 1234.5678)
        let result = svc.asBytes(precision: 2)
        XCTAssertEqual(result, 1234.56, accuracy: 0.01)
    }

    func testAsBytes_zeroPrecision() {
        let svc = ByteConverterService(bytes: 999.9)
        let result = svc.asBytes(precision: 0)
        XCTAssertEqual(result, 999.9, accuracy: 0.01)
    }

    // MARK: - Arithmetic operators

    func testAddition() {
        let a = ByteConverterService(bytes: 500)
        let b = ByteConverterService(bytes: 500)
        let result = a + b
        XCTAssertEqual(result.asBytes(), 1000, accuracy: 0.01)
    }

    func testSubtraction() {
        let a = ByteConverterService(bytes: 1000)
        let b = ByteConverterService(bytes: 300)
        let result = a - b
        XCTAssertEqual(result.asBytes(), 700, accuracy: 0.01)
    }

    func testAddInstance() {
        let a = ByteConverterService(bytes: 200)
        let b = ByteConverterService(bytes: 300)
        let result = a.add(value: b)
        XCTAssertEqual(result.asBytes(), 500, accuracy: 0.01)
    }

    func testSubtractInstance() {
        let a = ByteConverterService(bytes: 500)
        let b = ByteConverterService(bytes: 200)
        let result = a.subtract(value: b)
        XCTAssertEqual(result.asBytes(), 300, accuracy: 0.01)
    }

    // MARK: - Comparison operators

    func testGreaterThan_larger_isTrue() {
        let bigger = ByteConverterService(bytes: 1000)
        let smaller = ByteConverterService(bytes: 500)
        XCTAssertTrue(bigger > smaller)
    }

    func testGreaterThan_smaller_isFalse() {
        let bigger = ByteConverterService(bytes: 1000)
        let smaller = ByteConverterService(bytes: 500)
        XCTAssertFalse(smaller > bigger)
    }

    func testLessThan() {
        let a = ByteConverterService(bytes: 100)
        let b = ByteConverterService(bytes: 200)
        XCTAssertTrue(a < b)
        XCTAssertFalse(b < a)
    }

    func testGreaterThanOrEqual_equal() {
        let a = ByteConverterService(bytes: 100)
        let b = ByteConverterService(bytes: 100)
        XCTAssertTrue(a >= b)
    }

    func testLessThanOrEqual_equal() {
        let a = ByteConverterService(bytes: 100)
        let b = ByteConverterService(bytes: 100)
        XCTAssertTrue(a <= b)
    }

    // MARK: - Static compare / isEqual

    func testStaticCompare_leftSmaller() {
        let a = ByteConverterService(bytes: 100)
        let b = ByteConverterService(bytes: 200)
        XCTAssertEqual(ByteConverterService.compare(left: a, right: b), -1)
    }

    func testStaticCompare_equal() {
        let a = ByteConverterService(bytes: 150)
        let b = ByteConverterService(bytes: 150)
        XCTAssertEqual(ByteConverterService.compare(left: a, right: b), 0)
    }

    func testStaticCompare_leftLarger() {
        let a = ByteConverterService(bytes: 300)
        let b = ByteConverterService(bytes: 100)
        XCTAssertEqual(ByteConverterService.compare(left: a, right: b), 1)
    }

    func testStaticIsEqual_equal() {
        let a = ByteConverterService(bytes: 500)
        let b = ByteConverterService(bytes: 500)
        XCTAssertTrue(ByteConverterService.isEqual(left: a, right: b))
    }

    func testStaticIsEqual_notEqual() {
        let a = ByteConverterService(bytes: 500)
        let b = ByteConverterService(bytes: 501)
        XCTAssertFalse(ByteConverterService.isEqual(left: a, right: b))
    }

    func testInstanceCompareTo_lessThan() {
        let a = ByteConverterService(bytes: 100)
        let b = ByteConverterService(bytes: 200)
        XCTAssertEqual(a.compareTo(value: b), -1)
    }

    func testInstanceIsEqual_true() {
        let a = ByteConverterService(bytes: 256)
        let b = ByteConverterService(bytes: 256)
        XCTAssertTrue(a.isEqual(value: b))
    }

    // MARK: - toHumanReadable

    func testToHumanReadable_bytes() {
        let svc = ByteConverterService(bytes: 512)
        XCTAssertTrue(svc.toHumanReadable(unit: .B).hasSuffix("B"))
    }

    func testToHumanReadable_kiloBytes() {
        let svc = ByteConverterService(bytes: 2000)
        let result = svc.toHumanReadable(unit: .KB)
        XCTAssertTrue(result.contains("KB"), "Expected KB in: \(result)")
        XCTAssertTrue(result.contains("2"), "Expected value 2 in: \(result)")
    }

    func testToHumanReadable_megaBytes() {
        let svc = ByteConverterService.fromMegaBytes(value: 1.5)
        let result = svc.toHumanReadable(unit: .MB)
        XCTAssertTrue(result.contains("MB"))
        XCTAssertTrue(result.contains("1.5"))
    }

    func testToHumanReadable_gigaBytes() {
        let svc = ByteConverterService.fromGigaBytes(value: 2)
        let result = svc.toHumanReadable(unit: .GB)
        XCTAssertTrue(result.contains("GB"))
    }

    func testToHumanReadable_teraBytes() {
        let svc = ByteConverterService.fromTeraBytes(value: 1)
        let result = svc.toHumanReadable(unit: .TB)
        XCTAssertTrue(result.contains("TB"))
    }

    func testToHumanReadable_customPrecision() {
        let svc = ByteConverterService(bytes: 1_234_567)
        let result = svc.toHumanReadable(unit: .MB, precision: 3)
        XCTAssertTrue(result.contains("MB"))
    }
}
