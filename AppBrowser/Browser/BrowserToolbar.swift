import SwiftUI

struct BrowserToolbar: View {
    @EnvironmentObject private var viewModel: BrowserViewModel
    @EnvironmentObject private var safe: SafeBrowsingViewModel

    var body: some View {
        VStack(spacing: 5) {
            if viewModel.showPath {
                Text(viewModel.curentPath)
                    .multilineTextAlignment(.trailing)
                    .frame(minWidth: 100, maxWidth: .infinity)
            }
            HStack(spacing: 10) {
                let lastElement = viewModel.toolbarItems.last
                ForEach(viewModel.toolbarItems) { item in
                    Button(action: {
                        viewModel.handle(command: item)
                    }) {
                        Image(systemName: item.iconName())
                            .font(.system(size: 24))
                    }.disabled(
                        item == .goBack && !viewModel.canGoBack
                    )
                    if item != lastElement {
                        Spacer()
                    }
                }
            }.padding(.horizontal, 30)
        }
        .padding(.top, 10)
        .padding(.bottom, 15)
        .background(Color(UIColor.systemGray6))
    }
}
