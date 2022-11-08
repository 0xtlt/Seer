//
//  EmbededVideoView.swift
//  Seer
//
//  Created by Jacob Davis on 11/8/22.
//

import SwiftUI
import Foundation
import WebKit

#if os(iOS)
struct EmbededVideoView: UIViewRepresentable {
    
    let url: URL
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        let webview = WKWebView(frame: .zero, configuration: configuration)
        return webview
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        uiView.scrollView.isScrollEnabled = false
        print(url.absoluteString)
        uiView.load(URLRequest(url: url))
    }
}
#elseif os(macOS)
struct EmbededVideoView: NSViewRepresentable {

    let url: URL

    func makeNSView(context: Context) -> WKWebView {
        let view = WKWebView()
        view.autoresizingMask = [.width, .height]
        return view
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        guard context.coordinator.needsToLoadURL else { return }
        nsView.load(URLRequest(url: url))
    }

    func makeCoordinator() -> VideoEmbedView.Coordinator {
        Coordinator()
    }

    class Coordinator {
        var needsToLoadURL = true
    }
    
}
#endif

struct EmbededVideoView_Previews: PreviewProvider {
    static var previews: some View {
        EmbededVideoView(url: URL(string: "https://youtu.be/zK_awQZRaW4")!)
            .frame(height: 200)
    }
}
