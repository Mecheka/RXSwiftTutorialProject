//
//  ViewController.swift
//  LoginExample
//
//  Created by AKKHARAWAT CHAYAPIWAT on 6/24/17.
//  Copyright © 2017 AKKHARAWAT CHAYAPIWAT. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import SVProgressHUD
import Moya
import Moya_ObjectMapper

class ViewController: UIViewController {

	@IBOutlet weak var usernameTextField: UITextField!
	@IBOutlet weak var passwordTextField: UITextField!
	@IBOutlet weak var loginButton: UIButton!
	
	@IBOutlet var tapGesture: UITapGestureRecognizer!
	
	let disposeBag = DisposeBag()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		// Username: hellocore
		// Password: anything
	
		let isUsernameValid = usernameTextField
			.rx.text.orEmpty
			.asObservable()
			.map { (username) -> Bool in
				return username.characters.count >= 4
			}
		
		let isPasswordValid = passwordTextField
			.rx.text.orEmpty
			.asObservable()
			.map { (password) -> Bool in
				return password.characters.count >= 4
			}
		
		Observable
			.combineLatest(
				isUsernameValid,
				isPasswordValid
			) { (usrValid, pwdValid) -> Bool in
				return usrValid && pwdValid
			}.bind(to: loginButton.rx.isEnabled)
			.addDisposableTo(disposeBag)
		
		let loginService = Observable
			.combineLatest(
				usernameTextField.rx.text.orEmpty.asObservable(),
				passwordTextField.rx.text.orEmpty.asObservable()
			) { (usr, pwd) -> LoginService in
				return LoginService.login(username: usr, password: pwd)
			}
		
		loginButton.rx.tap.asObservable()
			.withLatestFrom(loginService)
			.do(onNext: { (_) in
				SVProgressHUD.show()
			})
			.flatMapLatest { (service) -> Observable<LoginResponse> in
				let provider = RxMoyaProvider<LoginService>(stubClosure: RxMoyaProvider.delayedStub(1))
				return provider
					.request(service)
					.mapObject(LoginResponse.self)
			}
			.catchError({ (error) -> Observable<LoginResponse> in
				return Observable.just(LoginResponse(JSON: error.json)!)
			})
			.do(onNext: { (_) in
				SVProgressHUD.popActivity()
			})
			.observeOn(MainScheduler.instance)
			.subscribe(onNext: {  [weak self](response) in
				var alertController: UIAlertController
				if response.responseStatus == .success {
					alertController = UIAlertController(title: "Success", message: "Welcome \(response.name ?? "")", preferredStyle: .alert)
				}else{
					alertController = UIAlertController(title: "Error", message: response.message ?? "Unknown Error", preferredStyle: .alert)
				}
				alertController.addAction(UIAlertAction(title: "OK", style: .cancel))
				self?.present(alertController, animated: true)
			})
			.addDisposableTo(disposeBag)
		
		
		tapGesture.rx.event
			.subscribe(onNext: { [weak self] (_) in
				self?.view.endEditing(true)
			})
			.addDisposableTo(disposeBag)
		
		
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}


}

