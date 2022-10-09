//
//  DetailViewModel.swift
//  IntroduceBodyBuilding
//
//  Created by 윤형석 on 2022/09/27.
//

import Foundation
import Alamofire
import RxSwift

class DetailViewModel {
//    static var detailViewModel: [DetailVCModel.Fields] = []
    var detailViewObservable: BehaviorSubject<[DetailVCModel.Fields]> = BehaviorSubject(value: [])
    
    init() {
        makeDetailVCData()
    }
    
    func makeDetailVCData() {
        let url = "https://firestore.googleapis.com/v1/projects/bodybuildingapp-3e7db/databases/(default)/documents/Detail"
        AF.request(url,
                   method: .get,
                   parameters: nil,
                   encoding: URLEncoding.default,
                   headers: ["Content-Type":"application/json", "Accept":"application/json"])
        .validate(statusCode: 200..<300)
        .responseDecodable(of: DetailVCModel.self) { response in // decoding
            switch response.result {
            case .success :
                print("성공")
                if let value = response.value?.documents {
//                    DetailViewModel.detailViewModel = value
                    self.detailViewObservable.onNext(value)
                }
            case .failure(let error):
                print("AF error: \(error)")
            }
        }
    }
}