
import UIKit
import CoreData
import RxSwift
import RxCocoa
import QuickLook

class DetailViewController: UIViewController {
    
    var addButtonBool: Bool?
    private var url: String?
    
    let disposeBag = DisposeBag()
    
    //MainVC, MyProgramVC에서 쓰이기 때문에 private 지정 X
    let detailVCIndexObservable = BehaviorSubject<DetailVCModel.Fields>(value: DetailVCModel.Fields())
    
    //위 Index Observable의 값 튜플화한 Observable
    private let tableViewObservable = BehaviorSubject<[(String ,String)]>(value: [("","")])
    
    //MARK: - @IBOutlet, @IBAction
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!{
        didSet{
            imageView.layer.masksToBounds = true
            imageView.layer.cornerRadius = 10
        }
    }
    @IBOutlet weak var routineTableView: UITableView!{
        didSet{
            routineTableView.rowHeight = 300
            routineTableView.layer.masksToBounds = true
            routineTableView.layer.cornerRadius = 15
            routineTableView.separatorColor = .black
        }
    }
    @IBOutlet weak var allRoutineButton: UIButton!{
        didSet{
            allRoutineButton.layer.masksToBounds = true
            allRoutineButton.layer.cornerRadius = 10
        }
    }
    @IBOutlet weak var descriptionLabel: UILabel!{
        didSet{
            
            //줄 간격 설정
            let attrString = NSMutableAttributedString(string: descriptionLabel.text!)
            let paragraphStyle = NSMutableParagraphStyle()
            
            descriptionLabel.lineBreakMode = .byWordWrapping
            descriptionLabel.numberOfLines = 0
            paragraphStyle.lineSpacing = 10
            attrString.addAttribute(NSAttributedString.Key.paragraphStyle, value: paragraphStyle, range: NSMakeRange(0, attrString.length))
            descriptionLabel.attributedText = attrString
        }
    }
    @IBOutlet weak var addRoutineButton: UIButton!{
        didSet{
            addRoutineButton.setTitle("루틴등록", for: .normal)
            addRoutineButton.layer.masksToBounds = true
            addRoutineButton.layer.cornerRadius = 15
        }
    }
    @IBOutlet weak var addButton: UIButton!{
        didSet{
            if addButtonBool == false{ //장바구니에서 접근할시 버튼
                addButton.isEnabled = false
            }
            addButton.layer.masksToBounds = true
            addButton.layer.cornerRadius = 15
        }
    }
    @IBAction func allRoutineButtonAction(_ sender: UIButton) {
        guard let webVC = UIStoryboard(name: "Main", bundle: nil)
            .instantiateViewController(withIdentifier: "WebViewController") as? WebViewController else {return}
        webVC.routineTitle = titleLabel.text ?? "not exist"
        webVC.url = self.url ?? "not exist"
        self.navigationController?.pushViewController(webVC, animated: true)
    }
    @IBAction func addRoutineButtonAction(_ sender: UIButton) {
        
    }
    @IBAction func basketButtonAction(_ sender: UIButton) {
        approachCoreData() //CoreData에 접근
    }
    //MARK: - viewDidLoad()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bindView()
        bindTableViewInView()
    }
}
//MARK: - 이전 뷰 인덱스에 맞는 detailViewModel 데이터 바인딩

extension DetailViewController {
    private func bindView() {
        detailVCIndexObservable.subscribe({[weak self] data in
            self?.titleLabel.text = data.element?.title ?? "not exist"
            self?.descriptionLabel.text = data.element?.description ?? "not exist"
            self?.imageView.image = UIImage(named: data.element?.image ?? "not exist")
            self?.url = data.element?.url ?? "not exist"
            
            var tempArray:[(String, String)] = []
            guard let days = data.element?.day else {return}
            guard let routines = data.element?.routineAtDay else {return}
            
            for (dayIndex, day) in days.enumerated(){ //(day, routine)의 튜플 배열 반환 -> [(day, routine)]
                for (routinIndex, routine) in routines.enumerated(){
                    if dayIndex == routinIndex{
                        let tuple = (day, routine)
                        tempArray.append(tuple)
                    }
                }
            }
            self?.tableViewObservable.onNext(tempArray)
        }).disposed(by: disposeBag)
    }
}
//MARK: - View안의 TableView에 데이터 바인딩

extension DetailViewController {
    private func bindTableViewInView(){
        tableViewObservable
            .bind(to: self.routineTableView.rx.items(cellIdentifier: "DetailTableViewCell", cellType: DetailTableViewCell.self)){ (index, element, cell) in
                
                cell.backgroundColor = .systemGray6
                cell.selectionStyle = .none
                
                cell.dayLabel.text = "Day \(element.0)"
                cell.routinLabel.text = element.1.replacingOccurrences(of: "\\n", with: "\n") //FireStroe Json 데이터 줄 바꿈
                cell.numberImageView.image = UIImage(systemName: "\(element.0).square")
            }.disposed(by: disposeBag)
    }
}
//MARK: - Alert Dialog 생성

extension DetailViewController {
    
    // duplicated : true -> 중복 안내 다이얼로그, false -> 추가완료 안내 다이얼로그
    private func makeAlertDialog(duplicated: Bool) -> Void {
        return duplicated ?
        divideAlert(title: "안내", message: "보관함에 이미 존재하는 프로그램입니다.", duplicatedBool: true) :
        divideAlert(title: "안내", message: "보관함에 프로그램을 담았습니다.   보관함으로 이동하시겠습니까 ?", duplicatedBool: false)
        
        // Alert Dialog 생성
        func divideAlert(title: String, message: String, duplicatedBool: Bool){
            let alert =  UIAlertController(title: title, message: message, preferredStyle: .alert)
            
            if(duplicatedBool == true) { // Dialog에 버튼 추가
                alert.addAction(CancelButton())
            }
            else {
                alert.addAction(OKButton())
                alert.addAction(CancelButton())
            }
            self.present(alert, animated: true, completion: nil) // 화면에 출력
            
            func OKButton() -> UIAlertAction { //OKButton Click -> 보관함 이동
                let alertSuccessBtn = UIAlertAction(title: "OK", style: .default) { _ in
                    guard let myProgramVC = UIStoryboard(name: "Main", bundle:  nil).instantiateViewController(withIdentifier: "MyProgramViewController") as? MyProgramViewController else {return}
                    self.navigationController?.pushViewController(myProgramVC, animated: true)
                }
                return alertSuccessBtn
            }
            func CancelButton() -> UIAlertAction {
                let alertDeleteBtn = UIAlertAction(title: "Cancel", style: .destructive) { _ in } //.destructive -> 글씨 빨갛게
                return alertDeleteBtn
            }
        }
    }
}
//MARK: - CoreData에 접근

extension DetailViewController {
    
    private func approachCoreData(){
        do{
            let myProgramObject = try getObject() //CoreData Entity인 MyProgram 정의
            MyProgramViewModel.coreData.isEmpty ? //CoreData에 데이터가 없을 시 -> 데이터 삽입, 데이터가 있을 시 -> 중복체크 후 데이터 삽입
            insertData(in: myProgramObject) : insertDataAfterDuplicatedCheck(in: myProgramObject)
        }
        catch{
            print("coreData Error: \(error)")
        }
        
        //CoreData 오브젝트 get
        func getObject() throws -> NSManagedObject{
            let viewContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
            guard let myProgramEntity = NSEntityDescription.entity(forEntityName: "MyProgram", in: viewContext) else{
                throw setDataError.EntityNotExist } //CoreData entity 정의
            let myProgramObject = NSManagedObject(entity: myProgramEntity, insertInto: viewContext)
            return myProgramObject
        }
        
        // CoreData에 데이터 삽입
        func insertData(in object: NSManagedObject) {
            let myProgram = object as! MyProgram
            //MyProgram entity 존재 시, unwrapping 후 coreData에 데이터 insert
            detailVCIndexObservable
                .subscribe { data in
                    myProgram.title = data.element?.title //
                    myProgram.image = data.element?.image
                    myProgram.description_ = data.element?.description
                    myProgram.division = data.element?.image //bodybuilding, powerbuilding, powerlifting 의 구분자 역활
                }.disposed(by: disposeBag)
            
            makeAlertDialog(duplicated: false) //보관함으로 이동 alert
            do{
                try (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext.save() //insert 적용
            }
            catch{
                print("save error: \(error)")
            }
        }
        
        // 데이터 중복체크 후 CoreData에 데이터 삽입
        func insertDataAfterDuplicatedCheck(in myProgramObject: NSManagedObject){
            _ = MyProgramViewModel() //선언과 동시에 MyProgramViewModel.coreData 최신화
            var count = 0
            for data in MyProgramViewModel.coreData{
                if (data.title == titleLabel.text){ //중복시 중복 다이얼로그 생성
                    makeAlertDialog(duplicated: true)
                }
                else{
                    count += 1
                    if count == MyProgramViewModel.coreData.count{ //전체 순회하였을 시(중복이 없을 시) coreData에 데이터 삽입
                        insertData(in: myProgramObject)
                    }
                }
            }
        }
        
        //오류 정의
        enum setDataError: Error{
            case EntityNotExist
        }
    }
}



