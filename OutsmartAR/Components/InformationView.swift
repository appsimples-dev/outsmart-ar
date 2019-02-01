//
//  InformationView.swift
//  OutsmartAR
//
//  Created by Giovanni Gardusi on 01/02/19.
//  Copyright © 2019 Outsmart. All rights reserved.
//

import UIKit

class InformationView: UIView {

    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var illustrationImage: UIImageView!
    
    func setLabel(text: String) {
        descriptionLabel.text = text
        illustrationImage.image = nil
    }
    
    func setImage(url: String) {
        descriptionLabel.text = nil
        let imageData: Data = try! Data(contentsOf: URL(string: url)!)
        illustrationImage.contentMode = .scaleAspectFit
        illustrationImage.image = UIImage(data: imageData)!
    }
}

extension InformationView {
    @available(iOS 10.0, *)
    func asImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { rendererContext in
            layer.render(in: rendererContext.cgContext)
        }
    }
}
