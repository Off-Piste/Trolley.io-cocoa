//
//  CurrencyConvertor.swift
//  Pods
//
//  Created by Harry Wright on 31.03.17.
//
//

import Foundation

internal let _offlineRatesUD: String = "OfflineRates"

let kDecimalHandler = NSDecimalNumberHandler(
    roundingMode: .plain,
    scale: 2,
    raiseOnExactness: true,
    raiseOnOverflow: true,
    raiseOnUnderflow: true,
    raiseOnDivideByZero: true
)

/// Completion handler to send an error if an error is recived.
public typealias Downloader = (CurrencyError?) -> Void

/// The CurrencyConvertable protocol that Currency conforms to
public protocol CurrencyConvertable {
    
    func convert(_ value: Float) -> Float
    
}

class JSONDecoder {
    
    static func object(
        from data: Data,
        withOptions options: JSONSerialization.ReadingOptions = .allowFragments
        ) throws -> Any
    {
        return try JSONSerialization.jsonObject(with: data, options: options)
    }
    
}

/// The Custom Currency Errors that can occur when downloading the JSON
///
/// - couldNotWorkWithJSON: An error when the JSON cannot be converted
/// - guardFail: An error when a guard statment fails
/// - error: A normal NSError/Error that has occured during the docatch
public enum CurrencyError: Error {
    
    case couldNotWorkWithJSON
    case guardFail(for: Int)
    case error(_ : Error)
    case ratesNil(_ : [String : AnyObject])
    case invalidURL(_ : String)
    
    var localizedDescription: String {
        switch self {
        case .couldNotWorkWithJSON:
            return "JSONSerialization could not convert data, check source"
        case .guardFail(let line):
            return "Guard failed on line: \(line)"
        case .error(let error) :
            return error.localizedDescription
        case .ratesNil(let json):
            return "Invalid JSON \(json)"
        case .invalidURL(let url):
            return "Invalid URL \(url)"
        }
    }
}

/**
 Currency Conversion Class, this will download the JSON for the rates and can be initalised with a custom value.
 
 # Note
 Money inside of the basket or Products are not automatically converted, 
 as users may not required that.
 */
public class CurrencyConverter: CurrencyConvertable {
    
    /// The shared instance of CurrencyConverter, 
    /// this is so all parts of the framework acces the same rates
    public static var shared = CurrencyConverter()
    
    /// The conversion rate that is used by the framework
    public private(set) var conversionRate: Float = 0.0
    
    /// The NSDecimalNumber for the conversion rate
    internal var decimalRate: NSDecimalNumber {
        return NSDecimalNumber(value: conversionRate)
    }
    
    /// The local currency code
    public var localeCurrencyCode: String {
        return _localCurrencyCode
    }
    
    /// The Defaults Manager that holds the required UD Key
    private let newManager: DefaultsManager = {
        return DefaultsManager(withKey: _offlineRatesUD)
    }()
    
    /// Setup with rates that will be used if the JSON hasn't downloaded
    private var _offlineRates: [String : Float] {
        do {
            guard let object = try newManager.retrieveObject() as? [String : Float] else {
                fatalError("Cannot cast to dictionary")
            }
            return object
        } catch {
            Log.error(
                error.localizedDescription,
                "Currency rate will be set to 1.0"
            )
            return ["Error" : 404]
        }
    }
    
    /// The Currency of the vendor, can be set in the `ECommerce-info.plist`
    private var _baseCurrency: String = DEFAULT_CURRENCY_TYPE
    
    /// The url for the api
    private var _apiUrl: String {
        return "http://api.fixer.io/latest?base=\(self._baseCurrency)"
    }
    
    /// The currency code that is send through Currency so that currencys 
    /// that aren't supported by the api can't crash the code
    private var _localCurrencyCode: String {
        let locale = Locale.current
        guard let currencyCode = locale.currencyCode else { return "GBP" }
        return Currency(localeIdentifier: currencyCode).description
    }
    
    fileprivate var _newAPIURL: String {
        return "http://api.fixer.io/latest?base=\(self._baseCurrency)&symbols=\(self._localCurrencyCode)"
    }
    
    /// Private init, only used for shared instance
    private init() { }
    
    /// Initaliser for if the user wishes to use a custom conversion rate
    /// or downloads there rate differently and wishes to work with our methods
    ///
    /// - Parameter cr: The Conversion rate as a Float
    public init(withCovertionRate cr: Float) { self.conversionRate = cr }
    
    /// The conversion method, this returns the converted rate, 
    /// in low internet zones it will used a saved value
    ///
    /// - Parameter value: The pre-converted value
    /// - Returns: The converted Value
    public func convert(_ value: Float) -> Float {
        if conversionRate == 0.0 { // Checks to see if downloaded, if not converts with saved rate
            guard let rate = self._offlineRates[self._localCurrencyCode] else { return value * 1.0 }
            return value * rate
        }
        
        return value * conversionRate
    }
    
    /// <#Description#>
    ///
    /// - Parameter value: <#value description#>
    /// - Returns: <#return value description#>
    func convert(value: NSDecimalNumber) -> NSDecimalNumber {
        if decimalRate == 0.0 {
            guard let rate = self._offlineRates[self._localCurrencyCode] else { return value }
            let dc = NSDecimalNumber(value: rate)
            return value.multiplying(by: dc)
        }
        return value.multiplying(by: decimalRate)
    }
    
    /// The Downloader for the currency JSON
    ///
    /// - Parameter completion: Check `Downloader` for details
    internal func downloadJSON(_ completion: @escaping Downloader) {
        // No need to convert from say GBP to GBP
        if self._localCurrencyCode == self._baseCurrency { return }
        
        guard let url = URL(string: _newAPIURL) else {
            completion(CurrencyError.invalidURL(_newAPIURL))
            return
        }
        
        let urlRequest = URLRequest(url: url)
        let session = URLSession.shared
        let task = session.dataTask(with: urlRequest, completionHandler: { (data, response, error) in
            if error != nil { completion(CurrencyError.error(error!)); return }
            guard let responseData = data as Data? else {
                completion(CurrencyError.guardFail(for: #line - 1))
                return
            }
            
            do {
                if let json = try JSONDecoder.object(from: responseData) as? [String : AnyObject] {
                    guard let rates = json["rates"] as? [String : AnyObject] else {
                        completion(CurrencyError.ratesNil(json))
                        return
                    }
                    
                    if let rate = self._offlineRates[self._localCurrencyCode] {
                        self.newManager.set(object: rates)
                        self.conversionRate = rate
                        
                        completion(nil)
                        return
                    } else {
                        completion(CurrencyError.ratesNil([:]))
                        return
                    }
                } else {
                    completion(CurrencyError.couldNotWorkWithJSON)
                    return
                }
            } catch {
                completion((error as! CurrencyError))
                return
            }
        })
        task.resume()
    }
    
    internal func setupJSONUserDefaults() {
        let manager = DefaultsManager(withKey: _offlineRatesUD)
        do {
            let values = try manager.retrieveObject()
            _checkForNotEmpty(values as! Dictionary<String, Any>, "Should have items inside")
        } catch {
            manager.set(object: [
                "AUD": 1.6231,
                "BGN": 2.2694,
                "BRL": 3.8936,
                "CAD": 1.6616,
                "CHF": 1.2414,
                "CNY": 8.5835,
                "CZK": 31.355,
                "DKK": 8.6315,
                "EUR": 1.1604,
                "HKD": 9.6832,
                "HRK": 8.6424,
                "HUF": 358.96,
                "IDR": 16590,
                "ILS": 4.5154,
                "INR": 80.867,
                "JPY": 138.54,
                "KRW": 1391.4,
                "MXN": 23.35,
                "MYR": 5.5074,
                "NOK": 10.64,
                "NZD": 1.7758,
                "PHP": 62.503,
                "PLN": 4.9006,
                "RON": 5.2736,
                "RUB": 70.014,
                "SEK": 11.096,
                "SGD": 1.7379,
                "THB": 42.877,
                "TRY": 4.5392,
                "USD": 1.2459,
                "ZAR": 16.032
                ]
            )
        }
    }
    
}