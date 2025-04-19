//
//  MessageBubbleView.swift
//  ChatApp
//
//  Created by madaozaku on 2025/04/18.
//
import SwiftUI

struct MessageBubbleView: View {
    let message: Message

    var body: some View {
        HStack {
            if message.isFromCurrentUser {
                Spacer()
                Text(message.content)
                    .padding(10)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(16)
                    .contextMenu {
                        Button(action: {
                            UIPasteboard.general.string = message.content
                        }) {
                            Label("コピー", systemImage: "doc.on.doc")
                        }
                    }
            } else {
                Text(message.content)
                    .padding(10)
                    .background(Color(.systemGray5))
                    .foregroundColor(.primary)
                    .cornerRadius(16)
                    .contextMenu {
                        Button(action: {
                            UIPasteboard.general.string = message.content
                        }) {
                            Label("コピー", systemImage: "doc.on.doc")
                        }
                    }
                Spacer()
            }
        }
    }
}
