import Foundation

protocol Calculatable: Numeric {
    init?(_ string: String)
}

extension Int: Calculatable {}
extension Double: Calculatable {}

extension Optional {
    func unwrap(or error: Error) throws -> Wrapped {
        guard let wrapped = self else {
            throw error
        }
        return wrapped
    }
}

struct Operator<Num: Calculatable>: CustomStringConvertible {
    let name: String
    let precedence: Int
    let assotiative: Assotiative
    let operands: Int
    let f: ([Num]) throws -> Num
    
    var description: String {
        return self.name
    }
}

enum Token<Num: Calculatable>: CustomStringConvertible {
    case value(Num)
    case `operator`(Operator<Num>)
    case parathensis(String)

    var description: String {
        switch self {
        case .value(let num): return "\(num)"
        case .operator(let op): return op.description
        case .parathensis(let type): return type
        }
    }
}

enum Assotiative {
    case left
    case right
    case none
}

func add<Num: Calculatable>(_ elements: [Num]) -> Num {
    return elements[0] + elements[1]
}

func subtract<Num: Calculatable>(_ elements: [Num]) -> Num {
    return elements[0] - elements[1]
}

func multiply<Num: Calculatable>(_ elements: [Num]) -> Num {
    return elements[0] * elements[1]
}

func power<Num: Calculatable>(_ elements: [Num]) throws -> Num {
    if elements[1] == 0 {
        return 1
    }
    var pow: Int = try (elements[1] as? Int).unwrap(or: EvaluationError.downCastError("Int"))
    if pow < 0 {
        return 0
    }
    var a: Int = try (elements[0] as? Int).unwrap(or: EvaluationError.downCastError("Int"))
    var res = 1
    while pow > 0 {
        if pow % 2 == 0 {
            a *= a
            pow /= 2
        } else {
            res *= a
            pow -= 1
        }
    }
    return try (res as? Num).unwrap(or: EvaluationError.upperCastError("Int"))
}

func myNegate<Num: Calculatable>(_ elements: [Num]) -> Num {
    return elements[0] * (-1)
}

func myAbs<Num: Calculatable>(_ elements: [Num]) throws -> Num {
    let negative: Bool
    if elements[0] is Int {
        let tmp = try (elements[0] as? Int).unwrap(or: EvaluationError.upperCastError("Int"))
        negative = tmp < 0
    } else {
        let tmp = try (elements[0] as? Double).unwrap(or: EvaluationError.upperCastError("Double"))
        negative = tmp < 0.0
    }
    if !negative {
        return elements[0]
    } else {
        return elements[0] * (-1)
    }
}

func myFact<Num: Calculatable>(_ elements: [Num]) throws -> Num {
    let up = try (elements[0] as? Int).unwrap(or: EvaluationError.downCastError("Int"))
    var res = 1
    if up > 0 {
        for i in 1...up {
            res *= i
        }
    } else if up == 0 {
        return 1
    } else {
        throw EvaluationError.illegalFactorial(up)
    }
    return try (res as? Num).unwrap(or: EvaluationError.upperCastError("Int"))
}

func division<Num: Calculatable>(_ elements: [Num]) throws -> Num {
    guard elements[0] != 0 else {
        throw EvaluationError.divisionByZero
    }
    if elements[0] is Int {
        let lhs = elements[0] as? Int
        let rhs = elements[1] as? Int
        let ans = try lhs.unwrap(or: EvaluationError.downCastError("Int")) / rhs.unwrap(or: EvaluationError.downCastError("Int")) as? Num
        return try ans.unwrap(or: EvaluationError.upperCastError("Int"))
    } else {
        let lhs = elements[0] as? Double
        let rhs = elements[1] as? Double
        let ans = try lhs.unwrap(or: EvaluationError.downCastError("Double")) / rhs.unwrap(or: EvaluationError.downCastError("Double")) as? Num
        return try ans.unwrap(or: EvaluationError.upperCastError("Double"))
    }
}

func remainder<Num: Calculatable>(_ elements: [Num]) throws -> Num {
    guard elements[0] != 0 else {
        throw EvaluationError.divisionByZero
    }
    let lhs = elements[0] as? Int
    let rhs = elements[1] as? Int
    let ans = try lhs.unwrap(or: EvaluationError.downCastError("Int")) % rhs.unwrap(or: EvaluationError.downCastError("Int")) as? Num
    return try ans.unwrap(or: EvaluationError.upperCastError("Int"))
}

func block<Num: Calculatable>(_ elements: [Num]) -> Num {
    return 0
}

func defaultOperators<Num: Calculatable>() -> [Operator<Num>] {
    [
        Operator(name: "+", precedence: 10, assotiative: Assotiative.left, operands: 2, f: add),
        Operator(name: "-", precedence: 10, assotiative: Assotiative.left, operands: 2, f: subtract),
        Operator(name: "*", precedence: 20, assotiative: Assotiative.left, operands: 2, f: multiply),
        Operator(name: "/", precedence: 20, assotiative: Assotiative.left, operands: 2, f: division),
        Operator(name: "%", precedence: 20, assotiative: Assotiative.left, operands: 2, f: remainder),
        Operator(name: "^", precedence: 40, assotiative: Assotiative.right, operands: 2, f: power), // -2^5 == -32, 2^3! == 64
        
        Operator(name: "negate", precedence: 30, assotiative: Assotiative.none, operands: 1, f: myNegate),
        Operator(name: "abs", precedence: 30, assotiative: Assotiative.none, operands: 1, f: myAbs),
        Operator(name: "!", precedence: 50, assotiative: Assotiative.none, operands: 1, f: myFact),
    ]
}

enum EvaluationError: Error, CustomStringConvertible {
    case invalidToken(token: String)
    case arityError
    case divisionByZero
    case downCastError(_ nameType: String)
    case upperCastError(_ nameType: String)
    case illegalFactorial(_ token: Int)

    var description: String {
        switch self {
        case .invalidToken(token: let token):
            return "Invalid token: \"\(token)\""
        case .arityError:
            return "arity error"
        case .divisionByZero:
            return "Divizion by zero"
        case .downCastError(nameType: let nameType):
            return "Error in downCast from Num to \"\(nameType)\""
        case .upperCastError(nameType: let nameType):
            return "Error in upperCast from \"\(nameType)\" to Num"
        case .illegalFactorial(token: let token):
            return "Take factorial from \"\(token)\" < 0"
        }
    }
}

func eval<Num: Calculatable>(_ input: String, _ postfix: Bool = false, operators ops: [Operator<Num>] = defaultOperators()) throws -> Num {
    let operators: [String: Operator<Num>] = Dictionary(uniqueKeysWithValues: ops.map { ($0.name, $0) })
    
    let parathensis: [String : String] = ["(": "(", ")": ")"]
    
    let unaryCollision: [String : String] = ["-" : "negate", "+" : "abs"]
    
    var inputs = input.components(separatedBy: .whitespaces)
    var isUnary = true
    for i in 0..<inputs.count {
        if operators[inputs[i]] != nil {
            if isUnary {
                inputs[i] = unaryCollision[inputs[i]] ?? inputs[i]
            }
            isUnary = true
        } else if inputs[i] == "(" {
            isUnary = true
        } else {
            isUnary = false
        }
    }
    
    let tokens: [Token<Num>] = try inputs.map {
        try (Num($0).map(Token.value) ?? operators[$0].map(Token.operator) ?? parathensis[$0].map(Token.parathensis)).unwrap(or: EvaluationError.invalidToken(token: $0))
    }

    let rpn: [Token<Num>]

    if (!postfix) {
        let rpnExt: (rpn: [Token<Num>], opStack: [Operator<Num>]) = try tokens.reduce(into: (rpn: [], opStack: [])) { (acc, token) in
            switch token {
            case .value:
                acc.rpn.append(token)
            case .operator(let op):
                if op.operands == 1 {
                    acc.opStack.append(op)
                } else {
                    while let topOp = acc.opStack.last, (topOp.precedence > op.precedence || (op.assotiative != Assotiative.right && topOp.precedence == op.precedence)) {

                        acc.rpn.append(.operator(topOp))
                        acc.opStack.removeLast()
                    }
                    acc.opStack.append(op)
                }
            case .parathensis(let type):
                if type == "(" {
                    acc.opStack.append(Operator(name: "(", precedence: 0, assotiative: Assotiative.left, operands: 0, f: block))
                } else if type == ")" {
                    while let topOp = acc.opStack.last, topOp.name != "(" {
                        acc.rpn.append(.operator(topOp))
                        acc.opStack.removeLast()
                        if acc.opStack.isEmpty {
                            throw EvaluationError.arityError
                        }
                    }
                    acc.opStack.removeLast()
                } else {
                    throw EvaluationError.invalidToken(token: type + " parathensis")
                }
            }
        }
        rpn = rpnExt.rpn + rpnExt.opStack.reversed().map(Token.operator)
    } else {
        rpn = tokens
    }

    let valStack: [Num] = try rpn.reduce(into: [Num]()) { (valStack, token) in
        switch token {
        case .value(let num):
            valStack.append(num)
        case .operator(let op):
            switch op.operands {
            case 1:
                guard let lhs = valStack.popLast() else {
                    throw EvaluationError.arityError
                }
                valStack.append(try op.f([lhs]))
            case 2:
                guard let rhs = valStack.popLast(), let lhs = valStack.popLast() else {
                    throw EvaluationError.arityError
                }
                valStack.append(try op.f([lhs, rhs]))
            default:
                throw EvaluationError.arityError
            }
        case .parathensis(let type):
            throw EvaluationError.invalidToken(token: type + " parathensis in evaluating part")
        }
    }

    guard let result = valStack.first, valStack.count == 1 else {
        throw EvaluationError.arityError
    }

    return result
}



var input = (readLine() ?? "0").components(separatedBy: .whitespaces) // some trobles with ")" if input by keyboard, but if cmd + v it is OK
let type = input.first == "--postfix" // unary only in special names
if input.first == "--postfix" || input.first == "--infix" {
    input.removeFirst()
}
let expression = input.reduce(into: "") { res, token in
    if res.isEmpty {
        res = "" + token
    } else {
        res = res + " " + token
    }
}
print(try eval(expression, type) as Int)

