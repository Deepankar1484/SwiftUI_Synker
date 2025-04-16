//
//  ForgotPassword.swift
//  SwiftUISynker
//
//  Created by Dhruv Goyal on 16/04/25.
//

import Foundation
import FirebaseAuth
import SwiftUI

import SwiftUI
import FirebaseAuth

struct ForgotPasswordEmailView: View {
    @Environment(\.dismiss) var dismiss
    @State private var email = ""
    @State private var message: String?
    @State private var isSent = false

    var body: some View {
        VStack(spacing: 20) {
            Text("Reset Password")
                .font(.title)
                .padding(.top)

            TextField("Enter your email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.emailAddress)
                .autocapitalization(.none)

            if let message = message {
                Text(message)
                    .foregroundColor(isSent ? .green : .red)
                    .font(.caption)
            }

            Button("Send Reset Email") {
                sendResetEmail()
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)

            Button("Back to Login") {
                dismiss()
            }
            .font(.caption)
            .padding(.top, 10)
        }
        .padding()
    }

    func sendResetEmail() {
        guard email.contains("@") else {
            message = "Please enter a valid email"
            isSent = false
            return
        }

        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let error = error {
                message = error.localizedDescription
                isSent = false
            } else {
                message = "Password reset email sent!"
                isSent = true
            }
        }
    }
}
 
