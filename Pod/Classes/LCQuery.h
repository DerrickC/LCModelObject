// Created by Derrick Chao on 2015/5/6.
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
@property (strong, nonatomic) NSString *requestUrl;
@property (strong, nonatomic) NSMutableDictionary *header;
@property (strong, nonatomic) NSMutableDictionary *parameters;
@property (strong, nonatomic) NSData *appendData;


// init
+ (instancetype)query;
+ (instancetype)queryWithRequestMethod:(LCRequestMethod)requestMethod;
+ (instancetype)queryWithRequestMethod:(LCRequestMethod)requestMethod relatedPath:(NSString *)relatedPath;
+ (instancetype)queryWithRequestMethod:(LCRequestMethod)requestMethod relatedPath:(NSString *)relatedPath parameters:(NSDictionary *)parameters;
+ (instancetype)queryWithRequestMethod:(LCRequestMethod)requestMethod url:(NSString *)url parameters:(NSDictionary *)parameters;
- (instancetype)initWithRequestMethod:(LCRequestMethod)requestMethod url:(NSString *)url parameters:(NSDictionary *)parameters;

// class method
+ (void)setBaseURL:(NSString *)baseURL;
+ (NSString *)baseURL;

// default header
+ (void)setDefaultHeaderValue:(NSString *)value forKey:(NSString *)key;
+ (void)setDefaultHeaderValues:(NSDictionary *)values;
+ (NSDictionary *)defaultHeaderValues;

// default parameter
+ (void)setDefaultParameter:(NSString *)parameter forKey:(NSString *)key;
+ (void)setDefaultParameters:(NSDictionary *)parameters;
+ (NSDictionary *)defaultParameters;
+ (void)enableCerFile:(NSString *)fileName;



// instance method
- (void)sendWithCompletion:(LCResultBlock)completion;

@end
