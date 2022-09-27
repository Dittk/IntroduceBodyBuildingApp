
import UIKit
import FirebaseFirestore
import CoreData
import RxSwift
import RxCocoa
import RxDataSources

class MainViewController: UIViewController{
    
    @IBOutlet weak var mainTableView: UITableView!

    let disposeBag = DisposeBag()
    var mainViewModel = MainTableViewModel()
    var detailViewModel = DetailViewModel()
    
    var isFiltering: Bool{ //검색 활성화 인식 로직
        let searchController = self.navigationItem.searchController
        let isActive = searchController?.isActive ?? false
        let isSearchBarHasText = searchController?.searchBar.text?.isEmpty == false //서치바에 텍스트가 존재 시 true
        return isActive && isSearchBarHasText
    }
    
    func makeSearchBar(){ //서치바 생성
        let searchController = UISearchController(searchResultsController: nil)
        navigationSet(searchController: searchController)
        searchControllerSet(searchController: searchController)
        
        func navigationSet(searchController: UISearchController){
            self.navigationItem.title = "Health Program"
            self.navigationController?.navigationBar.prefersLargeTitles = true
            self.navigationItem.hidesSearchBarWhenScrolling = true //스크롤 내릴 시 검색창 숨김
            self.navigationItem.searchController = searchController
        }
        
        func searchControllerSet(searchController: UISearchController){
            searchController.obscuresBackgroundDuringPresentation = false //false -> 검색창 활성화 시 주변 화면 흐림 X
            searchController.searchResultsUpdater = self //SearchBar에 데이터 입력 시 실시간으로 결과 반영
        }
    }
    
    func makeBasketButton() {
        
        let basketButton = UIButton()
        setButton()
        addCilckAction()

        func setButton(){
            basketButton.backgroundColor = .systemGray3
            basketButton.translatesAutoresizingMaskIntoConstraints = false //autolayout 사용 위해 false 필수
            basketButton.setImage(UIImage(named: "basket"), for: .normal)
            
            basketButton.layer.masksToBounds = true
            basketButton.layer.cornerRadius = 20
            basketButton.alpha = 0.9 //버튼 투명도
            
            view.addSubview(basketButton) //뷰에 버튼 추가
            
            basketButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 730).isActive = true //constraint 설정
            basketButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 300).isActive = true
            basketButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -40).isActive = true
            basketButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -18).isActive = true
        }
        
        func addCilckAction(){
            basketButton.rx.tap.bind { //버튼 액션
                let basetVC = UIStoryboard(name: "MyProgramViewController", bundle: nil)
                    .instantiateViewController(withIdentifier: "MyProgramViewController") as! MyProgramViewController
                self.present(basetVC, animated: true)
            }.disposed(by: disposeBag) // 구독해제 (메모리 정리)
        }
    }
    
    
    
    private func bindTableView(isFilterd: Bool) {
        
        setupTableViewOption()
        isFilterd ? bindingCell(data: mainViewModel.filteredObservable) : bindingCell(data: mainViewModel.tableViewObservable)
        addCilckEvent()
        
        func setupTableViewOption(){ //테이블 뷰 초기설정
            mainTableView.separatorStyle = .none
            mainTableView.showsVerticalScrollIndicator = false
            mainTableView.delegate = nil
            mainTableView.dataSource = nil
        }
        
        func bindingCell(data: BehaviorSubject<[MainTVCellModel.Fields]>){ // 메인 테이블 뷰에 cell 바인딩
            data.bind(to: self.mainTableView.rx.items(cellIdentifier: "MainTableViewCell", cellType: MainTableViewCell.self)) { (index, element, cell) in
                
                cell.titleLabel.text = element.title
                cell.authorLabel.text = element.author
                cell.descriptionLabel.text = element.description
                cell.recommendLabel.text = element.recommend
                cell.divisionLabel.text = element.division
                cell.healthImageView.image = UIImage(named: element.image )
            }.disposed(by: self.disposeBag)
        }
        
        func addCilckEvent(){ //click 이벤트
            mainTableView.rx.itemSelected
                .subscribe { [weak self] indexPath in //순환 참조 방지
                    self?.mainTableView.deselectRow(at: indexPath, animated: true) //셀 선택시 선택 효과 고정 제거
                    
                    let detailVC = UIStoryboard(name: "DetailViewController", bundle: nil)
                        .instantiateViewController(withIdentifier: "DetailViewController") as! DetailViewController
                    detailVC.titleName = DetailViewModel.detailViewModel[indexPath.row].title
                    detailVC.descrip = DetailViewModel.detailViewModel[indexPath.row].description
                    detailVC.imageName = DetailViewModel.detailViewModel[indexPath.row].image
                    detailVC.url = DetailViewModel.detailViewModel[indexPath.row].url
                    //                detailVC.title = DetailViewModel.detailViewModel[indexPath.row].title
                    self?.navigationController?.pushViewController(detailVC, animated: true)
                }.disposed(by: disposeBag)
        }

    }
        
    override func viewDidLoad() {
        super.viewDidLoad()
        makeSearchBar()
        makeBasketButton()
        bindTableView(isFilterd: false)
    }
}

extension MainViewController: UISearchResultsUpdating{
    func updateSearchResults(for searchController: UISearchController) { //SearchBar에 입력 시 실시간으로 결과 반영
        //        guard let text = searchController.searchBar.text?.uppercased() else {return}
        //
        //        func filter
        //
        //        cellData.filteredModel  = cellData.mainVCModel.filter({ MainVCModel in
        //            MainVCModel.title.uppercased().contains(text) || MainVCModel.author.uppercased().contains(text) ||
        //            MainVCModel.description.uppercased().contains(text) || MainVCModel.division.uppercased().contains(text)
        //        })
        //        isFiltering ? bindTableView(isFilterd: true) : bindTableView(isFilterd: false)
    }
}
