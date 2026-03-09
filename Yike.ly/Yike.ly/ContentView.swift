import SwiftUI

struct ContentView: View {
    @StateObject private var session = UserSession()

    var body: some View {
        Group {
            if session.isLoggedIn {
                MapView()
                    .environmentObject(session)
            } else {
                LoginView()
                    .environmentObject(session)
            }
        }
        .animation(.easeInOut, value: session.isLoggedIn)
    }
}

#Preview {
    ContentView()
}
