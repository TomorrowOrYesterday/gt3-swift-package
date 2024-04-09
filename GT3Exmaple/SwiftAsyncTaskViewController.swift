//
//  AsyncTaskViewController.swift
//  GT3Example
//
//  Created by NikoXu on 2020/4/29.
//  Copyright © 2020 Xniko. All rights reserved.
//
///  本文件使用通过向 GT3CaptchaManager 注册 GT3AsyncTaskProtocol 来写的示例
///  没有提供的 UIButton 样式，需要开发者自己设计和开发
///  其中 GT3AsyncTaskProtocol 向开发者开放验证注册和验证校验的环节，是最为开放的方式
//

import UIKit
import GT3Captcha

class SwiftAsyncTaskViewController: UIViewController {
    
    let api1 = "http://www.geetest.com/demo/gt/register-test"
    let api2 = "http://www.geetest.com/demo/gt/validate-test"
    
    var demoAsyncTask: DemoAsyncTask?
            
    fileprivate lazy var gt3CaptchaManager: GT3CaptchaManager = {
        let manager = GT3CaptchaManager(api1: nil, api2: nil, timeout: 5.0)
        manager.delegate = self as GT3CaptchaManagerDelegate
        manager.viewDelegate = self as GT3CaptchaManagerViewDelegate
        
        // 开启日志和Debug模式
        manager.enableDebugMode(true)
        GT3CaptchaManager.setLogEnabled(true)
        
        return manager
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        navigationItem.title = "GT3Captcha AsyncTask Demo (Swift)"
        view.backgroundColor = .white
        
        // 创建自定义的注册和校验任务
        let demoAsyncTask = DemoAsyncTask()
        demoAsyncTask.api1 = self.api1
        demoAsyncTask.api2 = self.api2
        // 为验证管理器注册自定义的异步任务
        // 此步骤不建议放到管理器的懒加载中
        // 保障内部注册动作，在调用开启验证之前完成
        gt3CaptchaManager.registerCaptcha(withCustomAsyncTask: demoAsyncTask, completion: nil);
        self.demoAsyncTask = demoAsyncTask // 在 manager 内是弱引用，为避免在后续使用时 asyncTask 不会已被提前释放，建议在外部将其保持到全局
        
        let asyncTaskButton = UIButton(frame: CGRect(x: 0, y: 0, width: 240, height: 64))
        asyncTaskButton.setTitle("请点击", for: .normal)
        asyncTaskButton.backgroundColor = .green
        asyncTaskButton.layer.masksToBounds = true
        asyncTaskButton.layer.cornerRadius = 5.0
        asyncTaskButton.center = view.center
        
        asyncTaskButton.addTarget(self, action: #selector(asyncTaskAction), for: .touchUpInside)
        
        view.addSubview(asyncTaskButton)
    }

    @objc func asyncTaskAction(_ sender: Any) {
        self.gt3CaptchaManager.startGTCaptchaWith(animated: true)
    }
    
}

extension SwiftAsyncTaskViewController: GT3CaptchaManagerDelegate, GT3CaptchaManagerViewDelegate {
    
    // MARK: GT3CaptchaManagerDelegate
    
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
        if let error = error {
            print("API2 error: \(error.code) - \(error.error_code) - \(error.gtDescription)")
            decisionHandler(.forbidden)
            return
        }
        
        if let data = data {
            print("API2 repsonse: \(String(data: data, encoding: .utf8) ?? "")")
            decisionHandler(.allow)
            return
        }
        else {
            print("API2 repsonse: nil")
            decisionHandler(.forbidden)
        }
        decisionHandler(.forbidden)
    }
    
    // MARK: GT3CaptchaManagerViewDelegate
    
    func gtCaptchaWillShowGTView(_ manager: GT3CaptchaManager) {
        print("gtcaptcha will show gtview")
    }
}

class DemoAsyncTask: NSObject {
    
    fileprivate var api1: String?
    fileprivate var api2: String?
    
    private var validateTask: URLSessionDataTask?
    private var registerTask: URLSessionDataTask?
}

extension DemoAsyncTask : GT3AsyncTaskProtocol {
    
    func executeRegisterTask(completion: @escaping (GT3RegisterParameter?, GT3Error?) -> Void) {
        /**
         *  解析和配置验证参数
         */
        guard let api1 = self.api1,
              let url = URL(string: "\(api1)?ts=\(Date().timeIntervalSince1970)") else {
            print("invalid api1 address")
            let gt3Error = GT3Error(domainType: .extern, code: -9999, withGTDesciption: "Invalid API1 address.")
            completion(nil, gt3Error)
            return
        }
        
        
        let dataTask = URLSession.shared.dataTask(with: url) { (data: Data?, response: URLResponse?, error: Error?) in
            
            if let error = error {
                let gt3Error = GT3Error(domainType: .extern, originalError: error, withGTDesciption: "Request API2 fail.")
                completion(nil , gt3Error)
                return
            }
            
            guard let data = data,
                let httpResp = response as? HTTPURLResponse, httpResp.statusCode == 200 else {
                let gt3Error = GT3Error(domainType: .extern, code: -9999, withGTDesciption: "Invalid API2 response.")
                completion(nil , gt3Error)
                return
            }
            
            if let param = try? JSONDecoder().decode(API1Response.self, from: data) {
                let registerParameter = GT3RegisterParameter()
                registerParameter.gt = param.gt
                registerParameter.challenge = param.challenge
                registerParameter.success = NSNumber(integerLiteral: param.success)
                completion(registerParameter, nil)
            }
            else {
                let gt3Error = GT3Error(domainType: .extern, code: -9999, userInfo: nil, withGTDesciption: "API1 invalid JSON. Origin data: \(String(data: data, encoding: .utf8) ?? "")")
                completion(nil, gt3Error)
            }
        }
        dataTask.resume()
        self.registerTask = dataTask
    }
    
    func executeValidationTask(withValidate param: GT3ValidationParam, completion: @escaping (Bool, GT3Error?) -> Void) {
        
        var indicatorStatus = false
        
        /**
         *  处理result数据, 进行二次校验
         */
        print("executeValidationTask param code: \(param.code), result: \(param.result ?? [:])")
        
        guard let api2 = self.api2,
            let url = URL(string: api2) else {
            print("invalid api2 address")
            let gt3Error = GT3Error(domainType: .extern, code: -9999, withGTDesciption: "Invalid API2 address.")
            completion(false, gt3Error)
            return
        }
        
        var mRequest = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 10.0)
        mRequest.httpMethod = "POST"
        
        let headerFields = ["Content-Type" : "application/x-www-form-urlencoded;charset=UTF-8"]
        mRequest.allHTTPHeaderFields = headerFields
        
        var postArray = Array<String>()
        if let result = param.result {
            for (key, value) in result {
                let item = String(format: "%@=%@", key as! String, value as! String)
                postArray.append(item)
            }
        }
        
        let postForm = postArray.joined(separator: "&")
        mRequest.httpBody = postForm.data(using: .utf8)
        
        let dataTask = URLSession.shared.dataTask(with: mRequest) { (data: Data?, response: URLResponse?, error: Error?) in
            
            if let error = error {
                let gt3Error = GT3Error(domainType: .extern, originalError: error, withGTDesciption: "Request API2 fail.")
                completion(false , gt3Error)
                return
            }
            
            guard let data = data,
                let httpResp = response as? HTTPURLResponse, httpResp.statusCode == 200 else {
                let gt3Error = GT3Error(domainType: .extern, code: -9999, withGTDesciption: "Invalid API2 response.")
                completion(false , gt3Error)
                return
            }
            
            if let result = try? JSONDecoder().decode(API2Response.self, from: data) {
                if result.status == "success" {
                    completion(true, nil)
                    indicatorStatus = true
                } else {
                    completion(false, nil)
                }
            }
            else {
                let gt3Error = GT3Error(domainType: .extern, code: -9999, withGTDesciption: "Invalid API2 data.")
                completion(false , gt3Error)
            }
            
            DispatchQueue.main.async {
                if indicatorStatus {
                    print("Demo 提示: 校验成功")
                } else {
                    print("Demo 提示: 校验失败")
                }
            }
        }
        dataTask.resume()
        self.validateTask = dataTask
    }
    
    func cancel() {
        self.registerTask?.cancel()
        self.validateTask?.cancel()
    }
}
