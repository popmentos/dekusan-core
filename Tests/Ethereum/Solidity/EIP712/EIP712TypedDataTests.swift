// Copyright © 2017-2018 Trust.
//
// This file is part of Trust. The full Trust copyright notice, including
// terms governing use, modification, and redistribution, is contained in the
// file LICENSE at the root of the source code distribution tree.

import XCTest
import DekuSanCore

class EIP712TypedDataTests: XCTestCase {
    var typedData: EIP712TypedData!

    override func setUp() {
        super.setUp()
        let string = """
{
    "types": {
        "EIP712Domain": [
            {"name": "name", "type": "string"},
            {"name": "version", "type": "string"},
            {"name": "chainId", "type": "uint256"},
            {"name": "verifyingContract", "type": "address"}
        ],
        "Person": [
            {"name": "name", "type": "string"},
            {"name": "wallet", "type": "address"}
        ],
        "Mail": [
            {"name": "from", "type": "Person"},
            {"name": "to", "type": "Person"},
            {"name": "contents", "type": "string"}
        ]
    },
    "primaryType": "Mail",
    "domain": {
        "name": "Ether Mail",
        "version": "1",
        "chainId": 1,
        "verifyingContract": "0xCcCCccccCCCCcCCCCCCcCcCccCcCCCcCcccccccC"
    },
    "message": {
        "from": {
            "name": "Cow",
            "wallet": "0xCD2a3d9F938E13CD947Ec05AbC7FE734Df8DD826"
        },
        "to": {
            "name": "Bob",
            "wallet": "0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB"
        },
        "contents": "Hello, Bob!"
    }
}
"""
        let data = string.data(using: .utf8)!
        let decoder = JSONDecoder()

        typedData = try? decoder.decode(EIP712TypedData.self, from: data)
        XCTAssertNotNil(typedData)
    }

    func testDecodeJSONModel() throws {
        let jsonString = """
        {
          "types": {
              "EIP712Domain": [
                  {"name": "name", "type": "string"},
                  {"name": "version", "type": "string"},
                  {"name": "chainId", "type": "uint256"},
                  {"name": "verifyingContract", "type": "address"}
              ],
              "Person": [
                  {"name": "name", "type": "string"},
                  {"name": "wallet", "type": "bytes32"},
                  {"name": "age", "type": "int256"},
                  {"name": "paid", "type": "bool"}
              ]
          },
          "primaryType": "Person",
          "domain": {
              "name": "Person",
              "version": "1",
              "chainId": 1,
              "verifyingContract": "0xCcCCccccCCCCcCCCCCCcCcCccCcCCCcCcccccccC"
          },
          "message": {
              "name": "alice",
              "wallet": "0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB",
              "age": 40,
              "paid": true
            }
        }
        """
        let jsonTypedData = try JSONDecoder().decode(EIP712TypedData.self, from: jsonString.data(using: .utf8)!)
        // swiftlint:disable:next line_length
        let result = "432c2e85cd4fb1991e30556bafe6d78422c6eeb812929bc1d2d4c7053998a4099c0257114eb9399a2985f8e75dad7600c5d89fe3824ffa99ec1c3eb8bf3b0501bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000280000000000000000000000000000000000000000000000000000000000000001"
        let data = jsonTypedData.encodeData(data: jsonTypedData.message, type: jsonTypedData.primaryType)
        XCTAssertEqual(data.hexString, result)
    }

    func testGenericJSON() throws {
        let jsonString = """
        {
          "number": 123456,
          "string": "this is a string",
          "null": null,
          "bytes": "0x1234",
          "array": [{
              "name": "bob",
              "address": "0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB",
              "age": 22,
              "paid": false
          }],
          "object": {
              "name": "alice",
              "address": "0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB",
              "age": 40,
              "paid": true
            }
        }
        """
        let data = jsonString.data(using: .utf8)!
        let message = try JSONDecoder().decode(JSON.self, from: data)
        XCTAssertNil(try? JSONDecoder().decode(EIP712TypedData.self, from: data))
        XCTAssertNotNil(message["object"]?.objectValue)
        XCTAssertNotNil(message["array"]!.arrayValue)
        XCTAssertNotNil(message["array"]?[0]?.objectValue)

        XCTAssertTrue(message["object"]!["paid"]!.boolValue!)
        XCTAssertTrue(message["null"]!.isNull)
        XCTAssertFalse(message["bytes"]!.isNull)

        XCTAssertNil(message["number"]!.stringValue)
        XCTAssertNil(message["string"]!.floatValue)
        XCTAssertNil(message["bytes"]!.boolValue)
        XCTAssertNil(message["object"]!.arrayValue)
        XCTAssertNil(message["array"]!.objectValue)
        XCTAssertNil(message["foo"])
        XCTAssertNil(message["array"]?[2])
    }

    func testEncodeType() {
        let result = "Mail(Person from,Person to,string contents)Person(string name,address wallet)"
        XCTAssertEqual(typedData.encodeType(primaryType: "Mail"), result.data(using: .utf8)!)
    }

    func testEncodedTypeHash() {
        let result = "a0cedeb2dc280ba39b857546d74f5549c3a1d7bdc2dd96bf881f76108e23dac2"
        XCTAssertEqual(typedData.typeHash.hexString, result)
    }

    func testEncodeData() {
        // swiftlint:disable:next line_length
        let result = "a0cedeb2dc280ba39b857546d74f5549c3a1d7bdc2dd96bf881f76108e23dac2fc71e5fa27ff56c350aa531bc129ebdf613b772b6604664f5d8dbe21b85eb0c8cd54f074a4af31b4411ff6a60c9719dbd559c221c8ac3492d9d872b041d703d1b5aadf3154a261abdd9086fc627b61efca26ae5702701d05cd2305f7c52a2fc8"
        let data = typedData.encodeData(data: typedData.message, type: typedData.primaryType)
        XCTAssertEqual(data.hexString, result)
    }

    func testStructHash() {
        let result = "c52c0ee5d84264471806290a3f2c4cecfc5490626bf912d01f240d7a274b371e"
        let data = typedData.encodeData(data: typedData.message, type: typedData.primaryType)
        XCTAssertEqual(Crypto.hash(data).hexString, result)

        let result2 = "f2cee375fa42b42143804025fc449deafd50cc031ca257e0b194a650a912090f"
//        let json = try! JSONDecoder().decode(JSON.self, from: try! JSONEncoder().encode(typedData.domain))
        let data2 = typedData.encodeData(data: typedData.domain, type: "EIP712Domain")
        XCTAssertEqual(Crypto.hash(data2).hexString, result2)
    }

    func testSignHash() {
        let cow = "cow".data(using: .utf8)!
        let privateKeyData = Crypto.hash(cow)
        let privateKey = PrivateKey(data: privateKeyData)!

        let address = "0xcd2a3d9f938e13cd947ec05abc7fe734df8dd826"
        let signed = Crypto.sign(hash: typedData.signHash, privateKey: privateKeyData)
        let result = "be609aee343fb3c4b28e1df9e632fca64fcfaede20f02e86244efddf30957bd2"
        XCTAssertEqual(privateKey.publicKey().ethereumAddress.description.lowercased(), address)
        XCTAssertEqual(typedData.signHash.hexString, result)
        XCTAssertEqual(signed.hexString, "4355c47d63924e8a72e509b65029052eb6c299d53a04e167c5775fd466751c9d07299936d304c153f6443dfa05f40ff007d72911b6f72307f996231605b9156201")
    }

    func testSignHashFromCF() throws {
        let url = Bundle.init(for: type(of: self)).url(forResource: "cryptofights_712", withExtension: "json")!
        let data = try Data(contentsOf: url)
        let typed = try JSONDecoder().decode(EIP712TypedData.self, from: data)

        let encoded = typed.encodeData(data: typed.message, type: typed.primaryType)
        let signhash = typed.signHash

        // swiftlint:disable:next line_length
        XCTAssertEqual("0x" + encoded.hexString, "0x9bb088b5f80aec2012a0ce9f4e550b808b2c0d003f6c92748fff8deb5879d86acfe49aa546453df3f2e768a97204a3268cef7c27df53cc2f2d47385cfeaf0000000000000000000000000000c36edf48e21cf395b206352a1819de658fd7f98800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000de0b6b3a764000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001")
        XCTAssertEqual("0x" + signhash.hexString, "0xdb12328a6d193965801548e1174936c3aa7adbe1b54b3535a3c905bd4966467c")
    }
}
