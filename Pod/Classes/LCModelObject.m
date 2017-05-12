// Created by Derrick Chao on 2015/2/25.
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

#import "AFNetworking.h"
#import "LCModelObject.h"
#import "LCSettings.h"
#import "LCModelObject+LocalStorage.h"

@implementation LCModelObject

@dynamic objectId;
@dynamic created;
@dynamic lastUpdated;

+ (instancetype)object {
    return [[[self class] alloc] init];
}

+ (instancetype)objectWithStorage:(NSDictionary *)storage {
    return [[[self class] alloc] initWithStorage:storage];
}

- (instancetype)initWithStorage:(NSDictionary *)storage {
    self = [super init];
    
    if (self) {
        [self.storage setDictionary:storage];
        
        // this method can't transfer the data to date object or custom object.
        //        [self setValuesForKeysWithDictionary:storage];
    }
    
    return self;
}

- (NSMutableDictionary *)storage {
    if (!_storage) {
        _storage = [NSMutableDictionary new];
    }
    
    return _storage;
}

- (NSString *)description {
    return [self.storage description];
}

- (id)initWithCoder:(NSCoder *)decoder {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    self.storage = [decoder decodeObjectForKey:@"storage"];
    self.objectId = [decoder decodeObjectForKey:@"objectId"];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:self.storage forKey:@"storage"];
    [encoder encodeObject:self.objectId forKey:@"objectId"];
}

#pragma mark - Subclassing

// *** overwrite official method. This is not custom method
+ (BOOL)resolveInstanceMethod:(SEL)selector {
    const char *rawName = sel_getName(selector);
    NSString *selectorName = NSStringFromSelector(selector);
    NSString *propertyName = nil;
    
    
    
    // get PropertyName from Selector
    if ([selectorName hasPrefix:@"set"]) {
        propertyName = [NSString stringWithFormat:@"%c%s", tolower(rawName[3]), (rawName+4)];
    } else if ([selectorName hasPrefix:@"is"]) {
        propertyName = selectorName;
    } else {
        propertyName = selectorName;
    }
    propertyName = [propertyName stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@":"]];
    const char *rawPropertyName = [propertyName UTF8String];
    
    
    // get Property from PropertyName
    Class cls = [self class];
    objc_property_t property = class_getProperty(self, [propertyName UTF8String]);
    if (!property) {
        return NO;
    }
    
    NSString *getterName = propertyName;
    NSString *setterName = [NSString stringWithFormat:@"set%c%s:", toupper(rawPropertyName[0]), (rawPropertyName+1)];
    NSString *propertyType = nil;
    
    NSString *propertyInfo = [NSString stringWithUTF8String:property_getAttributes(property)];
    
    NSArray *propertyAttributes = [propertyInfo componentsSeparatedByString:@","];
    for (NSString *attribute in propertyAttributes) {
        if ([attribute hasPrefix:@"T@\""]) {
            propertyType = [attribute substringWithRange:NSMakeRange(3, attribute.length - 4)];
            break;
        }
    }
    
    // custom getter and setter
    id (^getterBlock) (id) = ^id (LCModelObject *self) {
        NSString *objectKey = [[self class] rawFieldNameFromPropertyName:propertyName];
        Class propertyClass = NSClassFromString(propertyType);
        id o = [[self storage] objectForKey:objectKey];
        
        //        NSLog(@"propertyName: %@", propertyName);
        //        NSLog(@"propertyClass: %@", propertyClass);
        //        NSLog(@"o class: %@", [o class]);
        //        NSLog(@"o: %@", o);
        
        if ([propertyClass isSubclassOfClass:[LCModelObject class]] && self.isFromLocal == YES && [o isKindOfClass:[NSString class]]) {
            NSArray *results = [self.class findFromLocalByModelName:propertyType key:@"id" equalTo:o];
            
            if (results.firstObject) {
                [[self storage] setObject:results.firstObject forKey:objectKey];
            }
            
            return results.firstObject;
        }
        else if ([propertyClass isSubclassOfClass:[LCModelObject class]] || propertyClass == [LCModelObject class]) {
            if ([o isKindOfClass:[NSDictionary class]]) {
                LCModelObject *lcModelObject = [[propertyClass alloc] initWithStorage:(NSDictionary *)o];
                [[self storage] setObject:lcModelObject forKey:objectKey];
                return lcModelObject;
            }
        }
        else if (propertyClass == [NSArray class] && self.isFromLocal == YES && [o isKindOfClass:[NSString class]] ) {
            // get array property from local database
            Class objectType = [self objectTypeOfArrayProperty:objectKey];
            // check is many to many or 1 to many
            BOOL isManyToMany = [self.class isManyToManyBetweenModel:NSStringFromClass(self.class)
                                                            andModel:NSStringFromClass(objectType)];
            
            if (isManyToMany) {
                // find the objects from middle table
                NSString *middleTableName = [self.class middleTableNameFromModel:NSStringFromClass(self.class) andModel:NSStringFromClass(objectType)];
                NSArray *oArray = [self findFromLocalByModelName:NSStringFromClass(objectType) viaMiddleTable:middleTableName];
                
                return oArray;
            } else {
                NSArray *oArray = [self.class findFromLocalByModelName:NSStringFromClass(objectType) key:[NSString stringWithFormat:@"%@_id", NSStringFromClass(self.class)] equalTo:self.objectId];
                [[self storage] setObject:oArray forKey:objectKey];
                return oArray;
            }
        }
        else if ([o isKindOfClass:[NSArray class]]) {
            NSArray *oArray = (NSArray *)o;
            Class objectType = [self objectTypeOfArrayProperty:objectKey];
            if ([oArray.firstObject isKindOfClass:[NSDictionary class]]) {
                oArray = [[self class] convertResultsToLCObjects:oArray class:objectType];
                [[self storage] setObject:oArray forKey:objectKey];
                return oArray;
            }
        }
        else if ([propertyClass isSubclassOfClass:[LCObject class]]) {
            if ([o isKindOfClass:[NSString class]]) {
                NSDictionary *dictFromString = [LCObject dictionaryFromJSONString:o];
                id propertyObject = [propertyClass new];
                [propertyObject setValuesForKeysWithDictionary:dictFromString];
                
                return propertyObject;
            }
            
            if ([o isKindOfClass:[NSDictionary class]]) {
                LCObject *object = [propertyClass new];
                [object setValuesForKeysWithDictionary:o];
                
                return object;
            }
        }
        else if (![o isKindOfClass:propertyClass]) {
            if (o == [NSNull null] || o == nil) {
                return nil;
            }
            
            // convert object to property class type
            NSString *objectString = [o description];
            
            id result = [[self class] convertString:objectString toPropertyType:propertyType];
            
            // replace old date with the date object
            if ([propertyType isEqualToString:@"NSDate"] && result != nil) {
                [[self storage] setObject:result forKey:objectKey];
            }
            return result;
        }
        else if ((o == [NSNull null] || o == nil) && [propertyClass isSubclassOfClass:[LCModelObject class]] && self.isFromLocal) {
            // try to get data from local
            NSString *columnName = [NSString stringWithFormat:@"%@_id", propertyName];
            NSString *targetId = [[self storage] objectForKey:columnName];
            
            if (targetId) {
                NSArray *results = [self.class findFromLocalByModelName:propertyType key:@"id" equalTo:targetId];
                o = results.firstObject;
            }
        }
        
        if (o == [NSNull null] || o == nil) {
            return nil;
        }
        
        return o;
    };
    
    void (^setterBlock) (id, id) = ^(id self, id object) {
        NSString *objectKey;
        if (!object) {
            return;
        }
        
        objectKey = [[self class] rawFieldNameFromPropertyName:propertyName];
        [[self storage] setObject:object forKey:objectKey];
    };
    
    IMP getterIMP = imp_implementationWithBlock(getterBlock);
    IMP setterIMP = imp_implementationWithBlock(setterBlock);
    
    BOOL getterAdded = NO;
    BOOL setterAdded = NO;
    
    if (getterIMP != NULL) {
        getterAdded = class_addMethod(cls, NSSelectorFromString(getterName), getterIMP, "@@:");
    }
    
    if (setterIMP != NULL) {
        setterAdded = class_addMethod(cls, NSSelectorFromString(setterName), setterIMP, "v@:@");
    }
    
    if (!getterAdded || !setterAdded) {
        NSLog(@"====================");
        NSLog(@"error adding methods");
        NSLog(@"class: %@", NSStringFromClass(cls));
        NSLog(@"setter: %@ => added?:%d", setterName, setterAdded);
        NSLog(@"getter: %@ => added?:%d", getterName, getterAdded);
    }
    
    return YES;
}

+ (NSString *)fullURLWithRelativePath:(NSString *)relativePath {
    NSString *baseURL = [LCQuery baseURL];
    NSString *urlString = [NSString stringWithFormat:@"%@%@", baseURL, relativePath];
    NSString *urlStringWithToken = urlString;
    
    return urlStringWithToken;
}

#pragma mark - Convert

+ (NSArray *)convertResultsToLCObjects:(NSArray *)results {
    return [[self class] convertResultsToLCObjects:results class:[self class]];
}

+ (NSArray *)convertResultsToLCObjects:(NSArray *)results class:(Class)class {
    
    NSMutableArray *lcObjects = [NSMutableArray new];
    
    for (NSDictionary *result in results) {
        if ((id)result == [NSNull null]) {
            continue;
        }
        
        if (class) {
            LCModelObject *object = [[class alloc] init];
            [object.storage setDictionary:result];
            [lcObjects addObject:object];
        } else {
            [lcObjects addObject:result];
        }
    }
    
    return lcObjects;
}

+ (id)convertString:(NSString *)string toPropertyType:(NSString *)propertyType {
    if (NSClassFromString(propertyType) == [NSDate class]) {
        return [[self class] dateFromDateString:string];
    } else if (NSClassFromString(propertyType) == [NSNumber class]) {
        return [NSNumber numberWithFloat:[string floatValue]];
    } else if (NSClassFromString(propertyType) == [NSString class]) {
        return string;
    }
    
    return  nil;
}

- (Class)objectTypeOfArrayProperty:(NSString *)propertyName {
    // overwrite this method if subclass has array property
    
    return nil;
}

+ (NSString *)rawFieldNameFromPropertyName:(NSString *)propertyName {
    if ([propertyName isEqualToString:@"desc"]) {
        return @"description";
    } else if ([propertyName isEqualToString:@"objectId"]) {
        return @"id";
    }
    
    return propertyName;
}

#pragma mark - Class Method

+ (LCQuery *)query {
    return [[self class] queryWithRequestMethod:LCRequestMethodGET];
}

+ (LCQuery *)queryWithRequestMethod:(LCRequestMethod)requestMethod {
    return [[self class] queryWithRequestMethod:requestMethod relatedPath:nil];
}

+ (LCQuery *)queryWithRequestMethod:(LCRequestMethod)requestMethod relatedPath:(NSString *)relatedPath {
    return [[self class] queryWithRequestMethod:requestMethod relatedPath:relatedPath parameters:nil];
}

+ (LCQuery *)queryWithRequestMethod:(LCRequestMethod)requestMethod relatedPath:(NSString *)relatedPath parameters:(NSDictionary *)parameters {
    LCQuery *query = [LCQuery queryWithRequestMethod:requestMethod relatedPath:relatedPath parameters:parameters];
    return query;
}

+ (void)datePropertyFromTimestampS {
    [LCSettings setSetting:@(LCDateTransTypeTimestampS) forKey:DateTransTypeUserDefaultKey];
}

+ (void)datePropertyFromTimestampMS {
    [LCSettings setSetting:@(LCDateTransTypeTimestampMS) forKey:DateTransTypeUserDefaultKey];
}

+ (void)datePropertyFromDateFormat:(NSString *)format {
    [LCSettings setSetting:@(LCDateTransTypeDateFormat) forKey:DateTransTypeUserDefaultKey];
    [LCSettings setSetting:format forKey:DateFormatUserDefaultKey];
}

+ (LCDateTransType)currentDateTransType {
    NSNumber *num = [LCSettings settingForKey:DateTransTypeUserDefaultKey];
    if (num) {
        return num.integerValue;
    }
    
    return LCDateTransTypeTimestampS;
}

+ (NSDate *)dateFromDateString:(NSString *)dateString {
    LCDateTransType currentDateTransType = [self.class currentDateTransType];
    
    NSDate *date;
    switch (currentDateTransType) {
        case LCDateTransTypeTimestampS: {
            float timestamp = dateString.floatValue;
            date = [NSDate dateWithTimeIntervalSince1970:timestamp];
            break;
        }
            
        case LCDateTransTypeTimestampMS: {
            float timestamp = dateString.floatValue  / 1000.0;
            date = [NSDate dateWithTimeIntervalSince1970:timestamp];
            break;
        }
            
        case LCDateTransTypeDateFormat: {
            NSString *dateFormat = [LCSettings settingForKey:DateFormatUserDefaultKey];
            
            NSDateFormatter *dateFormatter = [NSDateFormatter new];
            [dateFormatter setDateFormat:dateFormat];
            [dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
            
            date = [dateFormatter dateFromString:dateString];
            break;
        }
            
        default:
            break;
    }
    
    return date;
}

+ (NSString *)dateStringFromDate:(NSDate *)date {
    LCDateTransType currentDateTransType = [self.class currentDateTransType];
    
    NSString *dateString;
    switch (currentDateTransType) {
        case LCDateTransTypeTimestampS: {
            NSTimeInterval timeInterval = [date timeIntervalSince1970];
            dateString = [NSString stringWithFormat:@"%f", timeInterval];
            break;
        }
            
        case LCDateTransTypeTimestampMS: {
            NSTimeInterval timeInterval = [date timeIntervalSince1970];
            dateString = [NSString stringWithFormat:@"%f", timeInterval * 1000];
            break;
        }
            
        case LCDateTransTypeDateFormat: {
            NSString *dateFormat = [LCSettings settingForKey:DateFormatUserDefaultKey];
            
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            [formatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
            [formatter setDateFormat:dateFormat];
            dateString = [formatter stringFromDate:date];
            break;
        }
            
        default:
            break;
    }
    
    return dateString;
}

#pragma mark - Instance Method

- (id)objectForKey:(NSString *)key {
    return [self.storage objectForKey:key];
}

- (void)setObject:(id)object forKey:(NSString *)key {
    [self.storage setObject:object forKey:key];
}

- (id)objectForKeyedSubscript:(NSString *)key {
    return [self valueForKey:key];
}

- (void)setObject:(id)object forKeyedSubscript:(NSString *)key {
    [self setValue:object forKey:key];
}

- (id)valueForUndefinedKey:(NSString *)key {
    return [self.storage objectForKey:key];
}

- (NSSet *)propertyNames {
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

#pragma mark - Private Custom Method

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
        if ([valueObject isKindOfClass:[LCModelObject class]] || [valueObject isKindOfClass:[LCObject class]]) {
            NSDictionary *valueDict = [valueObject jsonify];
            [jsonObject setValue:valueDict forKey:propertyName];
        } else {
            NSString *valueString = [NSString stringWithFormat:@"%@", valueObject];
            [jsonObject setValue:valueString forKey:propertyName];
        }
    }
    
    return jsonObject;
}

@end
