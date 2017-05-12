// Created by Derrick Chao on 2016/11/28.
// Copyright (c) 2017 Loopd Inc.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import <FMDB/FMDB.h>
#import "LCModelObject+LocalStorage.h"
#import "LCSettings.h"

#define RegisteredModelName                 @"RegisteredModelName"
#define LocalDatabaseFileName               @"LCModelObjectLocalStorage.db"

@implementation LCModelObject (LocalStorage)

#pragma mark - init

+ (NSMapTable *)sharedMapTable {
    static dispatch_once_t onceToken;
    static NSMapTable *sharedInstance;
    
    dispatch_once(&onceToken, ^{
        sharedInstance = [NSMapTable mapTableWithKeyOptions:NSMapTableStrongMemory
                                               valueOptions:NSMapTableWeakMemory];
    });
    
    return sharedInstance;
}

+ (dispatch_queue_t)writeSerialQueue {
    static dispatch_once_t onceToken;
    static dispatch_queue_t sharedWriteQueue;
    
    dispatch_once(&onceToken, ^{
        sharedWriteQueue = dispatch_queue_create("com.getloopd.LocalStorageManagerWriteQueue", DISPATCH_QUEUE_SERIAL);
    });
    
    return sharedWriteQueue;
}

#pragma mark Save Async

+ (void)pinAll:(NSArray *)objects completion:(LCBoolResultBlock)completion {
    dispatch_queue_t writeQueue = [self.class writeSerialQueue];
    dispatch_async(writeQueue, ^{
        FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:[self.class pathOfDB]];
        
        NSString *currentSQL = [self.class pinSQLForArray:objects];
        
        NSDate *date1 = [NSDate date];
        
        [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
            BOOL isSuccess = [db executeStatements:currentSQL];
            if (!isSuccess) {
                NSLog(@"save all failed \n>>>>> %@", currentSQL);
                NSLog(@"pin SQL error: %@", [db lastErrorMessage]);
                *rollback = YES;
            } else {
                NSDate *date2 = [NSDate date];
                NSLog(@"pin cost time: %f", [date2 timeIntervalSinceDate:date1]);
            }
        }];
        
        // cache!  Let a record only has 1 instance at the same time.
        [self.class cacheModelObjects:objects];
    });
}

#pragma mark Find Sync

+ (NSArray *)findAllFromLocal {
    return [self.class findFromLocalByKey:nil equalTo:nil];
}

+ (NSArray *)findFromLocalByKey:(NSString *)key equalTo:(NSString *)value {
    return [self.class findFromLocalByModelName:NSStringFromClass(self.class) key:key equalTo:value];
}

+ (NSArray *)findFromLocalByModelName:(NSString *)modelName key:(NSString *)key equalTo:(NSString *)value {
    NSDictionary *parameters = nil;
    if (key && value) {
        parameters = @{key: value};
    }
    return [self.class findFromLocalByModelName:modelName parameters:parameters];
}

+ (NSArray *)findFromLocalByModelName:(NSString *)modelName parameters:(NSDictionary *)parameters {
    NSString *conditionString = @"";
    if (parameters) {
        NSArray *keys = parameters.allKeys;
        for (NSString *key in keys) {
            if ([keys indexOfObject:key] == 0) {
                conditionString = [conditionString stringByAppendingFormat:@" WHERE %@ = %@", key, parameters[key]];
            } else {
                conditionString = [conditionString stringByAppendingFormat:@" AND %@ = %@", key, parameters[key]];
            }
        }
    }
    
    NSString *sql = [NSString stringWithFormat:@"SELECT * FROM %@%@;", modelName, conditionString];
    
    return [self.class findFromLocalBySQL:sql resultModelName:modelName];
}

+ (NSArray *)findFromLocalBySQL:(NSString *)SQL resultModelName:(NSString *)resultModelName {
    FMDatabase *db = [self.class database];
    NSMutableArray *fetchResult = [NSMutableArray new];
    
    if ([db open]) {
        FMResultSet *resultSet = [db executeQuery:SQL];
        while ([resultSet next]) {
            NSDictionary *resultDictionary = [resultSet resultDictionary];
            Class class = NSClassFromString(resultModelName);
            if ([class isSubclassOfClass:LCModelObject.class]) {
                LCModelObject *resultObject = [class objectWithStorage:resultDictionary];
                resultObject.isFromLocal = YES;
                [fetchResult addObject:resultObject];
            } else {
                // for m2m table
                [fetchResult addObject:resultDictionary];
            }
        }
        
        // disconnect with db
        [db close];
        [resultSet close];
    }
    
    return fetchResult;
}

#pragma mark Find Async

+ (void)findAllFromLocalWithCompletion:(LCArrayResultBlock)completion {
    [self.class findFromLocalByKey:nil equalTo:nil completion:completion];
}

+ (void)findFromLocalByKey:(NSString *)key equalTo:(NSString *)value completion:(LCArrayResultBlock)completion {
    [self.class findFromLocalByModelName:NSStringFromClass(self.class) key:key equalTo:value completion:completion];
}

+ (void)findFromLocalByModelName:(NSString *)modelName key:(NSString *)key equalTo:(NSString *)value completion:(LCArrayResultBlock)completion {
    NSDictionary *parameters = nil;
    if (key && value) {
        parameters = @{key: value};
    }
    [self.class findFromLocalByModelName:modelName parameters:parameters completion:completion];
}

+ (void)findFromLocalByModelName:(NSString *)modelName parameters:(NSDictionary *)parameters completion:(LCArrayResultBlock)completion {
    NSString *conditionString = @"";
    if (parameters) {
        NSArray *keys = parameters.allKeys;
        for (NSString *key in keys) {
            if ([keys indexOfObject:key] == 0) {
                conditionString = [conditionString stringByAppendingFormat:@" WHERE %@ = %@", key, parameters[key]];
            } else {
                conditionString = [conditionString stringByAppendingFormat:@" AND %@ = %@", key, parameters[key]];
            }
        }
    }
    NSString *sql = [NSString stringWithFormat:@"SELECT * FROM %@%@;", modelName, conditionString];
    
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:[self.class pathOfDB]];
    NSMutableArray *fetchResult = [NSMutableArray new];
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        // below should be execute synced.
        FMResultSet *resultSet = [db executeQuery:sql];
        while ([resultSet next]) {
            NSDictionary *resultDictionary = [resultSet resultDictionary];
            Class class = NSClassFromString(modelName);
            LCModelObject *resultObject = [class objectWithStorage:resultDictionary];
            resultObject.isFromLocal = YES;
            [fetchResult addObject:resultObject];
        }
        
        [resultSet close];
        
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(fetchResult, nil);
            });
        };
    }];
}

#pragma mark - Delete / Remove (async)

- (void)deleteWithCompletion:(LCBoolResultBlock)completion {
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:[self.class pathOfDB]];
    NSString *tableName = NSStringFromClass(self.class);
    
    // delete all rows in the table
    NSString *sql = [NSString stringWithFormat:@"DELETE FROM %@ WHERE id=%@;", tableName, self.objectId];
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL success = [db executeStatements:sql];
        if (!success) {
            NSLog(@"deleteWithCompletion sql: %@", sql);
            NSLog(@"deleteWithCompletion sql error: %@", [db lastErrorMessage]);
            *rollback = YES;
        }
        
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(success, nil);
            });
        };
    }];
}

+ (void)deleteAllFromLocalWithCompletion:(LCBoolResultBlock)completion {
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:[self.class pathOfDB]];
    NSString *tableName = NSStringFromClass(self.class);
    
    // delete all rows in the table
    NSString *sql = [NSString stringWithFormat:@"DELETE * FROM %@;", tableName];
    
    [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        BOOL success = [db executeStatements:sql];
        if (!success) {
            NSLog(@"deleteFromLocalAll sql: %@", sql);
            NSLog(@"deleteFromLocalAll sql error: %@", [db lastErrorMessage]);
            *rollback = YES;
        }
        
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(success, nil);
            });
        };
    }];
}

+ (void)removeWholeLocalDatabaseWithCompletion:(LCBoolResultBlock)completion {
    NSURL *docUrl = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    // get documents path
    NSString *documentsPath = docUrl.path;
    // get the path to our Data/plist file
    NSString *plistPath =
    [documentsPath stringByAppendingPathComponent:[NSString stringWithFormat:LocalDatabaseFileName]];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:plistPath]) {
        NSError *error;
        [[NSFileManager defaultManager] removeItemAtPath:plistPath error:&error];
    }
    
    // recreate local database
    [self.class prepareLocalDatabase];
    
    if (completion != nil) {
//        BOOL isError = (error == nil);
        completion(YES, nil);
    }
}

#pragma mark - Database Helper

+ (void)registerModel {
    if (self.class == [LCModelObject class]) {
        NSLog(@"LCModelObject registerModel error: please register a subclass of LCModelObject");
        return;
    }
    
    NSArray *registeredModelNames = [LCSettings settingForKey:RegisteredModelName];
    NSMutableSet *registeredModelNameSet = [NSMutableSet setWithArray:registeredModelNames];
    
    NSString *modelName = NSStringFromClass(self.class);
    [registeredModelNameSet addObject:modelName];
    
    // save
    [LCSettings setSetting:registeredModelNameSet.allObjects forKey:RegisteredModelName];
}

+ (void)prepareLocalDatabase {
    if (self.class != [LCModelObject class]) {
        NSLog(@"prepareLocalDatabase error: Please call the command by LCModelObject");
        return;
    }
    
    NSArray *registeredModelNames = [LCSettings settingForKey:RegisteredModelName];
    for (NSString *modelName in registeredModelNames) {
        Class modelClass = NSClassFromString(modelName);
        [modelClass createTableIfNeeded];
    }
    
    // create many to many table
    NSArray *m2mTablesArray = [LCSettings settingForKey:ManyToManyTableNamesUserDefaultKey];
    for (NSArray *pair in m2mTablesArray) {
        NSString *modelName1 = pair.firstObject;
        NSString *modelName2 = pair[1];
        [self.class createMiddleTableByModel:modelName1 andModel:modelName2];
    }
}

+ (NSString *)pathOfDB {
    NSURL *documentURL = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    NSString *documentPath = [documentURL.absoluteString stringByAppendingString:LocalDatabaseFileName];
    return documentPath;
}

+ (FMDatabase *)database {
    NSString *path = [self.class pathOfDB];
    return [FMDatabase databaseWithPath:path];
}
    
- (NSArray *)columnNamesFromProperties:(NSSet *)properties {
    NSMutableArray *result = [NSMutableArray new];
    [result addObject:@"id"];

    for (NSString *property in properties) {
        if (!property) {
            continue;
        }

        NSString *columnName = [self.class rawFieldNameFromPropertyName:property];
        NSString *valueString = [self.class valueStringFromObject:self propertyName:property];

        if (!valueString) {
            continue;
        }

        [result addObject:columnName];
    }

    return result;
}

- (NSArray *)valueNamesFromProperties:(NSSet *)properties {
    NSMutableArray *result = [NSMutableArray new];
    [result addObject:[NSString stringWithFormat:@"'%@'", self.objectId]];
    
    for (NSString *property in properties) {
        NSString *valueString = [self.class valueStringFromObject:self propertyName:property];
        if (!valueString) {
            continue;
        }
        
        valueString = [NSString stringWithFormat:@"'%@'", valueString];
        [result addObject:valueString];
    }
    
    return result;
}
    


#pragma mark - Create Table

+ (void)createTableIfNeeded {
    NSString *dbPath = [self.class pathOfDB];
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    NSString *tableName = NSStringFromClass(self.class);
    [queue inDatabase:^(FMDatabase *db) {
        if(![db tableExists:tableName]) {
            NSString *createTableSQL = [self.class sqlForCreateTable];
            [db executeUpdate:createTableSQL];
            if ([db hadError]) {
                NSLog(@"[LCModelObject] Could not create table %@. ERROR-: %@", tableName, [db lastErrorMessage]);
            }
        }
    }];
}

+ (NSString *)sqlForCreateTable {
    NSString *tableName = NSStringFromClass(self.class);
    NSSet *properties = [NSSet set];
    
    properties = [properties setByAddingObjectsFromSet:[self.class propertyNames]];
    NSString *createTableSQL = @"id TEXT";
    
    for (NSString *property in properties) {
        if (!property) {
            continue;
        }
        
        NSString *columnName = [self.class rawFieldNameFromPropertyName:property];
        createTableSQL = [createTableSQL stringByAppendingFormat:@", %@ TEXT", columnName];
    }
    
    // id
    createTableSQL = [createTableSQL stringByAppendingFormat:@", PRIMARY KEY(id ASC)"];
    
    createTableSQL = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (%@)", tableName, createTableSQL];
    
    return createTableSQL;
}

#pragma mark - M2M

+ (void)setManyToManyBetweenModel:(NSString *)modelName1 andModel:(NSString *)modelName2 {
//    NSString *middleTableName = [self.class middleTableNameFromModel:modelName1 andModel:modelName2];
    if (modelName1 && modelName1) {
        NSArray *pair = @[modelName1, modelName2];
        pair = [pair sortedArrayUsingSelector: @selector(localizedCaseInsensitiveCompare:)];
        
        NSArray *m2mTableNamesArray = [LCSettings settingForKey:ManyToManyTableNamesUserDefaultKey];
        NSMutableSet *manyToManyTables = [NSMutableSet setWithArray:m2mTableNamesArray];
        [manyToManyTables addObject:pair];
        [LCSettings setSetting:manyToManyTables.allObjects forKey:ManyToManyTableNamesUserDefaultKey];
    } else {
        NSLog(@"LCModel setManyToMany error: model name can't be nil.");
    }
}

+ (NSString *)middleTableNameFromModel:(NSString *)modelName1 andModel:(NSString *)modelName2 {
    NSString *middleTableName = nil;
    NSComparisonResult compareResult = [modelName1 compare:modelName2];
    if (compareResult == NSOrderedAscending || compareResult == NSOrderedSame) {
        middleTableName = [NSString stringWithFormat:@"%@_%@", modelName1, modelName2];
    } else {
        middleTableName = [NSString stringWithFormat:@"%@_%@", modelName2, modelName1];
    }
    
    return middleTableName;
}

+ (NSString *)sqlForCreateMiddleTableFromModel:(NSString *)modelName1 andModel:(NSString *)modelName2 {
    NSString *tableName = [self.class middleTableNameFromModel:modelName1 andModel:modelName2];
    
    NSString *createTableSQL = [NSString stringWithFormat:@"%@_id TEXT, %@_id TEXT", modelName1, modelName2];
    
    createTableSQL = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (%@ , UNIQUE(%@_id, %@_id) ON CONFLICT REPLACE)", tableName, createTableSQL, modelName1, modelName2];
    
    return createTableSQL;
}

+ (void)createMiddleTableByModel:(NSString *)modelName1 andModel:(NSString *)modelName2 {
    NSString *dbPath = [self.class pathOfDB];
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    NSString *tableName = NSStringFromClass(self.class);
    [queue inDatabase:^(FMDatabase *db) {
        if(![db tableExists:tableName]) {
            NSString *createTableSQL = [self.class sqlForCreateMiddleTableFromModel:modelName1
                                                                           andModel:modelName2];
            [db executeUpdate:createTableSQL];
            if ([db hadError]) {
                NSLog(@"[LCModelObject] Could not create middle table %@. ERROR-: %@", tableName, [db lastErrorMessage]);
            }
        }
    }];
}

+ (BOOL)isManyToManyBetweenModel:(NSString *)modelName1 andModel:(NSString *)modelName2 {
    if (modelName1 && modelName2) {
        NSArray *pair = @[modelName1, modelName2];
        pair = [pair sortedArrayUsingSelector: @selector(localizedCaseInsensitiveCompare:)];
        
        //    NSString *middleTableName = [self.class middleTableNameFromModel:modelName1 andModel:modelName2];
        NSArray *m2mTablesArray = [LCSettings settingForKey:ManyToManyTableNamesUserDefaultKey];
        
        if ([m2mTablesArray containsObject:pair]) {
            return YES;
        }
    }
    
    return NO;
}

#pragma mark Pin Data for M2M

+ (NSString *)pinSQLForM2MByObject:(LCModelObject *)object array:(NSArray *)array {
    NSString *middleTableName = [self.class middleTableNameFromModel:NSStringFromClass([object class])
                                                            andModel:NSStringFromClass([array.firstObject class])];
    
    NSString *pinSQL = @"";
    for (LCModelObject *element in array) {
        NSString *pinObjectSQL = [NSString stringWithFormat:@"INSERT OR REPLACE INTO %@ (%@_id,%@_id) VALUES ('%@','%@');", middleTableName, [object class], [element class], object.objectId, element.objectId];
        
        pinSQL = [pinSQL stringByAppendingString:pinObjectSQL];
    }
    
    
    return pinSQL;
}
    
#pragma mark Find Data for M2M (sync)
    
- (NSArray *)findFromLocalByModelName:(NSString *)modelName viaMiddleTable:(NSString *)middleTableName {
    // ============== get all data from middle table first
    NSString *middleKey = [NSString stringWithFormat:@"%@_id", NSStringFromClass(self.class)];
    NSArray *middleDatas = [self.class findFromLocalByModelName:middleTableName key:middleKey equalTo:self.objectId];
    
    // compose parameters
    NSString *findSQLBeginning = [NSString stringWithFormat:@"SELECT * FROM %@", modelName];
    NSString *findSQL = findSQLBeginning;
    for (NSDictionary *middleData in middleDatas) {
        NSString *targetIDColumnName = [NSString stringWithFormat:@"%@_id", modelName];
        NSString *targetID = middleData[targetIDColumnName];
        if ([findSQL isEqualToString:findSQLBeginning]) {
            findSQL = [findSQL stringByAppendingFormat:@" WHERE id=%@", targetID];
        } else {
            findSQL = [findSQL stringByAppendingFormat:@" OR id=%@", targetID];
        }
    }
    
    return [self.class findFromLocalBySQL:findSQL resultModelName:modelName];
}

#pragma mark -

+ (NSSet *)propertyNames {
    unsigned count;
    objc_property_t *properties = class_copyPropertyList(self.class, &count);
    
    NSMutableSet *rv = [NSMutableSet set];
    
    unsigned i;
    for (i = 0; i < count; i++) {
        objc_property_t property = properties[i];
        NSString *name = [NSString stringWithUTF8String:property_getName(property)];
        [rv addObject:name];
    }
    
    free(properties);
    
    // handle super class
    Class superclass = class_getSuperclass(self.class);
    NSString *superclassName = NSStringFromClass(superclass);
    if ([superclassName isEqualToString:@"LCModelObject"]) {
        return rv;
    }
    
    NSSet *superRv = [superclass propertyNames];
    [rv addObjectsFromArray:superRv.allObjects];
    
    return rv;
}

+ (NSString *)typeOfProperty:(NSString *)propertyName {
    objc_property_t property = class_getProperty(self.class, [propertyName UTF8String]);
    
    NSString *propertyInfo = [NSString stringWithUTF8String:property_getAttributes(property)];
    NSString *propertyType = nil;
    
    NSArray *propertyAttributes = [propertyInfo componentsSeparatedByString:@","];
    for (NSString *attribute in propertyAttributes) {
        if ([attribute hasPrefix:@"T@\""]) {
            propertyType = [attribute substringWithRange:NSMakeRange(3, attribute.length - 4)];
        }
    }
    
    return propertyType;
}

+ (NSString *)pinSQLForObject:(id)object {
    NSMutableString *sql = [NSMutableString new];
    NSString *tableName = NSStringFromClass([object class]);
    
    // if exist then update, or insert
    NSSet *allProperties = [[object class] propertyNames];
    NSArray *columnNames = [object columnNamesFromProperties:allProperties];
    NSArray *valueStrings = [object valueNamesFromProperties:allProperties];
    NSString *stringOfColumns = [columnNames componentsJoinedByString:@","];
    NSString *stringOfValues = [valueStrings componentsJoinedByString:@","];
    NSString *updateSQL = [self.class updateSQLFromColumns:columnNames values:valueStrings object:object];
    
    NSString *currentSQL = [NSString stringWithFormat:@"%@ INSERT OR IGNORE INTO %@ (%@) VALUES (%@);", updateSQL, tableName, stringOfColumns, stringOfValues];
    
    // if object of the property is kind of LCModelObject or NSArray
    for (NSString *property in allProperties) {
        if ([object[property] isKindOfClass:[LCModelObject class]]) {
            // the property type is LCModelObject
            NSString *tempSQL = [self.class pinSQLForArray:@[object[property]]];
            currentSQL = [currentSQL stringByAppendingString:tempSQL];
        } else if ([object[property] isKindOfClass:[NSArray class]]) {
            // the property type is array of LCModelObject
            NSArray *array = object[property];
            NSString *tempSQL = [object saveSQLOfArrayProperty:array];
            currentSQL = [currentSQL stringByAppendingString:tempSQL];
        }
    }
    
    [sql appendString:currentSQL];
    
    return sql;
}

+ (NSString *)pinSQLForArray:(NSArray<LCModelObject *> *)array {
    NSMutableString *sql = [NSMutableString new];
    for (id object in array) {
        NSString *currentSQL = [self.class pinSQLForObject:object];
        
        [sql appendString:currentSQL];
    }
    
    return sql;
}

+ (NSString *)updateSQLFromColumns:(NSArray *)columns values:(NSArray *)values object:(id)object {
    NSString *tableName = NSStringFromClass([object class]);
    NSString *objectId = object[@"objectId"];
    NSString *updateBeginning = [NSString stringWithFormat:@"UPDATE %@ SET ", tableName];
    NSString *result = updateBeginning;
    
    for (NSInteger i=0; i<columns.count; i++) {
        // try to add comma
        if (![result isEqualToString:updateBeginning]) {
            result = [result stringByAppendingString:@","];
        }
        
        NSString *column = columns[i];
        NSString *value = values[i];
        result = [result stringByAppendingFormat:@"%@=%@", column, value];
    }
    
    result = [result stringByAppendingFormat:@" WHERE id = %@;", objectId];
    
    return result;
}
    
+ (NSString *)valueStringFromObject:(id)object propertyName:(NSString *)propertyName {
    id value = object[propertyName];
    if ([value isKindOfClass:[NSDate class]]) {
        NSDate *date = value;
        NSString *dateString = [LCModelObject dateStringFromDate:date];
        return dateString;
    } else if ([value isKindOfClass:[LCModelObject class]]) {
        LCModelObject *modelObject = value;
        return modelObject.objectId;
    } else if ([value isKindOfClass:[NSArray class]]) {
        // check is many to many or not
        NSString *typeOfArrayElement = NSStringFromClass([object objectTypeOfArrayProperty:propertyName]);
//        NSString *typeOfObject = NSStringFromClass([object class]);
//        BOOL isM2M = [self.class isManyToManyBetweenModel:typeOfObject andModel:typeOfArrayElement];
//        if (isM2M) {
//            
//        }
        
        return typeOfArrayElement;
    } else if ([value isKindOfClass:[LCObject class]]) {
        LCObject *object = value;
        NSString *jsonString = [object jsonString];
        return jsonString;
    }
    
    if (value) {
        NSString *valueString = [value description];
        valueString = [valueString stringByReplacingOccurrencesOfString:@"'" withString:@"''"];
        return valueString;
    }
    
    return nil;
}

+ (void)addColumn:(NSString *)columnName type:(NSString *)type tableName:(NSString *)tableName {
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:[self.class pathOfDB]];
    [queue inDatabase:^(FMDatabase *db) {
        if (![db columnExists:columnName inTableWithName:tableName]) {
            NSString *sql = [NSString stringWithFormat:@"ALTER TABLE %@ ADD COLUMN %@ %@;", tableName, columnName, type];
            if (![db executeStatements:sql]) {
                NSLog(@"sql: %@", sql);
                NSLog(@"sql error: %@", [db lastErrorMessage]);
            }
        }
    }];
}

- (NSString *)saveSQLOfArrayProperty:(NSArray<LCModelObject *> *)array {
    NSMutableString *sql = [NSMutableString new];
    
    // check is m2m or not
    NSString *typeOfArrayElement = NSStringFromClass(array.firstObject.class);
    NSString *typeOfObject = NSStringFromClass(self.class);
    
    BOOL isM2M = [self.class isManyToManyBetweenModel:typeOfObject andModel:typeOfArrayElement];
    
    if (isM2M) {
        // save data into middle table
        NSString *m2mPinSQL = [self.class pinSQLForM2MByObject:self array:array];
        
        [sql appendString:m2mPinSQL];
    }
    
    // generate insert / update SQL statement for each.
    for (id object in array) {
        NSString *tableName = NSStringFromClass([object class]);
        
        if ([tableName isEqualToString:@"FloorPlan"]) {
            NSLog(@"");
        }
        
        // if exist then update, or insert
        NSSet *allProperties = [[object class] propertyNames];
        NSArray *columnNames = [object columnNamesFromProperties:allProperties];
        NSArray *valueStrings = [object valueNamesFromProperties:allProperties];
        NSString *stringOfColumns = [columnNames componentsJoinedByString:@","];
        NSString *stringOfValues = [valueStrings componentsJoinedByString:@","];
        NSString *updateSQL = [self.class updateSQLFromColumns:columnNames values:valueStrings object:object];
        
        // add relationship column and value
        stringOfColumns = [stringOfColumns stringByAppendingString:[NSString stringWithFormat:@",%@_id", NSStringFromClass(self.class)]];
        stringOfValues = [stringOfValues stringByAppendingFormat:@",'%@'", self.objectId];
        
        NSString *forUpdate = [NSString stringWithFormat:@",%@_id='%@' WHERE id =", NSStringFromClass(self.class), self.objectId];
        updateSQL = [updateSQL stringByReplacingOccurrencesOfString:@" WHERE id =" withString:forUpdate];
        
        // create column if not exist
        [self.class addColumn:[NSString stringWithFormat:@"%@_id", NSStringFromClass(self.class)]
                         type:@"TEXT"
                    tableName:tableName];
        
        NSString *currentSQL = [NSString stringWithFormat:@"%@ INSERT OR IGNORE INTO %@ (%@) VALUES (%@);", updateSQL, tableName, stringOfColumns, stringOfValues];
        
        // if object of the property is kind of LCModelObject or NSArray
        for (NSString *property in allProperties) {
            if ([object[property] isKindOfClass:[LCModelObject class]]) {
                NSString *tempSQL = [self.class pinSQLForArray:@[object[property]]];
                currentSQL = [currentSQL stringByAppendingString:tempSQL];
            } else if ([object[property] isKindOfClass:[NSArray class]]) {
                NSArray *array = object[property];
                NSString *tempSQL = [object saveSQLOfArrayProperty:array];
                currentSQL = [currentSQL stringByAppendingString:tempSQL];
            }
        }
        
        [sql appendString:currentSQL];
    }
    
    return sql;
}

//- (NSString *)columnSQLFromProperties:(NSSet *)properties {
//    NSString *result = @"id";
//    
//    for (NSString *property in properties) {
//        if (!property) {
//            continue;
//        }
//        
//        NSString *columnName = [self.class rawFieldNameFromPropertyName:property];
//        NSString *valueString = [self.class valueStringFromObject:self propertyName:property];
//        
//        if (!valueString) {
//            continue;
//        }
//        
//        result = [result stringByAppendingFormat:@",%@", columnName];
//    }
//    
//    return result;
//}
//
//- (NSString *)valuesSQLFromProperties:(NSSet *)properties {
//    NSString *result = [NSString stringWithFormat:@"'%@'", self.objectId];
//    
//    for (NSString *property in properties) {
//        NSString *valueString = [self.class valueStringFromObject:self propertyName:property];
//        if (!valueString) {
//            continue;
//        }
//        result = [result stringByAppendingFormat:@",'%@'", valueString];
//    }
//    
//    return result;
//}

#pragma mark - Single Instance

+ (void)cacheModelObjects:(NSArray *)modelObjects {
    for (LCModelObject *modelObject in modelObjects) {
        [self.class cacheModelObject:modelObject];
    }
}

+ (void)cacheModelObject:(LCModelObject *)modelObject {
    // LCUser_1234
    NSString *modelObjectClassName = NSStringFromClass([modelObject class]);
    NSString *cacheKey = [NSString stringWithFormat:@"%@_%@", modelObjectClassName, modelObject.objectId];
    
    NSMapTable *sharedMapTable = [self.class sharedMapTable];
    [sharedMapTable setObject:modelObject forKey:cacheKey];
}

+ (LCModelObject *)modelObjectFromCacheByKey:(NSString *)key {
    NSMapTable *sharedMapTable = [self.class sharedMapTable];
    return [sharedMapTable objectForKey:key];
}

@end
