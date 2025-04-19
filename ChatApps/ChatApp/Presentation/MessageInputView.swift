//
//  MessageInputView.swift
//  ChatApp
//
//  Created by madaozaku on 2025/04/18.
//
import SwiftUI

struct MessageInputView: View {
    @Binding var text: String
    let isConnected: Bool
    let onSend: () -> Void

    var body: some View {
        HStack {
            TextField("メッセージを入力", text: $text)
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(20)
                .disabled(!isConnected)
                .submitLabel(.send)
                .onSubmit(onSend)

            Button(action: onSend) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title)
                    .foregroundColor(isConnected ? .blue : .gray)
            }
            .disabled(!isConnected || text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .padding(.trailing, 8)
        }
        .padding(8)
        .background(Color(.systemBackground))
        .shadow(radius: 1)
    }
}
