import SwiftUI
import UIKit
import WebKit

/// O app é o mesmo index.html do PWA, empacotado dentro do .ipa.
///
/// Os arquivos são servidos por um esquema próprio (gestor://app/...) em vez de
/// file://. Com uma origem de verdade, o IndexedDB e o localStorage ficam
/// guardados no aparelho entre uma abertura e outra — em file:// o WebKit trata
/// cada carga como origem opaca e os dados podem sumir.
struct AppWebView: UIViewRepresentable {
    static let esquema = "gestor"

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .default()
        config.setURLSchemeHandler(context.coordinator, forURLScheme: Self.esquema)
        config.userContentController.add(context.coordinator, name: "salvar")

        let web = WKWebView(frame: .zero, configuration: config)
        web.isOpaque = false
        web.backgroundColor = .fundoDoApp
        web.scrollView.backgroundColor = .fundoDoApp
        web.scrollView.contentInsetAdjustmentBehavior = .never
        web.allowsBackForwardNavigationGestures = false
        context.coordinator.webView = web

        if let url = URL(string: "\(Self.esquema)://app/index.html") {
            web.load(URLRequest(url: url))
        }
        return web
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    final class Coordinator: NSObject, WKURLSchemeHandler, WKScriptMessageHandler {
        weak var webView: WKWebView?

        private var raiz: URL? {
            Bundle.main.resourceURL?.appendingPathComponent("www", isDirectory: true)
        }

        // MARK: servidor interno

        func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
            guard let url = urlSchemeTask.request.url, let raiz else {
                urlSchemeTask.didFailWithError(URLError(.badURL)); return
            }
            var caminho = url.path
            if caminho.isEmpty || caminho == "/" { caminho = "/index.html" }
            let arquivo = raiz.appendingPathComponent(String(caminho.dropFirst()))
            // nunca sair da pasta www
            guard arquivo.standardizedFileURL.path.hasPrefix(raiz.standardizedFileURL.path),
                  let dados = try? Data(contentsOf: arquivo) else {
                let resp = HTTPURLResponse(url: url, statusCode: 404, httpVersion: "HTTP/1.1", headerFields: nil)!
                urlSchemeTask.didReceive(resp)
                urlSchemeTask.didReceive(Data())
                urlSchemeTask.didFinish()
                return
            }
            let resp = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1",
                                       headerFields: ["Content-Type": Self.tipo(de: arquivo.pathExtension),
                                                      "Content-Length": String(dados.count)])!
            urlSchemeTask.didReceive(resp)
            urlSchemeTask.didReceive(dados)
            urlSchemeTask.didFinish()
        }

        func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {}

        private static func tipo(de ext: String) -> String {
            switch ext.lowercased() {
            case "html": return "text/html; charset=utf-8"
            case "js": return "text/javascript; charset=utf-8"
            case "css": return "text/css; charset=utf-8"
            case "json", "webmanifest": return "application/json"
            case "svg": return "image/svg+xml"
            case "png": return "image/png"
            default: return "application/octet-stream"
            }
        }

        // MARK: backup — o <a download> do navegador não funciona no WKWebView

        /// Recebe {nome, conteudo} do JS, grava num arquivo temporário e abre a
        /// folha de compartilhamento: "Salvar em Arquivos", WhatsApp, e-mail…
        func userContentController(_ userContentController: WKUserContentController,
                                   didReceive message: WKScriptMessage) {
            guard message.name == "salvar",
                  let corpo = message.body as? [String: Any],
                  let nome = corpo["nome"] as? String,
                  let conteudo = corpo["conteudo"] as? String else { return }
            let seguro = nome.replacingOccurrences(of: "/", with: "-")
            let destino = FileManager.default.temporaryDirectory.appendingPathComponent(seguro)
            do {
                try conteudo.data(using: .utf8)?.write(to: destino, options: .atomic)
            } catch {
                webView?.evaluateJavaScript("toast('Não consegui salvar o arquivo','err')")
                return
            }
            guard let web = webView, let raizVC = web.window?.rootViewController else { return }
            var topo = raizVC
            while let p = topo.presentedViewController { topo = p }
            let folha = UIActivityViewController(activityItems: [destino], applicationActivities: nil)
            folha.popoverPresentationController?.sourceView = web
            folha.popoverPresentationController?.sourceRect = CGRect(x: web.bounds.midX, y: web.bounds.maxY - 80, width: 1, height: 1)
            topo.present(folha, animated: true)
        }
    }
}
