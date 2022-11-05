//
//  CameraSessionDelegate.swift
//  MetalShaderCamera
//
//  Created by Alex Staravoitau on 25/04/2016.
//  Copyright © 2016 Old Yellow Bricks. All rights reserved.
//  License: Apache 2.0

import AVFoundation

/**
 States of capturing session
 
 - Ready: Ready to start capturing
 - Streaming: Capture in progress
 - Stopped: Capturing stopped
 - Waiting: Waiting to get access to hardware
 - Error: An error has occured    
 */
public enum CameraState {
    case ready
    case streaming
    case stopped
    case waiting
    case error
}

/**
 Streaming error
 */
public enum AsCameraError: Error {
    
     // Streaming errors
    case noHardwareAccess
    case failedToAddCaptureInputDevice
    case failedToAddCaptureOutput
    case requestedHardwareNotFound
    case inputDeviceNotAvailable
    case captureSessionRuntimeError

    // Conversion errors
    case failedToCreateTextureCache
    case missingSampleBuffer
    case failedToGetImageBuffer
    case failedToCreateTextureFromImage
    case failedToRetrieveTimestamp
    
    /**
     Indicates if the error is related to streaming the media.
     
     - returns: True if the error is related to streaming, false otherwise
     */
    public func isStreamingError() -> Bool {
        switch self {
        case .noHardwareAccess,
             .failedToAddCaptureInputDevice,
             .failedToAddCaptureOutput,
             .requestedHardwareNotFound,
             .inputDeviceNotAvailable,
             .captureSessionRuntimeError:
            return true
        default:
            return false
        }
    }
    
    public var localizedDescription: String {
        return "\(self)"
    }
}
