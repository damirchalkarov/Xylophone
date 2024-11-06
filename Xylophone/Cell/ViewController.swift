import UIKit
import AVFoundation

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    var player: AVAudioPlayer?

    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var sequenceLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    var isRecordingStarted = false
    var timer: Timer?
    var seconds = 0
    var isRunning = false
    var buttonSequence: [String] = []
    var userName: String?
    var userRecordArrayOfDictionaries: [[String: Any]] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self // Установка делегата
        tableView.allowsSelection = true
        
        sequenceLabel.isHidden = true
        
        getUserRecord()
        tableView.register(UINib(nibName:"RecordTableViewCell", bundle: nil), forCellReuseIdentifier: "cellIdentifier")
        tableView.dataSource = self
//        tableView.rowHeight = 40
        
        recordButton.layer.cornerRadius = 10
        playButton.layer.cornerRadius = 10
        
    }
    

    @IBAction func toggleTimer(_ sender: UIButton) {
        if isRunning {
            stopTimer()
            recordButton.setImage(UIImage(systemName: "record.circle"), for: .normal)
            sequenceLabel.isHidden = false
            askForInfo()
        } else {
            startTimer()
            recordButton.setImage(UIImage(systemName: "stop"), for: .normal)
        }
    }

    func startTimer() {
        isRunning = true
    }

    func stopTimer() {
        isRunning = false
    }

    @IBAction func buttonPressed(_ sender: UIButton) {
        let buttonTitle = sender.title(for: .normal)!
        print("\(buttonTitle) button was pressed")
        playSound(fileName: buttonTitle)

        sender.alpha = 0.5
        view.backgroundColor = sender.backgroundColor

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            sender.alpha = 1
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.view.backgroundColor = .white
        }

        saveButtonPress(tag: buttonTitle)
    }

    func playSound(fileName: String) {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "wav") else { return }

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)

            player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.wav.rawValue)

            guard let player = player else { return }
            player.play()
        } catch let error {
            print(error.localizedDescription)
        }
    }

    func updateSequenceLabel() {
        sequenceLabel.text = buttonSequence.joined(separator: ", ")
    }

    @IBAction func recordButtonPressed(_ sender: Any) {
        if !isRecordingStarted {
            isRecordingStarted = true
            updateSequenceLabel()
        }
    }

    func saveButtonPress(tag: String) {
        buttonSequence.append(tag)
        updateSequenceLabel()
    }

    func getCurrentTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: Date())
    }

    @IBAction func playSequence(_ sender: UIButton) {
        playRecordedSequence()
    }

    func playRecordedSequence() {
        if let selectedIndexPath = tableView.indexPathForSelectedRow {
            playRecord(at: selectedIndexPath.row)
        } else {
            print("No record selected")
        }
    }

    func playRecord(at index: Int) {
        guard index < userRecordArrayOfDictionaries.count,
              let record = userRecordArrayOfDictionaries[index]["record"] as? [String] else { return }

        var delay: TimeInterval = 0
        for buttonTag in record {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                self.playSound(fileName: buttonTag)
            }
            delay += 0.5
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return userRecordArrayOfDictionaries.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "cellIdentifier", for: indexPath) as? RecordTableViewCell else {
            return UITableViewCell() // Вернуть пустую ячейку в случае ошибки
        }

        let dictionary = userRecordArrayOfDictionaries[indexPath.row]
        if let name = dictionary["name"] as? String, let record = dictionary["record"] as? [String] {
            cell.recordTextLabel.text = "Name: \(name), Record: \(record.joined(separator: ", ")) \n"
        }

        return cell
    }

    // Реализуем метод для удаления записи
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Удаляем запись из массива userRecordArrayOfDictionaries
            userRecordArrayOfDictionaries.remove(at: indexPath.row)

            // Удаляем запись из UserDefaults
            let userDefaults = UserDefaults.standard
            userDefaults.set(userRecordArrayOfDictionaries, forKey: "userRecord")

            // Убираем запись из таблицы
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }

    func getUserRecord() {
        let userDefaults = UserDefaults.standard
        if let savedRecords = userDefaults.array(forKey: "userRecord") as? [[String: Any]] {
            userRecordArrayOfDictionaries = savedRecords
        }
    }

    // Сохраняем запись
    func askForInfo() {
        let alert = UIAlertController(title: "Save", message: "Please enter a name for this record.", preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "Enter name here"
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        alert.addAction(UIAlertAction(title: "Save", style: .default, handler: { _ in
            if let name = alert.textFields?.first?.text {
                self.userName = name
                self.saveRecord(name: name)
            }
        }))
        self.present(alert, animated: true, completion: nil)
    }

    func saveRecord(name: String) {
        let newRecord = [
            "name": name,
            "record": buttonSequence
        ] as [String : Any]
        userRecordArrayOfDictionaries.insert(newRecord, at: 0)
        let userDefaults = UserDefaults.standard
        userDefaults.set(userRecordArrayOfDictionaries, forKey: "userRecord")
        tableView.reloadData()
        buttonSequence.removeAll()
    }
}
