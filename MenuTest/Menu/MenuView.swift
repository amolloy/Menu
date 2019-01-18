//
//  MenuView.swift
//  Menus
//
//  Created by Simeon on 2/6/18.
//  Copyright © 2018 Two Lives Left. All rights reserved.
//

import UIKit

//MARK: - MenuView

public class MenuView: UIView, MenuThemeable {
    
    public static let menuWillPresent = Notification.Name("CodeaMenuWillPresent")
    
    private let titleLabel = UILabel()
    private let gestureBarView = UIView()
    private let tintView = UIView()
    private let effectView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
    
    public var title: String {
        didSet {
            titleLabel.text = title
            contents?.title = title
        }
    }
    
    private var menuPresentationObserver: Any!
    
    private var contents: MenuContents?
    private var theme: MenuTheme
    private var longPress: UILongPressGestureRecognizer!
    
    private let itemsSource: () -> [MenuItem]
    
    public enum Alignment {
        case left
        case center
        case right
    }
    
    public var contentAlignment = Alignment.right {
        didSet {
            if contentAlignment == .center {
                titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
            } else {
                titleLabel.setContentHuggingPriority(.required, for: .horizontal)
            }
        }
    }
    
    public init(title: String, theme: MenuTheme, itemsSource: @escaping () -> [MenuItem]) {
        self.itemsSource = itemsSource
        self.title = title
        self.theme = theme
        
        super.init(frame: .zero)
		translatesAutoresizingMaskIntoConstraints = false
		
		gestureBarView.translatesAutoresizingMaskIntoConstraints = false
		tintView.translatesAutoresizingMaskIntoConstraints = false
        
        titleLabel.text = title
        titleLabel.textColor = theme.darkTintColor
        titleLabel.textAlignment = .center
        titleLabel.setContentHuggingPriority(.required, for: .horizontal)
		titleLabel.translatesAutoresizingMaskIntoConstraints = false
		
        let clippingView = UIView()
		clippingView.translatesAutoresizingMaskIntoConstraints = false
        clippingView.clipsToBounds = true
        
        addSubview(clippingView)
        
        clippingView.layer.cornerRadius = 8.0
        
        clippingView.addSubview(effectView)

		effectView.translatesAutoresizingMaskIntoConstraints = false
        effectView.contentView.addSubview(tintView)
        effectView.contentView.addSubview(titleLabel)
        effectView.contentView.addSubview(gestureBarView)
        
		NSLayoutConstraint.activate([
			clippingView.leftAnchor.constraint(equalTo: self.leftAnchor),
			self.rightAnchor.constraint(equalTo: clippingView.rightAnchor),
			clippingView.topAnchor.constraint(equalTo: self.topAnchor),
			self.bottomAnchor.constraint(equalTo: clippingView.bottomAnchor),

			effectView.leftAnchor.constraint(equalTo: clippingView.leftAnchor),
			clippingView.rightAnchor.constraint(equalTo: effectView.rightAnchor),
			effectView.topAnchor.constraint(equalTo: clippingView.topAnchor),
			clippingView.bottomAnchor.constraint(equalTo: effectView.bottomAnchor),

			tintView.leftAnchor.constraint(equalTo: effectView.leftAnchor),
			effectView.rightAnchor.constraint(equalTo: tintView.rightAnchor),
			tintView.topAnchor.constraint(equalTo: effectView.topAnchor),
			effectView.bottomAnchor.constraint(equalTo: tintView.bottomAnchor),
			
			titleLabel.leftAnchor.constraint(equalTo: effectView.leftAnchor, constant: 12),
			effectView.rightAnchor.constraint(equalTo: titleLabel.rightAnchor, constant: 12),
			titleLabel.centerYAnchor.constraint(equalTo: effectView.centerYAnchor),
			
			gestureBarView.centerXAnchor.constraint(equalTo: effectView.centerXAnchor),
			gestureBarView.heightAnchor.constraint(equalToConstant: 2),
			gestureBarView.widthAnchor.constraint(equalToConstant: 20),
			effectView.bottomAnchor.constraint(equalTo: gestureBarView.bottomAnchor, constant: 3)
			])
        
        gestureBarView.layer.cornerRadius = 1.0
        
        longPress = UILongPressGestureRecognizer(target: self, action: #selector(longPressGesture(_:)))
        longPress.minimumPressDuration = 0.0
        addGestureRecognizer(longPress)
        
        applyTheme(theme)
        
        menuPresentationObserver = NotificationCenter.default.addObserver(forName: MenuView.menuWillPresent, object: nil, queue: nil) {
            [weak self] notification in
            
            if let poster = notification.object as? MenuView, let this = self, poster !== this {
                self?.hideContents(animated: false)
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(menuPresentationObserver)
    }
	
	public override var forFirstBaselineLayout: UIView {
		get {
			return titleLabel
		}
	}
    
    //MARK: - Required Init
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - Gesture Handling
    
    private var gestureStart: Date = .distantPast
    
    @objc private func longPressGesture(_ sender: UILongPressGestureRecognizer) {
        
        //Highlight whatever we can
        if let contents = self.contents {
            let localPoint = sender.location(in: self)
            let contentsPoint = convert(localPoint, to: contents)
            
            if contents.pointInsideMenuShape(contentsPoint) {
                contents.highlightedPosition = CGPoint(x: contentsPoint.x, y: localPoint.y)
            }
        }

        switch sender.state {
        case .began:
            if !isShowingContents {
                gestureStart = Date()
                showContents()
            } else {
                gestureStart = .distantPast
            }
            
            contents?.isInteractiveDragActive = true
        case .cancelled:
            fallthrough
        case .ended:
            let gestureEnd = Date()
            
            contents?.isInteractiveDragActive = false
            
            if gestureEnd.timeIntervalSince(gestureStart) > 0.3 {
                if let contents = contents {
                    let point = convert(sender.location(in: self), to: contents)
                    
                    if contents.point(inside: point, with: nil) {
                        contents.selectPosition(point, completion: {
                            [weak self] menuItem in
                            
                            self?.hideContents(animated: true)
                            
                            menuItem.performAction()
                        })
                    } else {
                        hideContents(animated: true)
                    }
                }
            }
            
        default:
            ()
        }
    }
    
    public func showContents() {
        NotificationCenter.default.post(name: MenuView.menuWillPresent, object: self)
        
        let contents = MenuContents(name: title, items: itemsSource(), theme: theme)
        
        for view in contents.stackView.arrangedSubviews {
            if let view = view as? MenuItemView {
                var updatableView = view
                updatableView.updateLayout = {
                    [weak self] in
                    
                    self?.relayoutContents()
                }
            }
        }
        
        addSubview(contents)

		switch contentAlignment {
		case .left:
			NSLayoutConstraint.activate([
				contents.topAnchor.constraint(equalTo: self.topAnchor),
				contents.rightAnchor.constraint(equalTo: self.rightAnchor)
				])
		case .right:
			NSLayoutConstraint.activate([
				contents.topAnchor.constraint(equalTo: self.topAnchor),
				contents.leftAnchor.constraint(equalTo: self.leftAnchor)
				])
		case .center:
			NSLayoutConstraint.activate([
				contents.centerXAnchor.constraint(equalTo: self.centerXAnchor),
				])
		}
        
        effectView.isHidden = true
        
        longPress?.minimumPressDuration = 0.07
        
        self.contents = contents
        
        setNeedsLayout()
        layoutIfNeeded()
        
        contents.generateMaskAndShadow(alignment: contentAlignment)
        contents.focusInitialViewIfNecessary()
    }
    
    public func hideContents(animated: Bool) {
        let contentsView = contents
        contents = nil
        
        longPress?.minimumPressDuration = 0.0
        
        effectView.isHidden = false
        
        if animated {
            UIView.animate(withDuration: 0.2, animations: {
                contentsView?.alpha = 0.0
            }) {
                finished in
                contentsView?.removeFromSuperview()
            }
        } else {
            contentsView?.removeFromSuperview()
        }
    }
    
    private var isShowingContents: Bool {
        return contents != nil
    }
    
    //MARK: - Relayout
    
    private func relayoutContents() {
        if let contents = contents {
            setNeedsLayout()
            layoutIfNeeded()
            
            contents.generateMaskAndShadow(alignment: contentAlignment)
        }
    }
    
    //MARK: - Hit Testing
    
    public override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        guard let contents = contents else {
            return super.point(inside: point, with: event)
        }
        
        let contentsPoint = convert(point, to: contents)
        
        if !contents.pointInsideMenuShape(contentsPoint) {
            hideContents(animated: true)
        }
        
        return contents.pointInsideMenuShape(contentsPoint)
    }
    
    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let contents = contents else {
            return super.hitTest(point, with: event)
        }
        
        let contentsPoint = convert(point, to: contents)
        
        if !contents.pointInsideMenuShape(contentsPoint) {
            hideContents(animated: true)
        } else {
            return contents.hitTest(contentsPoint, with: event)
        }
        
        return super.hitTest(point, with: event)
    }
    
    //MARK: - Theming
    
    public func applyTheme(_ theme: MenuTheme) {
        self.theme = theme
        
        titleLabel.font = theme.font
        titleLabel.textColor = theme.darkTintColor
        gestureBarView.backgroundColor = theme.gestureBarTint
        tintView.backgroundColor = theme.backgroundTint
        effectView.effect = theme.blurEffect
        
        contents?.applyTheme(theme)
    }
    
    public override func tintColorDidChange() {
        titleLabel.textColor = tintColor
    }
}
