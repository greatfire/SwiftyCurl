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

        var request = URLRequest(url: .init(string: "http://die.netzarchitekten.com")!)
//        request.setValue("benjaminerhart.com", forHTTPHeaderField: "Host")

        let curl = SwiftyCurl()
        curl.followLocation = true
        curl.queue = .global(qos: .background)

        let progress = Progress()
        let observation = progress.observe(\.fractionCompleted) { progress, _ in
            print("Progress: \(progress.completedUnitCount)")
        }

        curl.perform(with: request, progress: progress) { data, response, error in
            print(String(data: data ?? .init(), encoding: .utf8) ?? "(nil)")

            if let response = response as? HTTPURLResponse {
                print("Response: \(response.url) \(response.statusCode)\nheaders: \(response.allHeaderFields)")
            }

            if let error = error {
                print("Error: \(error)")
            }
        }
    }
}
