//
//  ProgressView.swift
//  CustomProgressBar
//
//  Created by Sztanyi Szabolcs on 16/10/14.
//  Copyright (c) 2014 Sztanyi Szabolcs. All rights reserved.
//

import UIKit

class ProgressView: UIView {
    
    // the layer that shows the actual progress
    private let progressLayer: CAShapeLayer = CAShapeLayer()
    
    private var progressLabel: UILabel = UILabel()
    private var sizeProgressLabel : UILabel = UILabel()
    
    // layer to show the dashed circle layer
    private var dashedLayer: CAShapeLayer = CAShapeLayer()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    private func setupView() {
        backgroundColor = UIColor.clearColor()
        createProgressLayer()
    }
    
    private func createProgressLayer() {
        let startAngle = CGFloat(M_PI_2)
        let endAngle = CGFloat(M_PI * 2 + M_PI_2)
        let centerPoint = CGPointMake(CGRectGetWidth(frame)/2 , CGRectGetHeight(frame)/2)
        
        progressLayer.path = UIBezierPath(arcCenter:centerPoint, radius: CGRectGetWidth(frame)/2 - 10.0, startAngle:startAngle, endAngle:endAngle, clockwise: true).CGPath
        progressLayer.backgroundColor = UIColor.clearColor().CGColor
        progressLayer.fillColor = nil
        progressLayer.strokeColor = UIColor(red:0.31, green:0.31, blue:0.31, alpha:1.0).CGColor
        progressLayer.lineWidth = 2.0
        progressLayer.strokeStart = 0.0
        progressLayer.lineCap = kCALineCapRound
        progressLayer.strokeEnd = 0.0
        layer.addSublayer(progressLayer)
        
    }  
    
    func animateProgressViewToProgress(progress: Float) {
        let animation = CABasicAnimation(keyPath: "strokeEnd")
        animation.fromValue = CGFloat(progressLayer.strokeEnd)
        animation.toValue = CGFloat(progress)
        animation.duration = 0.2
        animation.fillMode = kCAFillModeForwards
        progressLayer.strokeEnd = CGFloat(progress)
        progressLayer.addAnimation(animation, forKey: "animation")
    }
    
    func updateProgressViewLabelWithProgress(percent: Float) {
        progressLabel.text = NSString(format: "%.0f %@", percent, "%") as String
    }
    
    func updateProgressViewWith(totalSent: Float, totalFileSize: Float) {
        sizeProgressLabel.text = NSString(format: "%.1f MB / %.1f MB", convertFileSizeToMegabyte(totalSent), convertFileSizeToMegabyte(totalFileSize)) as String
    }
    
    private func convertFileSizeToMegabyte(size: Float) -> Float {
        return (size / 1024) / 1024
    }
    
    func hideProgressView() {
        progressLayer.strokeEnd = 0.0
        progressLayer.removeAllAnimations()
    }
    
    override func animationDidStop(anim: CAAnimation, finished flag: Bool) {
        hideProgressView()
    }
}


