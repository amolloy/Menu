//
//  MenuItem.swift
//  Menus
//
//  Created by Simeon on 6/6/18.
//  Copyright © 2018 Two Lives Left. All rights reserved.
//

import UIKit

public protocol MenuItemView {
    var highlighted: Bool { get set }
    
    var highlightPosition: CGPoint { get set }
    
    var initialFocusedRect: CGRect? { get }
    
    var updateLayout: () -> Void { get set }
    
    func startSelectionAnimation(completion: @escaping () -> Void)
}

extension MenuItemView {
    public func startSelectionAnimation(completion: @escaping () -> Void) {}
    
    public var initialFocusedRect: CGRect? { return nil }
}

//MARK: - Separator

class SeparatorMenuItemView: UIView, MenuItemView, MenuThemeable {
    
    private let separatorLine = UIView()
    
    init() {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
		separatorLine.translatesAutoresizingMaskIntoConstraints = false
		
        addSubview(separatorLine)
        
		NSLayoutConstraint.activate([
			separatorLine.leftAnchor.constraint(equalTo: self.leftAnchor),
			self.rightAnchor.constraint(equalTo: separatorLine.rightAnchor),
			separatorLine.heightAnchor.constraint(equalToConstant: 1),
			separatorLine.topAnchor.constraint(equalTo: self.topAnchor, constant: 2),
			self.bottomAnchor.constraint(equalTo: separatorLine.bottomAnchor, constant: 2)
			])
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - Menu Item View

    var highlighted: Bool = false
    
    var highlightPosition: CGPoint = .zero
    
    var updateLayout: () -> Void = {}
    
    //MARK: - Themeable
    
    func applyTheme(_ theme: MenuTheme) {
        separatorLine.backgroundColor = theme.separatorColor
    }
}

//MARK: - Standard Menu Item

extension String {
    var renderedShortcut: String {
        switch self {
        case " ":
            return "Space"
        case "\u{8}":
            return "⌫"
        default:
            return self
        }
    }
}

extension ShortcutMenuItem.Shortcut {
    var labels: [UILabel] {
        
        let symbols = modifiers.symbols + [key]
        
        return symbols.map {
            let label = UILabel()
			label.translatesAutoresizingMaskIntoConstraints = false
            label.text = $0.renderedShortcut
            label.textAlignment = .right
            
            if $0 == key {
                label.textAlignment = .left
				label.widthAnchor.constraint(greaterThanOrEqualTo: label.heightAnchor).isActive = true
            }
            
            return label
        }
    }
}

public class ShortcutMenuItemView: UIView, MenuItemView, MenuThemeable {
    
    private let nameLabel = UILabel()
    private let shortcutStack = UIView()
    
    private var shortcutLabels: [UILabel] {
        return shortcutStack.subviews.compactMap { $0 as? UILabel }
    }
    
    public init(item: ShortcutMenuItem) {
        super.init(frame: .zero)
		translatesAutoresizingMaskIntoConstraints = false
		nameLabel.translatesAutoresizingMaskIntoConstraints = false
		shortcutStack.translatesAutoresizingMaskIntoConstraints = false
        
        nameLabel.text = item.name
        
        addSubview(nameLabel)

        nameLabel.textColor = .black
        
		var constraints = [NSLayoutConstraint]()
		constraints.append(contentsOf: [
			nameLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: 4),
			nameLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -4),
			nameLabel.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 10),
			nameLabel.rightAnchor.constraint(lessThanOrEqualTo: self.rightAnchor, constant:-10)
			])
		        
        if let shortcut = item.shortcut, ShortcutMenuItem.displayShortcuts {
            addSubview(shortcutStack)
            
			constraints.append(contentsOf:[
				nameLabel.rightAnchor.constraint(lessThanOrEqualTo: shortcutStack.leftAnchor, constant: -12),
				
				shortcutStack.topAnchor.constraint(equalTo: self.topAnchor, constant: 2),
				shortcutStack.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -2),
				self.rightAnchor.constraint(equalTo: shortcutStack.rightAnchor, constant: -6)
				])
            
            shortcutStack.setContentHuggingPriority(.required, for: .horizontal)
            
            let labels = shortcut.labels
            
            for (index, label) in labels.enumerated() {
                shortcutStack.addSubview(label)
                
				constraints.append(contentsOf:[
					label.topAnchor.constraint(equalTo: shortcutStack.topAnchor),
					label.bottomAnchor.constraint(equalTo: shortcutStack.bottomAnchor)
					])
				
				if index == 0 {
					constraints.append(label.leftAnchor.constraint(equalTo: shortcutStack.leftAnchor))
				} else if index < labels.count - 1 {
					constraints.append(label.leftAnchor.constraint(equalTo: labels[index - 1].rightAnchor, constant: 1.0 / UIScreen.main.scale))
				}
				
				if index == labels.count - 1 {
					if index > 0 {
						constraints.append(label.leftAnchor.constraint(equalTo: labels[index - 1].rightAnchor, constant: 2))
					}
					constraints.append(label.rightAnchor.constraint(equalTo: shortcutStack.rightAnchor))
				}
            }
        }
		
		NSLayoutConstraint.activate(constraints)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func startSelectionAnimation(completion: @escaping () -> Void) {
        updateHighlightState(false)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            [weak self] in
            self?.updateHighlightState(true)
            
            completion()
        }
    }
    
    //MARK: - Menu Item View
    
    public var highlighted: Bool = false {
        didSet {
            updateHighlightState(highlighted)
        }
    }
    
    public var highlightPosition: CGPoint = .zero
    
    public var updateLayout: () -> Void = {}
    
    //MARK: - Themeable Helpers
    
    private var highlightedBackgroundColor: UIColor = .clear
    
    private func updateHighlightState(_ highlighted: Bool) {
        nameLabel.isHighlighted = highlighted
        shortcutLabels.forEach { $0.isHighlighted = highlighted }
        
        backgroundColor = highlighted ? highlightedBackgroundColor : .clear
    }
    
    //MARK: - Themeable
    
    public func applyTheme(_ theme: MenuTheme) {
        nameLabel.font = theme.font
        nameLabel.textColor = theme.textColor
        nameLabel.highlightedTextColor = theme.highlightedTextColor
        
        highlightedBackgroundColor = theme.highlightedBackgroundColor
        
        shortcutLabels.forEach {
            label in
            
            label.font = theme.font
            label.textColor = theme.textColor
            label.highlightedTextColor = theme.highlightedTextColor
        }
        
        updateHighlightState(highlighted)
    }
}
