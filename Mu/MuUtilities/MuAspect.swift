//
//  File.swift
//  File
//
//  Created by warren on 8/3/21.
//

import UIKit

/// x,y clips inside width,height
public typealias ClipRect = CGRect

public class MuAspect {

    /** create a clipping rect where x,y is inside boundary, not offset
    - Parameters:
      - from: sourc size to rescale and clip
      - to: destination size in which to fill
     */
    static public func fillClip(from: CGSize, to: CGSize) -> ClipRect {

        let ht = to.height      // height to
        let wt = to.width       // width to
        let rt = wt/ht          // ratio to

        let hf = from.height    // height from
        let wf = from.width     // width from
        let rf = wf/hf          // ratio from

        if rt < rf {

            let h = ht
            let w = wf * (ht/hf)
            let x = (w-wt) / 2
            let y = CGFloat(0)

            return CGRect(x: x, y: y, width: w, height: h)

        } else if rt > rf {

            let w = wt
            let h = hf * (wt/wf)
            let y = (h-ht) / 2
            let x = CGFloat(0)

            return CGRect(x: x, y: y, width: w, height: h)

        } else {

            return CGRect(x: 0, y: 0, width: wt, height: ht)

        }
    }
    /** create a clipping rect where x,y is inside boundary, not offset
     - Parameters:
     - p: point in transform from texture to view coordinates
     - texSize: texture which fills a view, which may be clipped
     - viewSize: view in which tranform texture point
     */
    static public func texturePointToView(_ p: CGPoint, texSize: CGSize, viewSize: CGSize) -> CGPoint {

        let fill = fillClip(from: texSize, to: viewSize)
        let norm = fill.normalize()
        let x0 = p.x / norm.width  / texSize.width
        let y0 = p.y / norm.height / texSize.height
        let x1 = (x0 - norm.minX) * viewSize.width
        let y1 = (y0 - norm.minY) * viewSize.height
        return CGPoint(x: x1, y: y1)
    }

    /** create a clipping rect where x,y is inside boundary, not offset
     - Parameters:
     - p: point in captured in view
     - viewSize: view which captured point in its coordinates
     - texSize: original texture which filled view, which may be clipped
     */
    static public func viewPointToTexture(_ p: CGPoint, viewSize: CGSize, texSize: CGSize) -> CGPoint {
        
        let fill = fillClip(from: texSize, to: viewSize)
        let norm = fill.normalize()
        let x0 = p.x / viewSize.width
        let y0 = p.y / viewSize.height
        let x1 = (x0 + norm.minX) * norm.width * texSize.width
        let y1 = (y0 + norm.minY) * norm.height * texSize.height
        return CGPoint(x: x1, y: y1)
    }
    

    /** translate a point from input `from` which contains self as a ClipRect

     - Parameters:
       - from: the `to` rect that clips this rect
       - p: the point inside the `in` rect
     - returns:
       point adjusted within clipped self

     */
    static public func clipPoint(_ p: CGPoint, from: CGSize, clip: ClipRect) -> CGPoint {

        let hf = from.height    // from height
        let wf = from.width     // from width
        let hc = clip.height    // clip total height
        let wc = clip.width     // clip total width
        let xc = clip.minX      // clip position x
        let yc = clip.minY      // clip position y

        let xx = xc/wc          // normalized x clip
        let ww = 1-(xx*2)       // nomalized width - clipped borders
        let yy = yc/hc          // normalized y clip
        let hh = 1-(yy*2)       // nomalized width - clipped borders

        let pp = CGPoint(x: (xx + (p.x/wf) * ww) * wc,
                         y: (yy + (p.y/hf) * hh) * hc)
        return pp

    }

}
