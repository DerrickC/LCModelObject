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
- (void)deleteWithCompletion:(LCBoolResultBlock)completion;
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
