// Created by Derrick Chao on 2016/11/22.
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


#import <objc/runtime.h>
#import "LCModelObject+LocalStorage.h"
#import "LCObject.h"

@implementation LCObject

- (NSString *)description {
    return [[self jsonify] description];
}

#pragma mark - init

+ (instancetype)objectWithDictionary:(NSDictionary *)dictionary {
    return [[[self class] alloc] initWithDictionary:dictionary];
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
    self = [super init];
    
    if (self) {
        [self setValuesForKeysWithDictionary:dictionary];
    }
    
    return self;
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key {
    
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
    
    return rv;
}

#pragma mark - JSON data transfer

- (NSDictionary *)jsonify {
    NSString *propertyName;
    unsigned int outCount, i;
    objc_property_t *properties = class_copyPropertyList([self class], &outCount);
    
    NSMutableArray *propertyNames = [[NSMutableArray alloc] init];
    for (i = 0; i < outCount; i++) {
        objc_property_t property = properties[i];
        propertyName = [NSString stringWithCString:property_getName(property) encoding:NSStringEncodingConversionAllowLossy];
        if (![propertyName isEqualToString:@"description"] && ![propertyName isEqualToString:@"debugDescription"] && ![propertyName isEqualToString:@"hash"] && ![propertyName isEqualToString:@"superclass"]) {
            [propertyNames addObject:propertyName];
        }
    }
    
    NSDictionary *jsonObject = [[NSMutableDictionary alloc] init];
    for(NSString *propertyName in propertyNames) {
        if (![self valueForKey:propertyName]) {
            continue;
        }
        id valueObject = [self valueForKey:propertyName];
        if ([valueObject isKindOfClass:[LCModelObject class]]) {
            NSDictionary *valueDict = [valueObject jsonify];
            [jsonObject setValue:valueDict forKey:propertyName];
        } else {
            NSString *valueString = [NSString stringWithFormat:@"%@", valueObject];
            [jsonObject setValue:valueString forKey:propertyName];
        }
    }
    
    return jsonObject;
}

- (NSString *)jsonString {
    NSDictionary *jsonify = [self jsonify];
    
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonify
                                                       options:0
                                                         error:&error];
    if (!jsonData) {
        NSLog(@"LCObject jsonString: error: %@", error.localizedDescription);
        return @"{}";
    } else {
        return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
}

+ (NSDictionary *)dictionaryFromJSONString:(NSString *)string {
    NSError *jsonError;
    NSData *objectData = [string dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:objectData
                                                         options:NSJSONReadingMutableContainers
                                                           error:&jsonError];
    
    return json;
}

@end
