import SwiftUI
import UIKit

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var username = ""
    @State private var password = ""
    @State private var isAgree = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var showServiceAgreement = false
    @State private var showPrivacyPolicy = false
    @State private var showProtocolAlert = false
    @State private var pendingLoginAction: (() -> Void)?
    @StateObject private var weChatManager = WeChatLoginManager.shared

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: "FFFFD4"), Color(hex: "D1FBD8")],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea(.container, edges: .top)

            VStack(spacing: 0) {
                Spacer().frame(height: 80)

                Image("login-logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 275, height: 76)
                    .padding(.leading, 24)

                Spacer().frame(height: 32)

                VStack(spacing: 0) {
                    Spacer().frame(height: 32)

                    // 账号输入
                    HStack(spacing: 12) {
                        Image(systemName: "person.fill")
                            .foregroundColor(.secondary)
                            .font(.system(size: 18))
                            .frame(width: 20)
                        TextField("请输入账号", text: $username)
                            .font(.system(size: 16))
                            .autocapitalization(.none)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(Color(hex: "F7F8FA"))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal, 24)

                    Spacer().frame(height: 14)

                    // 密码输入
                    HStack(spacing: 12) {
                        Image(systemName: "lock.fill")
                            .foregroundColor(.secondary)
                            .font(.system(size: 18))
                            .frame(width: 20)
                        SecureField("请输入密码", text: $password)
                            .font(.system(size: 16))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(Color(hex: "F7F8FA"))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal, 24)

                    Spacer().frame(height: 26)

                    // 登录按钮
                    Button(action: handleLogin) {
                        Group {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("登录")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                    }
                    .background(
                        LinearGradient(colors: [Color(hex: "0AB00A"), Color(hex: "0A9200")],
                                       startPoint: .leading, endPoint: .trailing)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 25))
                    .padding(.horizontal, 24)
                    .disabled(isLoading)

                    // 协议
                    HStack(spacing: 4) {
                        Spacer()
                        Button(action: { isAgree.toggle() }) {
                            Image(systemName: isAgree ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(isAgree ? Color(hex: "0A9200") : Color(hex: "CCCCCC"))
                                .font(.system(size: 16))
                        }
                        Text("我同意康源华善")
                            .font(.system(size: 11.5))
                            .foregroundColor(Color(hex: "999999"))
                        Button(action: { showServiceAgreement = true }) {
                            Text("《服务协议》")
                                .font(.system(size: 11.5))
                                .foregroundColor(Color(hex: "0A9200"))
                        }
                        Text("和")
                            .font(.system(size: 11.5))
                            .foregroundColor(Color(hex: "999999"))
                        Button(action: { showPrivacyPolicy = true }) {
                            Text("《隐私政策》")
                                .font(.system(size: 11.5))
                                .foregroundColor(Color(hex: "0A9200"))
                        }
                        Spacer()
                    }
                    .padding(.top, 18)

                    if weChatManager.isWeChatInstalled {
                        // 微信登录
                        Spacer().frame(height: 18)

                        Button(action: handleWeChatLogin) {
                            HStack(spacing: 8) {
                                if weChatManager.isLoggingIn {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "07C160")))
                                } else {
                                    Image("wechat-icon")
                                        .resizable()
                                        .renderingMode(.template)
                                        .foregroundColor(Color(hex: "07C160"))
                                        .frame(width: 18, height: 18)
                                    Text("微信登录")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(Color(hex: "666666"))
                                }
                            }
                            .frame(minWidth: 104)
                            .padding(.horizontal, 22)
                            .padding(.vertical, 10)
                            .background(Color(hex: "F7F8FA"))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .disabled(isLoading || weChatManager.isLoggingIn)
                    }

                    Spacer().frame(height: 32)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.white)
                .clipShape(TopRoundedRectangle(radius: 25))
                .shadow(color: .black.opacity(0.05), radius: 10, y: -5)
            }
        }
        .alert("提示", isPresented: $showError, actions: {
            Button("确定") { }
        }, message: {
            Text(errorMessage ?? "")
        })
        .alert("提示", isPresented: $showProtocolAlert, actions: {
            Button("取消", role: .cancel) { }
            Button("我同意") {
                isAgree = true
                pendingLoginAction?()
                pendingLoginAction = nil
            }
        }, message: {
            Text("请先同意《服务协议》和《隐私政策》")
        })
        .sheet(isPresented: $showServiceAgreement) {
            ServiceAgreementView()
        }
        .sheet(isPresented: $showPrivacyPolicy) {
            PrivacyPolicyView()
        }
        .onAppear {
            weChatManager.refreshWeChatInstallationStatus()
        }
        .onReceive(weChatManager.$errorMessage.compactMap { $0 }) { message in
            errorMessage = message
            showError = true
            weChatManager.errorMessage = nil
        }
    }

    private func handleLogin() {
        guard !username.isEmpty else {
            errorMessage = "请输入账号"
            showError = true
            return
        }
        guard !password.isEmpty else {
            errorMessage = "请输入密码"
            showError = true
            return
        }
        guard isAgree else {
            pendingLoginAction = doLogin
            showProtocolAlert = true
            return
        }
        doLogin()
    }

    private func doLogin() {
        isLoading = true
        Task {
            do {
                let body = ["userName": username, "password": password, "type": "店长"]
                let response: LoginResponse = try await NetworkService.shared.post("/sysUser/login", body: body)
                if let token = response.token, let userId = response.userId {
                    authManager.login(token: token, userId: userId)
                    await authManager.fetchUserInfo()
                } else {
                    errorMessage = "登录失败，请检查账号密码"
                    showError = true
                }
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
            isLoading = false
        }
    }

    private func handleWeChatLogin() {
        guard isAgree else {
            pendingLoginAction = doWeChatLogin
            showProtocolAlert = true
            return
        }
        doWeChatLogin()
    }

    private func doWeChatLogin() {
        weChatManager.requestLogin()
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}

// MARK: - Top Rounded Rectangle (iOS 15 compatible)

struct TopRoundedRectangle: Shape {
    let radius: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: radius))
        path.addArc(
            center: CGPoint(x: radius, y: radius),
            radius: radius,
            startAngle: .degrees(180),
            endAngle: .degrees(270),
            clockwise: false
        )
        path.addLine(to: CGPoint(x: rect.width - radius, y: 0))
        path.addArc(
            center: CGPoint(x: rect.width - radius, y: radius),
            radius: radius,
            startAngle: .degrees(270),
            endAngle: .degrees(0),
            clockwise: false
        )
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.closeSubpath()
        return path
    }
}
