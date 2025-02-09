import SwiftUI

struct ConfigurationErrorView: View {
    var title: String
    var message: String

    var body: some View {
        VStack(spacing: 25) {
            Image(systemName: "xmark.octagon.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(.red)

            Text(title)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            Text(message)
                .font(.title2)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .foregroundColor(.secondary)

        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .ignoresSafeArea()
    }
}

struct ConfigurationErrorView_Previews: PreviewProvider {
    static var previews: some View {
        ConfigurationErrorView(
            title: "App Startup Error",
            message: "Something went wrong. Please check your internet connection and try again.")
    }
}

