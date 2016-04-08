//
//  DetailViewController.swift
//  ResourceLoaderTests
//
//  Created by Jann Schafranek on 08/04/16.
//  Copyright © 2016 Jann Schafranek. All rights reserved.
//

import UIKit
import AVFoundation
import MobileCoreServices

class DetailViewController: UIViewController, AVAssetResourceLoaderDelegate, NSURLSessionDelegate, NSURLSessionDataDelegate {
    var player:AVPlayer = AVPlayer()

    override func viewDidLoad() {
        super.viewDidLoad()
        session = NSURLSession(configuration: NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier("ident"), delegate: self, delegateQueue: NSOperationQueue.mainQueue())
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func doTapped(sender: AnyObject) {
        print("beginning")
        setupSession()
        let asset = AVURLAsset(URL: NSURL(string: "testing-http://mp3.ffh.de/radioffh/livestream.mp3")!) // This can be replaced by any other api stream
        asset.resourceLoader.setDelegate(self, queue: dispatch_get_main_queue())
        let playerItem = AVPlayerItem(asset: asset)
        player = AVPlayer(playerItem: playerItem)
        player.actionAtItemEnd = AVPlayerActionAtItemEnd.None
        player.play()
        print("done")
    }
    
    @IBAction func playTapped(sender: AnyObject) {
        print(player.rate)
    }
    
    @IBAction func testTapped(sender: AnyObject) {
        print(player.currentItem?.loadedTimeRanges.first?.CMTimeRangeValue.start.seconds)
    }
    
    func setupSession(){
        let session = AVAudioSession.sharedInstance()
        do{
            try session.setCategory(AVAudioSessionCategoryPlayback)
            try session.setActive(true)
            print("set up")
        }catch let err as NSError{
            print("error setting up session:", err)
        }
    }
    
    // RESOURCE LOADER
    var request:AVAssetResourceLoadingRequest?
    
    func resourceLoader(resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        print("lR:", loadingRequest)
        self.request = loadingRequest
        let task = session.dataTaskWithURL(NSURL(string: (loadingRequest.request.URL?.absoluteString.stringByReplacingOccurrencesOfString("testing-", withString: ""))!)!)
        task.resume()
        return true
    }
    
    // URL SESSION DATA
    var session:NSURLSession!
    
    func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveResponse response: NSURLResponse, completionHandler: (NSURLSessionResponseDisposition) -> Void) {
        //print("resp:", response)
        completionHandler(.Allow)
    }
    
    func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveData data: NSData) {
        if let request = request, dataRequest = request.dataRequest{
            let neededData = dataRequest.requestedLength - Int(dataRequest.currentOffset)
            if (data.length >= neededData){
                print("finishing")
                if let contentInformationRequest = request.contentInformationRequest, mimeType = dataTask.response?.MIMEType{
                    print("finishing 2:", mimeType)
                    contentInformationRequest.contentLength = dataTask.countOfBytesExpectedToReceive
                    if let contentType = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, mimeType as CFString, nil)?.takeRetainedValue(){
                        let contentType = contentType as String
                        print("finishing 3:", contentType)
                        contentInformationRequest.contentType = contentType
                        contentInformationRequest.byteRangeAccessSupported = true
                    }
                }
                dataRequest.respondWithData(data.subdataWithRange(NSMakeRange(0, neededData)))
                //dataRequest.respondWithData(data) // using this, the loadingRequest asks for the complete file
                dataTask.cancel()
                request.finishLoading()
                self.request = nil
            }else{
                dataRequest.respondWithData(data)
            }
        }
    }
}