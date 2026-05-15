import SwiftUI

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

    var body: some View {
        ZStack {
            // Background gradient matching original
            LinearGradient(colors: [Color(hex: "FFFFD4"), Color(hex: "D1FBD8")],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack {
                Spacer().frame(height: 80)

                // Logo
                if UIImage(named: "login-logo") != nil {
                    Image("login-logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 275, height: 76)
                        .padding(.leading, 25)
                } else {
                    Text("康源华善")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Color(hex: "0A9200"))
                }

                Spacer().frame(height: 34)

                // White card
                VStack(spacing: 0) {
                    // Form
                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("账号")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            TextField("请输入账号", text: $username)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .autocapitalization(.none)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("密码")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            SecureField("请输入密码", text: $password)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }

                        Button(action: handleLogin) {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 48)
                            } else {
                                Text("登录")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 48)
                            }
                        }
                        .background(Color(hex: "0A9200"))
                        .cornerRadius(10)
                        .disabled(isLoading)
                    }
                    .padding(.horizontal, 25)

                    // Agreement
                    HStack(spacing: 4) {
                        Button(action: { isAgree.toggle() }) {
                            Image(systemName: isAgree ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(isAgree ? Color(hex: "0A9200") : .gray)
                                .font(.title3)
                        }
                        HStack(spacing: 2) {
                            Text("我同意康源华善")
                                .font(.caption)
                            Button(action: { showServiceAgreement = true }) {
                                Text("《服务协议》")
                                    .font(.caption)
                                    .foregroundColor(Color(hex: "0A9200"))
                            }
                            Text("和")
                                .font(.caption)
                            Button(action: { showPrivacyPolicy = true }) {
                                Text("《隐私政策》")
                                    .font(.caption)
                                    .foregroundColor(Color(hex: "0A9200"))
                            }
                        }
                        Spacer()
                    }
                    .padding(.top, 16)
                    .padding(.horizontal, 25)

                    Spacer().frame(height: 30)
                }
                .background(Color.white)
                .cornerRadius(25, corners: [.topLeft, .topRight])
                .frame(maxHeight: .infinity)
            }
        }
        .alert("提示", isPresented: $showError, actions: {
            Button("确定") { }
        }, message: {
            Text(errorMessage ?? "")
        })
        .sheet(isPresented: $showServiceAgreement) {
            ServiceAgreementView()
        }
        .sheet(isPresented: $showPrivacyPolicy) {
            PrivacyPolicyView()
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
            errorMessage = "请先同意《用户协议》和《隐私协议》"
            showError = true
            return
        }

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
}

// MARK: - Rounded Corner Helper

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCornerShape(radius: radius, corners: corners))
    }
}

struct RoundedCornerShape: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let tl = CGPoint(x: rect.minX, y: rect.minY)
        let tr = CGPoint(x: rect.maxX, y: rect.minY)
        let bl = CGPoint(x: rect.minX, y: rect.maxY)
        let br = CGPoint(x: rect.maxX, y: rect.maxY)

        if corners.contains(.topLeft) {
            path.move(to: CGPoint(x: tl.x + radius, y: tl.y))
        } else {
            path.move(to: tl)
        }

        if corners.contains(.topRight) {
            path.addLine(to: CGPoint(x: tr.x - radius, y: tr.y))
            path.addArc(center: CGPoint(x: tr.x - radius, y: tr.y + radius), radius: radius, startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)
        } else {
            path.addLine(to: tr)
        }

        if corners.contains(.bottomRight) {
            path.addLine(to: CGPoint(x: br.x, y: br.y - radius))
            path.addArc(center: CGPoint(x: br.x - radius, y: br.y - radius), radius: radius, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
        } else {
            path.addLine(to: br)
        }

        if corners.contains(.bottomLeft) {
            path.addLine(to: CGPoint(x: bl.x + radius, y: bl.y))
            path.addArc(center: CGPoint(x: bl.x + radius, y: bl.y - radius), radius: radius, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
        } else {
            path.addLine(to: bl)
        }

        if corners.contains(.topLeft) {
            path.addLine(to: CGPoint(x: tl.x, y: tl.y + radius))
            path.addArc(center: CGPoint(x: tl.x + radius, y: tl.y + radius), radius: radius, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
        } else {
            path.addLine(to: tl)
        }

        path.closeSubpath()
        return path
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
