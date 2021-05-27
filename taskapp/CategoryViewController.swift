//
//  CategoryViewController.swift
//  taskapp
//
//  Created by SugiuraArisa on 2021/05/26.
//

import UIKit

class CategoryViewController: UIViewController {
    @IBOutlet weak var categoryNameText: UITextField!
        
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    // segue で画面遷移する時に呼ばれる
    override func prepare(for segue: UIStoryboardSegue, sender: Any?){
        var category: Category?

        if self.categoryNameText.text != "" {
            category = Category()
            // カテゴリー名を反映
            category!.name = self.categoryNameText.text ?? ""
        }
        else{
            category = nil
        }
        // segueから遷移先のControllerを取得する
        let inputViewController:InputViewController = segue.destination as! InputViewController
        inputViewController.addCategory = category
    }
}
