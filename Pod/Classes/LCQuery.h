//
//  LoopdRequest.h
//  Loopd
//
//  Created by Derrick Chao on 2015/5/6.
//  Copyright (c) 2015 Loopd Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, LCRequestMethod) {
    LCRequestMethodGET,
    LCRequestMethodPOST,
    LCRequestMethodPUT,
    LCRequestMethodDELETE
};

typedef void (^LCResultBlock)(id responseObject, NSError *error);
typedef void (^LCArrayResultBlock)(NSArray *objects, NSError *error);
typedef void (^LCBoolResultBlock)(BOOL succeeded, NSError *error);
typedef void (^LCVoidCompletion)(void);





@interface LCQuery : NSObject

@property (nonatomic) LCRequestMethod requestMethod;
@property (nonatomic) NSTimeInterval timeoutInterval;
@property (strong, nonatomic) NSString *relatedPath;
@property (strong, nonatomic) NSMutableDictionary *header;
@property (strong, nonatomic) NSMutableDictionary *parameters;
@property (strong, nonatomic) NSData *appendData;


// init
+ (instancetype)queryWithClass:(Class)class;
+ (instancetype)queryWithClass:(Class)class requestMethod:(LCRequestMethod)requestMethod;
+ (instancetype)queryWithClass:(Class)class requestMethod:(LCRequestMethod)requestMethod relatedPath:(NSString *)relatedPath;
+ (instancetype)queryWithClass:(Class)class requestMethod:(LCRequestMethod)requestMethod relatedPath:(NSString *)relatedPath parameters:(NSDictionary *)parameters;
- (instancetype)initWithClass:(Class)class requestMethod:(LCRequestMethod)requestMethod relatedPath:(NSString *)relatedPath parameters:(NSDictionary *)parameters;

// class method
+ (void)setBaseURL:(NSString *)baseURL;
+ (NSString *)baseURL;

// default header
+ (void)setDefaultValue:(NSString *)value forHeaderField:(NSString *)headerField;
+ (void)setDefaultHeaderFields:(NSDictionary *)headerFields;
+ (NSDictionary *)defaultHeaderFields;

// default parameter
+ (void)setDefaultParameter:(NSString *)parameter forKey:(NSString *)key;
+ (void)setDefaultParameters:(NSDictionary *)parameters;
+ (NSDictionary *)defaultParameters;
+ (void)enableCerFile:(NSString *)fileName;



// instance method
- (void)sendWithCompletion:(LCResultBlock)completion;

@end
