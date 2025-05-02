//
//  SettingsViewModel.swift
//  TempMail
//
//  Created by Rishi Singh on 02/05/25.
//

import Foundation

class SettingsViewModel: ObservableObject {
    static var shared = SettingsViewModel()
    
    @Published var selectedSetting: SettingPage = .importPage
    @Published var navigationStack: [SettingPage] = [.importPage]
    @Published var currentPointer: Int = 0
    @Published var isNavigatingManually = true
    
    // Import Page
    @Published var selectedImportVersion: Int = 0
    
    var backButtonDisabled: Bool {
        currentPointer <= 0
    }
    
    var forwardBtnDisabled: Bool {
        currentPointer >= navigationStack.count - 1
    }
    
    func handleNavigationChange(_ oldValue: SettingPage, _ newValue: SettingPage) {
        guard isNavigatingManually else { return }

        if currentPointer == navigationStack.count - 1 {
            navigationStack.append(newValue)
            currentPointer += 1
        } else if navigationStack[currentPointer] != newValue {
            navigationStack = Array(navigationStack.prefix(upTo: currentPointer + 1))
            navigationStack.append(newValue)
            currentPointer += 1
        }
    }
    
    func goBack() {
        if currentPointer > 0 {
            currentPointer -= 1
            isNavigatingManually = false
            selectedSetting = navigationStack[currentPointer]
            DispatchQueue.main.async {
                self.isNavigatingManually = true
            }
        }
    }

    func goForward() {
        if currentPointer < navigationStack.count - 1 {
            currentPointer += 1
            isNavigatingManually = false
            selectedSetting = navigationStack[currentPointer]
            DispatchQueue.main.async {
                self.isNavigatingManually = true
            }
        }
    }
}
