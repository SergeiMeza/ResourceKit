//
//  AppendableProtocols.swift
//  ResourceKit
//
//  Created by Yudai.Hirose on 2017/09/23.
//  Copyright © 2017年 kingkong999yhirose. All rights reserved.
//

import Foundation

public protocol AppendableForPaths: class {
    func appendFileReferencePaths(urls: [URL])
    func appendLocalizedPaths(urls: [URL])
}

public protocol AppendableForXibs: class {
    func appendXib(_ xib: Xib)
}

public protocol AppendableForStoryboard: class {
    func appendTableViewCell(_ className: String, reusableIdentifier: String)
    func appendCollectionViewCell(_ className: String, reusableIdentifier: String)
    func appendViewControllerInfoReference(_ className: String?, viewControllerInfo: ViewControllerInfoOfStoryboard)
}
