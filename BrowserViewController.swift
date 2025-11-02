import Cocoa
import WebKit

final class BrowserViewController: NSViewController {
    private let startURL = URL(string: "https://fantasy-hub.ru/dashboard")!
    private var webView: WKWebView!
    private var mobileMode = false
    private let mobileUA = "Mozilla/5.0 (Linux; Android 12; Pixel 5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/118.0.0.0 Mobile Safari/537.36"

    private let topBar = NSView()
    private let btnMobile = NSButton(title: "Моб. версия: выкл", target: nil, action: nil)

    override func loadView() {
        self.view = NSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.white.cgColor

        let config = WKWebViewConfiguration()
        config.websiteDataStore = .nonPersistent()
        config.suppressesIncrementalRendering = false
        config.limitsNavigationsToAppBoundDomains = false
        config.preferences.javaScriptCanOpenWindowsAutomatically = true

        let userContent = WKUserContentController()
        config.userContentController = userContent

        // lite оптимизации
        let cssKillAnimations = """
        const st=document.createElement('style');st.id='fh-lite-style';st.textContent='*{animation:none!important;transition:none!important;text-shadow:none!important;box-shadow:none!important}html,body{scroll-behavior:auto!important;overscroll-behavior:contain!important;-webkit-font-smoothing:auto!important}';document.documentElement.appendChild(st);
        """
        userContent.addUserScript(WKUserScript(source: cssKillAnimations, injectionTime: .atDocumentEnd, forMainFrameOnly: false))

        // throttle RAF
        let jsThrottleRAF = """
        (function(){const t=30;const i=1000/t;let l=performance.now();const r=window.requestAnimationFrame;window.requestAnimationFrame=function(c){return r(function s(n){if(n-l<i){return r(s)}l=n;c(n)})};const _st=window.setTimeout;window.setTimeout=function(fn,ms){if(typeof ms==='number'&&ms<16)ms=16;return _st(fn,ms)}})();
        """
        userContent.addUserScript(WKUserScript(source: jsThrottleRAF, injectionTime: .atDocumentEnd, forMainFrameOnly: false))

        // lazy media
        let jsLazy = """
        (function(){function q(e){if(e.tagName==='IMG'){if(!e.loading)e.loading='lazy';e.decoding='async'}if(e.tagName==='IFRAME'){if(!e.loading)e.loading='lazy'}if(e.tagName==='VIDEO'){try{e.preload='metadata';e.autoplay=false;e.pause()}catch(_){}}}const mo=new MutationObserver((m)=>{for(const r of m){if(r.type==='childList'){r.addedNodes&&r.addedNodes.forEach(n=>{if(n.nodeType===1){q(n);n.querySelectorAll&&n.querySelectorAll('img,iframe,video').forEach(q)}})}}});mo.observe(document.documentElement,{subtree:true,childList:true});document.querySelectorAll('img,iframe,video').forEach(q)})();
        """
        userContent.addUserScript(WKUserScript(source: jsLazy, injectionTime: .atDocumentEnd, forMainFrameOnly: false))

        // batching WebSocket: micro-queue по умолчанию
        let jsWsBatch = """
        (function(){const MODE='micro';const DELAY=0;const NWS=window.WebSocket;window.WebSocket=function(u,p){const ws=new NWS(u,p);const hs=new Set();let onh=null;function d(ev){const e=new MessageEvent('message',{data:ev.data,origin:ev.origin,lastEventId:ev.lastEventId});if(onh){try{onh.call(ws,e)}catch(_){}}hs.forEach(h=>{try{h.call(ws,e)}catch(_){}})}let q=[];let sch=false;function f(){sch=false;const a=q;q=[];for(let i=0;i<a.length;i++)d(a[i])}function s(){if(sch)return;sch=true;Promise.resolve().then(f)}ws.addEventListener('message',function(ev){q.push(ev);s()});Object.defineProperty(ws,'onmessage',{get(){return onh},set(h){onh=(typeof h==='function')?h:null}});const oa=ws.addEventListener.bind(ws);ws.addEventListener=function(t,h,o){if(t==='message'&&typeof h==='function'){hs.add(h);return}return oa(t,h,o)};const or=ws.removeEventListener.bind(ws);ws.removeEventListener=function(t,h,o){if(t==='message'&&typeof h==='function'){hs.delete(h);return}return or(t,h,o)};return ws}})();
        """
        userContent.addUserScript(WKUserScript(source: jsWsBatch, injectionTime: .atDocumentEnd, forMainFrameOnly: false))

        webView = WKWebView(frame: .zero, configuration: config)
        webView.customUserAgent = nil
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.allowsBackForwardNavigationGestures = false
        webView.setValue(false, forKey: "drawsBackground")

        topBar.wantsLayer = true
        topBar.layer?.backgroundColor = NSColor(calibratedWhite: 0.96, alpha: 1).cgColor
        topBar.translatesAutoresizingMaskIntoConstraints = false
        btnMobile.target = self
        btnMobile.action = #selector(toggleMobile)
        btnMobile.bezelStyle = .rounded
        btnMobile.translatesAutoresizingMaskIntoConstraints = false

        topBar.addSubview(btnMobile)
        view.addSubview(topBar)
        view.addSubview(webView)

        NSLayoutConstraint.activate([
            topBar.topAnchor.constraint(equalTo: view.topAnchor),
            topBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topBar.heightAnchor.constraint(equalToConstant: 40),

            btnMobile.leadingAnchor.constraint(equalTo: topBar.leadingAnchor, constant: 10),
            btnMobile.centerYAnchor.constraint(equalTo: topBar.centerYAnchor),
            btnMobile.widthAnchor.constraint(equalToConstant: 160),
            btnMobile.heightAnchor.constraint(equalToConstant: 28),

            webView.topAnchor.constraint(equalTo: topBar.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        var req = URLRequest(url: startURL, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 60)
        webView.load(req)
        preventSleep()
    }

    @objc private func toggleMobile() {
        mobileMode.toggle()
        btnMobile.title = mobileMode ? "Моб. версия: вкл" : "Моб. версия: выкл"
        webView.customUserAgent = mobileMode ? mobileUA : nil
        webView.evaluateJavaScript("location.reload()", completionHandler: nil)
        if let win = view.window, !NSEvent.modifierFlags.contains(.command) {
            if mobileMode {
                win.setContentSize(NSSize(width: 420, height: 800))
            } else {
                win.setContentSize(NSSize(width: 1200, height: 800))
            }
            win.center()
        }
    }

    private var assertionID: IOPMAssertionID = 0
    private func preventSleep() {
        // запрет сна системы и дисплея
        let reasonForActivity = "FHBrowser Active" as CFString
        let kassert = kIOPMAssertionTypeNoDisplaySleep as CFString
        let res = IOPMAssertionCreateWithName(kassert, IOPMAssertionLevel(kIOPMAssertionLevelOn), reasonForActivity, &assertionID)
        if res != kIOReturnSuccess {
            _ = IOPMAssertionCreateWithName(kIOPMAssertionTypeNoIdleSleep as CFString, IOPMAssertionLevel(kIOPMAssertionLevelOn), reasonForActivity, &assertionID)
        }
    }
}

// MARK: - Delegates

extension BrowserViewController: WKNavigationDelegate, WKUIDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        NSLog("Ready \(Date())")
    }
}
