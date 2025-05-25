import SwiftUI

struct ShowPhotoSourceOptionsView: View {
    let onSelection: (PhotoSourceOption) -> Void
    let onCancel: () -> Void
    @State private var showContent = false
    
    var body: some View {
        ZStack {
            Rectangle()
               .fill(Color.black.opacity(showContent ? 0.4 : 0))
               .ignoresSafeArea(.all)
               .allowsHitTesting(true)
               .onTapGesture {
                   dismissView()
               }
           .animation(.easeInOut(duration: 0.2), value: showContent)
            
            VStack {
                Spacer()
                
                VStack(spacing: 0) {
                    Text("Select Photo Source")
                        .font(.headline)
                        .foregroundColor(.black)
                        .padding(.top, 20)
                        .padding(.horizontal, 20)
                    
                    Divider()
                        .padding(.top, 15)
                    
                    VStack(spacing: 0) {
                        ForEach(Array(PhotoSourceOption.allCases.enumerated()), id: \.offset) { index, option in
                            PhotoSourceOptionRow(
                                option: option,
                                onTap: {
                                    handleSelection(option)
                                }
                            )
                            
                            if index < PhotoSourceOption.allCases.count - 1 {
                                Divider()
                                    .padding(.leading, 20)
                            }
                        }
                    }
                    
                    VStack(spacing: 0) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 8)
                        
                        Button(action: dismissView) {
                            HStack {
                                Spacer()
                                Text("Cancel")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.red)
                                Spacer()
                            }
                            .padding(.vertical, 16)
                            .background(Color.white)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                .padding(.horizontal, 20)
                .scaleEffect(showContent ? 1.0 : 0.9)
                .opacity(showContent ? 1.0 : 0.0)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showContent)
                
                Spacer()
            }
        }
        .onAppear {
            showContent = true
        }
    }
    
    private func handleSelection(_ option: PhotoSourceOption) {
        withAnimation(.easeInOut(duration: 0.2)) {
            showContent = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            onSelection(option)
        }
    }
    
    private func dismissView() {
        withAnimation(.easeInOut(duration: 0.2)) {
            showContent = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            onCancel()
        }
    }
}

struct PhotoSourceOptionRow: View {
    let option: PhotoSourceOption
    let onTap: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 15) {
                Image(systemName: option.iconName)
                    .font(.system(size: 20))
                    .foregroundColor(.blue)
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(option.title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.black)
                    
                    if let description = option.description {
                        Text(description)
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.gray.opacity(0.6))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                Color.gray.opacity(isPressed ? 0.1 : 0.0)
                    .animation(.easeInOut(duration: 0.1), value: isPressed)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

extension PhotoSourceOption {
    var iconName: String {
        switch self {
        case .camera:
            return "camera.fill"
        case .photoLibrary:
            return "photo.on.rectangle"
        }
    }
    
    var title: String {
        switch self {
        case .camera:
            return "Camera"
        case .photoLibrary:
            return "Photo Library"
        }
    }
    
    var description: String? {
        switch self {
        case .camera:
            return "Take a new photo"
        case .photoLibrary:
            return "Choose from existing photos"
        }
    }
}
