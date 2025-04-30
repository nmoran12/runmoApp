//
//  LoginView.swift
//  Runr
//
//  Created by Noah Moran on 13/1/2025.
//

import SwiftUI
import Firebase
import FirebaseAuth

struct LoginView: View {
    @StateObject var viewModel = LoginViewModel()
    @EnvironmentObject var registrationViewModel: RegistrationViewModel

    @State private var email = ""
    @State private var password = ""

    var body: some View {
        NavigationStack{
            VStack{
                
                Spacer()
                
                // Logo Image
                Text("Runmo")
                    .font(.system(size: 40))
                    .fontWeight(.bold)
                
                // Text Fields
                // entering email
                VStack{
                    TextField("Enter your email", text: $viewModel.email)
                        .autocapitalization(.none)
                        .modifier(IGTextFieldModifier())
                    
                // entering password
                    SecureField("Enter your password", text: $viewModel.password)
                        .modifier(IGTextFieldModifier())
                }
                
                Button {
                    Task {
                        do {
                            try await viewModel.signIn()
                            
                            // AUTHORISATION REQUESTS FOR THE USER UPON LOGIN
                            // If signIn is successful, then ask for HealthKit authorization
                            HealthKitManager.shared.requestAuthorization { success, error in
                                if success {
                                    print("HealthKit authorization granted.")
                                } else {
                                    print("HealthKit authorization failed: \(error?.localizedDescription ?? "")")
                                }
                            }
                        } catch {
                            print("Login failed: \(error)")
                        }
                    }
                } label: {
                    Text("Login")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(width: 360, height: 44)
                        .background(Color(.systemBlue))
                        .cornerRadius(8)
                }
                .padding(.vertical)
                
                Spacer()
                
                Divider()
                
                NavigationLink {
                    AddEmailView()
                        .environmentObject(registrationViewModel)
                        .navigationBarBackButtonHidden(true)
                } label: {
                    HStack(spacing: 3){
                        Text("Don't have an account?")
                        
                        Text("Sign Up")
                            .fontWeight(.semibold)
                    }
                    .font(.footnote)
                }
                .padding(.vertical, 16)

            }
        }
    }
}


#Preview {
    LoginView()
}
