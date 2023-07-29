import Accelerate

func erf(x: Double) -> Double {
    var result: Double = 0.0
    vErf(1, [x], &result)
    return result
}
func gaussianVolume(to p: Double) -> Double {
    let mean = 0.5
    let sigma = sqrt(1/(2 * Double.pi))  // this sigma ensures the area under curve is 1 for our case

    let erf_p = erf((p - mean) / (sigma * sqrt(2)))
    let erf_0 = erf((0 - mean) / (sigma * sqrt(2)))

    return 0.5 * (erf_p - erf_0)
}

func gaussianPDF(x: Double) -> Double {
    let mean = 0.5
    let sigma = sqrt(1/(2 * Double.pi))
    let coeff = 1 / (sigma * sqrt(2 * Double.pi))
    return coeff * exp(-pow(x - mean, 2) / (2 * pow(sigma, 2)))
}

func gaussianVolumeInverse(volume: Double) -> Double {
    let epsilon = 1e-6
    var p = 0.5  // initial guess

    // Newton-Raphson method
    while true {
        let diff = gaussianVolume(to: p) - volume
        if abs(diff) < epsilon {
            break
        }
        p -= diff / gaussianPDF(x: p)
    }

    return p
}
 
