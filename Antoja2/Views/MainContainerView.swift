import SwiftUI

struct MainContainerView: View {
    @StateObject private var chatViewModel: ChatViewModel

    init(userID: String) {
        _chatViewModel = StateObject(wrappedValue: ChatViewModel(userID: userID))
    }

    var body: some View {
        ChatView(viewModel: chatViewModel)
    }
}
