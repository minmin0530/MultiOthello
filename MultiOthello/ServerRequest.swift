//
//  ServerRequest.swift
//  MultiOthello
//
//  Created by 泉芳樹 on 2022/01/03.
//

import Foundation

class ServerRequest {
    func sendServerRequest(urlString: String, params: [String:Any], completion: @escaping (_: Data) -> Void){
        let request = NSMutableURLRequest(url: URL(string: urlString)!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        do{
            request.httpBody = try JSONSerialization.data(withJSONObject: params, options: .prettyPrinted)
            let task:URLSessionDataTask = URLSession.shared.dataTask(with: request as URLRequest, completionHandler: {(data,response,error) -> Void in
                if error == nil {
                    completion(data!)
                } else {
                    print("server error:\(String(describing:error))")
                    return
                }
            })
            task.resume()
        }catch{
            print("error:\(error)")
        }
    }

    func sendServerGetRequest(urlString: String, completion: @escaping (_: Data) -> Void){
        let request = NSMutableURLRequest(url: URL(string: urlString)!)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let task: URLSessionDataTask = URLSession.shared.dataTask(with: request as URLRequest, completionHandler: {(data,response,error) -> Void in
            if error == nil {
                completion(data!)
            } else {
                print("server error:\(String(describing:error))")
                return
            }
        })
        task.resume()
    }
}
