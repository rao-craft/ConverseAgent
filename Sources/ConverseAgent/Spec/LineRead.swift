//  WHAT: A value read from a line, or the reason it could not be, in words a refusal quotes.

import Foundation

enum LineRead<Value> {
    case success(Value)
    case failure(String)
}

extension LineRead: Sendable where Value: Sendable {}
extension LineRead: Equatable where Value: Equatable {}
