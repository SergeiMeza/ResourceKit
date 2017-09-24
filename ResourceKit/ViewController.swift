//
//  viewcontroller.swift
//  ResourceKit
//
//  Created by Hirose.Yudai on 2016/04/06.
//  Copyright © 2016年 Hirose.Yudai. All rights reserved.
//

import Foundation

struct ViewControllerInfoOfStoryboard {
    let viewControllerId: String
    let storyboardName: String
    let initialViewControllerId: String?
    let storyboardIdentifier: String
    
    var segues: [String] = []
    
    init(viewControllerId: String,
         storyboardName: String,
         initialViewControllerId: String?,
         storyboardIdentifier: String) {
        self.viewControllerId = viewControllerId
        self.storyboardName = storyboardName
        self.initialViewControllerId = initialViewControllerId
        self.storyboardIdentifier = storyboardIdentifier
    }
    
    var isInitial: Bool {
        return viewControllerId == initialViewControllerId
    }
}

class ViewController {
    var storyboardInfos: [ViewControllerInfoOfStoryboard] = []
    let className: ResourceType
    let superClassName: ResourceType 
    
    fileprivate lazy var hasSuperClass: Bool = {
        return self.superClass != nil
    }()
    
    fileprivate lazy var superClass: ViewController? = ProjectResource
        .shared
        .viewControllers
        .filter ({ $0.className == self.superClassName })
        .first
    
    init(className: String, superClassName: String = "") throws {
        self.className = try ResourceType(viewController: className)
        self.superClassName = try ResourceType(viewController: superClassName)
    }
    
    var name: String {
        return className.name
    }
}
