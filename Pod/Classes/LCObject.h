//
//  LCObject.h
//  Loopd
//
//  Created by Derrick Chao on 2016/11/22.
//  Copyright © 2016 Loopd Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LCObject : NSObject

+ (instancetype)objectWithDictionary:(NSDictionary *)dictionary;

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

- (NSDictionary *)jsonify;
- (NSString *)jsonString;
+ (NSDictionary *)dictionaryFromJSONString:(NSString *)string;

@end
