//
//  NetworkManager.swift
//  Network
//
//  Created by Harry Wright on 19.06.17.
//  Copyright © 2017 Trolley. All rights reserved.
//

import Foundation
import Alamofire

let kLocalURL: String = "http://localhost:8080/API"
let kLocalIPURL: String = "http://127.0.0.1:8080/API"

extension String {

    static func urlRoute(for items: String...) -> String {
        return items.joined(separator: "/")
    }

}

/// <#Description#>
@objc public class TRLNetworkManager : NSObject {

    var network: TRLNetwork

    var error: Error?

    internal init(network: TRLNetwork, key: String) {
        self.network = network
        self.network.parsedURL._addPath(key)
    }

    internal init(_ url: URLConvertible, key: String) throws {
        self.network = try TRLNetwork(url)
        self.network.parsedURL._addPath(key)
    }

    @available(*, unavailable, renamed: "init(_:key:)")
    internal init?(url: URLConvertible, key: String) {
        TRLCoreNetworkingLogger.info("Please use `init(_:key:) throws` instead")
        return nil
    }

}

extension TRLNetworkManager {

    public override var description: String {
        return self.network.parsedURL.description
    }

}

public extension TRLNetworkManager {

    /// <#Description#>
    ///
    /// - Parameters:
    ///   - route: <#route description#>
    ///   - parameters: <#parameters description#>
    ///   - encoding: <#encoding description#>
    ///   - headers: <#headers description#>
    /// - Returns: <#return value description#>
    func get(
        _ route: String,
        with parameters: Parameters?,
        encoding: ParameterEncoding,
        headers: HTTPHeaders?
        ) -> TRLRequest
    {
        return self.network.get(route, with: parameters, encoding: encoding, headers: headers)
    }

    /// <#Description#>
    ///
    /// - Parameters:
    ///   - item: <#item description#>
    ///   - route: <#route description#>
    ///   - parameters: <#parameters description#>
    ///   - encoding: <#encoding description#>
    ///   - headers: <#headers description#>
    /// - Returns: <#return value description#>
    func get(
        item: String,
        in route: String,
        with parameters: Parameters?,
        encoding: ParameterEncoding,
        headers: HTTPHeaders?
        ) -> TRLRequest
    {
        let route = String.urlRoute(for: route, item)
        return self.network.get(route, with: parameters, encoding: encoding, headers: headers)
    }
    
}

// TODO: Add Post/Put/Delete

extension TRLNetworkManager {

}
