//
//  PrivacyPolicyView.swift
//  Runr
//
//  Created by Noah Moran on 20/3/2025.
//

import SwiftUI

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            Text("Your Privacy Policy content goes here...")
            // you have a privacy policy on "Termly"
            // https://app.termly.io/dashboard/website/239a7f06-01d5-4183-9906-b92afc5c71cc/privacy-policy
                .padding()
        }
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
    }
}


#Preview {
    PrivacyPolicyView()
}
