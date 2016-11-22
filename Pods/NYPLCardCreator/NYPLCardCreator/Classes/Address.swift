import Foundation

struct Address {
  let street1: String
  let street2: String?
  let city: String
  let region: String
  let zip: String
  
  /// Takes a JSON object of the form retured from the server (where "state" is mapped
  /// to the `region` property).
  static func addressWithJSONObject(_ object: AnyObject) -> Address? {
    guard
      let address = object as? [String: AnyObject],
      let street1 = address["line_1"] as? String,
      let city = address["city"] as? String,
      let region = address["state"] as? String,
      let zip = address["zip"] as? String
      else
    {
      return nil
    }
    
    return Address(street1: street1, street2: address["line_2"] as? String, city: city, region: region, zip: zip)
  }
  
  /// Returns a JSON object of the form required by the server.
  func JSONObject() -> [String: String] {
    return [
      "line_1": self.street1,
      "line_2": self.street2 == nil ? "" : self.street2!,
      "city": self.city,
      "state": self.region,
      "zip": self.zip
    ]
  }
}
