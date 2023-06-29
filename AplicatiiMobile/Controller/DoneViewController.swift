//
//  DoneViewController.swift
//  AplicatiiMobile
//
//  Created by Iulian Bogdanovici on 27.06.2023.
//

import UIKit

class DoneViewController: ToDosViewController {
    
    override var vcTitle: String { Text.doneTitle.text }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addButton.isHidden = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        filterToDos()
    }
    
    override func filterToDos() {
        fetchToDos()
        filteredTexts = []
        filteredTexts = texts.filter({ ($0.value(forKey: "isCompleted") as! Bool) == true
        })
        DispatchQueue.main.async { [weak self] in
            self?.tableView.reloadData()
        }
    }

}
