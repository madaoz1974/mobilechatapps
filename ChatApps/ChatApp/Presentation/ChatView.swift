//
//  ChatView.swift
//  ChatApp
//
//  Created by 車田巡 on 2025/04/18.
//

// MARK: - Views
import SwiftUI

struct ChatView: View {
    // @State instead of @StateObject for Observable classes
    @State private var viewModel = ChatViewModel()
    @State private var showingUserList = false

    var body: some View {
        NavigationView {
            VStack {
                // Connection status
                if !viewModel.isConnected {
                    ConnectionStatusView(
                        errorMessage: viewModel.errorMessage,
                        onConnect: viewModel.connect
                    )
                }

                // Chat messages
                ScrollViewReader { scrollProxy in
                    ScrollView {
                        LazyVStack {
                            ForEach(viewModel.messageGroups().indices, id: \.self) { groupIndex in
                                let group = viewModel.messageGroups()[groupIndex]
                                MessageGroupView(messageGroup: group, users: viewModel.users)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .onChange(of: viewModel.messages.count) { _, _ in
                        // Scroll to bottom when new messages arrive
                        if let lastGroup = viewModel.messageGroups().indices.last {
                            withAnimation {
                                scrollProxy.scrollTo(lastGroup, anchor: .bottom)
                            }
                        }
                    }
                }

                // Message input
                MessageInputView(
                    text: $viewModel.newMessageText,
                    isConnected: viewModel.isConnected,
                    onSend: viewModel.sendMessage
                )
            }
            .navigationTitle("チャット")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingUserList.toggle() }) {
                        Label("ユーザー一覧", systemImage: "person.3")
                    }
                }

                ToolbarItem(placement: .navigationBarLeading) {
                    if viewModel.isConnected {
                        Button(action: viewModel.disconnect) {
                            Text("切断")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingUserList) {
                UserListView(users: viewModel.users)
            }
            .onAppear {
                viewModel.connect()
            }
            .onDisappear {
                viewModel.disconnect()
            }
        }
    }
}
