//
//  ViewController.swift
//  SwiftyCurl
//
//  Created by Benjamin Erhart on 10/25/2024.
//  Copyright (c) 2024 Benjamin Erhart. All rights reserved.
//

import UIKit
import SwiftyCurl

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        print(SwiftyCurl.libcurlVersion)

        let curl = SwiftyCurl()
        curl.followLocation = true
        curl.queue = .global(qos: .background)
        curl.verbose = true

        let progress = Progress()
        let observation1 = progress.observe(\.fractionCompleted) { progress, _ in
            print("Progress1: \(progress.completedUnitCount) of \(progress.totalUnitCount) = \(progress.fractionCompleted)")
        }

        curl.perform(with: .init(url: .init(string: "http://google.com")!), progress: progress) { data, response, error in
//            print(String(data: data ?? .init(), encoding: .ascii) ?? "(nil)")

            if let response = response as? HTTPURLResponse {
                print("Response1: \(response.url?.absoluteString ?? "(nil)") \(response.statusCode)\nheaders: \(response.allHeaderFields)")
            }

            if let error = error {
                print("Error: \(error)")
            }

            observation1.invalidate()
        }

        let task = curl.task(with: .init(url: .init(string: "https://google.com")!))
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
