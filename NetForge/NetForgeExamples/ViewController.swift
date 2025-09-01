//
//  ViewController.swift
//  NetForgeExamples
//
//  Created by GPS on 28/01/25.
//

import UIKit
import NetForge


struct PostDto: Codable {
    let userId: Int?
    let id: Int?
    let title: String?
    let completed: Bool?
}
struct PostRequestBuilder: RequestBuilder {
    var body: Data?
    
    var baseURL: String? {
        "https://jsonplaceholder.typicode.com/"
    }
    
    var path: String { "todos" }
    
    var method: HTTPMethod { .post }
}

class ViewController: UIViewController {
    
    private let networkManager = NetworkManager()
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        Task {
            do {
                var request = PostRequestBuilder()
                request.body = try JSONEncoder().encode(PostDto(userId: 1, id: 1, title: "foo", completed: false))
                let dto: PostDto = try await networkManager.sendAsyncRequest(from: request)
                print("DTO:\(dto)")
            } catch {
                print("Error:\(error.localizedDescription)")
            }
        }
    }


}

