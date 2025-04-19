//
//  ConnectionStatusView.swift
//  ChatApp
//
//  Created by madaozaku on 2025/04/18.
//
import SwiftUI

struct ConnectionStatusView: View {
    let errorMessage: String?
    let onConnect: () -> Void

    var body: some View {
        VStack {
            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .padding()
            }

            Button(action: onConnect) {
                Text("サーバーに接続")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemGray6))
    }
}
