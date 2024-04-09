//
//  DefaultDemoViewController.swift
//  GT3Example
//
//  Created by NikoXu on 2020/4/29.
//  Copyright © 2020 Xniko. All rights reserved.
//
///  本文件使用 GT3CaptchaButton 来写的示例
///  GT3CaptchaButton 提供了默认的 UIButton 样式
///  但是相对限制了开发调整的空间
//

import UIKit

import GT3Captcha

class SwiftDefaultDemoViewController: UIViewController {
    
    let api1 = "http://www.geetest.com/demo/gt/register-test"
    let api2 = "http://www.geetest.com/demo/gt/validate-test"
    
    private lazy var gt3CaptchaManager: GT3CaptchaManager = {
        let manager = GT3CaptchaManager.init(api1: api1, api2: api2, timeout: 5.0)
        manager.delegate = self
//        manager.enableDebugMode(true)
        
        return manager
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white

        if let captchaButton = GT3CaptchaButton(frame: CGRect(x: 0, y: 0, width: 260, height: 44), captchaManager: gt3CaptchaManager) {
            view.addSubview(captchaButton)
            captchaButton.center = view.center
            captchaButton.startCaptcha()
        }
        
    }
    
}

extension SwiftDefaultDemoViewController: GT3CaptchaManagerDelegate {
    
    func gtCaptcha(_ manager: GT3CaptchaManager, willSendRequestAPI1 originalRequest: URLRequest, withReplacedHandler replacedHandler: @escaping (URLRequest) -> Void) {
        // 添加防缓存时间戳，避免 challenge 重复使用
        // 否则会遇到 -21 错误码
        if let urlStr = originalRequest.url?.absoluteString,
           let url = URL(string: "\(urlStr)?t=\(NSDate().timeIntervalSince1970 * 1000)") {
            let request = URLRequest(url: url)
            replacedHandler(request)
            return
        }
        
        replacedHandler(originalRequest)
    }
    
    func gtCaptcha(_ manager: GT3CaptchaManager, didReceiveDataFromAPI1 dictionary: [AnyHashable : Any]?, withError error: GT3Error?) -> [AnyHashable : Any]? {
        print(dictionary)
        
        return dictionary
    }
    
    func gtCaptcha(_ manager: GT3CaptchaManager, errorHandler error: GT3Error) {
        print("error code: \(error.code)")
        print("error desc: \(error.error_code) - \(error.gtDescription)")
        
        // 处理验证中返回的错误
        if (error.code == -999) {
            // 请求被意外中断, 一般由用户进行取消操作导致
        }
        else if (error.code == -10) {
            // 预判断时被封禁, 不会再进行图形验证
        }
        else if (error.code == -20) {
            // 尝试过多
        }
        else {
            // 网络问题或解析失败, 更多错误码参考开发文档
        }
    }
    
    func gtCaptcha(_ manager: GT3CaptchaManager, didReceiveSecondaryCaptchaData data: Data?, response: URLResponse?, error: GT3Error?, decisionHandler: ((GT3SecondaryCaptchaPolicy) -> Void)) {
        
        var indicatorStatus = false
        
        if let error = error {
            print("API2 error: \(error.code) - \(error.error_code) - \(error.gtDescription)")
            decisionHandler(.forbidden)
            return
        }
        
        guard let httpResp = response as? HTTPURLResponse, httpResp.statusCode == 200 else {
            print("Unexcepted API2 response status")
            decisionHandler(.forbidden)
            return
        }
        
        guard let data = data else {
            print("API2 response nil")
            decisionHandler(.forbidden)
            return
        }
        
        if let result = try? JSONDecoder().decode(API2Response.self, from: data) {
            if result.status == "success" {
                decisionHandler(.allow)
                indicatorStatus = true
            } else {
                decisionHandler(.forbidden)
            }
        }
        else {
            print("Invalid API2 data.")
            decisionHandler(.forbidden)
        }
        
        DispatchQueue.main.async {
            if indicatorStatus {
                print("Demo 提示: 校验成功")
            } else {
                print("Demo 提示: 校验失败")
            }
        }
    }
    
    
//    func gtCaptcha(_ manager: GT3CaptchaManager, didReceiveDataFromAPI1 dictionary: [AnyHashable : Any]?, withError error: GT3Error?) -> [AnyHashable : Any] {
//        if let error = error {
//            print("API1 error: \(error.code) - \(error.error_code) - \(error.gtDescription)")
//            return nil
//        }
//        
//        print("API1 response: \(dictionary ?? [:])")
//        
//        return dictionary
//    }
}
