import SwiftUI

@Observable
final class TabBarVisibility {
    private(set) var isHidden = false
    private var suppressionCount = 0

    func suppressTabBar() {
        suppressionCount += 1
        isHidden = suppressionCount > 0
    }

    func restoreTabBar() {
        suppressionCount = max(0, suppressionCount - 1)
        isHidden = suppressionCount > 0
    }
}
