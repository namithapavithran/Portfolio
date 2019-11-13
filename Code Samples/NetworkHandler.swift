//
//  NetworkHandler.swift
//  Foodist
//
//  Created by Namitha Pavithran on 18/07/2019.
//

import Foundation

enum NetworkError: Error {
    case networkError(String)
}

struct NetworkHandler {

    func getAPIData<T: Codable>(_ url: String, completion: @escaping (Result<T, NetworkError>) -> Void) {
        let APIKey = "548dcfd5b3msha4dd0fe2766d521p19675djsne07dbbe555fe"
        let hostHeader = "spoonacular-recipe-food-nutrition-v1.p.rapidapi.com"
        let session = URLSession.shared
        guard
            let url = URL(string: url)
            else { return }
        var request = URLRequest(url: url)
        request.addValue(APIKey, forHTTPHeaderField: "X-RapidAPI-Key")
        request.addValue(hostHeader, forHTTPHeaderField: "X-RapidAPI-Host")
        let task = session.dataTask(with: request) { (data, _, error) in
            if error == nil {
                if let data = data {
                    let result: Result<T, Error> = self.decode(data: data)

                    switch result {
                    case .failure(let error):
                        print(error)
                    case .success(let value):
                        completion(.success(value))
                    }
                }
            } else {
                guard let error = error else { return }
                completion(.failure(.networkError(error.localizedDescription)))
            }

        }
        task.resume()
    }

    private func decode<CodableStruct: Codable> (data: Data) -> Result<CodableStruct, Error> {

        do {
            let decoder = JSONDecoder()
            let decodedResult = try decoder.decode(CodableStruct.self, from: data)
            return .success(decodedResult)
        } catch let error {
            print("error in decoding for ", CodableStruct.self)
            return .failure(error)
        }
    }
}
