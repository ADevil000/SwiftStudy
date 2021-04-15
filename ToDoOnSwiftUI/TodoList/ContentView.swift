import SwiftUI

struct TodoListView: View {
    @StateObject var viewModel = TodoListViewModel()
    
    var body: some View {
        List {
            HStack {
                TextField("", text: $viewModel.adderText)
                Button("+", action: {
                    if !viewModel.adderText.isEmpty {
                        viewModel.allPlans.append( TodoListViewModel.PlanModel( text: viewModel.adderText))
                        viewModel.adderText = ""
                    }
                })
            }
            ForEach(viewModel.allPlans) { plan in
                PlanView(plan: plan)
            }
        }
    }
}

struct PlanView: View {
    @StateObject var plan: TodoListViewModel.PlanModel
    
    var body: some View {
        Text(plan.text).strikethrough(plan.isCompleted, color: .black).foregroundColor(plan.isCompleted ? .gray : .black).onTapGesture {
            self.plan.isCompleted.toggle()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        TodoListView()
    }
}

