import UIKit
import WebKit
import SnapKit

class WebViewController: UIViewController{
    private var webView: WKWebView!
    
    @IBAction func closeButtonAction(_ sender: Any) {
        self.presentingViewController?.dismiss(animated: true)
    }
    @IBOutlet weak var sourceLabel: UILabel!
    var routineTitle: String = ""
    var url: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationSet()
        openWebView()
    }
}
//MARK: - 네비게이션 바 속성

extension WebViewController {
    private func navigationSet(){
        self.navigationItem.title = routineTitle
        self.navigationItem.largeTitleDisplayMode = .never
    }
}

//MARK: - WebView 세팅 후 로드

extension WebViewController {
    private func openWebView(){
        setWebView()
        setAutoLayout()
        loadWebView()
        
        func setWebView(){
            
            let source: String = "var meta = document.createElement('meta');" +
            "meta.name = 'viewport';" +
            "meta.content = 'width=device-width, initial-scale=0.4, maximum-scale=5.0, user-scalable=yes';" +
            "var head = document.getElementsByTagName('head')[0];" +
            "head.appendChild(meta);"

            let script: WKUserScript = WKUserScript(source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
            
            let preferences = WKPreferences()
            preferences.javaScriptEnabled = true
            preferences.javaScriptCanOpenWindowsAutomatically = true
            
            let contentController = WKUserContentController()
            contentController.add(self, name: "bridge")
            contentController.addUserScript(script)
            
            let configuration = WKWebViewConfiguration()
            configuration.preferences = preferences
            configuration.userContentController = contentController

            webView = WKWebView(frame: self.view.bounds, configuration: configuration)
            webView.uiDelegate = self
            webView.navigationDelegate = self
            
            webView.alpha = 0
            UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseIn, animations: {
                self.webView.alpha = 1
            }) { _ in
            }
        }
        
        //WebView Start
        func loadWebView(){
            DispatchQueue.main.async {
                guard let url = URL(string: self.url) else {return}
                self.webView.load(URLRequest(url: url))
            }
        }
        
        //WebView AutoLayout Set
        func setAutoLayout() {
            view.addSubview(webView)
            webView.snp.makeConstraints { make in
                make.top.equalTo(sourceLabel).offset(35)
                make.left.right.bottom.equalToSuperview()
            }
        }
    }
}
//MARK: - WKUIDelegate

extension WebViewController: WKUIDelegate{
    public func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        
    }
}
//MARK: - WKNavigationDelegate

extension WebViewController: WKNavigationDelegate{
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        decisionHandler(.allow)
    }
    
}
//MARK: - WKScriptMessageHandler

extension WebViewController: WKScriptMessageHandler{
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
    }
}



