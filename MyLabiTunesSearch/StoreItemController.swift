//
//  StoreItemController.swift
//  MyLabiTunesSearch
//
//  Created by 曹家瑋 on 2023/11/1.
//

import Foundation
import UIKit

// MARK: - 新的寫法

/*
class StoreItemController {
    
    // 定義錯誤類型，用來表示在網路請求過程中可能遇到的錯誤情況
    enum StoreItemError: Error, LocalizedError {
        case itemsNotFound          // 當找不到項目時返回的錯誤
        case imageDataMissing       // 當圖片資料缺失時返回的錯誤
    }

    // 根據查詢條件從 iTunes API 獲取資料
    func fetchItems(matching query: [String: String]) async throws -> [StoreItem] {
        // 設定要請求的 URL 和 傳入的 query 作為查詢參數
        var urlComponents = URLComponents(string: "https://itunes.apple.com/search")!
        urlComponents.queryItems = query.map({ URLQueryItem(name: $0.key, value: $0.value) })
        
        // 發出異步的網路請求，取得資料和響應
        let (data, response) = try await URLSession.shared.data(from: urlComponents.url!)
        
        // 確保響應是 HTTPURLResponse 類型且狀態碼為 200，否則拋出錯誤
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw StoreItemError.itemsNotFound
        }
        
        // 使用 JSONDecoder 解碼資料為 SearchResponse 物件
        let jsonDecoder = JSONDecoder()
        let searchResponse = try jsonDecoder.decode(SearchResponse.self, from: data)
        
        // 回傳解碼後的結果
        return searchResponse.results
        
    }
    
    // 從給定的 URL 異步獲取圖片
    func fetchImage(from url: URL) async throws -> UIImage {
        // 發起異步網路請求，獲取資料和回應
        let (data, response) = try await URLSession.shared.data(from: url)
        
        // 確認回應是 HTTPURLResponse 並且狀態碼是 200，否則拋出錯誤
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw StoreItemError.imageDataMissing
        }
        
        // 嘗試將獲取的資料轉換為 UIImage，如果無法轉換則拋出錯誤
        guard let image = UIImage(data: data) else {
            throw StoreItemError.imageDataMissing
        }
        
        // 返回 UIImage
        return image
    }
    
}
*/

// MARK: - 傳統寫法

class StoreItemController {
    
    // 定義錯誤類型，用來表示在網路請求過程中可能遇到的錯誤情況
    enum StoreItemError: Error, LocalizedError {
        case itemsNotFound          // 當找不到項目時返回的錯誤
        case imageDataMissing       // 當圖片資料缺失時返回的錯誤
    }
    
    // 根據查詢條件從 iTunes API 獲取資料，完成後透過回調傳回結果
    func fetchItems(matching query: [String: String], completion: @escaping (Result<[StoreItem], Error>) -> Void) {
        // 設定要請求的 URL 和 傳入的 query 作為查詢參數
        var urlComponents = URLComponents(string: "https://itunes.apple.com/search")!
        urlComponents.queryItems = query.map({ URLQueryItem(name: $0.key, value: $0.value) })
        
        // 確認 URL 正確
        guard let url = urlComponents.url else { return }
        
        // 執行資料任務，從網路獲取資料
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            // 回到主線程更新 UI 或處理結果
            DispatchQueue.main.async {
                // 處理錯誤情況
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                // 確認回應狀態碼並解析資料
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200, let data = data else {
                    completion(.failure(StoreItemError.itemsNotFound))
                    return
                }
                
                do {
                    // 使用 JSONDecoder 解析 JSON 資料
                    let searchResponse = try JSONDecoder().decode(SearchResponse.self, from: data)
                    completion(.success(searchResponse.results))
                } catch {
                    completion(.failure(error))
                }
            }
        }.resume()
    }
        
    
    // 從給定的 URL 非同步獲取圖片，完成後透過回調傳回結果
    func fetchImage(from url: URL, completion: @escaping (Result<UIImage, Error>) -> Void) {
        
        // 執行資料任務獲取圖片資料
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            // 回到主線程更新 UI 或處理結果
            DispatchQueue.main.async {
                // 處理錯誤情況
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                // 確認回應狀態碼並確認資料存在
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200, let data = data else {
                    completion(.failure(StoreItemError.imageDataMissing))
                    return
                }
                
                // 嘗試將獲取的資料轉換為 UIImage
                if let image = UIImage(data: data) {
                    completion(.success(image))
                } else {
                    completion(.failure(StoreItemError.imageDataMissing))
                }
                
            }
        }.resume()
    }
    
}
