//
//  ViewController.swift
//  macOS_Example
//
//  Created by Benjamin Erhart on 31.10.24.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import Cocoa
import SwiftyCurl

class ViewController: NSViewController, CurlTaskDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()

        print(SwiftyCurl.libcurlVersion)

        let request = URLRequest(url: .init(string: "http://google.com")!)

        let curl = SwiftyCurl()
        curl.followLocation = true
        curl.delegate = self
        curl.queue = .global(qos: .background)
//        curl.verbose = true

        let progress = Progress()
        let observation1 = progress.observe(\.fractionCompleted) { progress, _ in
            print("Progress1: \(progress.completedUnitCount) of \(progress.totalUnitCount) = \(progress.fractionCompleted)")
        }

        Task {
            curl.userAgent = await SwiftyCurl.defaultUserAgent()

            do {
                let (data, response) = try await curl.perform(with: request, progress: progress)
//                print(String(data: data, encoding: .ascii) ?? "(nil)")

                if let response = response as? HTTPURLResponse {
                    print("Response1: \(response.url?.absoluteString ?? "(nil)") \(response.statusCode)\nheaders: \(response.allHeaderFields)")
                }
            }
            catch {
                print("Error: \(error)")
            }

            observation1.invalidate()

            let task = curl.task(with: request)
            let observation2 = task?.progress.observe(\.fractionCompleted) { progress, _ in
                print("Progress2: \(progress.completedUnitCount) of \(progress.totalUnitCount) = \(progress.fractionCompleted)")
            }

            print("Ticket: \(task?.taskIdentifier ?? UInt.max)")

            do {
                let result = try await task?.resume()
//                print(String(data: result?.0 ?? .init(), encoding: .ascii) ?? "(nil)")

                if let response = result?.1 as? HTTPURLResponse {
                    print("Response2: \(response.url?.absoluteString ?? "(nil)") \(response.statusCode)\nheaders: \(response.allHeaderFields)")
                }
            }
            catch {
                print("Error: \(error)")
            }

            observation2?.invalidate()
        }
    }

    // MARK: - CurlTaskDelegate

    func task(_ task: CurlTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest) -> Bool {
        print("\(task) willPerformHTTPRedirection: \(response), newRequest: \(request)")

        return true
    }

    func task(_ task: CurlTask, isHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest) {
        print("\(task) isHTTPRedirection: \(response), newRequest: \(request)")
    }

    func task(_ task: CurlTask, didReceive challenge: URLAuthenticationChallenge) -> Bool {
        print("\(task) didReceive: \(challenge)")

        return true
    }

    func task(_ task: CurlTask, didReceive response: URLResponse) -> Bool {
        print("\(task) didReceive: \(response)")

        return true
    }

    func task(_ task: CurlTask, didReceive data: Data) -> Bool {
        print("\(task) didReceive: \(data)")

        return true
    }

    func task(_ task: CurlTask, didCompleteWithError error: (any Error)?) {
        print("\(task) didCompleteWithError: \(error?.localizedDescription ?? "(nil)")")
    }
}
