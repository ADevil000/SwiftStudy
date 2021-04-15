import Foundation

enum Suit : CustomStringConvertible, CaseIterable {
    case Hearts
    case Diamonds
    case Clubs
    case Spades
    var description: String {
        switch self {
        case .Hearts: return "Hearts"
        case .Diamonds: return "Diamonds"
        case .Spades: return "Spades"
        case .Clubs: return "Clubs"
        }
    }
}

enum Letter : CustomStringConvertible, CaseIterable {
    case J
    case Q
    case K
    case A
    var description: String {
        switch self {
        case .A:
            return "A"
        case .J:
            return "J"
        case .K:
            return "K"
        case .Q:
            return "Q"
        }
    }
}

enum  Mean : CustomStringConvertible {
    case num(Int)
    case letter(Letter)
    var description: String {
        switch self {
        case .num(let valueNum):
            return "\(valueNum)"
        case .letter(let valueLetter):
            return "\(valueLetter)"
        }
    }
}

struct CardDeck {
    var cards : [(Suit, Mean)]
    
    init() {
        cards = []
        for suit in Suit.allCases {
            for mean in 2...10 {
                cards.append((suit, Mean.num(mean)))
            }
        }
        for suit in Suit.allCases {
            for mean in Letter.allCases {
                cards.append((suit, Mean.letter(mean)))
            }
        }
        cards.shuffle()
    }
    
    init(_ deck : [(Suit, Mean)]) {
        cards = deck
    }
}

class Hand {
    let rulesJQK = [Letter.K : 10, Letter.Q : 10, Letter.J : 10]
    var acesWith11 = 0
    var costA : Int = 11
    
    var cards : [(Suit, Mean)] = []
    var total : Int = 0
    
    func take(card : (Suit, Mean)) {
        self.cards.append(card)
        switch card.1 {
        case .num(let value):
            total += value
        case .letter(let rule):
            total += rulesJQK[rule] ?? costA
            if costA == 11 && rule == Letter.A {
                acesWith11 += 1
            }
        }
        if total > 21 {
            total -= acesWith11 * 10
            acesWith11 = 0
            costA = 1
        }
    }
    
    init(_ card : (Suit, Mean)) {
        self.cards.append(card)
        switch card.1 {
        case .num(let value):
            total += value
        case .letter(let rule):
            total += rulesJQK[rule] ?? costA
            if rule == Letter.A {
                acesWith11 += 1
            }
        }
    }
    
    init(_ cards : ((Suit, Mean), (Suit, Mean))) {
        self.cards.append(cards.0)
        switch cards.0.1 {
        case .num(let value):
            total += value
        case .letter(let rule):
            total += rulesJQK[rule] ?? costA
            if rule == Letter.A {
                acesWith11 += 1
            }
        }
        self.cards.append(cards.1)
        switch cards.1.1 {
        case .num(let value):
            total += value
        case .letter(let rule):
            total += rulesJQK[rule] ?? costA
            if rule == Letter.A {
                acesWith11 += 1
            }
        }
        if total > 21 {
            costA = 1
            total -= acesWith11 * 10
            acesWith11 = 0
        }
    }
}

enum Stage {
    case win, lose, draw, play
}

class Dealer { // like a game
    var dealerHand, playerHand : Hand
    var deck : CardDeck
    var result : Stage = .play // -1 : play, 0 : player won, 1 : player lost, 2 : draw
    
    init() {
        deck = CardDeck()
        playerHand = Hand((deck.cards.removeLast(), deck.cards.removeLast()))
        dealerHand = Hand(deck.cards.removeLast())
        if (playerHand.total == 21) {
            print("PLayer win with BlackJack")
            result = .win
        }
    }
    
    init(deck : [(Suit, Mean)], playerHand : ((Suit, Mean), (Suit, Mean))) {
        self.deck = CardDeck(deck)
        self.playerHand = Hand(playerHand)
        self.dealerHand = Hand(self.deck.cards.removeLast())
        if (self.playerHand.total == 21) {
            print("PLayer win with BlackJack")
            result = .win
        }
    }
    
    func show() -> Void {
        switch result {
        case .win:
            print("Player win with \(playerHand.total) versus dealer's \(dealerHand.total)")
        case .lose:
            print("Player lose with \(playerHand.total) versus dealer's \(dealerHand.total)")
        case .draw:
            print("DRAW with \(playerHand.total)")
        case .play:
            print("Be patient, you are playing. You have \(playerHand.total)")
        }
        print("Player's cards: ", playerHand.cards)
        print("Dealer's cards: ", dealerHand.cards)
    }
    
    deinit {
        
    }
    
    func give() {
        if deck.cards.isEmpty {
            deck = CardDeck()
        }
        playerHand.take(card: deck.cards.removeLast())
        let res = playerHand.total
        switch res {
        case ..<21:
            print("After player took he has \(res)")
        case 21:
            result = .win
        default:
            result = .lose
        }
    }
    
    func pass() {
        while dealerHand.total < 17 {
            if deck.cards.isEmpty {
                deck = CardDeck()
            }
            dealerHand.take(card: deck.cards.removeLast())
        }
        if (dealerHand.total > 21 || dealerHand.total < playerHand.total) {
            result = .win
        } else if (dealerHand.total == playerHand.total) {
            result = .draw
        } else {
            result = .lose
        }
    }
    
    var isPlay: Bool {
        return result == .play
    }
    
}

//let dealer = Dealer(deck : Array(repeating: (Suit.Clubs, Mean.letter(.A)), count: 50), playerHand: ((Suit.Clubs, Mean.letter(.A)), (Suit.Clubs, Mean.letter(.A))))
let dealer = Dealer()
while dealer.isPlay {
    print(dealer.playerHand.cards)
    print("Input 'take' or 'pass'")
    let input = readLine()
    if input == "take" {
        dealer.give()
    } else if input == "pass" {
        dealer.pass()
    } else {
        print("You should input 'take' or 'pass'. Try again")
    }
}
dealer.show()
