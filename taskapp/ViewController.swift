//
//  ViewController.swift
//  taskapp
//
//  Created by SugiuraArisa on 2021/05/19.
//

import UIKit
import RealmSwift

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource,
                      UIPickerViewDelegate, UIPickerViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    
    // Realmインスタンスを取得する
    let realm = try! Realm()
    
    // DB内のタスクが格納されるリスト。
    // 検索したタスク一覧
    var filterdArr = try! Realm().objects(Task.self).sorted(byKeyPath: "date", ascending: true)
    // フィルタしたカテゴリのID
    var selectCategoryId: String? = nil
    
    // カテゴリ選択のPickerView
    let categoryPV = UIPickerView()
    let categoryList = try! Realm().objects(Category.self).sorted(byKeyPath: "id", ascending: true)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        tableView.delegate = self
        tableView.dataSource = self
        
        categoryPV.delegate = self
        categoryPV.dataSource = self
        
        // 検索
        self.createTaskList(nil)
        
        // カテゴリ一覧が空の場合、初期値（カテゴリなし）のレコードを登録する
        if categoryList
            .count == 0 {
            let categoryNone = Category()
            categoryNone.id = 0
            categoryNone.name = "-"
            // DBの更新
            try! realm.write {
                self.realm.add(categoryNone, update: .modified)
            }
        }
    }
    
    // IPickerViewの列の数
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    // UIPickerViewの行数、要素の全数
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        self.categoryList.count
    }
    // UIPickerViewに表示する配列
    func pickerView(_ pickerView: UIPickerView,
                    titleForRow row: Int,
                    forComponent component: Int) -> String? {
        return self.categoryList[row].name
    }
    
    // カテゴリ選択ボタンのクリックイベント
    @IBAction func categoryButton(_ sender: Any) {
        // カテゴリ選択用のアラートダイアログ（カテゴリエリアに選択ボタンが被るので、改行で調整）
        let message = "フィルタするカテゴリを選択してください\n\n\n\n\n\n\n"
        let alert = UIAlertController(title: "カテゴリ選択", message: message, preferredStyle: .alert)
        
        // カテゴリ選択
        if self.categoryList.count > 0 {
            self.categoryPV.selectRow(0, inComponent: 0, animated: true) // 初期値
        }
        self.categoryPV.frame = CGRect(x: 0, y: 60, width: alert.view.bounds.width, height: 150) // 配置、サイズ
        self.categoryPV.autoresizingMask = [.flexibleWidth]
        
        alert.view.addSubview(self.categoryPV)
        
        // 選択ボタン
        let selectAction = UIAlertAction(title: "選択", style: .default) { action in
            print("tapped select")
            self.selectCategoryId = self.categoryList[self.categoryPV.selectedRow(inComponent: 0)].id.description
            self.createTaskList(self.selectCategoryId)
        }
        // クリアボタン
        let clearAction = UIAlertAction(title: "クリア", style: .destructive) { action in
              print("tapped clear")
            // フィルタをクリア
            self.selectCategoryId = nil
            self.createTaskList(self.selectCategoryId)
          }
        // キャンセルボタン
        let cancelAction = UIAlertAction(title: "キャンセル", style: .cancel) { action in
            print("tapped cancel")
        }
        // アクションの追加
        alert.addAction(selectAction)
        alert.addAction(clearAction)
        alert.addAction(cancelAction)
        
        // UIAlertControllerの表示
        present(alert, animated: true, completion: nil)
    }
    
    // データの数（＝セルの数）を返すメソッド
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filterdArr.count
    }
    
    // 各セルの内容を返すメソッド
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // 再利用可能な cell を得る
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)

        // Cellに値を設定する
        let task = filterdArr[indexPath.row]
        
        let title = task.title != "" ? task.title : "(タイトルなし)"
        cell.textLabel?.text = title
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"

        let dateString:String = formatter.string(from: task.date)
        let categoryName:String? = task.category?.name
        if categoryName == nil {
            cell.detailTextLabel?.text = dateString + "  カテゴリ：(カテゴリなし)"
        }
        else{
            cell.detailTextLabel?.text = dateString + "  カテゴリ：" + categoryName!
        }
        
        return cell
    }
    
    // 各セルを選択した時に実行されるメソッド
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "cellSegue",sender: nil)
    }
    
    // セルが削除が可能なことを伝えるメソッド
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath)-> UITableViewCell.EditingStyle {
        return .delete
    }

    // Delete ボタンが押された時に呼ばれるメソッド
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // 削除するタスクを取得する
            let task = self.filterdArr[indexPath.row]

            // ローカル通知をキャンセルする
            let center = UNUserNotificationCenter.current()
            center.removePendingNotificationRequests(withIdentifiers: [String(task.id)])

            // データベースから削除する
            try! realm.write {
                // DBのレコード削除
                self.realm.delete(task)
                // タスク一覧を更新
                self.createTaskList(self.selectCategoryId)
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
    }
    
    // segue で画面遷移する時に呼ばれる
    override func prepare(for segue: UIStoryboardSegue, sender: Any?){
        let inputViewController:InputViewController = segue.destination as! InputViewController

        if segue.identifier == "cellSegue" {
            // 既存タスクの場合
            let indexPath = self.tableView.indexPathForSelectedRow
            inputViewController.task = filterdArr[indexPath!.row]
            
            // 保存ボタンの非表示
            inputViewController.saveButton.isEnabled = false
            inputViewController.saveButton.tintColor = UIColor.clear
            inputViewController.isUpdateRecord = true
            
        } else {
            // 新規作成タスクの場合
            let task = Task()

            let allTasks = realm.objects(Task.self)
            if allTasks.count != 0 {
                task.id = allTasks.max(ofProperty: "id")! + 1
            }
            
            // 保存ボタンの表示
            inputViewController.saveButton.isEnabled = true
            inputViewController.saveButton.tintColor = nil
            inputViewController.isUpdateRecord = false

            inputViewController.task = task
        }
    }
    
    // 入力画面から戻ってきた時に TableView を更新する
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.createTaskList(nil)
    }

    // 表示一覧作成
    func createTaskList(_ index: String?){
        if index == nil {
            // indexが未設定の場合は、全件表示
            self.filterdArr = try! Realm().objects(Task.self)
                                .sorted(byKeyPath: "date", ascending: true)

        } else {
            let filterKey = "category.id = " + index!
            self.filterdArr = try! Realm().objects(Task.self)
                                .filter(filterKey)
                                .sorted(byKeyPath: "date", ascending: true)
        }

        // 一覧の更新
        tableView.reloadData()
    }
    
    // 「登録」ボタンに紐づけられた処理
    @IBAction func unwind(_ segue: UIStoryboardSegue) {
    }
}

