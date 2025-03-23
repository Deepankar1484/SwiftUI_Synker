//
//  SwiftUISynkerApp.swift
//  SwiftUISynker
//
//  Created by Deepankar Garg on 19/03/25.
//

import SwiftUI

@main
struct SwiftUISynkerApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack{
                AuthenticationView()
            }
        }
    }
}
