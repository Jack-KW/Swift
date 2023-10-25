import Foundation

#if os(iOS)
import UIKit
public typealias CPColor = UIColor
#elseif os(OSX)
import Cocoa
public typealias CPColor = NSColor
#endif

extension CPColor {
    
    // the following code was copied from https://github.com/jathu/sweetercolor/blob/master/Sweetercolor/Sweetercolor.swift
    // it is also inspired by https://stackoverflow.com/questions/64963538/how-can-i-know-the-difference-in-percentage-between-one-uicolor-and-another
  
    // **Note**: There is a tiny update from the original copy. In var LAB, I updated pow(c, 1/3) to pow(c, Double(1)/3) 
  
    // To test the performance of this CIEDE2000 implementation, I wrote a UI to use this extension to compare different
    // colors, which is in the same directory containing this file. The result is promising.
    
    /**
        Detemine the distance between two colors based on the way humans perceive them.
        Uses the Sharma 2004 alteration of the CIEDE2000 algorithm.
     
        - parameter compare color: A UIColor to compare.
     
        - returns: A CGFloat representing the deltaE
    */
    func CIEDE2000(compare color: UIColor) -> CGFloat {
        // the original algorithm is explained at: http://www.ece.rochester.edu/~gsharma/ciede2000/ciede2000noteCRNA.pdf
        
        func rad2deg(r: CGFloat) -> CGFloat {
            return r * CGFloat(180/Double.pi)
        }
        
        func deg2rad(d: CGFloat) -> CGFloat {
            return d * CGFloat(Double.pi/180)
        }
        
        // step 1. init the weighting factors k_l, k_c, k_h
        let k_l = CGFloat(1), k_c = CGFloat(1), k_h = CGFloat(1)
        
        // step 2. calculate the LAB values based the sRGB value of this UIColor
        let LAB1 = self.LAB
        let L_1 = LAB1[0], a_1 = LAB1[1], b_1 = LAB1[2]
        
        let LAB2 = color.LAB
        let L_2 = LAB2[0], a_2 = LAB2[1], b_2 = LAB2[2]
        
        // step 3. calculate C_i, h_i
        let C_1ab = sqrt(pow(a_1, 2) + pow(b_1, 2))
        let C_2ab = sqrt(pow(a_2, 2) + pow(b_2, 2))
        let C_ab  = (C_1ab + C_2ab)/2
        
        let G = 0.5 * (1 - sqrt(pow(C_ab, 7)/(pow(C_ab, 7) + pow(25, 7))))
        let a_1_p = (1 + G) * a_1 // p means the prime symbol
        let a_2_p = (1 + G) * a_2
        
        let C_1_p = sqrt(pow(a_1_p, 2) + pow(b_1, 2))
        let C_2_p = sqrt(pow(a_2_p, 2) + pow(b_2, 2))
        
        // Read note 1 (page 23) for clarification on radians to hue degrees
        // Since atan2 fucntion returns an angular value in radians ranging from -π to π. This must
        // be converted to a hue angle in degrees between 0 and 360 by addition of 2π to nagative
        // hue angles, followed by a multiplication by 180/π to convert from radians to degrees.
        // 180 / π means that half a circle in degrees (180 degrees) corresponds to half a circle in radians (π radians)
        let h_1_p = (b_1 == 0 && a_1_p == 0) ? 0 : (atan2(b_1, a_1_p) + CGFloat(2 * Double.pi)) * CGFloat(180/Double.pi)
        let h_2_p = (b_2 == 0 && a_2_p == 0) ? 0 : (atan2(b_2, a_2_p) + CGFloat(2 * Double.pi)) * CGFloat(180/Double.pi)
        
        // step 4. calculate delta L prime, delta C prime, delta H prime
        let deltaL_p = L_2 - L_1
        let deltaC_p = C_2_p - C_1_p
        
        var h_p: CGFloat = 0
        if (C_1_p * C_2_p) == 0 {
            h_p = 0
        } else if Swift.abs(h_2_p - h_1_p) <= 180 {
            h_p = h_2_p - h_1_p
        } else if (h_2_p - h_1_p) > 180 {
            h_p = h_2_p - h_1_p - 360
        } else if (h_2_p - h_1_p) < -180 {
            h_p = h_2_p - h_1_p + 360
        }
        
        let deltaH_p = 2 * sqrt(C_1_p * C_2_p) * sin(deg2rad(d: h_p/2))
        
        // step 5. calculate CIEDE2000 Color-Difference delta E 00
        let L_p = (L_1 + L_2)/2
        let C_p = (C_1_p + C_2_p)/2
        
        var h_p_bar: CGFloat = 0
        if (h_1_p * h_2_p) == 0 {
            h_p_bar = h_1_p + h_2_p
        } else if Swift.abs(h_1_p - h_2_p) <= 180 {
            h_p_bar = (h_1_p + h_2_p)/2
        } else if Swift.abs(h_1_p - h_2_p) > 180 && (h_1_p + h_2_p) < 360 {
            h_p_bar = (h_1_p + h_2_p + 360)/2
        } else if Swift.abs(h_1_p - h_2_p) > 180 && (h_1_p + h_2_p) >= 360 {
            h_p_bar = (h_1_p + h_2_p - 360)/2
        }
        
        let T1 = cos(deg2rad(d: h_p_bar - 30))
        let T2 = cos(deg2rad(d: 2 * h_p_bar))
        let T3 = cos(deg2rad(d: (3 * h_p_bar) + 6))
        let T4 = cos(deg2rad(d: (4 * h_p_bar) - 63))
        let T = 1 - rad2deg(r: 0.17 * T1) + rad2deg(r: 0.24 * T2) - rad2deg(r: 0.32 * T3) + rad2deg(r: 0.20 * T4)
        
        let deltaTheta = 30 * exp(-pow((h_p_bar - 275)/25, 2))
        let R_c = 2 * sqrt(pow(C_p, 7)/(pow(C_p, 7) + pow(25, 7)))
        let S_l =  1 + ((0.015 * pow(L_p - 50, 2))/sqrt(20 + pow(L_p - 50, 2)))
        let S_c = 1 + (0.045 * C_p)
        let S_h = 1 + (0.015 * C_p * T)
        let R_t = -sin(deg2rad(d: 2 * deltaTheta)) * R_c
        
        // Calculate total
        
        let P1 = deltaL_p/(k_l * S_l)
        let P2 = deltaC_p/(k_c * S_c)
        let P3 = deltaH_p/(k_h * S_h)
        let deltaE = sqrt(pow(P1, 2) + pow(P2, 2) + pow(P3, 2) + (R_t * P2 * P3))
        
        return deltaE
    }
    
    /**
        Get the red, green, blue and alpha values.
     
        - returns: An array of four CGFloat numbers from [0, 1] representing RGBA respectively.
    */
    var RGBA: [CGFloat] {
        var R: CGFloat = 0
        var G: CGFloat = 0
        var B: CGFloat = 0
        var A: CGFloat = 0
        self.getRed(&R, green: &G, blue: &B, alpha: &A)
        return [R,G,B,A]
    }
    
    /**
        Get the CIE XYZ values.
     
        - returns: An array of three CGFloat numbers representing XYZ respectively.
    */
    var XYZ: [CGFloat] {
        // https://www.image-engineering.de/library/technotes/958-how-to-convert-between-srgb-and-ciexyz
        // http://www.easyrgb.com/index.php?X=MATH&H=02#text2
        
        let RGBA = self.RGBA
        
        func XYZ_helper(c: CGFloat) -> CGFloat {
            return (0.04045 < c ? pow((c + 0.055)/1.055, 2.4) : c/12.92) * 100
        }
        
        let R = XYZ_helper(c: RGBA[0])
        let G = XYZ_helper(c: RGBA[1])
        let B = XYZ_helper(c: RGBA[2])
        
        let X: CGFloat = (R * 0.4124564) + (G * 0.3575761) + (B * 0.1804375)
        let Y: CGFloat = (R * 0.2126729) + (G * 0.7151522) + (B * 0.0721750)
        let Z: CGFloat = (R * 0.0193339) + (G * 0.1191920) + (B * 0.9503041)
        
        return [X, Y, Z]
    }
    
    /**
        Get the CIE L*ab values.
     
        - returns: An array of three CGFloat numbers representing LAB respectively.
    */
    var LAB: [CGFloat] {
        // http://www.easyrgb.com/index.php?X=MATH&H=07#text7
        
        let XYZ = self.XYZ
        
        func LAB_helper(c: CGFloat) -> CGFloat {
            return 0.008856 < c ? pow(c, Double(1)/3) : ((7.787 * c) + (16/116))
        }
        
        let referenceX = 95.047
        let referenceY = 100.0
        let referenceZ = 108.883
        let X: CGFloat = LAB_helper(c: XYZ[0] / referenceX)
        let Y: CGFloat = LAB_helper(c: XYZ[1] / referenceY)
        let Z: CGFloat = LAB_helper(c: XYZ[2] / referenceZ)
        
        let L: CGFloat = (116 * Y) - 16
        let A: CGFloat = 500 * (X - Y)
        let B: CGFloat = 200 * (Y - Z)
        
        return [L, A, B]
    }
}
