//
//  ViewController.swift
//  taskapp
//
//  Created by SugiuraArisa on 2021/05/19.
//

import UIKit
import RealmSwift

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    // Realmインスタンスを取得する
    let realm = try! Realm()
    
    // DB内のタスクが格納されるリスト。
    // 日付の近い順でソート：昇順
    // 以降内容をアップデートするとリスト内は自動的に更新される。
    var taskArray = try! Realm().objects(Task.self).sorted(byKeyPath: "date", ascending: true)
    
    // 検索したタスク一覧
    var filterdArr: [Task] = []
    
    // 検索候補一覧
    var searchWordList: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        tableView.delegate = self
        tableView.dataSource = self
        
        searchBar.delegate = self
        
        // 検索
        searchBarSearchButtonClicked(searchBar)
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
                // Viewを再作成
                self.searchBarSearchButtonClicked(self.searchBar)
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
        self.searchBarSearchButtonClicked(self.searchBar)
    }
    
    // 検索ボタンクリック時の処理
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if let text = searchBar.text {
            if text == "" {
                // 検索文字列がからの場合は、全件表示
                self.filterdArr = Array(self.taskArray)
            } else {
                self.filterdArr = Array(self.taskArray).filter { $0.category!.name.contains(text) }
            }
            
            // 一覧の更新
            tableView.reloadData()
        }
    }
    // 検索エリア入力中の処理
    func searchBar(_ searchBar: UISearchBar, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        // 変換中のテキストも正しく取得できるようにするために遅延させる
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) { [weak self] in
            guard let self = self else { return }
            self.searchBarSearchButtonClicked(self.searchBar)
        }

        return true
    }
    
    // 「登録」ボタンに紐づけられた処理
    @IBAction func unwind(_ segue: UIStoryboardSegue) {
    }
}

