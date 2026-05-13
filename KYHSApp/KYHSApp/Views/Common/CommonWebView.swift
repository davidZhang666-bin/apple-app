import SwiftUI
import WebKit

struct CommonWebView: View {
    let urlString: String

    var body: some View {
        if let url = URL(string: urlString) {
            WebView(url: url)
        } else {
            Text("无效的链接")
                .foregroundColor(.secondary)
        }
    }
}
