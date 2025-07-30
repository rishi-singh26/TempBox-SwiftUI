//
//  AddressMigrationPlan.swift
//  TempBox
//
//  Created by Rishi Singh on 12/06/25.
//

import SwiftData

enum AddressMigrationPlan: SchemaMigrationPlan {
    static var schemas: [VersionedSchema.Type] {
        [AddressSchemaV1.self, AddressSchemaV2.self, AddressSchemaV3.self]
    }
    
    static var stages: [MigrationStage] {
        [migrateV1toV2, migrateV2toV3]
    }
    
    static let migrateV1toV2 = MigrationStage.lightweight(
        fromVersion: AddressSchemaV1.self,
        toVersion: AddressSchemaV2.self
    )
    
    static let migrateV2toV3 = MigrationStage.lightweight(
        fromVersion: AddressSchemaV2.self,
        toVersion: AddressSchemaV3.self
    )
}
