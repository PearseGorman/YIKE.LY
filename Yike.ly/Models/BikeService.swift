//
//  BikeService.swift
//  Yike.ly
//
//  Created by Pearse Gorman on 3/24/26.
//

import Foundation

class BikeService {
    func fetchLocation(for bikeId: Int, completion: @escaping (BikeLocation?) -> Void) {
        let urlString = "http://51.79.65.180/get_bike_location.php?bike_id=\(bikeId)"
        guard let url = URL(string: urlString) else { return }

        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data else {
                completion(nil)
                return
            }
            
            // Turn JSON into a Swift Object
            let location = try? JSONDecoder().decode(BikeLocation.self, from: data)
            
            // Send the result back to the GUI
            DispatchQueue.main.async {
                completion(location)
            }
        }.resume()
    }
}
