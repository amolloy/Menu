//
//  ViewController.swift
//  MenuTest
//
//  Created by Simeon Saint-Saens on 3/1/19.
//  Copyright © 2019 Two Lives Left. All rights reserved.
//

import UIKit
import Menu

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let menu = MenuView(title: "Menu", theme: LightMenuTheme()) { [weak self] () -> [MenuItem] in
            return [
                ShortcutMenuItem(name: "Undo", shortcut: (.command, "Z"), action: {
                    [weak self] in
                    
                    let alert = UIAlertController(title: "Undo Action", message: "You selected undo", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    
                    self?.present(alert, animated: true, completion: nil)
                }),
                
                ShortcutMenuItem(name: "Redo", shortcut: ([.command, .shift], "Z"), action: {}),
                
                SeparatorMenuItem(),
                
                ShortcutMenuItem(name: "Insert Image…", shortcut: ([.command, .alternate], "I"), action: {}),
                ShortcutMenuItem(name: "Insert Link…", shortcut: ([.command, .alternate], "L"), action: {}),
                
                SeparatorMenuItem(),
                
                ShortcutMenuItem(name: "Help", shortcut: (.command, "?"), action: {}),
            ]
        }
        
        view.addSubview(menu)
        
        menu.tintColor = .black
        
		NSLayoutConstraint.activate([
			menu.centerXAnchor.constraint(equalTo: view.centerXAnchor),
			menu.centerYAnchor.constraint(equalTo: view.centerYAnchor),
			menu.heightAnchor.constraint(equalToConstant: 40)
			])
    }


}

