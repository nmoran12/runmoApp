//
//  RunningProgramLandingView.swift
//  Runr
//
//  Created by Noah Moran on 10/4/2025.
//

import SwiftUI

struct RunningProgramLandingView: View {
    @StateObject var viewModel = NewRunningProgramViewModel()
    // Retrieve the current user's username from your auth service.
    var currentUsername: String = AuthService.shared.currentUser?.username ?? "UnknownUser"

    // Debug flag: Set to true to force showing the selection view even if there's an active program.
    // You can later remove this or only use it in DEBUG builds.
    //#if DEBUG
    //let forceShowSelectionView = true
    //#else
    let forceShowSelectionView = false
    //#endif

    var body: some View {
        Group {
            if viewModel.hasActiveProgram && !forceShowSelectionView {
                // Use the updated template if available; otherwise, fall back to beginner18WeekProgram.
                NewRunningProgramContentView(plan: viewModel.currentProgram ?? beginner18WeekProgram)
                    .environmentObject(viewModel)
            } else {
                NewRunningProgramSelectionView()
                    .environmentObject(viewModel)
            }

        }
        .onAppear {
            Task {
                // Only check for an active running program when debugging is not forcing the selection view.
                if !forceShowSelectionView {
                    await viewModel.checkActiveUserProgram(for: currentUsername)
                    if viewModel.hasActiveProgram {
                        await viewModel.loadActiveUserProgram(for: currentUsername)
                    }
                }
            }
        }
    }
}

struct RunningProgramLandingView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            RunningProgramLandingView()
        }
    }
}
