//
//  APIContainerProtocol.swift
//  Timeline FM
//
//  Created by Zachary DeGeorge on 8/27/18.
//  Copyright © 2018 Next Day Project. All rights reserved.
//

import Foundation

// MARK: - APIContainerProtocol

protocol APIContainerProtocol {
    
    static var descriptor: APIClassDescriptor { get }
    associatedtype Item: APIModelProtocol
    
    var items: [Item] { get set }
    
    subscript(_: String?) -> Item? { get }
    subscript(_: Int?) -> Item? { get }
    var count: Int { get }
    
    var retrieveUrl: String? { get }
    var retrieveParams: JSON? { get }
    func process(data: [JSON])
    
    func retrieve(_ callback: @escaping (_ err: Error?, _ newResult: Any?) -> Void, _ initialValue: Any?)
    
    mutating func add(_ value: Any?)
    mutating func remove(_ value: Any?)
    mutating func update(_ value: Any?)
    func sort()
    
    func toJson() -> [JSON]
}


extension APIContainerProtocol {
    
    var count: Int {
        return items.count
    }
    
    subscript(index: Int?) -> Item? {
        guard let index = index, index < self.count else {
            return nil
        }
        
        return items[index]
    }
    
    subscript(id: String?) -> Item? {
        guard let id = id, self.count > 0 else {
            return nil
        }
        
        for item in items {
            if item.id == id {
                return item
            }
        }
        
        return nil
    }
    
    func index(name: String?) -> Int? {
        guard let name = name, self.count > 0 else {
            return nil
        }
        
        var i = 0
        for item in items {
            if item.name == name {
                return i
            }
            
            i += 1
        }
        
        return nil
    }
    
    func index(id: String?) -> Int? {
        guard let id = id, self.count > 0 else {
            return nil
        }
        
        var i = 0
        for item in items {
            if item.id == id {
                return i
            }
            
            i += 1
        }
        
        return nil
    }
    
    func get(name: String?) -> Item? {
        guard let name = name, self.count > 0 else {
            return nil
        }
        
        for item in items {
            if item.name == name {
                return item
            }
        }
        
        return nil
    }
    
    
    func get(tag: Int) -> Item? {
        
        let matches = self.items.filter({ (item) -> Bool in
            return item.tag == tag
        })
        
        if matches.count > 0 {
            return matches[0]
        }
        
        return nil
    }
    
    mutating func add(_ value: Any?) {
        guard let item = value as? Item else {
            return
        }
        
        if let index = self.index(id: item.id) {
            items.remove(at: index)
        }
        
        items.append(item)
        sort()
    }
    
    mutating func remove(_ value: Any?) {
        guard let item = value as? Item else {
            return
        }
        
        if let index = self.index(id: item.id) {
            items.remove(at: index)
        }
    }
    
    mutating func update(_ value: Any?) {
        guard let item = value as? Item else {
            return
        }
        
        if let index = self.index(id: item.id) {
            items.remove(at: index)
            items.insert(item, at: index)
            return
        }
        
        items.append(item)
        sort()
    }
    
    func toJson() -> [JSON] {
        var json = [JSON]()
        
        for item in items {
            json.append(item.toJson())
        }
        
        return json
    }
    
}

// MARK: - APIContainerSingletonProtocol

protocol APIContainerSingletonProtocol {
    associatedtype Shared
    
    static var shared: Shared { get }
}
