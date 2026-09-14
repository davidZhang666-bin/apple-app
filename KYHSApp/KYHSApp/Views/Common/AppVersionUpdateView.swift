import SwiftUI
import UIKit

/// A mandatory update screen. It deliberately has no close or cancel action.
struct AppVersionUpdateView: View {
    let versionInfo: AppVersionInfo

    private var appStoreURL: URL? {
        // Prefer a URL supplied by the API, then an Info.plist value so the
        // App Store product URL can be configured without another app build.
        let configuredURL = versionInfo.appStoreUrl
            ?? versionInfo.downloadUrl
            ?? (Bundle.main.object(forInfoDictionaryKey: "AppStoreURL") as? String)
        guard let configuredURL,
              !configuredURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            // The App Store product ID is not part of the version API contract.
            // Search by the app name as a usable fallback until AppStoreURL is configured.
            return URL(string: "https://apps.apple.com/cn/search?term=%E5%BA%B7%E6%BA%90%E5%8D%8E%E5%96%84")
        }
        return URL(string: configuredURL)
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Text("发现新版本")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(Color(hex: "222222"))
                    .padding(.top, 28)

                Text("版本 \(versionInfo.versionName ?? "")")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(hex: "0A9200"))
                    .padding(.top, 12)

                ScrollView {
                    Text(versionInfo.updateContent?.isEmpty == false ? versionInfo.updateContent! : "本次更新包含功能优化和问题修复")
                        .font(.system(size: 15))
                        .foregroundColor(Color(hex: "555555"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 22)
                        .padding(.vertical, 18)
                }
                .frame(maxHeight: 180)

                Button(action: openAppStore) {
                    Text("跳转更新")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(
                            LinearGradient(colors: [Color(hex: "0AB00A"), Color(hex: "0A9200")],
                                           startPoint: .leading, endPoint: .trailing)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 22)
            }
            .frame(maxWidth: 340)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.2), radius: 18)
        }
        .interactiveDismissDisabled(true)
    }

    private func openAppStore() {
        guard let url = appStoreURL else { return }
        UIApplication.shared.open(url)
    }
}
