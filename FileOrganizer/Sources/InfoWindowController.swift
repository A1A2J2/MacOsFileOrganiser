import AppKit

class InfoWindowController: NSWindowController, NSWindowDelegate {
    
    init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "About File Organizer"
        window.center()
        
        super.init(window: window)
        window.delegate = self
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        guard let contentView = window?.contentView else { return }
        
        let scrollView = NSScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = false
        contentView.addSubview(scrollView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: contentView.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
        
        let stackView = NSStackView()
        stackView.orientation = .vertical
        stackView.alignment = .centerX
        stackView.spacing = 15
        stackView.edgeInsets = NSEdgeInsets(top: 30, left: 20, bottom: 30, right: 20)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        scrollView.documentView = stackView
        stackView.widthAnchor.constraint(equalTo: scrollView.contentView.widthAnchor).isActive = true
        
        // App Icon (using a system symbol as a placeholder if no icon exists)
        let imageView = NSImageView()
        imageView.image = NSImage(systemSymbolName: "folder.badge.gearshape", accessibilityDescription: "File Organizer Logo")
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: 80),
            imageView.heightAnchor.constraint(equalToConstant: 80)
        ])
        stackView.addArrangedSubview(imageView)
        
        // App Name
        let nameLabel = NSTextField(labelWithString: "File Organizer")
        nameLabel.font = NSFont.boldSystemFont(ofSize: 24)
        stackView.addArrangedSubview(nameLabel)
        
        // Version
        let versionLabel = NSTextField(labelWithString: "Version 1.0.0")
        versionLabel.font = NSFont.systemFont(ofSize: 12)
        versionLabel.textColor = .secondaryLabelColor
        stackView.addArrangedSubview(versionLabel)
        
        // Divider
        let divider = NSBox()
        divider.boxType = .separator
        divider.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(divider)
        divider.widthAnchor.constraint(equalTo: stackView.widthAnchor, constant: -40).isActive = true
        
        // Legal Info
        let legalText = """
        © 2026 A1A2J2. All rights reserved.
        
        This software is provided "as-is", without any express or implied warranty. In no event shall the authors be held liable for any damages arising from the use of this software.
        
        DISCLAIMER: We hold no responsibility for any lost, corrupted, or misplaced files. Please ensure you have adequate backups of your data before utilizing automated file organization features.
        """
        
        let legalLabel = NSTextField(labelWithString: legalText)
        legalLabel.font = NSFont.systemFont(ofSize: 11)
        legalLabel.textColor = .secondaryLabelColor
        legalLabel.alignment = .center
        legalLabel.isSelectable = true
        legalLabel.maximumNumberOfLines = 0
        legalLabel.lineBreakMode = .byWordWrapping
        legalLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        
        stackView.addArrangedSubview(legalLabel)
        
        legalLabel.translatesAutoresizingMaskIntoConstraints = false
        legalLabel.widthAnchor.constraint(equalTo: stackView.widthAnchor, constant: -40).isActive = true
    }
}
