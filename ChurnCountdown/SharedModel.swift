//
//  SharedModel.swift
//  ChurnCountdown
//
//  Created by Hildisvíni Óttar on 28/12/2021.
//

import Foundation

final class Model : ObservableObject {
    
    /// Any changes to model trigger view updates to any observing SwiftUI View heirarchy
    @Published var currentBlock = 0
    @Published var nextChurnheight = UserDefaults.standard.integer(forKey: "nextChurnHeight")
    @Published var churnInterval = UserDefaults.standard.integer(forKey: "churnInterval")
    @Published var blockDuration = 5.9
    private var websocketTask : URLSessionWebSocketTask?

    private var lastBlockTimes = [Date]()
    
    /// Singleton
    static let shared = Model()
    private init() {
        if churnInterval == 0 {
            churnInterval = 43200 //default
        }
        reconnect()
    }
    
    func reconnect() {
        self.lastBlockTimes.removeAll()
        websocketTask?.cancel()
        websocketTask = nil
        self.loadNextChurnHeight()
        self.loadChurnInterval()
        self.connectWebsocket()
    }
    
    /// Load mimir for CHURNINTERVAL
    private func loadChurnInterval() {
        let url = URL(string: "https://midgard.thorchain.info/v2/thorchain/mimir")!
        let dataTask = URLSession.shared.dataTask(with: url) { data, response, error in
            guard error == nil, data != nil else { return }
            if let data = data,
                let json = String(data: data, encoding: .utf8),
                let dict = json.convertToDictionary(),
               let churnInterval = dict["CHURNINTERVAL"] as? Int {
                
                DispatchQueue.main.async {
                    self.churnInterval = churnInterval
                    UserDefaults.standard.set(churnInterval, forKey: "churnInterval")
                    UserDefaults.standard.synchronize()
                }
            }
        }
        dataTask.resume()
    }
    
    
    /// Load nextChurnHeight from network
    private func loadNextChurnHeight() {
        let url = URL(string: "https://midgard.thorchain.info/v2/network")!
        let dataTask = URLSession.shared.dataTask(with: url) { data, response, error in
            guard error == nil, data != nil else { return }
            if let data = data,
                let json = String(data: data, encoding: .utf8),
                let dict = json.convertToDictionary(),
               let churnHeight = dict["nextChurnHeight"] as? String {
                
                DispatchQueue.main.async {
                    self.nextChurnheight = (churnHeight as NSString).integerValue
                    UserDefaults.standard.set(self.nextChurnheight, forKey: "nextChurnHeight")
                    UserDefaults.standard.synchronize()
                }
            }
        }
        dataTask.resume()
    }
    
    
    /// Connect to Websocket rpc endpoint and receive block updates
    private func connectWebsocket() {
        let url = URL(string: "wss://rpc.thorchain.info/websocket")!
        self.websocketTask = URLSession.shared.webSocketTask(with: url)
        self.addListener()
        // Send request to listen for new blocks
        let message = URLSessionWebSocketTask.Message.string(#"{"jsonrpc":"2.0","id":1,"method":"subscribe","params":["tm.event='NewBlock'"]}"#)
        websocketTask?.send(message) { error in
            if let error = error {
                #if DEBUG
                print("WebSocket sending error: \(error)")
                #endif
            }
        }
        websocketTask?.resume()
    }
    
    private func addListener() {
        // Listen for data
        websocketTask?.receive { result in
            switch result {
            case .failure(let error):
                #if DEBUG
                print("Failed to receive message: \(error)")
                #endif
                self.reconnect()
            case .success(let message):
                switch message {
                case .string(let text):
                    if let dict = text.convertToDictionary(),
                       let result = dict["result"] as? [String:Any],
                       let data = result["data"] as? [String:Any],
                       let value = data["value"] as? [String:Any],
                       let block = value["block"] as? [String:Any],
                       let header = block["header"] as? [String:Any],
                       let height = header["height"] as? String {
                        
                        DispatchQueue.main.async {
                            self.currentBlock = (height as NSString).integerValue
                            if self.currentBlock >= self.nextChurnheight {
                                self.loadNextChurnHeight()
                            }
                            self.lastBlockTimes.append(Date())
                            if self.lastBlockTimes.count > 4 {
                                let dateDiff = self.lastBlockTimes.last!.timeIntervalSince(self.lastBlockTimes.first!) //seconds
                                let averageTime = dateDiff / TimeInterval(self.lastBlockTimes.count - 1)
                                self.blockDuration = averageTime
                                #if DEBUG
                                print("New Block: \(self.currentBlock). Average Time: \(String(format: "%.2f",averageTime))")
                                #endif
                            }
                        }
                    }
                case .data(let data):
                    #if DEBUG
                    print("Received binary message: \(data)")
                    #endif
                @unknown default:
                    fatalError()
                }
                self.addListener() //recursive add. Only sends one message per block added
            }
        }
    }
}
