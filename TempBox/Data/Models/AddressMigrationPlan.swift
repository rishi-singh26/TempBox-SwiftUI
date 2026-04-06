//
//  AddressMigrationPlan.swift
//  TempBox
//
//  Created by Rishi Singh on 12/06/25.
//

import SwiftData

enum AddressMigrationPlan: SchemaMigrationPlan {
    static var schemas: [VersionedSchema.Type] {
        [AddressSchemaV1.self, AddressSchemaV2.self, AddressSchemaV3.self, AddressSchemaV4.self, AddressSchemaV41.self]
    }
    
    static var stages: [MigrationStage] {
        [migrateV1toV2, migrateV2toV3, migrateV3toV4, migrateV4toV41]
    }
    
    static let migrateV1toV2 = MigrationStage.lightweight(
        fromVersion: AddressSchemaV1.self,
        toVersion: AddressSchemaV2.self
    )
    
    static let migrateV2toV3 = MigrationStage.lightweight(
        fromVersion: AddressSchemaV2.self,
        toVersion: AddressSchemaV3.self
    )
    
    static let migrateV3toV4 = MigrationStage.lightweight(
        fromVersion: AddressSchemaV3.self,
        toVersion: AddressSchemaV4.self
    )
    
    static let migrateV4toV41 = MigrationStage.lightweight(
        fromVersion: AddressSchemaV4.self,
        toVersion: AddressSchemaV41.self
    )
}
