//
//  UserListView.swift
//  ChatApp
//
//  Created by madaozaku on 2025/04/18.
//
import SwiftUI

struct UserListView: View {
    let users: [User]
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            List {
                ForEach(users) { user in
                    HStack {
                        Text(user.name)
                        Spacer()
                        Circle()
                            .frame(width: 10, height: 10)
                            .foregroundColor(user.isOnline ? .green : .gray)
                    }
                }
            }
            .navigationTitle("オンラインユーザー (\(users.count))")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}
