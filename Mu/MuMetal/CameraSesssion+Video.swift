//
//  CameraSesssion+Video.swift
//  MuseSky
//
//  Created by warren on 11/12/19.
//  Copyright © 2019 DeepMuse All rights reserved.
//

import Foundation
import AVFoundation

extension CameraSession: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    /**
     Converts a sample buffer received from camera to a Metal texture

     - Parameters:
       - sampleBuffer: Sample buffer
       - textureCache: Texture cache
       - planeIndex:   Index of the plane for planar buffers. Defaults to 0.
       - pixelFormat:  Metal pixel format. Defaults to `.BGRA8Unorm`.

     - returns: Metal texture or nil
    */
    private func texture(sampleBuffer: CMSampleBuffer?,
                         textureCache: CVMetalTextureCache?,
                         planeIndex: Int = 0,
                         pixelFormat: MTLPixelFormat = .bgra8Unorm) throws -> MTLTexture
    {
        guard let sampleBuffer = sampleBuffer else { throw AsCameraError.missingSampleBuffer }
        guard let textureCache = textureCache else { throw AsCameraError.failedToCreateTextureCache }
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { throw AsCameraError.failedToGetImageBuffer }

        let isPlanar = CVPixelBufferIsPlanar(imageBuffer)
        let width = isPlanar ? CVPixelBufferGetWidthOfPlane(imageBuffer, planeIndex) : CVPixelBufferGetWidth(imageBuffer)
        let height = isPlanar ? CVPixelBufferGetHeightOfPlane(imageBuffer, planeIndex) : CVPixelBufferGetHeight(imageBuffer)

        var imageTexture: CVMetalTexture?
        let result = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, textureCache, imageBuffer, nil, pixelFormat, width, height, planeIndex, &imageTexture)
        guard
            let imageTexture = imageTexture,
            let texture = CVMetalTextureGetTexture(imageTexture),
            result == kCVReturnSuccess
        else {
            throw AsCameraError.failedToCreateTextureFromImage
        }
        return texture
    }

    /**
     Strips out the timestamp value out of the sample buffer received from camera.

     - parameter sampleBuffer: Sample buffer with the frame data
     - returns: Double value for a timestamp in seconds or nil
     - throws: failed to retrieve timestamp
     */
    private func timestamp(sampleBuffer: CMSampleBuffer?) throws -> Double {
        guard let sampleBuffer = sampleBuffer else { throw AsCameraError.missingSampleBuffer }

        let time = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        guard time != CMTime.invalid else { throw AsCameraError.failedToRetrieveTimestamp }
        return (Double)(time.value) / (Double)(time.timescale);
    }

    public func captureOutput(_ captureOutput: AVCaptureOutput,
                              didOutput sampleBuffer: CMSampleBuffer,
                              from connection: AVCaptureConnection) {
        do {
            let textureRGB = try texture(sampleBuffer: sampleBuffer, textureCache: textureCache)
            let _ = try self.timestamp(sampleBuffer: sampleBuffer)
            self.camTex = textureRGB
        }
        catch let error as AsCameraError {
            self.handleError(error)
        }
        catch {
            /// only throw `AsCameraError` errors
        }
    }

}
