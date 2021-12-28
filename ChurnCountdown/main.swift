//
//  main.swift
//  ChurnCountdown
//
//  Created by Hildisvíni Óttar on 28/12/2021.
//

import Cocoa

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
_ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
