import SwiftUI

class TodoListViewModel: ObservableObject {
    static var id = 0
    @Published var adderText = ""
    @Published var allPlans: [PlanModel] = []

    class PlanModel: Identifiable, ObservableObject {
        var id: String = UUID().uuidString
        var text: String
        @Published var isCompleted = false
        
        init(text: String) {
            self.text = text
        }
    }
}
