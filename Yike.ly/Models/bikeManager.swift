//
//  bikeManager.swift
//  Yike.ly
//
//  Created by Pearse Gorman on 4/1/26.
//

import SwiftUI
import Combine

class BikeManager: ObservableObject {
    @Published var bikes: [Bike] = []
    
    // Call this to refresh all bikes from your server
    func loadBikesFromServer() {
        // Note: You might need to create a new PHP script 'get_all_bikes.php'
        // to return the whole list, or loop through IDs like this:
        let url = URL(string: "http://51.79.65.180/get_bike_location.php?bike_id=1")!
        
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data else { return }
            do {
                let dto = try JSONDecoder().decode(BikeDTO.self, from: data)
                DispatchQueue.main.async {
                    // This uses your partner's existing convenience init!
                    let newBike = Bike(from: dto)
                    
                    // Update the list (or find the specific bike to update)
                    if let index = self.bikes.firstIndex(where: { $0.id == newBike.id }) {
                        self.bikes[index].coordinate = newBike.coordinate
                    } else {
                        self.bikes.append(newBike)
                    }
                }
            } catch {
                print("Decoding error: \(error)")
            }
        }.resume()
    }
}
