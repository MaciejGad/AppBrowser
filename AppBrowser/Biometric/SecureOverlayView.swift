import SwiftUI

struct SecureOverlayView: View {
    @EnvironmentObject private var viewModel: BiometricViewModel
    
    var body: some View {
        ZStack {
            Color.white
                .edgesIgnoringSafeArea(.all)
            VStack(spacing: 30) {
                icon()
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 150)
                    .cornerRadius(10)
                Spacer()
                if viewModel.isLocked {
                    Image(systemName: "lock.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .foregroundColor(.blue)
                    Text("Odblokuj aplikację")
                        .font(.title)
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(.title2)
                            .foregroundColor(.red)
                    }
                    Spacer()
                    Button(action: authenticate) {
                        Text("Odblokuj")
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal, 40)
                }
            }
            .padding(.top, 50)
            .padding(.bottom, 20)
        }
    }
    
    func authenticate() {
        viewModel.authenticate()
    }
    
    private func icon() -> Image {
        if let appIcon = UIImage.appIcon {
            return Image(uiImage: appIcon)
        } else {
            return Image(systemName: "lock.fill")
        }
    }
}

struct SecureOverlayView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = BiometricViewModel(autoAuthentication: false)
        viewModel.errorMessage = "An error occured"
        return SecureOverlayView().environmentObject(viewModel)
    }
}

