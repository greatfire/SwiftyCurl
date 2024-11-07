//
//  ViewController.swift
//  macOS_Example
//
//  Created by Benjamin Erhart on 31.10.24.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import Cocoa
import SwiftyCurl

class ViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let request = URLRequest(url: .init(string: "http://google.com")!)

        let curl = SwiftyCurl()
        curl.followLocation = true
        curl.queue = .global(qos: .background)

        let progress = Progress()
        let observation1 = progress.observe(\.fractionCompleted) { progress, _ in
            print("Progress1: \(progress.completedUnitCount) of \(progress.totalUnitCount) = \(progress.fractionCompleted)")
        }

        curl.perform(with: request, progress: progress) { data, response, error in
//            print(String(data: data ?? .init(), encoding: .ascii) ?? "(nil)")

            if let response = response as? HTTPURLResponse {
                print("Response1: \(response.url?.absoluteString ?? "(nil)") \(response.statusCode)\nheaders: \(response.allHeaderFields)")
            }

            if let error = error {
                print("Error: \(error)")
            }

            observation1.invalidate()
        }

        let task = curl.task(with: request)
        let observation2 = task?.progress.observe(\.fractionCompleted) { progress, _ in
            print("Progress2: \(progress.completedUnitCount) of \(progress.totalUnitCount) = \(progress.fractionCompleted)")
        }

        print("Ticket: \(task?.taskIdentifier ?? UInt.max)")

        task?.resume { data, response, error in
//            print(String(data: data ?? .init(), encoding: .ascii) ?? "(nil)")

            if let response = response as? HTTPURLResponse {
                print("Response2: \(response.url?.absoluteString ?? "(nil)") \(response.statusCode)\nheaders: \(response.allHeaderFields)")
            }

            if let error = error {
                print("Error: \(error)")
            }

            observation2?.invalidate()
        }
    }
}
