//
//  BaseViewController.swift
//  FIDO2
//
//  Created by Corgi on 2022/9/19.
//

import UIKit

class BaseViewController: UIViewController {
    
    // MARK: NavigationBar Style
    
    /// 設定 NavigationBar 的顏色
    /// - Parameters:
    ///   - backgroundColor: navigationBar 的背景色
    ///   - tintColor: navigationBar 的色調顏色，預設為 UIColor.white
    ///   - foregroundColor: navigationBar 上的文字顏色，預設為 UIColor.white
    // = #colorLiteral(red: 0.2769057453, green: 0.3493403792, blue: 0.3832941055, alpha: 1) #37474F
    public func setNavigationBarStyle() {
        self.navigationItem.backButtonTitle = ""
        if #available(iOS 15.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
            self.navigationController?.navigationBar.tintColor = #colorLiteral(red: 0.2769057453, green: 0.3493403792, blue: 0.3832941055, alpha: 1)
            appearance.titleTextAttributes = [NSAttributedString.Key.foregroundColor: #colorLiteral(red: 0.2769057453, green: 0.3493403792, blue: 0.3832941055, alpha: 1),
                                              NSAttributedString.Key.font: UIFont(name: "PingFangTC-SemiBold", size: 18)!]
            appearance.shadowColor = .clear
            self.navigationController?.navigationBar.standardAppearance = appearance
            self.navigationController?.navigationBar.scrollEdgeAppearance = appearance
        } else {
            self.navigationController?.navigationBar.barTintColor = #colorLiteral(red: 0.09019608051, green: 0, blue: 0.3019607961, alpha: 1)
            self.navigationController?.navigationBar.tintColor = #colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1)
            self.navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor :   #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)]
        }
    }
    
    // MARK: - NavigationController.present
    
    /// NavigationController.presentViewController 跳頁 (帶 Closure)
    /// - Parameters:
    ///   - viewController: 要跳頁到的 UIViewController
    ///   - animated: 是否要換頁動畫，預設為 true
    ///   - completion: 換頁過程中，要做的事，預設為 nil
    public func presentViewController(viewController: UIViewController, animated: Bool = true, isFullScreen: Bool = true, completion: (() -> Void)? = nil) {
        self.navigationController?.present(viewController, animated: animated, completion: completion)
    }
    
    // MARK: - NavigationController.push
    
    /// NavigationController.pushViewController 跳頁 (不帶 Closure)
    /// - Parameters:
    ///   - viewController: 要跳頁到的 UIViewController
    ///   - animated: 是否要換頁動畫，預設為 true
    public func pushViewController(_ viewController: UIViewController, animated: Bool = true) {
        self.navigationController?.pushViewController(viewController, animated: animated)
//        if let navigationController = UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.rootViewController as? UINavigationController {
//            navigationController.pushViewController(viewController, animated: animated)
//        }
    }
    
    /// NavigationController.pushViewController 跳頁 (帶 Closure)
    /// - Parameters:
    ///   - viewController: 要跳頁到的 UIViewController
    ///   - animated: 是否要換頁動畫
    ///   - completion: 換頁過程中，要做的事
    public func pushViewController(_ viewController: UIViewController, animated: Bool, completion: @escaping () -> Void) {
        self.navigationController?.pushViewController(viewController, animated: animated)
        guard animated, let coordinator = transitionCoordinator else {
            DispatchQueue.main.async { completion() }
            return
        }
        coordinator.animate(alongsideTransition: nil) { _ in completion() }
    }
    
    // MARK: - NavigationController.pop
    
    /// NavigationController.popViewController 回上一頁 (不帶 Closure)
    /// - Parameters:
    ///   - animated: 是否要換頁動畫，預設為 true
    public func popViewController(_ animated: Bool = true) {
        self.navigationController?.popViewController(animated: animated)
    }
    
    /// NavigationController.popViewController 回上一頁 (帶 Closure)
    /// - Parameters:
    ///   - animated: 是否要換頁動畫
    ///   - completion: 換頁過程中，要做的事
    public func popViewController(animated: Bool, completion: @escaping () -> Void) {
        self.navigationController?.popViewController(animated: animated)
        guard animated, let coordinator = transitionCoordinator else {
            DispatchQueue.main.async { completion() }
            return
        }
        coordinator.animate(alongsideTransition: nil) { _ in completion() }
    }
    
    /// NavigationController.popupViewController 回到指定 ViewController (不帶 Closure)
    /// - Parameters:
    ///   - currectVC: 目前所在的 ViewController
    ///   - popVC_index: 在 NavigationController.viewControllers 中，指定 ViewController 的 index
    ///   - animated: 是否要換頁動畫，預設為 true
    public func popupViewController(vc: UIViewController,
                                    modalPresentationStyle: UIModalPresentationStyle,
                                    modalTransitionStyle: UIModalTransitionStyle,
                                    animated: Bool = true,
                                    completion: (()-> Void)? = nil) {
        vc.modalPresentationStyle = modalPresentationStyle
        vc.modalTransitionStyle = modalTransitionStyle
        if let navigationController = UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.rootViewController?.presentedViewController as? UINavigationController {
            navigationController.present(vc, animated: animated, completion: completion)
        }
    }

    /// NavigationController.popToViewController 回到指定 ViewController (帶 Closure)
    /// - Parameters:
    ///   - viewControllerClass: 要跳頁到的 viewControllerClass
    ///   - animated: 是否要換頁動畫
    ///   - completion: 換頁過程中，要做的事
    public func popToViewController(viewControllerClass: AnyClass, animated: Bool = true, completion: (() -> Void)? = nil) {
        if let vc = self.navigationController?.viewControllers.first(where: { $0.isKind(of: viewControllerClass) }) {
            self.navigationController?.popToViewController(vc, animated: true)
        }

        guard animated, let coordinator = transitionCoordinator else {
            DispatchQueue.main.async { completion?() }
            return
        }
        
        coordinator.animate(alongsideTransition: nil) { _ in completion?() }
    }

    
    /// NavigationController.popToRootViewController 回到 Root ViewController
    /// - Parameters:
    ///   - animated: 是否要換頁動畫，預設為 true
    public func popToRootViewController(_ animated: Bool = true) {
        self.navigationController?.popToRootViewController(animated: animated)
    }
    
    // MARK: - NavigationController.dismiss
    
    /// NavigationController.dismiss (帶 Closure)
    /// - Parameters:
    ///   - animated: 是否要關閉動畫，預設為 true
    ///   - completion: 關閉過程中，要做的事，預設為 nil
    public func dismissViewController(_ animated: Bool = true, completion: (()-> Void)? = nil) {
        self.navigationController?.dismiss(animated: animated, completion: completion)
    }
    
    // MARK: - ViewController.popUp
    
    /// ViewController.popUp (帶 Closure)
    /// - Parameters:
    ///   - viewController: 要彈出的 ViewController
    ///   - modalPresentationStyle: UIModalPresentationStyle，預設為 .overFullScreen
    ///   - modalTransitionStyle: UIModalTransitionStyle，預設為 .coverVertical
    ///   - animated: 是否要彈出動畫，預設為 true
    ///   - completion: 彈出過程中，要做的事，預設為 nil
    public func popUpViewController(viewController: UIViewController,
                                    modalPresentationStyle: UIModalPresentationStyle = .overFullScreen,
                                    modalTransitionStyle: UIModalTransitionStyle = .coverVertical,
                                    animated: Bool = true,
                                    completion: (()-> Void)? = nil) {
        viewController.modalPresentationStyle = modalPresentationStyle
        viewController.modalTransitionStyle = modalTransitionStyle
        self.present(viewController, animated: animated, completion: completion)
    }
    
    /// ViewController.dismissPopUp
    /// - Parameters:
    ///   - animated: 是否要關閉動畫，預設為 true
    ///   - completion: 關閉過程中，要做的事，預設為 nil
    public func dismissPopUpViewController(_ animated: Bool = true, completion: (()-> Void)? = nil) {
        self.dismiss(animated: animated, completion: completion)
    }
}
