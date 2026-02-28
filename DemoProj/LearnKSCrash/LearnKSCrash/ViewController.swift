//
//  ViewController.swift
//  LearnKSCrash
//
//  Created by Sunset on 28/2/2026.
//

import UIKit
import Darwin

class ViewController: UIViewController {
    private let viewModel = CrashLabViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
}

private extension ViewController {
    func setupUI() {
        view.backgroundColor = .systemBackground

        let titleLabel = UILabel()
        titleLabel.text = "KSCrash Crash Lab"
        titleLabel.font = .boldSystemFont(ofSize: 24)
        titleLabel.textAlignment = .center

        let descriptionLabel = UILabel()
        descriptionLabel.text =
            "Use these buttons to manually trigger Signal/Mach crashes and observe KSCrash reports."
        descriptionLabel.numberOfLines = 0
        descriptionLabel.textAlignment = .center
        descriptionLabel.textColor = .secondaryLabel

        let machButton = makeButton(
            title: "Trigger Mach Bad Access",
            action: UIAction { [weak self] _ in
                self?.confirmCrash(
                    title: "Trigger Mach Crash?",
                    message: "This will write to an illegal memory address and crash immediately."
                ) {
                    self?.viewModel.triggerMachBadAccess()
                }
            }
        )

        let signalButton = makeButton(
            title: "Trigger Signal Abort",
            action: UIAction { [weak self] _ in
                self?.confirmCrash(
                    title: "Trigger Signal Crash?",
                    message: "This will raise SIGABRT and crash immediately."
                ) {
                    self?.viewModel.triggerSignalAbort()
                }
            }
        )

        let stack = UIStackView(arrangedSubviews: [titleLabel, descriptionLabel, machButton, signalButton])
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }

    func makeButton(title: String, action: UIAction) -> UIButton {
        var config = UIButton.Configuration.filled()
        config.title = title
        config.cornerStyle = .large
        config.buttonSize = .large
        return UIButton(configuration: config, primaryAction: action)
    }

    func confirmCrash(title: String, message: String, onConfirm: @escaping () -> Void) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Crash Now", style: .destructive) { _ in
            onConfirm()
        })
        present(alert, animated: true)
    }
}

private final class CrashLabViewModel {
    func triggerMachBadAccess() {
        // Deliberately write to an illegal address to produce EXC_BAD_ACCESS.
        let invalidPointer = UnsafeMutablePointer<UInt8>(bitPattern: 0x1)!
        invalidPointer.pointee = 0xFF
    }

    func triggerSignalAbort() {
        // Deliberately raise SIGABRT to produce a fatal signal crash.
        raise(SIGABRT)
    }
}
