import SwiftUI

struct BrowserToolbar: View {
    @EnvironmentObject private var viewModel: BrowserViewModel
    @EnvironmentObject private var safe: SafeBrowsingViewModel
    
    var body: some View {
        VStack(spacing: 5) {
            Text(viewModel.curentPath)
                .multilineTextAlignment(.trailing)
                .frame(minWidth: 100, maxWidth: .infinity)
                .padding(.top)
            HStack(spacing: 10) {
                Button(action: {
                    viewModel.goBack()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 24))
                }.disabled(!viewModel.canGoBack)
                
                Spacer()
                
                Button(action: {
                    viewModel.loadHome()
                }) {
                    Image(systemName: "house")
                        .font(.system(size: 24))
                }
                
                Spacer()
                
                Button(action: {
                    viewModel.reload()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 24))
                }
                
                Spacer()
                
                Button(action: {
                    viewModel.openInExternalBrowser()
                }) {
                    Image(systemName: "arrow.up.right.square")
                        .font(.system(size: 24))
                }
                
                Spacer()
                
                Button(action: {
                    viewModel.print()
                }) {
                    Image(systemName: "printer.filled.and.paper")
                        .font(.system(size: 24))
                }
            }.padding(.horizontal, 30)
        }
        .padding(.bottom, 15)
        .background(Color(UIColor.systemGray6))
    }
}
