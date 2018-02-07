//
//  ViewControllerOutput.swift
//  ResourceKit
//
//  Created by Yudai.Hirose on 2017/09/23.
//  Copyright © 2017年 kingkong999yhirose. All rights reserved.
//

import Foundation

public protocol ViewControllerOutput: Output {
    
}

public struct ViewControllerOutputImpl: ViewControllerOutput {
    let name: String
    let storyboardInfos: [ViewControllerInfoOfStoryboard]
    let hasSuperClass: Bool
    let superClassStoryboardInfos: [ViewControllerInfoOfStoryboard]
    let config: Config
    
    public fileprivate(set) var declaration: String = ""
    var seguesForGenerateStruct: [String] {
        return storyboardInfos.flatMap { $0.segues }
    }
    
    init(
        name: String,
        storyboardInfos: [ViewControllerInfoOfStoryboard],
        hasSuperClass: Bool,
        superClassStoryboardInfos: [ViewControllerInfoOfStoryboard],
        config: Config
        ) {
        self.name = name
        self.storyboardInfos = storyboardInfos
        self.hasSuperClass = hasSuperClass
        self.superClassStoryboardInfos = superClassStoryboardInfos
        self.config = config
        
        self.declaration = generateDeclarationIfStoryboardInfoExists()
    }
}

// MARK: - Private
fileprivate extension ViewControllerOutputImpl {
    func generateDeclarationIfStoryboardInfoExists() -> String {
        if storyboardInfos.isEmpty {
            return ""
        }
        
        return generateDeclaration()
    }
    
    func generateDeclaration() -> String {
        let begin = "extension \(name) {" + Const.newLine
        let viewControllerAndPerformSegueFunctions = storyboardInfos
            .flatMap {
                let viewControllerFunctions = generateForInsitantiateViewController(from: $0)
                let performSeguesFunctions = generateForPerformSegue(from: $0)
                
                if viewControllerFunctions.isEmpty {
                    return performSeguesFunctions.appendNewLineIfNotEmpty()
                }
                
                if performSeguesFunctions.isEmpty {
                    return viewControllerFunctions.appendNewLineIfNotEmpty()
                }
                
                return viewControllerFunctions.appendNewLineIfNotEmpty().appendNewLineIfNotEmpty()
                    + performSeguesFunctions.appendNewLineIfNotEmpty().appendNewLineIfNotEmpty()
            }
            .joined()
        let segueStruct = generateForSegueStruct()
        let body = viewControllerAndPerformSegueFunctions + segueStruct.appendNewLineIfNotEmpty()
        let end = "}" + Const.newLine
        
        return [begin, body, end].joined().appendNewLineIfNotEmpty()
    }
    
    func generateForSegueStruct() -> String {
        if !config.segue.standard {
            return ""
        }
        if seguesForGenerateStruct.isEmpty {
            return ""
        }
        
        let begin = "\(Const.tab1)public struct Segue {"
        let body: String = seguesForGenerateStruct
            .flatMap {
                "\(Const.tab2)public static let \($0.lowerFirst): String = \"\($0)\""
            }
            .joined()
        let end = "\(Const.tab1)}"
        return [begin, body, end].joined(separator: Const.newLine)
    }
    
    func generateForInsitantiateViewController(from storyboard: ViewControllerInfoOfStoryboard) -> String {
        if !config.viewController.instantiateStoryboardAny {
            return ""
        }
        
        return storyboard.isInitial ? fromStoryboardForInitial(from: storyboard) : fromStoryboard(from: storyboard)
    }
    
    func generateForPerformSegue(from storyboard: ViewControllerInfoOfStoryboard) -> String {
        if !config.needGenerateSegue {
            return ""
        }
        
        return generatePerformSegues(from: storyboard)
    }
    
    func generatePerformSegues(from storyboard: ViewControllerInfoOfStoryboard) -> String {
        if !config.needGenerateSegue {
            return ""
        }
        
        if storyboard.segues.isEmpty {
            return ""
        }
        
        if seguesForGenerateStruct.isEmpty {
            return ""
        }
        
        return seguesForGenerateStruct
            .flatMap {
                generatePerformSegue(from: storyboard, and: $0)
            }
            .joined(separator: Const.newLine)
    }
    
    func generatePerformSegue(from storyboard: ViewControllerInfoOfStoryboard, and segueIdentifier: String) -> String {
        let overrideOrNil = makeOverrideIfNeededForPerformSegue(from: storyboard)
        let overrideOrObjC = overrideOrNil == nil ? "@objc " : overrideOrNil! + " "
        let head = "\(Const.tab1)\(overrideOrObjC)"
        if config.segue.addition {
            return [
                "\(head)open func performSegue\(segueIdentifier)(closure: ((UIStoryboardSegue) -> Void)? = nil) {",
                "\(Const.tab2)performSegue(\"\(segueIdentifier)\", closure: closure)",
                "\(Const.tab1)}",
                ]
                .joined(separator: Const.newLine)
        }
        return [
            "\(head)open func performSegue\(segueIdentifier)(sender: AnyObject? = nil) {",
            "\(Const.tab2)performSegue(withIdentifier: \"\(segueIdentifier)\", sender: sender)",
            "\(Const.tab1)}",
            ]
            .joined(separator: Const.newLine)
    }
    
    func fromStoryboard(from storyboard: ViewControllerInfoOfStoryboard) -> String {
        if storyboard.storyboardIdentifier.isEmpty {
            return ""
        }
        
        let overrideOrNil = makeOverrideIfNeededForFromStoryboardFunction(from: storyboard)
        let overrideOrObjC = overrideOrNil == nil ? "@objc " : overrideOrNil! + " "
        let head = "\(Const.tab1)\(overrideOrObjC)open class func "
        if storyboardInfos.filter({ $0.storyboardName == storyboard.storyboardName }).count > 1 {
            return [
                head + "instanceFrom\(storyboard.storyboardName + storyboard.storyboardIdentifier)() -> \(name) {",
                "\(Const.tab2)let storyboard = UIStoryboard(name: \"\(storyboard.storyboardName)\", bundle: nil) ",
                "\(Const.tab2)let viewController = storyboard.instantiateViewController(withIdentifier: \"\(storyboard.storyboardIdentifier)\") as! \(name)",
                "\(Const.tab2)return viewController",
                "\(Const.tab1)}"
                ]
                .joined(separator: Const.newLine)
        }
        
        return [
            head + "instanceFrom\(storyboard.storyboardName)() -> \(name) {",
            "\(Const.tab2)let storyboard = UIStoryboard(name: \"\(storyboard.storyboardName)\", bundle: nil) ",
            "\(Const.tab2)let viewController = storyboard.instantiateViewController(withIdentifier: \"\(storyboard.storyboardIdentifier)\") as! \(name)",
            "\(Const.tab2)return viewController",
            "\(Const.tab1)}",
            ]
            .joined(separator: Const.newLine)
    }
    
    func fromStoryboardForInitial(from storyboard: ViewControllerInfoOfStoryboard) -> String {
        let overrideOrNil = makeOverrideIfNeededForFromStoryboardFunction(from: storyboard)
        let overrideOrObjC = overrideOrNil == nil ? "@objc " : overrideOrNil! + " "
        let head = "\(Const.tab1)\(overrideOrObjC)open class func "
        
        if storyboardInfos.filter ({ $0.isInitial }).count > 1 {
            return [
                head + "initialFrom\(storyboard.storyboardName)() -> \(name) {",
                "\(Const.tab2)let storyboard = UIStoryboard(name: \"\(storyboard.storyboardName)\", bundle: nil) ",
                "\(Const.tab2)let viewController = storyboard.instantiateInitialViewController() as! \(name)",
                "\(Const.tab2)return viewController",
                "\(Const.tab1)}"
                ]
                .joined(separator: Const.newLine)
        }
        
        return [
            head + "initialViewController() -> \(name) {",
            "\(Const.tab2)let storyboard = UIStoryboard(name: \"\(storyboard.storyboardName)\", bundle: nil) ", 
            "\(Const.tab2)let viewController = storyboard.instantiateInitialViewController() as! \(name)",
            "\(Const.tab2)return viewController",
            "\(Const.tab1)}"
            ]
            .joined(separator: Const.newLine)
    }
    
    func needOverrideForStoryboard(_ storyboard: ViewControllerInfoOfStoryboard) -> Bool {
        if !hasSuperClass {
            return false
        }
        
        // For initialViewController()
        let hasInitialOfSuperClass = superClassStoryboardInfos.filter({ $0.isInitial }).count > 0
        let needOverrideForInitial = hasInitialOfSuperClass && storyboard.isInitial
        if needOverrideForInitial {
            return true
        }
        
        if storyboard.storyboardIdentifier.isEmpty {
            return false
        }
        
        // For not initialViewController()
        let storyboardsForIsNotInitial = superClassStoryboardInfos.filter({ !$0.isInitial })
        return storyboardsForIsNotInitial.filter({ $0.storyboardName == storyboard.storyboardName }).count > 1
    }
    
    func needOverrideForSegue(_ storyboard: ViewControllerInfoOfStoryboard) -> Bool {
        if !hasSuperClass {
            return false
        }
        
        let superClassSegues = superClassStoryboardInfos.flatMap { $0.segues }
        let segues = storyboardInfos.flatMap { $0.segues }
        
        return superClassSegues.contains { superClassSegue in
            segues.contains { segue in
                segue == superClassSegue
            }
        }
    }
    
    func makeOverrideIfNeededForFromStoryboardFunction(from storyboard: ViewControllerInfoOfStoryboard) -> String? {
        return needOverrideForStoryboard(storyboard) ? "override" : nil
    }

    func makeOverrideIfNeededForPerformSegue(from storyboard: ViewControllerInfoOfStoryboard) -> String? {
        return needOverrideForSegue(storyboard) ? "override" : nil
    }
    
}
