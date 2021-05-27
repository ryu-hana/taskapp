//
//  InputViewController.swift
//  taskapp
//
//  Created by SugiuraArisa on 2021/05/20.
//

import UIKit
import RealmSwift

class InputViewController: UIViewController, UIPickerViewDelegate , UIPickerViewDataSource {
    @IBOutlet weak var categoryPickerView: UIPickerView!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var contentsTextView: UITextView!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var NewCategoryButton: UIButton!
    
    let realm = try! Realm()
    var task: Task!
    var isUpdateRecord: Bool = false
    
    var addCategory: Category!
    
    // DB内のカテゴリが格納されるリスト。
    // id順でソート：昇順
    var categoryArray = try! Realm().objects(Category.self).sorted(byKeyPath: "id", ascending: true)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print(Realm.Configuration.defaultConfiguration.fileURL!)
        
        categoryPickerView.delegate = self
        categoryPickerView.dataSource = self

        // 背景をタップしたらdismissKeyboardメソッドを呼ぶように設定する
        let tapGesture: UITapGestureRecognizer = UITapGestureRecognizer(target:self, action:#selector(dismissKeyboard))
        self.view.addGestureRecognizer(tapGesture)

        // 表示項目の初期設定
        titleTextField.text = task.title
        contentsTextView.text = task.contents
        datePicker.date = task.date
        
        // レイアウト変更
        contentsTextView.layer.borderColor = UIColor.blue.cgColor
        contentsTextView.layer.borderWidth = 0.1
        contentsTextView.layer.cornerRadius = 5.0
        contentsTextView.layer.masksToBounds = true
        
        // カテゴリ一覧がからの場合、初期値（カテゴリなし）のレコードを登録する
        if categoryArray.count == 0 {
            let categoryNone = Category()
            categoryNone.id = 0
            categoryNone.name = "-"
            // DBの更新
            try! realm.write {
                self.realm.add(categoryNone, update: .modified)
            }
        }
        
        // カテゴリPickerViewの初期選択
        let index = categoryArray.firstIndex(where: {$0.id == task.category?.id})
        self.categoryPickerView.selectRow((index != nil) ? index! : 0, inComponent: 0, animated: false)
    }
    
    @objc func dismissKeyboard(){
        // キーボードを閉じる
        view.endEditing(true)
    }
    
    // segue で画面遷移する時に呼ばれる
    override func prepare(for segue: UIStoryboardSegue, sender: Any?){
        // カテゴリ追加画面への遷移の場合
        if segue.identifier == "categorySegue" {
        }
        else{ // 一覧画面への遷移の場合
            self.isUpdateRecord = true
        }
    }
    
    // IPickerViewの列の数
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    // UIPickerViewの行数、要素の全数
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        self.categoryArray.count
    }
    
    // UIPickerViewに表示する配列
    func pickerView(_ pickerView: UIPickerView,
                    titleForRow row: Int,
                    forComponent component: Int) -> String? {
        return self.categoryArray[row].name
    }

    // 画面非表示前処理
    override func viewWillDisappear(_ animated: Bool) {
        if self.isUpdateRecord == true {
            // Saveボタンが非表示の場合（既存タスク）、登録内容を更新する
            try! realm.write {
                // 表示項目からタスク変数に内容を反映
                self.task.title = self.titleTextField.text!
                self.task.contents = self.contentsTextView.text
                self.task.date = self.datePicker.date
                self.task.category = self.categoryArray[self.categoryPickerView.selectedRow(inComponent: 0)]
                // DBの更新
                self.realm.add(self.task, update: .modified)
            }

            // 通知を設定
            setNotification(task: task)
            
            super.viewWillDisappear(animated)
        }
    }
    
    // タスクのローカル通知を登録する
    func setNotification(task: Task) {
        let content = UNMutableNotificationContent()
        // タイトルと内容を設定(中身がない場合メッセージ無しで音だけの通知になるので「(xxなし)」を表示する)
        if task.title == "" {
            content.title = "(タイトルなし)"
        } else {
            content.title = task.title
        }
        if task.contents == "" {
            content.body = "(内容なし)"
        } else {
            content.body = task.contents
        }
        content.sound = UNNotificationSound.default

        // ローカル通知が発動するtrigger（日付マッチ）を作成
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: task.date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)

        // identifier, content, triggerからローカル通知を作成（identifierが同じだとローカル通知を上書き保存）
        let request = UNNotificationRequest(identifier: String(task.id), content: content, trigger: trigger)

        // ローカル通知を登録
        let center = UNUserNotificationCenter.current()
        center.add(request) { (error) in
            print(error ?? "ローカル通知登録 OK")  // error が nil ならローカル通知の登録に成功したと表示します。errorが存在すればerrorを表示します。
        }

        // 未通知のローカル通知一覧をログ出力
        center.getPendingNotificationRequests { (requests: [UNNotificationRequest]) in
            for request in requests {
                print("/---------------")
                print(request)
                print("---------------/")
            }
        }
    }
    
    // カテゴリ入力画面からの遷移前処理
    @IBAction func unwind(_ segue: UIStoryboardSegue) {
        try! realm.write {
            if self.addCategory != nil {
                // id付与
                if self.categoryArray.count > 0 {
                    let maxIdCategory = self.categoryArray.max { (a, b) -> Bool in
                        return a.id < b.id
                    }
                    self.addCategory.id = maxIdCategory!.id + 1
                }
                else{
                    self.addCategory.id = 0
                }
                // DBの更新
                self.realm.add(self.addCategory, update: .modified)
                
                // カテゴリPickerViewの再読み込み
                self.categoryPickerView.reloadAllComponents()
            }
        }
    }

}
