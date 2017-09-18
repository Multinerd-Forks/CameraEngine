import UIKit
import AVFoundation

public typealias blockCompletionDetectionFace = (_ face: AVMetadataFaceObject) -> (Void)
public typealias blockCompletionDetectionCode = (_ code: AVMetadataMachineReadableCodeObject) -> (Void)

public enum CameraEngineCaptureOutputDetection {
    case face
    case qrCode
    case barcode
    case none

    func foundationCaptureOutputDetection() -> [AVMetadataObject.ObjectType] {

        switch self {
            case .face: return [ AVMetadataObject.ObjectType.face ]
            case .qrCode: return [ AVMetadataObject.ObjectType.qr ]
            case .barcode: return [
                AVMetadataObject.ObjectType.upce,
                AVMetadataObject.ObjectType.code39,
                AVMetadataObject.ObjectType.code39Mod43,
                AVMetadataObject.ObjectType.ean13,
                AVMetadataObject.ObjectType.ean8,
                AVMetadataObject.ObjectType.code93,
                AVMetadataObject.ObjectType.code128,
                AVMetadataObject.ObjectType.pdf417,
                AVMetadataObject.ObjectType.aztec
            ]
            case .none: return []
        }
    }

    public static func availableDetection() -> [CameraEngineCaptureOutputDetection] {

        return [
            .face,
            .qrCode,
            .barcode,
            .none
        ]
    }

    public func description() -> String {

        switch self {
            case .face: return "Face detection"
            case .qrCode: return "QRCode detection"
            case .barcode: return "Barcode detection"
            case .none: return "No detection"
        }
    }
}

class CameraEngineMetadataOutput: NSObject, AVCaptureMetadataOutputObjectsDelegate {

    private var metadataOutput: AVCaptureMetadataOutput?

    private var currentMetadataOutput: CameraEngineCaptureOutputDetection = .none

    var previewLayer: AVCaptureVideoPreviewLayer?

    var blockCompletionFaceDetection: blockCompletionDetectionFace?

    var blockCompletionCodeDetection: blockCompletionDetectionCode?

    var shapeLayer = CAShapeLayer()

    var layer2 = CALayer()

    func configureMetadataOutput(_ session: AVCaptureSession, sessionQueue: DispatchQueue, metadataType: CameraEngineCaptureOutputDetection) {

        if self.metadataOutput == nil {
            self.metadataOutput = AVCaptureMetadataOutput()
            self.metadataOutput?.setMetadataObjectsDelegate(self, queue: sessionQueue)
            if session.canAddOutput(self.metadataOutput!) {
                session.addOutput(self.metadataOutput!)
            }
        }
        self.metadataOutput!.metadataObjectTypes = metadataType.foundationCaptureOutputDetection()
        self.currentMetadataOutput = metadataType
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {

        guard let previewLayer = self.previewLayer else {
            return
        }

        for metadataObject in metadataObjects {
            switch metadataObject.type {
                case .face:
                    if let block = self.blockCompletionFaceDetection, self.currentMetadataOutput == .face {
                        let transformedMetadataObject = previewLayer.transformedMetadataObject(for: metadataObject)
                        block(transformedMetadataObject as! AVMetadataFaceObject)
                    }
                case .qr:
                    if let block = self.blockCompletionCodeDetection, self.currentMetadataOutput == .qrCode {
                        let transformedMetadataObject = previewLayer.transformedMetadataObject(for: metadataObject)
                        block(transformedMetadataObject as! AVMetadataMachineReadableCodeObject)
                    }
                case AVMetadataObject.ObjectType.upce,
                     AVMetadataObject.ObjectType.code39,
                     AVMetadataObject.ObjectType.code39Mod43,
                     AVMetadataObject.ObjectType.ean13,
                     AVMetadataObject.ObjectType.ean8,
                     AVMetadataObject.ObjectType.code93,
                     AVMetadataObject.ObjectType.code128,
                     AVMetadataObject.ObjectType.pdf417,
                     AVMetadataObject.ObjectType.aztec:
                    if let block = self.blockCompletionCodeDetection, self.currentMetadataOutput == .barcode {
                        let transformedMetadataObject = previewLayer.transformedMetadataObject(for: metadataObject)
                        block(transformedMetadataObject as! AVMetadataMachineReadableCodeObject)
                    }
                default:break
            }
        }
    }

}
