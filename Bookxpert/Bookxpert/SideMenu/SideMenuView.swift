import SwiftUI

struct SideMenuView<ViewModel>: View where ViewModel: SideMenuViewModelProtocol {
    @ObservedObject var viewModel: ViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            userHeaderView
            menuItemsView
            
            Spacer()
        }
        .frame(width: 280)
        .background(Color.white)
        .shadow(color: .black.opacity(0.2), radius: 5, x: 2, y: 0)
    }
    
    @ViewBuilder
    private var userHeaderView: some View {
        VStack(spacing: 12) {
            profileImageButton()
            
            Text(viewModel.userName)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.horizontal, 20)
        .padding(.vertical, 40)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
    
    @ViewBuilder
    private func profileImageContent() -> some View {
        if let profileImage = viewModel.profileImage {
            Image(uiImage: profileImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 80, height: 80)
                .clipShape(Circle())
        } else {
            Circle()
                .fill(Color.white.opacity(0.2))
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.white.opacity(0.8))
                )
        }
    }
    
    @ViewBuilder
    private func profileImageButton() -> some View {
        Button(action: {
            viewModel.handleProfilePhotoTap()
        }) {
            ZStack {
                profileImageContent()
                
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Circle()
                            .fill(Color.black.opacity(0.7))
                            .frame(width: 24, height: 24)
                            .overlay(
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white)
                            )
                            .offset(x: -8, y: -8)
                    }
                }
            }
            .frame(width: 80, height: 80)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    @ViewBuilder
    private var menuItemsView: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(SideMenuItem.allCases, id: \.self) { item in
                MenuItemRow(
                    item: item,
                    isLoading: viewModel.isLoading && item == .logout,
                    onTap: {
                        viewModel.handleMenuItemTap(item)
                    }
                )
                
                if item != SideMenuItem.allCases.last {
                    Divider()
                        .padding(.leading, 60)
                }
            }
        }
        .background(Color.white)
    }
}

struct MenuItemRow: View {
    let item: SideMenuItem
    let isLoading: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 15) {
                Image(systemName: item.icon)
                    .font(.system(size: 18))
                    .foregroundColor(item.isDestructive ? .red : .gray)
                    .frame(width: 24, height: 24)
                
                Text(item.rawValue)
                    .font(.system(size: 16))
                    .foregroundColor(item.isDestructive ? .red : .black)
                
                Spacer()
                
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(.gray.opacity(0.6))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.white)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isLoading)
    }
}
