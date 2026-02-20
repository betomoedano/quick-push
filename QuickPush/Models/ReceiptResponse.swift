//
//  ReceiptResponse.swift
//  QuickPush
//
//  Created by beto on 2/20/26.
//

import Foundation

struct ReceiptResponse: Codable {
  let data: [String: PushReceipt]?
  let errors: [PushResponse.PushError]?

  struct PushReceipt: Codable {
    let status: String          // "ok" or "error"
    let message: String?
    let details: ReceiptDetails?

    struct ReceiptDetails: Codable {
      let error: String?        // e.g. "DeviceNotRegistered"
    }
  }
}
