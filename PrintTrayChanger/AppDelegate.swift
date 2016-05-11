//
//  AppDelegate.swift
//  PrintTrayChanger
//
//  Created by Tjark Saul on 10.5.16.
//  Copyright © 2016 Tjark Saul. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSURLSessionDelegate {

    @IBOutlet weak var window: NSWindow!
    @IBOutlet weak var menu: NSMenu!
    var statusItem: NSStatusItem!
    var darkModeOn: Bool!
    
    let printer = "HP LaserJet 500 color M551 [63125D]"
    let ipAddress = "192.168.134.15"
    
    let trays = [
        "Tray1", "Tray2", "Tray3"
    ]
    let sizes = [
        "A4", "A5", "A6"
    ]
    let weights: [String:String] = [
        "AnySupportedType": "Beliebiger Typ",
        "Plain": "Normal",
        "HPMatte105gsm": "HP Matt 105 g",
        "HPMatte120Gsm": "HP Matt 120g",
        "HPMatte160gsm": "HP Matt 160 g",
        "HPMatte200gsm": "HP Matt 200 g",
        "HPSoftGloss120gsm": "HP Glanzpapier 120 g",
        "HPGlossy130gsm": "HP Hochglanz 130 g",
        "HPGlossy160gsm": "HP Hochglanz 150 g",
        "HPGlossy220gsm": "HP Hochglanz 200 g",
        "Light": "Leicht 60-74g",
        "MidWeight": "Mittelschw. 96-110g",
        "Heavy": "Schwer 111-130g",
        "ExtraHeavy": "Extraschwer 131-175 g",
        "Cardstock": "Karton 176-220",
        "MidWeightGlossy": "MittSchw Hglnz 96 - 110 g",
        "HeavyGlossy": "Hglz schw 111-130g",
        "ExtraHeavyGloss": "XSchwHglnz131-175g",
        "CardstockGlossy": "Karte Hglnz 176 - 220 g",
        "Transparency": "Farbtransparenz",
        "Labels": "Etiketten",
        "StationeryLetterhead": "Briefkopf",
        "Envelope": "Umschlag",
        "StationeryPreprinted": "Vorgedruckt",
        "StationeryPrepunched": "Vorgelocht",
        "Color": "Farbig",
        "Bond": "Briefpapier",
        "Recycled": "Recycling",
        "Rough": "Druckmodus",
        "HPToughPaper": "HP ToughPaper",
        "FilmOpaque": "Folie Opak",
        "HPEcoSmartLite": "HP EcoSMART Lite",
    ]
    
    func makeMenu() {
        menu.removeAllItems()
        for tray in trays {
            let item = NSMenuItem(title: tray, action: nil, keyEquivalent: "")
            item.submenu = NSMenu.init()
            menu.addItem(item)
            for size in sizes {
                let subItem = NSMenuItem(title: size, action: nil, keyEquivalent: "")
                subItem.submenu = NSMenu.init()
                item.submenu!.addItem(subItem)
                for (weightName, weightTitle) in weights {
                    let weightItem = MyMenuItem(title: weightTitle, action: "changePaper:", keyEquivalent: "")
                    weightItem.Tray = tray
                    weightItem.Size = size
                    weightItem.Weight = weightName
                    weightItem.enabled = true
                    subItem.submenu!.addItem(weightItem)
                }
            }
        }
        menu.addItem(NSMenuItem.separatorItem())
        menu.addItem(NSMenuItem(title: "Quit", action: "quit:", keyEquivalent: "Q"))
    }
    
    @objc func quit(sender: AnyObject?) {
        NSApp.performSelector(Selector("terminate:"), withObject: nil, afterDelay: 0.0)
    }
    
    @objc func changePaper(sender: AnyObject?) {
        if let item = sender as? MyMenuItem {
            NSLog("Setting %@ to paper %@ of size %@.", item.Tray, item.Weight, item.Size);
            let settings = [
                "MediaSize": item.Size,
                "MediaType": item.Weight,
                "FormButtonSubmit": "OK"
            ];
            // we can do this that simple since we only have [A-Za-z0-9] in our names/values
            let requestString = settings.map() { $0.0 + "=" + $0.1 }.joinWithSeparator("&")
            
            let url = NSURL.init(string: "https://" + ipAddress + "/hp/device/TraySettings/Index?id=" + item.Tray);
            let request = NSMutableURLRequest.init(URL: url!);
            request.setValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
            request.HTTPMethod = "POST";
            request.HTTPBody = requestString.dataUsingEncoding(NSUTF8StringEncoding);
            print("Sending URL request");
            let session = NSURLSession(configuration: NSURLSession.sharedSession().configuration, delegate: self, delegateQueue: NSOperationQueue.mainQueue());
            let task = session.dataTaskWithRequest(request, completionHandler: {
                taskData, response, error -> () in
                print("Completion handler called");
                if let httpResponse = response as? NSHTTPURLResponse {
                    print(httpResponse.statusCode)
                }
                if (taskData == nil) {
                    print(error);
                }
                for i in (item.menu?.itemArray)! {
                    i.state = NSOffState;
                }
                item.state = NSOnState;
            });
            task.resume();
        }
    }
    
    func URLSession(session: NSURLSession,
        didReceiveChallenge challenge: NSURLAuthenticationChallenge,
        completionHandler: (NSURLSessionAuthChallengeDisposition,
        NSURLCredential?) -> Void) {
        completionHandler(NSURLSessionAuthChallengeDisposition.UseCredential, NSURLCredential(forTrust: challenge.protectionSpace.serverTrust!))
    }


    func applicationDidFinishLaunching(aNotification: NSNotification) {
        statusItem = NSStatusBar.systemStatusBar().statusItemWithLength(NSVariableStatusItemLength)
        statusItem.image = NSImage(named: "office-print.png")
        
        makeMenu()
        statusItem.menu = menu
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }


}

