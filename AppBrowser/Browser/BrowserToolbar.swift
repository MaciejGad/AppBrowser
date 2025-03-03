import SwiftUI

struct BrowserToolbar: ToolbarContent {
    @EnvironmentObject private var viewModel: BrowserViewModel
    @EnvironmentObject private var safe: SafeBrowsingViewModel

    var body: some ToolbarContent {
        ToolbarItem(placement: .bottomBar) {
            VStack(spacing: 5) {
                HStack(spacing: 10) {
                    let lastElement = viewModel.toolbarItems.last
                    ForEach(viewModel.toolbarItems) { item in
                        Button(action: {
                            viewModel.handle(command: item)
                        }) {
                            Image(systemName: item.iconName())
                                .font(.system(size: 20))
                        }.disabled(
                            item == .goBack && !viewModel.canGoBack
                        )
                        if item != lastElement {
                            Spacer()
                        }
                    }
                }
            }
        }
    }
}
