import UIKit

import Foundation
import ModelIO
// Create an empty 3D grid with the specified dimensions
func createEmptyGrid(width: Int, height: Int, depth: Int) -> [[[Int]]] {
    return [[[Int]]](repeating: [[Int]](repeating: [Int](repeating: 0, count: depth), count: height), count: width)
}

// Create an occupancy grid from a 3D point cloud
func createOccupancyGrid(pointCloud: [[[Int]]]) -> [[[Int]]] {
    let width = pointCloud.count
    let height = pointCloud[0].count
    let depth = pointCloud[0][0].count
    
    // Create an empty grid with the same dimensions as the point cloud
    var grid = createEmptyGrid(width: width, height: height, depth: depth)
    
    // Loop through the point cloud and set each occupied voxel in the grid to 1
    for x in 0..<width {
        for y in 0..<height {
            for z in 0..<depth {
                if pointCloud[x][y][z] == 1 {
                    grid[x][y][z] = 1
                }
            }
            
        }
       
    }
    return grid
}
let pointCloud = [[[1, 0, 0], [0, 0, 0], [0, 0, 0]],
                         [[0, 0, 0], [0, 1, 0], [0, 0, 0]],
                        [[0, 0, 0], [0, 0, 0], [0, 0, 1]]]
let occupancyGrid = createOccupancyGrid(pointCloud: pointCloud)
print(occupancyGrid)  // Should print [[[1, 0, 0], [0, 0, 0], [0, 0, 0]], [[0, 0, 0], [0, 1, 0], [0, 0, 0]], [[0, 0, 0], [0, 0, 0], [0, 0, 1]]]

