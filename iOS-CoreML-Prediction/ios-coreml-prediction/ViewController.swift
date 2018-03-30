//
//  ViewController.swift
//  ios-coreml-prediction
//
//  Created by Jakub Tlach on 11/22/17.
//  Copyright © 2017 Jakub Tlach. All rights reserved.
//

import UIKit
import CoreML

class ViewController: UIViewController {
	
	@IBOutlet weak var drawView: DrawView!
	@IBOutlet weak var predictLabel: UILabel!
	
	let model = KerasMnist()
	var inputImage: CGImage!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.
		predictLabel.isHidden = true
	}
	
	@IBAction func tappedClear(_ sender: Any) {
		drawView.lines = []
		drawView.setNeedsDisplay()
		predictLabel.isHidden = true
	}
	
	@IBAction func tappedDetect(_ sender: Any) {
		let context = drawView.getViewContext()
		inputImage = context?.makeImage()
		let pixelBuffer = UIImage(cgImage: inputImage).pixelBuffer()
		
		
		
		let output = try? model.prediction(image: pixelBuffer!)
		predictLabel.text = output?.classLabel
		predictLabel.isHidden = false
	}
	
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	
}

extension UIImage {
	func pixelBuffer() -> CVPixelBuffer? {
		let width = self.size.width
		let height = self.size.height
		let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
					 kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
		var pixelBuffer: CVPixelBuffer?
		let status = CVPixelBufferCreate(kCFAllocatorDefault,
										 Int(width),
										 Int(height),
										 kCVPixelFormatType_OneComponent8,
										 attrs,
										 &pixelBuffer)
		
		guard let resultPixelBuffer = pixelBuffer, status == kCVReturnSuccess else {
			return nil
		}
		
		CVPixelBufferLockBaseAddress(resultPixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
		let pixelData = CVPixelBufferGetBaseAddress(resultPixelBuffer)
		
		let grayColorSpace = CGColorSpaceCreateDeviceGray()
		guard let context = CGContext(data: pixelData,
									  width: Int(width),
									  height: Int(height),
									  bitsPerComponent: 8,
									  bytesPerRow: CVPixelBufferGetBytesPerRow(resultPixelBuffer),
									  space: grayColorSpace,
									  bitmapInfo: CGImageAlphaInfo.none.rawValue) else {
										return nil
		}
		
		context.translateBy(x: 0, y: height)
		context.scaleBy(x: 1.0, y: -1.0)
		
		UIGraphicsPushContext(context)
		self.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
		UIGraphicsPopContext()
		CVPixelBufferUnlockBaseAddress(resultPixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
		
		return resultPixelBuffer
	}
	
	func scaleImage(toSize newSize: CGSize) -> UIImage? {
		let newRect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height).integral
		UIGraphicsBeginImageContextWithOptions(newSize, false, 0)
		if let context = UIGraphicsGetCurrentContext() {
			context.interpolationQuality = .high
			let flipVertical = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: newSize.height)
			context.concatenate(flipVertical)
			context.draw(self.cgImage!, in: newRect)
			let newImage = UIImage(cgImage: context.makeImage()!)
			UIGraphicsEndImageContext()
			return newImage
		}
		return nil
	}
}

