//
//  initialOnboardView.swift
//  Runr
//
//  Created by Noah Moran on 5/5/2025.
//

import SwiftUI

struct InitialOnboardView: View {
    /// Called when the user taps “Get Started”
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // 🎽 Icon + Title
            Image(systemName: "figure.run.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .foregroundColor(.blue)

            Text("Welcome to Runr!")
                .font(.largeTitle).bold()

            // Description
            Text("""
            We’ll build a personalized running plan just for you. \
            First you’ll pick your experience level, then tell us your age and gender, \
            so we can tailor every workout to your goals.
            """)
            .font(.body)
            .multilineTextAlignment(.center)
            .padding(.horizontal)

            Spacer()

            // Continue button
            Button("Get Started") {
                onContinue()
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(10)
            .padding(.horizontal)
            .padding(.bottom, 16)  // adjust for home indicator

        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .navigationBarHidden(true)
    }
}

struct InitialOnboardView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            InitialOnboardView(onContinue: { })
        }
    }
}
