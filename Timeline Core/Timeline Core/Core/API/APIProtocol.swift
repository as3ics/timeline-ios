//
//  APIProtocol.swift
//  Timeline FM
//
//  Created by Zachary DeGeorge on 8/12/18.
//  Copyright © 2018 Next Day Project. All rights reserved.
//

import Foundation
import CoreLocation
import MapKit
import CoreData

// MARK: - APIModelProtocol

protocol APIModelProtocol {
    
    // MARK: - Required Descriptors
    
    var descriptor: String { get }
    var modelType: ModelType { get }
    var entityName: String { get }
    
    var keys: [String] { get }
    
    // MARK: - Required Initializers
    
    init()
    init(attrs: JSON)
    init(object: NSManagedObject)
    func commonInit()
    
    // MARK: - Required Variables
    
    var name: String? { get }
    var id: String? { get }
    var timestamp: Date? { get }
    var tag: Int { get set }
    var shallBeRemoved: Bool { get set }
    
    var photos: Photos { get set }
    
    var entity: NSManagedObject? { get set }
    
    // MARK: - API Required Values
    
    var createUrl: String? { get }
    var createParams: JSON? { get }
    var retrieveUrl: String? { get }
    var retrieveParams: JSON? { get }
    var updateUrl: String? { get }
    var updateParams: JSON? { get }
    var deleteUrl: String? { get }
    var deleteParams: JSON? { get }
    
    // MARK: - API Requried Handlers
    
    func processCreate(data: JSON) -> Bool
    func processRetrieve(data: JSON) -> JSON?
    
    // MARK: - API Required Methods
    
    func create(_ callback: @escaping (_ err: Error?, _ newResult: Any?) -> Void, _ initialValue: Any?)
    func retrieve(_ callback: @escaping (_ err: Error?, _ newResult: Any?) -> Void, _ initialValue: Any?)
    func update(_ callback: @escaping (_ err: Error?, _ newResult: Any?) -> Void, _ initialValue: Any?)
    func delete(_ callback: @escaping (_ err: Error?, _ newResult: Any?) -> Void, _ initialValue: Any?)
    
    func create(_ callback: @escaping (_ success: Bool) -> Void)
    func retrieve(_ callback: @escaping (_ success: Bool) -> Void)
    func update(_ callback: @escaping (_ success: Bool) -> Void)
    func delete(_ callback: @escaping (_ success: Bool) -> Void)
    
    func retrievePhotos(_ callback: @escaping (_ err: Error?, _ newResult: Any?) -> Void, _ initialValue: Any?)
    
    func toJson() -> JSON
    func cleanse()
    
    // MARK: - Core Data Methods
    func deleteEntity()
    func createEntity() -> NSManagedObject?
    func saveEntity()
    func json() -> JSON
    
    // MARK: - CRUD Shortcuts
    /*
    func view()
    func edit()
    func create()
    */
}

// MARK: - APIContainerProtocol

protocol APIContainerProtocol {
    
    // MARK: - Required Typealias
    
    associatedtype Item: APIModelProtocol
    
    // MARK: - Requried Descriptors
    
    var descriptor: String { get }
    var modelType: ModelType { get }
    var entityName: String { get }
    
    // MARK: - Required Arrays
    
    var items: [Item] { get set }
    var entities: [NSManagedObject] { get set }
    
    
    // MARK: - Requried Subscripts
    
    subscript(_: String?) -> Item? { get }
    subscript(_: Int?) -> Item? { get }
    func get(name: String?) -> Item?
    func get(tag: Int) -> Item?
    func index(id: String?) -> Int?
    func index(name: String?) -> Int?
    func entity(id: String?) -> NSManagedObject?
    func item(id: String?) -> Item?
    var count: Int { get }
    
    // MARK: - API Required Values
    
    var retrieveUrl: String? { get }
    var retrieveParams: JSON? { get }
    
    // MARK: - API Required Handlers
    
    func process(_ callback: @escaping (_ err: Error?, _ newResult: Any?) -> Void, _ initialValue: Any?)
    
    // MARK: - API Requried Methods
    
    func synchronize(_ callback: @escaping (_ err: Error?, _ newResult: Any?) -> Void, _ initialValue: Any?)
    func retrieve(_ callback: @escaping (_ err: Error?, _ newResult: Any?) -> Void, _ initialValue: Any?)
    
    func deleteAllEntities()
    
    mutating func add(_ value: Any?, sort: Bool , insert: Bool)
    mutating func remove(_ value: Any?, sort: Bool)
    mutating func update(_ value: Any?, sort: Bool)
    
    func sort()
    
    func toJson() -> [JSON]
}

// MARK: - APIContainerSingletonProtocol

protocol APIContainerSingletonProtocol {
    associatedtype Shared
    
    static var shared: Shared { get }
}
