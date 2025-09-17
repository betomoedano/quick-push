//
//  PushResponse.swift
//  QuickPush
//
//  Created by beto on 2/20/25.
//

import Foundation

struct PushResponse: Codable {
  let data: [PushTicket]?
  let errors: [PushError]?
  
  struct PushTicket: Codable {
    let status: String
    let id: String?  // Present only if status == "ok"
    let message: String?  // Present only if status == "error"
    let details: [String: String]?  // JSON details object, can vary
  }
  
  struct PushError: Codable {
    let code: String
    let message: String
    let type: String?
    let isTransient: Bool?
    let metadata: ErrorMetadata?
    let requestId: String?
    
    struct ErrorMetadata: Codable {
      let appId: String?
      let experienceId: String?
    }
  }
}
