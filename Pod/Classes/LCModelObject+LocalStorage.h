//
//  LCModelObject+LocalStorage.h
//  Loopd
//
//  Created by Derrick Chao on 2016/11/28.
//  Copyright © 2016 Loopd Inc. All rights reserved.
//

#import "LCModelObject.h"

@interface LCModelObject (LocalStorage)

#pragma mark - Pin (async)
+ (void)pinAll:(NSArray *)objects completion:(LCBoolResultBlock)completion;

#pragma mark - Find (sync)
+ (NSArray *)findAllFromLocal;
+ (NSArray *)findFromLocalByKey:(NSString *)key equalTo:(NSString *)value;
+ (NSArray *)findFromLocalByModelName:(NSString *)modelName key:(NSString *)key equalTo:(NSString *)value;
+ (NSArray *)findFromLocalByModelName:(NSString *)modelName parameters:(NSDictionary *)parameters;

#pragma mark - Find (async)
+ (void)findAllFromLocalWithCompletion:(LCArrayResultBlock)completion;
+ (void)findFromLocalByKey:(NSString *)key equalTo:(NSString *)value completion:(LCArrayResultBlock)completion;
+ (void)findFromLocalByModelName:(NSString *)modelName key:(NSString *)key equalTo:(NSString *)value completion:(LCArrayResultBlock)completion;
+ (void)findFromLocalByModelName:(NSString *)modelName parameters:(NSDictionary *)parameters completion:(LCArrayResultBlock)completion;

#pragma mark - Delete / Remove (async)
+ (void)deleteAllFromLocalWithCompletion:(LCBoolResultBlock)completion;
+ (void)removeWholeLocalDatabaseWithCompletion:(LCBoolResultBlock)completion;

#pragma mark - M2M Relationship

+ (void)setManyToManyBetweenModel:(NSString *)modelName1 andModel:(NSString *)modelName2;
+ (BOOL)isManyToManyBetweenModel:(NSString *)modelName1 andModel:(NSString *)modelName2;
+ (NSString *)middleTableNameFromModel:(NSString *)modelName1 andModel:(NSString *)modelName2;
- (NSArray *)findFromLocalByModelName:(NSString *)modelName viaMiddleTable:(NSString *)middleTableName;

#pragma mark - Local Storage

+ (void)registerModel;
+ (void)prepareLocalDatabase;

@end
