func rayBoxIntersection(origin: [Double], direction: [Double], vmin: [Double], vmax: [Double]) -> (flag: Bool, tmin: Double) {
    var tmin: Double
    var tmax: Double
    
    if direction[0] >= 0 {
        tmin = (vmin[0] - origin[0]) / direction[0]
        tmax = (vmax[0] - origin[0]) / direction[0]
    } else {
        tmin = (vmax[0] - origin[0]) / direction[0]
        tmax = (vmin[0] - origin[0]) / direction[0]
    }

    if direction[1] >= 0 {
        let tymin = (vmin[1] - origin[1]) / direction[1]
        let tymax = (vmax[1] - origin[1]) / direction[1]

        if tmin > tymax || tymin > tmax {
            return (false, -1)
        }

        if tymin > tmin {
            tmin = tymin
        }

        if tymax < tmax {
            tmax = tymax
        }
    }

    if direction[2] >= 0 {
        let tzmin = (vmin[2] - origin[2]) / direction[2]
        let tzmax = (vmax[2] - origin[2]) / direction[2]

        if tmin > tzmax || tzmin > tmax {
            return (false, -1)
        }

        if tzmin > tmin {
            tmin = tzmin
        }

        if tzmax < tmax {
            tmax = tzmax
        }
    }
    
    return (true, tmin)
}


//let origin = [0, 0, 0]
//let direction = [1, 1, 1]
//let vmin = [-1, -1, -1]
//let vmax = [1, 1, 1]

//let result = rayBoxIntersection(origin: origin, direction: direction, vmin: vmin, vmax: vmax)

// if result.flag == true {
//     print("The ray intersects the box at a distance of \(result.tmin) from the origin.")
// } else {
//     print("The ray does not intersect the box.")
// }
