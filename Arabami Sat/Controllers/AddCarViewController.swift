//
//  AddCarViewController.swift
//  Arabami Sat
//
//  Created by Slavcho Petkovski on 9.5.21.
//

import UIKit
import FirebaseCrashlytics

class AddCarViewController: BaseViewController {
    enum ValidationError {
        case noImageSelected
        case noManufacturer
        case noModel
    }

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var carImageView: UIImageView!
    @IBOutlet weak var openGalleryBtn: UIButton!
    @IBOutlet weak var manufacturerTF: UITextField!
    @IBOutlet weak var modelTF: UITextField!

//    private let reachability = try? Reachability()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.setupViews()
        self.setupButton()
        self.setupTextFields()
        self.registerForNotifications()
        
        Crashlytics.crashlytics().setCustomValue("will add new car", forKey: "addCar")
        Crashlytics.crashlytics().log("custom message")

//        self.addReachabilityObservers()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
//        self.startNotifier()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
//        self.stopNotifier()
    }

//    private func addReachabilityObservers() {
//        self.reachability?.whenReachable = { _ in
//            print("online")
//        }
//
//        self.reachability?.whenUnreachable = { _ in
//            print("offline")
//        }
//    }

//    // listen for changes in network
//    private func startNotifier() {
//        do {
//            try reachability?.startNotifier(withImmediateCheck: false)
//        } catch {
//            return
//        }
//    }
//
//    // stop listening for changes in network
//    private func stopNotifier() {
//        self.reachability?.stopNotifier()
//    }

    private func setupViews() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.hideKeyboard))
        self.view.addGestureRecognizer(tap)
    }

    private func setupButton() {
        self.openGalleryBtn.setTitle(Strings.SelectImage, for: .normal)
    }

    private func setupTextFields() {
        self.manufacturerTF.placeholder = Strings.Manufacturer
        self.modelTF.placeholder = Strings.Model
    }

    private func registerForNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillShow(_:)),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillHide(_:)),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)
    }

    private func validateCar() -> ValidationError? {
        guard self.carImageView.image != nil else {
            return .noImageSelected
        }

        guard let text = self.manufacturerTF.text,
              !text.isEmpty else {
            return .noManufacturer
        }

        guard let text = self.modelTF.text,
              !text.isEmpty else {
            return .noModel
        }

        return nil
    }

    // MARK: Notifications methods
    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let info = (notification as NSNotification).userInfo,
            let val = info[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else {
            return
        }

        var kbRect = val.cgRectValue
        kbRect = self.view.convert(kbRect, from: nil)

        let contentInsets = UIEdgeInsets(top: 0, left: 0, bottom: kbRect.size.height, right: 0)
        self.scrollView.contentInset = contentInsets
        self.scrollView.scrollIndicatorInsets = contentInsets

        var aRect = self.view.frame
        aRect.size.height -= kbRect.size.height

        let scrollPointY = kbRect.size.height - self.view.frame.size.height - self.modelTF.frame.origin.y
            + self.modelTF.frame.size.height - 20
        if !aRect.contains(CGPoint(x: self.modelTF.frame.origin.x, y: self.modelTF.frame.origin.y)) {
            let scrollPoint = CGPoint(x: 0.0, y: scrollPointY)
            self.scrollView.setContentOffset(scrollPoint, animated: true)
        }

        UIView.animate(withDuration: 0.2) {
            self.view.layoutIfNeeded()
        }
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        let contentInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        self.scrollView.contentInset = contentInsets
        self.scrollView.scrollIndicatorInsets = contentInsets

        UIView.animate(withDuration: 0.2) {
            self.view.layoutIfNeeded()
        }
    }

    @objc private func hideKeyboard(sender: UITapGestureRecognizer) {
        self.view.endEditing(true)
    }

    // IBActions
    @IBAction func pickImageFromGallery(_ sender: UIButton) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary

        self.present(picker, animated: true)
    }

    @IBAction func saveCar(_ sender: Any) {
        guard let error = self.validateCar() else {
            let manufacturer = self.manufacturerTF.text
            let model = self.modelTF.text
            let id = UUID().uuidString
            let newCar = Car(imageRealmId: id, manufacturer: manufacturer, model: model)
            
            if let imageData = self.carImageView.image?.jpegData(compressionQuality: AppConstants.imageCompression) {
                DBManager.shared.saveImageToRealm(with: imageData, id: id)
            }

            DBManager.shared.addNewCar(car: newCar) { error in
                guard let err = error else {
                    return
                }

                self.showAlert(with: Strings.Error, message: err.localizedDescription)
            }
            
            self.navigationController?.popViewController(animated: true)

            return
        }

        switch error {
        case .noImageSelected:
            self.showAlert(with: Strings.Error, message: Strings.NoImageSelected)
        case .noManufacturer:
            self.showAlert(with: Strings.Error, message: Strings.NoManufacturer)
        case .noModel:
            self.showAlert(with: Strings.Error, message: Strings.NoModel)
        }
    }
}

extension AddCarViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == self.manufacturerTF {
            self.modelTF.becomeFirstResponder()
        } else {
            self.modelTF.resignFirstResponder()
        }

        return true
    }
}

extension AddCarViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        if let image = info[.originalImage] as? UIImage {
            self.carImageView.image = image
        }

        self.dismiss(animated: true, completion: nil)
    }
}