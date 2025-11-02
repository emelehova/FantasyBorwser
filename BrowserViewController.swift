import Cocoa
import WebKit

class BrowserViewController: NSViewController, WKNavigationDelegate, WKUIDelegate {
    private let startURL = URL(string: "https://fantasy-hub.ru/dashboard")!
    private var webView: WKWebView!
    private var isMobile = false
    private var defaultUA: String?
    private let mobileUA = "Mozilla/5.0 (Linux; Android 12; Pixel 5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/118.0.0.0 Mobile Safari/537.36"
    private var args: [String]

    init(arguments: [String]) {
        self.args = arguments
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        self.args = []
        super.init(coder: coder)
    }

    override func loadView() {
        self.view = NSView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let config = WKWebViewConfiguration()
        config.websiteDataStore = WKWebsiteDataStore.nonPersistent()
        config.allowsAirPlayForMediaPlayback = false
        config.suppressesIncrementalRendering = false
        config.preferences.javaScriptEnabled = true
        config.preferences.javaScriptCanOpenWindowsAutomatically = false

        let userController = WKUserContentController()
        injectScripts(userController: userController)
        config.userContentController = userController

        webView = WKWebView(frame: self.view.bounds, configuration: config)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.autoresizingMask = [.width, .height]
        webView.translatesAutoresizingMaskIntoConstraints = true
        webView.frame = self.view.bounds
        self.view.addSubview(webView)
        defaultUA = webView.value(forKey: "userAgent") as? String

        NotificationCenter.default.addObserver(self, selector: #selector(windowDidResize), name: NSWindow.didResizeNotification, object: self.view.window)

        loadStartURL()
    }

    @objc func windowDidResize() {
        webView.frame = self.view.bounds
    }

    func loadStartURL() {
        var req = URLRequest(url: startURL, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 30)
        req.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        webView.load(req)
    }

    private func injectScripts(userController: WKUserContentController) {
        if args.contains("--lite") {
            let css = """
            const s=document.createElement('style');s.id='fh-lite';s.textContent=`*{animation:none!important;transition:none!important;text-shadow:none!important;box-shadow:none!important}html,body{scroll-behavior:auto!important;overscroll-behavior:contain!important;-webkit-font-smoothing:auto!important}`;
            document.documentElement.appendChild(s);
            """
            let raf = """
            (function(){const targetFps=30;const frameInterval=1000/targetFps;let last=performance.now();const _raf=window.requestAnimationFrame;window.requestAnimationFrame=function(cb){return _raf(function ts(now){if(now-last<frameInterval){return _raf(ts)}last=now;cb(now)})};const _st=window.setTimeout;window.setTimeout=function(f,t){if(typeof t==='number'&&t<16)t=16;return _st(f,t)};})();
            """
            userController.addUserScript(WKUserScript(source: css, injectionTime: .atDocumentStart, forMainFrameOnly: false))
            userController.addUserScript(WKUserScript(source: raf, injectionTime: .atDocumentStart, forMainFrameOnly: false))
        }

        if args.contains("--ultralite") {
            let ultra = """
            (function(){const s=document.createElement('style');s.id='fh-ultra';s.textContent='*{-webkit-backdrop-filter:none!important;backdrop-filter:none!important;filter:none!important;outline:0!important}*,*:before,*:after{will-change:auto!important}img,video,canvas{image-rendering:auto!important}';document.documentElement.appendChild(s);})();
            """
            userController.addUserScript(WKUserScript(source: ultra, injectionTime: .atDocumentStart, forMainFrameOnly: false))
        }

        if args.contains("--lazy-media") {
            let lazy = """
            (function(){function tweak(el){if(el.tagName==='IMG'){if(!el.loading)el.loading='lazy';el.decoding='async'}if(el.tagName==='IFRAME'){if(!el.loading)el.loading='lazy'}if(el.tagName==='VIDEO'){try{el.preload='metadata';el.autoplay=false;el.pause()}catch(e){}}}const m=new MutationObserver((list)=>{for(const r of list){if(r.type==='childList'){r.addedNodes&&r.addedNodes.forEach(n=>{if(n.nodeType===1){tweak(n);n.querySelectorAll&&n.querySelectorAll('img,iframe,video').forEach(tweak)}})}}});m.observe(document.documentElement,{subtree:true,childList:true});document.querySelectorAll('img,iframe,video').forEach(tweak);})();
            """
            userController.addUserScript(WKUserScript(source: lazy, injectionTime: .atDocumentStart, forMainFrameOnly: false))
        }

        if args.contains("--block-assets") {
            let hide = "const _s=document.createElement('style');_s.id='fh-hide-assets';_s.textContent='img,video,iframe{display:none!important;visibility:hidden!important}';document.documentElement.appendChild(_s);"
            userController.addUserScript(WKUserScript(source: hide, injectionTime: .atDocumentStart, forMainFrameOnly: false))
        }

        if let batchArg = args.first(where: { $0.starts(with: "--ws-batch=") }) {
            let v = String(batchArg.split(separator: "=")[1])
            var mode = "micro"
            var delay = 0
            if v.lowercased() == "raf" { mode = "raf"; delay = 0 }
            else if let ms = Int(v), ms > 0 { mode = "ms"; delay = ms }

            let js = """
            (function(){
              const MODE='\(mode)';
              const DELAY=\(delay);
              const NativeWS=window.WebSocket;
              window.WebSocket=function(url, protocols){
                const ws=new NativeWS(url, protocols);
                const handlers=new Set();
                let onhandler=null;
                function deliver(ev){
                  const e=new MessageEvent('message',{data:ev.data,origin:ev.origin,lastEventId:ev.lastEventId});
                  if(onhandler){try{onhandler.call(ws,e)}catch(_){}}
                  handlers.forEach(h=>{try{h.call(ws,e)}catch(_){}})
                }
                let queue=[];
                let scheduled=false;
                function flush(){scheduled=false;const q=queue;queue=[];for(let i=0;i<q.length;i++)deliver(q[i])}
                function schedule(){if(scheduled)return;scheduled=true;if(MODE==='raf'){requestAnimationFrame(flush)}else if(MODE==='ms'){setTimeout(flush,DELAY)}else{Promise.resolve().then(flush)}}
                ws.addEventListener('message',function(ev){queue.push(ev);schedule()});
                Object.defineProperty(ws,'onmessage',{get(){return onhandler},set(h){onhandler=(typeof h==='function')?h:null}});
                const oAdd=ws.addEventListener.bind(ws);
                ws.addEventListener=function(type, handler, options){if(type==='message'&&typeof handler==='function'){handlers.add(handler);return}return oAdd(type,handler,options)}
                const oRem=ws.removeEventListener.bind(ws);
                ws.removeEventListener=function(type, handler, options){if(type==='message'&&typeof handler==='function'){handlers.delete(handler);return}return oRem(type,handler,options)}
                return ws;
              };
            })();
            """
            userController.addUserScript(WKUserScript(source: js, injectionTime: .atDocumentStart, forMainFrameOnly: false))
        }
    }

    func toggleMobileMode() {
        isMobile.toggle()
        if isMobile {
            webView.customUserAgent = mobileUA
            if let win = self.view.window {
                win.setContentSize(NSSize(width: 420, height: 800))
                win.center()
            }
        } else {
            webView.customUserAgent = defaultUA
            if let win = self.view.window {
                win.setContentSize(NSSize(width: 1200, height: 800))
                win.center()
            }
        }
        reloadCurrent()
    }

    func reloadCurrent() {
        if let u = webView.url {
            webView.reload()
        } else {
            loadStartURL()
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
    }
}
