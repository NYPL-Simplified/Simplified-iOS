/// Represents the type of card implied by some home, school, or work address.
///
/// The exact implications of a particular card type on the registration flow are
/// somewhat subtle. Consult the API documentation for more information.
enum CardType {
  case none
  case temporary
  case standard
}
