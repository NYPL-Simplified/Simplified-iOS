import Foundation

final class ValidateAddressResponse {  
  enum Response {
    case validAddress(message: String, address: Address, cardType: CardType)
    case alternativeAddresses(message: String, addressTuples: [(Address, CardType)])
    case unrecognizedAddress(message: String)
  }
  
  class func responseWithData(_ data: Data) -> Response? {
    guard
      let JSONObject = try? JSONSerialization.jsonObject(with: data, options: []) as! [String: AnyObject],
      let type = JSONObject["type"] as? String,
      let message = JSONObject["message"] as? String
      else { return nil }
    
    switch type {
    case "valid-address":
      var cardType = CardType.none
      if JSONObject["card_type"] as? String == "temporary" {
        cardType = .temporary
      } else if JSONObject["card_type"] as? String == "standard" {
        cardType = .standard
      }
      guard
        let addressObject = JSONObject["address"],
        let address = Address.addressWithJSONObject(addressObject)
        else { return nil }
      return Response.validAddress(message: message, address: address, cardType: cardType)
    case "alternate-addresses":
      guard let addressContainingObjects = JSONObject["addresses"] as? [AnyObject] else { return nil }
      let addressTuples = addressContainingObjects.flatMap({(object: AnyObject) -> (Address, CardType)? in
        guard
          let JSONObject = object as? [String: AnyObject],
          let addressJSON = JSONObject["address"] as? [String: AnyObject],
          let address = Address.addressWithJSONObject(addressJSON as AnyObject)
          else { return nil }
        let cardTypeString = JSONObject["card_type"] as? String
        var cardType = CardType.none
        if cardTypeString == "temporary" {
          cardType = .temporary
        } else if cardTypeString == "standard" {
          cardType = .standard
        }
        return (address, cardType)
      })
      return Response.alternativeAddresses(message: message, addressTuples: addressTuples)
    case "unrecognized-address":
      return Response.unrecognizedAddress(message: message)
    default:
      break
    }
    
    return nil
  }
}
