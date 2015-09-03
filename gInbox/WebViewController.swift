//
//  WebViewController.swift
//  gInbox
//
//  Created by Chen Asraf on 11/11/14.
//  Copyright (c) 2014 Chen Asraf. All rights reserved.
//

import Foundation
import WebKit
import AppKit
import Cocoa

class WebViewController: NSViewController, WKNavigationDelegate {
    
    @IBOutlet weak var webView: WebView!
    
    // constants
    let webUrl = "https://inbox.google.com"
    let webUA = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/38.0.2125.111 Safari/537.36"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let request = NSURLRequest(URL: NSURL(string: webUrl)!)
        webView.customUserAgent = webUA
        webView.mainFrame.loadRequest(request)
        NSEvent.addLocalMonitorForEventsMatchingMask(NSEventMask.KeyDownMask, handler: {(event: NSEvent!) -> (NSEvent) in
            if event.modifierFlags & .CommandKeyMask != nil {
                let numberPressed = event.charactersIgnoringModifiers!
                let number:Int? = numberPressed.toInt()
                
                if number != nil && self.webView.mainFrameURL.rangeOfString("\(number!-1)") != nil {
                    return event
                }
                else if numberPressed == "1" {
                    let urlString = NSString(format: "%@/u/0/?authuser=0",self.webUrl)
                    let request = NSURLRequest(URL: NSURL(string: urlString as String)!)
                    self.webView.mainFrame.loadRequest(request)
                } else if numberPressed == "2" {
                    let urlString = NSString(format: "%@/u/0/?authuser=1",self.webUrl)
                    let request = NSURLRequest(URL: NSURL(string: urlString as String)!)
                    self.webView.mainFrame.loadRequest(request)
                } else if numberPressed == "3" {
                    let urlString = NSString(format: "%@/u/0/?authuser=2",self.webUrl)
                    let request = NSURLRequest(URL: NSURL(string: urlString as String)!)
                    self.webView.mainFrame.loadRequest(request)
                }
                
            }
            return event
        })
    }
    
    func webView(sender: WKWebView,
        decidePolicyForNavigationAction navigationAction: WKNavigationAction, decisionHandler: (WKNavigationActionPolicy) -> Void) {
            if sender == webView {
                NSWorkspace.sharedWorkspace().openURL(navigationAction.request.URL!)
            }
            //            if sender != webView {
            //                decisionHandler(WKNavigationActionPolicy.Allow)
            //            }
            //            if navigationAction.request.URL == "#" {
            //                return
            //            }
    }
    
    override func webView(sender: WebView!, decidePolicyForNavigationAction actionInformation: [NSObject : AnyObject]!, request: NSURLRequest!, frame: WebFrame!, decisionListener listener: WebPolicyDecisionListener!) {
        
        if actionInformation["WebActionOriginalURLKey"] != nil {
            let url:String = (actionInformation["WebActionOriginalURLKey"]?.absoluteString as String?)!
            let hangoutsNav:Bool = (url.hasPrefix("https://plus.google.com/hangouts/") || url.hasPrefix("https://talkgadget.google.com/u/"))
            let hideHangouts:Bool = (Preferences.getInt("hangoutsMode") > 0)
            
            if (url.hasPrefix("#")) {
                NSWorkspace.sharedWorkspace().openURL(NSURL(string: url)!)
                listener.ignore()
            } else if hideHangouts && hangoutsNav {
                listener.ignore()
            } else {
                listener.use()
            }
        }
    }
    
    override func webView(webView: WebView!, decidePolicyForNewWindowAction actionInformation: [NSObject : AnyObject]!, request: NSURLRequest!, newFrameName frameName: String!, decisionListener listener: WebPolicyDecisionListener!) {
        if (request.URL!.absoluteString!.hasPrefix("https://accounts.google.com") == true || request.URL!.absoluteString!.hasPrefix("https://inbox.google.com") == true) {
            webView.mainFrame.loadRequest(request)
        } else {
            NSWorkspace.sharedWorkspace().openURL(NSURL(string: (actionInformation["WebActionOriginalURLKey"]?.absoluteString)!)!)
            listener.ignore()
        }
    }
    
    override func webView(sender: WebView!, didFinishLoadForFrame frame: WebFrame!) {
    }
    
    func consoleLog(message: String) {
        NSLog("[JS] -> %@", message)
    }
    
    override func webView(sender: WebView!, didClearWindowObject windowObject: WebScriptObject!, forFrame frame: WebFrame!) {
        if (webView.mainFrameDocument != nil) { // && frame.DOMDocument == webView.mainFrameDocument) {
            let document:DOMDocument = webView.mainFrameDocument
            let hangoutsMode: String? = Preferences.getString("hangoutsMode")
            let windowScriptObject = webView.windowScriptObject;
            windowScriptObject.setValue(self, forKey: "gInbox")
            windowScriptObject.evaluateWebScript("console = { log: function(msg) { gInbox.consoleLog(msg); } }")
            
            let path = NSBundle.mainBundle().pathForResource("gInboxTweaks", ofType: "js", inDirectory: "Assets")
            let jsString = String(contentsOfFile: path!, encoding: NSUTF8StringEncoding, error: nil)
            let script = document.createElement("script")
            let jsText = document.createTextNode(jsString)
            let bodyEl = document.getElementsByName("body").item(0)
            
            script.setAttribute("type", value: "text/javascript")
            script.appendChild(jsText)
            bodyEl?.appendChild(script)
            
            //windowScriptObject.evaluateWebScript(String(format: "console.log('test'); hangoutsMode(%@)", hangoutsMode!))
        }
    }
    
    
    func isSelectorExcludedFromWebScript(selector: Selector) -> Bool {
        if selector == Selector("consoleLog") {
            return false
        }
        return true
    }
    
    
}