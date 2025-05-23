//
//  ProfileView.swift
//  AtomicWill
//
//  Created by Caner Kucuk on 5/23/25.
//
// ProfileView.swift
import SwiftUI

struct ProfileView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Image(systemName: "person.fill.viewfinder")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
                    .padding(.bottom)
                Text("Profile Page")
                    .font(.largeTitle)
                Text("User settings and information will go here.")
                    .font(.title3)
                    .foregroundColor(.gray)
            }
            .navigationTitle("Profile")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
    }
}

#Preview {
    ProfileView()
}
