import SwiftUI
import UIKit

extension View {
    /// 兼容 iOS 15 的下拉刷新：iOS 16+ 走原生 `.refreshable`，iOS 15 通过
    /// 反射底层 `UIScrollView` 挂 `UIRefreshControl`（`.refreshable` 在 iOS 15
    /// 只对 `List` 生效，`ScrollView` 不响应）。
    func compatRefreshable(tint: UIColor = .white,
                           action: @escaping @Sendable () async -> Void) -> some View {
        modifier(CompatRefreshableModifier(tint: tint, action: action))
    }
}

private struct CompatRefreshableModifier: ViewModifier {
    let tint: UIColor
    let action: @Sendable () async -> Void

    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            content
                .tint(Color(uiColor: tint))
                .refreshable { await action() }
        } else {
            content.background(
                ScrollViewRefresher(tint: tint, action: action)
                    .frame(width: 0, height: 0)
            )
        }
    }
}

private struct ScrollViewRefresher: UIViewRepresentable {
    let tint: UIColor
    let action: @Sendable () async -> Void

    func makeUIView(context: Context) -> UIView {
        let v = UIView()
        DispatchQueue.main.async {
            attachIfNeeded(from: v, context: context)
        }
        return v
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.action = action
        DispatchQueue.main.async {
            attachIfNeeded(from: uiView, context: context)
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(action: action) }

    private func attachIfNeeded(from view: UIView, context: Context) {
        if let existing = context.coordinator.scrollView,
           existing.refreshControl != nil {
            return
        }
        guard let scrollView = findScrollView(from: view) else { return }
        let control = UIRefreshControl()
        control.tintColor = tint
        control.addTarget(context.coordinator,
                          action: #selector(Coordinator.onPull(_:)),
                          for: .valueChanged)
        scrollView.refreshControl = control
        context.coordinator.scrollView = scrollView
        context.coordinator.refreshControl = control
    }

    private func findScrollView(from view: UIView) -> UIScrollView? {
        var node: UIView? = view
        while let n = node {
            for sibling in (n.superview?.subviews ?? []) {
                if let sv = firstScrollView(in: sibling) { return sv }
            }
            node = n.superview
        }
        return nil
    }

    private func firstScrollView(in view: UIView) -> UIScrollView? {
        if let sv = view as? UIScrollView { return sv }
        for sub in view.subviews {
            if let sv = firstScrollView(in: sub) { return sv }
        }
        return nil
    }

    final class Coordinator: NSObject {
        var action: @Sendable () async -> Void
        weak var scrollView: UIScrollView?
        weak var refreshControl: UIRefreshControl?

        init(action: @escaping @Sendable () async -> Void) {
            self.action = action
        }

        @objc func onPull(_ sender: UIRefreshControl) {
            let work = action
            Task { @MainActor in
                await work()
                sender.endRefreshing()
            }
        }
    }
}
