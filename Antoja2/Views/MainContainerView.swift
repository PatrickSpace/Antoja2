import SwiftUI

struct MainContainerView: View {
    @StateObject private var chatViewModel: ChatViewModel
    private let userID: String

    init(userID: String) {
        self.userID = userID
        _chatViewModel = StateObject(wrappedValue: ChatViewModel(userID: userID))
    }

    var body: some View {
        ChatView(viewModel: chatViewModel, userID: userID)
    }
}
