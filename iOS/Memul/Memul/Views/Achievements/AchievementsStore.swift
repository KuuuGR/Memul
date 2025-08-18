//
//  AchievementsStore.swift
//  Memul
//
//  Created by KuuuGR on 18/08/2025.
//

import Foundation

protocol AchievementsStore {
    func load() throws -> AchievementsSnapshot?
    func save(_ snapshot: AchievementsSnapshot) throws
}

final class FileAchievementsStore: AchievementsStore {
    private let url: URL
    init(filename: String = "achievements_v1.json") {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.url = dir.appendingPathComponent(filename)
    }

    func load() throws -> AchievementsSnapshot? {
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(AchievementsSnapshot.self, from: data)
    }

    func save(_ snapshot: AchievementsSnapshot) throws {
        let data = try JSONEncoder().encode(snapshot)
        let tmp = url.appendingPathExtension("tmp")
        try data.write(to: tmp, options: .atomic)
        if FileManager.default.fileExists(atPath: url.path) {
            _ = try FileManager.default.replaceItemAt(url, withItemAt: tmp)
        } else {
            try FileManager.default.moveItem(at: tmp, to: url)
        }
    }
}

