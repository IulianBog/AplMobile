//
//  ToDoTableViewCell.swift
//  AplicatiiMobile
//
//  Created by Iulian Bogdanovici on 26.06.2023.
//

import UIKit

class ToDoTableViewCell: UITableViewCell {
    @IBOutlet weak var completedButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    weak var delegate: ToDoCellDelegate?
    var isCompleted: Bool = false
    var vcTitle: String = ""
    
    func configure(with text: String, data: Data?) {
        titleLabel.text = text
        setButtonImage()
        backgroundView?.backgroundColor = UIColor.white
        if let data = data, let backgroundImage = UIImage(data: data) {
            backgroundView?.backgroundColor = UIColor(patternImage: backgroundImage)
        }

    }
    
    @IBAction func completedButtonPressed(_ sender: Any) {
        isCompleted.toggle()
        setButtonImage()
        delegate?.cellDidToggleIsCompleted(cell: self)
    }
    
    private func setButtonImage() {
        completedButton.isEnabled = vcTitle == Text.toDoTitle.text
        isCompleted ? completedButton.setImage(UIImage(systemName: "checkmark.circle"), for: .normal) : completedButton.setImage(UIImage(systemName: "circle"), for: .normal)
    }
}
