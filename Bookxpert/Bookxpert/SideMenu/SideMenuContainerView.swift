import SwiftUI
import UIKit

struct SideMenuContainerView<ViewModel>: View where ViewModel: SideMenuViewModelProtocol {
    @ObservedObject var viewModel: ViewModel
    let onDismiss: () -> Void

    @State private var isMenuVisible = false

    var body: some View {
        ZStack(alignment: .leading) {
            // Background overlay
            Color.black.opacity(isMenuVisible ? 0.3 : 0)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }
                .animation(.easeInOut(duration: 0.3), value: isMenuVisible)

            // Side menu positioned from leading edge
            HStack(spacing: 0) {
                SideMenuView(
                    viewModel: viewModel
                )
                .offset(x: isMenuVisible ? 0 : -300)
                .animation(.easeInOut(duration: 0.3), value: isMenuVisible)

                Spacer()
            }
        }
        .onAppear {
            isMenuVisible = true
        }
        .onDisappear {
            isMenuVisible = false
        }
    }
}

