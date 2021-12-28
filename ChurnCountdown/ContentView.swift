//
//  ContentView.swift
//  ChurnCountdown
//
//  Created by Hildisvíni Óttar on 28/12/2021.
//

import SwiftUI
import AppKit
import WebKit


struct ContentView: View {
    @StateObject var model = Model.shared
    @State private var blockTime = false
    @State private var reconnectButtonActive = false
    @State private var timer = Timer.publish(every: 8, on: .current, in: .common).autoconnect()
    
    var blocksRemaining : Int {
        model.nextChurnheight - model.currentBlock
    }
    
    private func timeRemaining(_ blocksRemaining : Int) -> (Int,Int,Int) { //days, hours, minutes
        let totalMinutes : Double = Double(blocksRemaining) * model.blockDuration / 60.0
        let daysRemaining : Int = Int(floor(totalMinutes / 1440.0))
        let hoursRemaining : Int = Int(floor((totalMinutes - Double((daysRemaining*1440))) / 60.0))
        let minutesRemaining : Int = Int(ceil(totalMinutes - Double(daysRemaining*1440) - Double(hoursRemaining*60)))
        return (daysRemaining, hoursRemaining, minutesRemaining)
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            Text("CHURN COUNTDOWN")
                .font(Font.system(size: 26.0))
                .fontWeight(.semibold)
                .foregroundColor(Color.primary)
            
            if blockTime {
                CountView(label: "blocks", value: blocksRemaining)
            } else { // Human Time
                HStack(alignment: .center, spacing: 16) {
                    let (days,hours,minutes) = timeRemaining(blocksRemaining)
                    CountView(label: "days", value: days)
                    CountView(label: "hours", value: hours)
                    CountView(label: "minutes", value: minutes)
                }
            }
            
            let progress : Double = 1.0 - Double(blocksRemaining) / Double(model.churnInterval)
            ProgressView(value: min(max(progress,0.0),1.0))
                .padding(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
            
            HStack(alignment: .center, spacing: 44) {
                VStack(alignment: .center, spacing: 4) {
                    Image(systemName: "cube")
                    Text("Current block")
                    Text("\(model.currentBlock)")
                        .foregroundColor(Color.primary)
                        .font(Font.system(size: 22))
                        .fontWeight(.semibold)
                }

                VStack(alignment: .center, spacing: 4) {
                    Image(systemName: "arrowshape.bounce.forward")
                    Text("Churn block")
                    Text("\(model.nextChurnheight)")
                        .foregroundColor(Color.primary)
                        .font(Font.system(size: 22))
                        .fontWeight(.semibold)
                }
            }
            .foregroundColor(Color(NSColor.secondaryLabelColor))
            
            Picker("", selection: $blockTime) {
                Text("Human Time").tag(false)
                Text("Block Time").tag(true)
            }
            .pickerStyle(.segmented)
            .padding(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
            
            VStack(alignment: .leading, spacing: 0, content: {
                let secPerBlock = String(format: "%.1f",model.blockDuration)
                let (days,hours,minutes) = timeRemaining(model.churnInterval)
                Text("\(secPerBlock) sec/block")
                Text("Churn interval: \(days)d \(hours)h \(minutes)m")
                Text("Churn interval: \(model.churnInterval) blocks")
            })
                .foregroundColor(Color(NSColor.secondaryLabelColor))
                        
            HStack {
                Spacer()
                Button(action: {
                    model.reconnect()
                    reconnectButtonActive = false
                    self.timer = Timer.publish(every: 8, on: .current, in: .common).autoconnect()
                })
                {
                    Label("Reconnect", systemImage: "arrow.counterclockwise")
                        .font(.caption)
                }
                .disabled(!reconnectButtonActive)
                
                Button(action: {
                    NSApplication.shared.terminate(self)
                })
                {
                    Label("Quit", systemImage: "hand.wave")
                        .font(.caption)
                }
                .padding(4)
            }
            .onReceive(timer) { _ in
                reconnectButtonActive = true
                timer.upstream.connect().cancel()
            }
        }
        .padding(8)
        .frame(width: 360.0, height: 360.0, alignment: .top)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

struct CountView : View {
    let label : String //e.g. 'days'
    let value : Int
    
    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            let text = value >= 1000 ? "\(value)" : String(format: "%02d",value)
            Text(text)
                .font(Font.system(size: 50))
                .fontWeight(.semibold)
                
            Text(label)
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .foregroundColor(Color(NSColor.controlBackgroundColor))
        )
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ContentView().colorScheme(.light)
            ContentView().colorScheme(.dark)
        }
    }
}
