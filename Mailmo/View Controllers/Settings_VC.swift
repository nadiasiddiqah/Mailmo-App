//
//  Settings_VC.swift
//  Mailmo
//
//  Created by Nadia Siddiqah on 3/24/21.
//

import UIKit
import GoogleSignIn
import Firebase
import JGProgressHUD

class Settings_VC: UIViewController {
    
    // MARK: - Variables
    let firebaseAuth = Auth.auth()
    let firebaseData = Database.database().reference()
    
    // MARK: - Outlets
    @IBOutlet weak var emailButton: UIButton!
    
    // MARK: - View Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
    }
    
    // MARK: - Navigation
    func transitionToSignIn() {
        
        // Hide HUD
        hudView(show: false)
        
        // Update root view controller to SignInVC (when user signs out)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            let signInVC = self.storyboard?.instantiateViewController(withIdentifier: "SignInVC") as? SignIn_VC
            self.view.window?.rootViewController = signInVC
            self.view.window?.makeKeyAndVisible()
        }
    }
    
    // MARK: - Action Methods
    @IBAction func changeEmail(_ sender: Any) {
        
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Would you like to update your email address?",
                                          message: nil,
                                          preferredStyle: .alert)
            alert.addTextField { (textField) in
                textField.placeholder = "Enter new email"
                textField.addTarget(alert, action: #selector(alert.fieldDidChangeInAlert), for: .editingChanged)
            }
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            
            let saveAction = UIAlertAction(title: "Save", style: .default, handler: { [weak self] (_) in
                guard let strongSelf = self else { return }
                
                guard let prefEmail = alert.textFields?[0].text else { return }
                
                let cleanedPrefEmail = prefEmail.trimmingCharacters(in: .whitespacesAndNewlines)
                strongSelf.emailButton.setTitle("\(cleanedPrefEmail)", for: .normal)
                Utils.currentUserInfo?.prefEmail = cleanedPrefEmail
                strongSelf.postPrefEmail()
            })
            saveAction.isEnabled = false
            alert.addAction(saveAction)
            
            self.present(alert, animated: true, completion: nil)
        }
        
    }
    
    @IBAction func pressedLogOut(_ sender: Any) {
        let alert = UIAlertController(title: nil,
                                      message: "Are you sure you want to log out?",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Log Out", style: .destructive, handler: { [weak self] (_) in
            guard let strongSelf = self else { return }

            strongSelf.logOut()
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.pruneNegativeWidthConstraints()
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func pressedRate(_ sender: Any) {
        let alert = UIAlertController(title: "Enjoying Mailmo?",
                                      message: "Your app store review helps spread the word and improve the Mailmo app!",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Rate Now", style: .default, handler: { [weak self] (_) in
            guard let strongSelf = self else { return }
            strongSelf.pressedRateNow()
        }))
        alert.addAction(UIAlertAction(title: "Send Feedback", style: .default, handler: { [weak self] (_) in
            guard let strongSelf = self else { return }
            strongSelf.pressedRateNow()
        }))
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    func pressedRateNow() {
        guard let scene = view.window?.windowScene else { return }
        AppStoreReviewManager.requestReviewIfAppropriate(scene: scene)
        
        // In case user already has reviewed app, direct them to app store link
        guard let writeReviewURL = URL(string: "https://apps.apple.com/app/id1570551825?action=write-review") else {
            fatalError("Expected a valid URL")
        }
        UIApplication.shared.open(writeReviewURL, options: [:], completionHandler: nil)
    }
    
    // MARK: - View Methods
    func setupView() {
        retrieveEmail()
    }
    
    // MARK: - Methods
    func retrieveEmail() {
        emailButton.titleLabel?.minimumScaleFactor = 0.5
        emailButton.titleLabel?.numberOfLines = 1
        emailButton.titleLabel?.adjustsFontSizeToFitWidth = true
        if let user = Utils.currentUserInfo {
            if user.prefEmail == Utils.n_a {
                emailButton.setTitle("\(user.email)", for: .normal)
            } else {
                emailButton.setTitle("\(user.prefEmail)", for: .normal)
            }
        }
    }
    
    func postPrefEmail() {
        
        // Post data to Firebase
        if let uid = firebaseAuth.currentUser?.uid {
            print("Successfully posted data to Firebase")
            if let user = Utils.currentUserInfo { 
                firebaseData.child("users/\(uid)").setValue(["name": user.name,
                                                             "email": user.email,
                                                             "prefEmail": user.prefEmail])
            }

        }
    }
    
    
    func logOut() {
        // Show HUD
        hudView(show: true)
        
        // Sign user out of Google
        GIDSignIn.sharedInstance()?.signOut()
        
        // Sign user out of Firebase
        do {
            try Auth.auth().signOut()
            transitionToSignIn()
        } catch {
            Utils.dismissHud(Utils.hud, text: "Error", detailText: error.localizedDescription, delay: 1)
        }
        print("Logged out")
    }
    
    
    func hudView(show: Bool) {
        if show {
            Utils.hud.textLabel.text = "Logging out..."
            Utils.hud.detailTextLabel.text = nil
            Utils.hud.show(in: view, animated: true)
        } else {
            Utils.hud.dismiss(afterDelay: 1.5, animated: true)
        }
    }
    
}
