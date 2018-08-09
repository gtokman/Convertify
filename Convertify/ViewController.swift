//
//  ViewController.swift
//  Convertify
//
//  Created by Hayden Hong on 8/7/18.
//  Copyright © 2018 Hayden Hong. All rights reserved.
//

import Alamofire
import SpotifyLogin
import UIKit

class ViewController: UIViewController {
    private var appleMusic = appleMusicSearcher()
    private var spotify = spotifySearcher()
    var link: String?
    
    // Mark: Properties
    @IBOutlet var convertButton: UIButton!
    @IBOutlet var titleLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Initialize with this color for animations' sake
        
        NotificationCenter.default.addObserver(self, selector: #selector(setupSpotifyCredentials), name: .SpotifyLoginSuccessful, object: nil)
        setupSpotifyCredentials()
    }
    
    @objc func changeButtonAppearance() {
        if self.link?.contains("https://open.spotify.com/") ?? false {
            setConvertButton(title: "Open in Apple Music", color: UIColor(red: 0.98, green: 0.34, blue: 0.76, alpha: 1.0), enabled: true)
            convertButton.isEnabled = true
        } else if link?.contains("https://itunes.apple.com/") ?? false {
            setConvertButton(title: "Open in Spotify", color: UIColor(red: 0.52, green: 0.74, blue: 0.00, alpha: 1.0), enabled: true)
        } else {
            setConvertButton(title: "No link found in clipboard", color: UIColor.gray, enabled: false)
        }
    }
    
    private func setConvertButton(title: String, color: UIColor, enabled: Bool) {
        convertButton.setTitle(title, for: .normal)
        
        // Animate color shift
        UIView.animate(withDuration: 3.0, delay: 0.0, animations: {
            self.titleLabel.textColor = UIColor.white
            self.view.backgroundColor = color
            self.convertButton.setTitleColor(UIColor.white, for: .normal)
        }, completion: nil)
        
        convertButton.isEnabled = enabled
    }
    
    @objc func setupSpotifyCredentials() {
        SpotifyLogin.shared.getAccessToken { accessToken, error in
            if accessToken != nil {
                self.spotify.token = accessToken
            } else {
                // Alert users to needing Spotify login
                let alert = UIAlertController(title: "Spotify Login Not Found", message: "This app requires a Spotify account. Please login now.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("Login", comment: "Open Spotify Login"), style: .default, handler: { _ in
                    // Open the Spotify login prompt
                    SpotifyLoginPresenter.login(from: self, scopes: [])
                }))
                self.present(alert, animated: true, completion: nil)
            }
            
            if error != nil {
                print(error ?? "")
            }
        }
    }
    
    @objc func finishLogin() {
        SpotifyLogin.shared.getAccessToken { accessToken, _ in
            if accessToken != nil {
                self.spotify.token = accessToken
            } else {
                // Logout just in case
                SpotifyLogin.shared.logout()
                let alert = UIAlertController(title: "We had trouble logging in", message: "Please try logging into Spotify again", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("Retry", comment: "Retry Spotify login"), style: .default, handler: { _ in
                    // restart Spotify login flow
                    self.setupSpotifyCredentials()
                }))
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    func handleLink() {
        if (link?.contains("https://open.spotify.com/") ?? false) {
            // Get the Apple Music version if the link is Spotify
            if spotify.token != nil {
                spotify.search(link: link!)!.responseJSON { response in
                    if let result = response.result.value {
                        let query = self.spotify.name! + " by " + self.spotify.artist!
                        self.titleLabel.text = query
                        self.appleMusic.search(name: query, type: self.spotify.type!)
                    }
                }
            } else {
                setupSpotifyCredentials()
            }
        } else if (link?.contains("https://itunes.apple.com/") ?? false) {
            appleMusic.search(link: link!)!.responseJSON { response in
                if let result = response.result.value {
                    let query = self.appleMusic.name! + " by " + self.appleMusic.artist!
                    self.titleLabel.text = query
                    self.spotify.search(name: query, type: self.appleMusic.type!)
                }
            }
        }
    }
    
    // Mark: Actions
    @IBAction func openSong(_ sender: Any) {
        if (link?.contains("https://open.spotify.com/") ?? false) {
            appleMusic.open()
        } else if (link?.contains("https://itunes.apple.com/") ?? false) {
            spotify.open()
        }
    }
}
