//
//  ARViewController.swift
//  OutsmartAR
//
//  Created by Giovanni Gardusi on 01/02/19.
//  Copyright © 2019 Outsmart. All rights reserved.
//

import UIKit
import ARKit
import Vision

class ARViewController: UIViewController {
    
    var leapFrames = 0
    var discoveredQRCodes: [String] = []
    var informationView: InformationView?
    
    var _detectedAnchor: Any?
    var _sceneView: Any? = {
        if #available(iOS 11.0, *) {
            return ARSCNView(frame: UIScreen.main.bounds)
        }
        return nil
    }()
    
    @available(iOS 11.0, *)
    var sceneView: ARSCNView {
        if let sceneView = _sceneView as? ARSCNView {
            return sceneView
        }
        fatalError("ARSCNView was not created")
    }
    
    @available(iOS 11.0, *)
    var detectedAnchor: ARAnchor? {
        return _detectedAnchor as? ARAnchor
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 11.0, *) {
            view.addSubview(sceneView)
            informationView = Bundle.main.loadNibNamed("InformationView", owner: nil, options: nil)?.first as? InformationView
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if #available(iOS 11.0, *) {
            sceneView.delegate = self
            let configuration = ARWorldTrackingConfiguration()
            configuration.planeDetection = .horizontal
            sceneView.session.run(configuration)
            sceneView.session.delegate = self
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if #available(iOS 11.0, *) {
            sceneView.session.pause()
        }
    }
}

@available(iOS 11.0, *)
extension ARViewController: ARSCNViewDelegate {
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        DispatchQueue.main.async {
            self.attachCustomNode(to: node, for: anchor)
        }
    }

    func attachCustomNode(to node: SCNNode, for anchor: ARAnchor) {

        guard let view = informationView, detectedAnchor?.identifier == anchor.identifier else { return }

        let plane = SCNPlane(width: 0.1, height: 0.1)
        let imageMaterial = SCNMaterial()
        imageMaterial.diffuse.contents = view.asImage().rotate(radians: -1.57)
        plane.materials = [imageMaterial]
        node.addChildNode(SCNNode(geometry: plane))
    }
}

@available(iOS 11.0, *)
extension ARViewController: ARSessionDelegate {
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        guard leapFrames >= 30 else {
            leapFrames += 1
            return
        }
        leapFrames = 0
        
        let image = CIImage(cvPixelBuffer: frame.capturedImage)
        let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: nil)

        if let features = detector?.features(in: image) as? [CIQRCodeFeature] {
            features.forEach({ feature in
                let message = feature.messageString ?? ""
                if !discoveredQRCodes.contains(message) {
                    discoveredQRCodes.append(message)
                    let transform = frame.camera.transform
                    var translation = matrix_identity_float4x4
                    
                    translation.columns.3.z = -0.2
                    _detectedAnchor = ARAnchor(transform: transform * translation)
                    if let anchor = detectedAnchor {
                        if message.hasSuffix(".pnj") {
                            self.informationView?.setImage(url: message)
                        } else {
                            self.informationView?.setLabel(text: message)
                        }
                        self.sceneView.session.add(anchor: anchor)
                    }
                }
            })
        }
    }
}
