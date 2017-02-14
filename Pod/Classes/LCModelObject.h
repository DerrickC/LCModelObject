//
//  LCModelObject.h
//  Loopd
//
//  Created by Derrick Chao on 2015/2/25.
//  Copyright (c) 2015 Loopd Inc. All rights reserved.


#import <objc/runtime.h>
#import <Foundation/Foundation.h>
#import "LCQuery.h"
#import "LCObject.h"


typedef NS_ENUM(NSInteger, LCDateTransType) {
    LCDateTransTypeTimestampS,
    LCDateTransTypeTimestampMS,
    LCDateTransTypeDateFormat
};


@interface LCModelObject : NSObject <NSCoding>

@property (nonatomic) BOOL isFromLocal;
@property (strong, nonatomic) NSMutableDictionary *storage;
@property (strong, nonatomic) NSString *objectId;
@property (strong, nonatomic) NSDate *created;
@property (strong, nonatomic) NSDate *lastUpdated;

#pragma mark - Init

+ (instancetype)object;
+ (instancetype)objectWithStorage:(NSDictionary *)storage;
- (instancetype)initWithStorage:(NSDictionary *)storage;


/**
 Return a full URL string by relativePath.

 @param relativePath - E.g. users/1234
 @return full URL
 */
+ (NSString *)fullURLWithRelativePath:(NSString *)relativePath;


/**
 Sometimes the column name of a record from server that is reserved key for iOS.
 So we can not use the name as property name.
 Like: id, description...
 So overwrite this method to mapping a new name for it.

 @param propertyName - string of the model property name
 @return column name of the table from server
 */
+ (NSString *)rawFieldNameFromPropertyName:(NSString *)propertyName;



/**
 set what the format of date
 */
+ (void)datePropertyFromTimestampS;
+ (void)datePropertyFromTimestampMS;
+ (void)datePropertyFromDateFormat:(NSString *)format;



/**
 Return the current date type. There are 3 types.
 1. second timestamp
 2. millisecond timestamp
 3. specific format string

 @return LCDateTransType
 */
+ (LCDateTransType)currentDateTransType;



#pragma mark - Query
/**
 Create the query object by request method, path, and parameters.
 Then send the query to server.

 @return LCQuery
 */
+ (LCQuery *)query;
+ (LCQuery *)queryWithRequestMethod:(LCRequestMethod)requestMethod;
+ (LCQuery *)queryWithRequestMethod:(LCRequestMethod)requestMethod relatedPath:(NSString *)relatedPath;
+ (LCQuery *)queryWithRequestMethod:(LCRequestMethod)requestMethod relatedPath:(NSString *)relatedPath parameters:(NSDictionary *)parameters;


/**
 Transfer self object to JSON format dictionary

 @return self dictionary
 */
- (NSDictionary *)jsonify;


/**
 @return all the property names of self object.
 */
- (NSSet *)propertyNames;

/**
 *  Please over write this method if subclass has a array property;
 *  return class name of the elements.
 *
 *  @param propertyName Array property name.
 *
 *  @return Class name of the elements of the array.
 */
- (Class)objectTypeOfArrayProperty:(NSString *)propertyName;

/*!
 @abstract Returns the value associated with a given key.
 
 @discussion This method enables usage of literal syntax on `PFObject`.
 E.g. `NSString *value = object[@"key"];`
 
 @param key The key for which to return the corresponding value.
 
 @see objectForKey:
 */
- (id)objectForKey:(NSString *)key;
- (id)objectForKeyedSubscript:(NSString *)key;
- (void)setObject:(id)object forKeyedSubscript:(NSString *)key;
- (void)setObject:(id)object forKey:(NSString *)key;



#pragma mark - Helper


/**
 After we call an API of server.
 We will get an array of the model.
 This method helps us to convert an array of dictionary to an array of the model object.

 @param results raw result from server
 @return array of the model
 */
+ (NSArray *)convertResultsToLCObjects:(NSArray *)results;


/**
 Before you use this method.
 Please set the date format first.
 Call datePropertyFromTimestampS or datePropertyFromTimestampMS or datePropertyFromDateFormat:
 datePropertyFromTimestampS as default!
 
 E.g.  
 [LCModelObject dateFromDateString:123456789]; // timestamp
 [LCModelObject dateFromDateString:@"2017.01.01"]; // date string

 @param dateString - the date string from server.
 @return NSDate object
 */
+ (NSDate *)dateFromDateString:(NSString *)dateString;


/**
 Like upper method, this method convert date object to string.

 @param date - NSDate object
 @return date string
 */
+ (NSString *)dateStringFromDate:(NSDate *)date;

@end

