import UIKit

class PrintHelper: ObservableObject {

    @MainActor
    func print(formatter: UIViewPrintFormatter, pageName: String) {
        let printInfo = UIPrintInfo(dictionary: nil)
        printInfo.jobName = pageName
        printInfo.outputType = .general
        let printController = UIPrintInteractionController.shared
        printController.printInfo = printInfo
        printController.showsNumberOfCopies = false
        printController.printFormatter = formatter
        printController.present(animated: true, completionHandler: nil)
    }
}
