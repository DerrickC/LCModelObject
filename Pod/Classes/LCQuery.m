//
//  LoopdRequest.m
//  Loopd
//
//  Created by Derrick Chao on 2015/5/6.
//  Copyright (c) 2015年 Loopd Inc. All rights reserved.
//

#import <AFNetworking/AFNetworking.h>
#import "LCModelObject+LocalStorage.h"
#import "LCQuery.h"
#import "LCSettings.h"

#define SettingsPlistFileName               @"LCModelObjectSettingsPlistFileName"
#define QueryDefaultHeaderFieldKey          @"QueryDefaultHeaderFieldKey"
#define QueryDefaultParametersKey           @"QueryDefaultParametersKey"
#define QueryCertFileNameKey                @"QueryCertFileNameKey"
#define QueryBaseURL                        @"QueryBaseURL"

@interface LCQuery ()
@property (strong, nonatomic) Class targetClass;
@end

@implementation LCQuery

- (instancetype)init {
    self = [super init];
    
    if (self) {
        self.parameters = [NSMutableDictionary new];
        self.header = [NSMutableDictionary new];
        self.timeoutInterval = 0;
    }
    
    return self;
}

#pragma mark - Init

+ (instancetype)queryWithClass:(Class)class {
    return [[self class] queryWithClass:class requestMethod:LCRequestMethodGET relatedPath:nil];
}

+ (instancetype)queryWithClass:(Class)class requestMethod:(LCRequestMethod)requestMethod {
    return [[self class] queryWithClass:class requestMethod:requestMethod relatedPath:nil];
}

+ (instancetype)queryWithClass:(Class)class requestMethod:(LCRequestMethod)requestMethod relatedPath:(NSString *)relatedPath {
    return [[self class] queryWithClass:class requestMethod:requestMethod relatedPath:relatedPath parameters:nil];
}

+ (instancetype)queryWithClass:(Class)class requestMethod:(LCRequestMethod)requestMethod relatedPath:(NSString *)relatedPath parameters:(NSDictionary *)parameters {
    return [[LCQuery alloc] initWithClass:class requestMethod:requestMethod relatedPath:relatedPath parameters:parameters];
}

- (instancetype)initWithClass:(Class)class requestMethod:(LCRequestMethod)requestMethod relatedPath:(NSString *)relatedPath parameters:(NSDictionary *)parameters {
    
    self = [self init];
    
    if (self) {
        self.targetClass = class;
        self.requestMethod = requestMethod;
        self.relatedPath = relatedPath;
        if (parameters) {
            [self.parameters setDictionary:parameters];
        }
    }
    
    return self;
}

#pragma mark - Class Method

+ (void)setBaseURL:(NSString *)baseURL {
     [LCSettings setSetting:baseURL forKey:QueryBaseURL];
}

+ (NSString *)baseURL {
    return [LCSettings settingForKey:QueryBaseURL];
}

#pragma mark Header
+ (void)setDefaultValue:(NSString *)value forHeaderField:(NSString *)headerField {
    NSMutableDictionary *defaultHeaderFields = [[[self class] defaultHeaderFields] mutableCopy];
    
    if (defaultHeaderFields == nil) {
        defaultHeaderFields = [NSMutableDictionary new];
    }
    
    [defaultHeaderFields setObject:value forKey:headerField];
    
    [LCSettings setSetting:defaultHeaderFields forKey:QueryDefaultHeaderFieldKey];
}

+ (void)setDefaultHeaderFields:(NSDictionary *)headerFields {
    [LCSettings setSetting:headerFields forKey:QueryDefaultHeaderFieldKey];
}

+ (NSDictionary *)defaultHeaderFields {
    return [LCSettings settingForKey:QueryDefaultHeaderFieldKey];
}

#pragma mark Parameters

+ (void)setDefaultParameter:(NSString *)parameter forKey:(NSString *)key {
    NSMutableDictionary *defaultParameters = [[[self class] defaultParameters] mutableCopy];
    
    if (defaultParameters == nil) {
        defaultParameters = [NSMutableDictionary new];
    }
    
    [defaultParameters setObject:parameter forKey:key];
    
    [LCSettings setSetting:defaultParameters forKey:QueryDefaultParametersKey];
}

+ (void)setDefaultParameters:(NSDictionary *)parameters {
    [LCSettings setSetting:parameters forKey:QueryDefaultParametersKey];
}

+ (NSDictionary *)defaultParameters {
    return [LCSettings settingForKey:QueryDefaultParametersKey];
}

+ (void)enableCerFile:(NSString *)fileName {
    [LCSettings setSetting:fileName forKey:QueryCertFileNameKey];
}

#pragma mark - Instance Method

- (void)sendWithCompletion:(LCResultBlock)completion {
    
    if (self.targetClass == nil) {
        NSLog(@"[ERROR]: targetClass should not be nil!!!");
        if (completion) {
            NSError *error =  [NSError errorWithDomain:@"" code:400 userInfo:@{@"message": @"[ERROR]: targetClass should not be nil!!!"}];
            completion(nil, error);
        }
        
        return;
    }
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    
    // add acceptableContentType
    NSMutableSet *acceptableContentTypes = [manager.responseSerializer.acceptableContentTypes mutableCopy];
    [acceptableContentTypes addObject:@"application/vnd.api+json"];
    manager.responseSerializer.acceptableContentTypes = acceptableContentTypes;
    
    // security policy
    NSString *cerFileName = [LCSettings settingForKey:QueryCertFileNameKey];
    if (cerFileName != nil) {
        AFSecurityPolicy *policy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModePublicKey];
        manager.securityPolicy = policy;
        // if you install pods with use_framework!.
        // you need add below to make you pass the SSH connection.
        NSString *pathToCert = [[NSBundle mainBundle]pathForResource:cerFileName ofType:@"cer"];
        NSData *localCertificate = [NSData dataWithContentsOfFile:pathToCert];
        manager.securityPolicy.pinnedCertificates = [NSSet setWithObject:localCertificate];
    }
    
    NSString *requestMethod;
    
    switch (self.requestMethod) {
            case LCRequestMethodGET:
            requestMethod = @"GET";
            break;
            case LCRequestMethodPOST:
            requestMethod = @"POST";
            break;
            case LCRequestMethodPUT:
            requestMethod = @"PUT";
            break;
            case LCRequestMethodDELETE:
            requestMethod = @"DELETE";
            break;
            
            
        default:
            if (completion) {
                NSError *error = [NSError errorWithDomain:@"error" code:400 userInfo:@{@"message": @"invalid request method"}];
                completion(@"error", error);
                return;
            }
            break;
    }
    
    // compose request url
    NSMutableURLRequest *request;
    NSString *baseURL = [LCQuery baseURL];
    NSString *urlString;
    if ([self.relatedPath rangeOfString:@"http://"].location == NSNotFound && [self.relatedPath rangeOfString:@"https://"].location == NSNotFound) {
        // relative path
        urlString = [NSString stringWithFormat:@"%@%@", baseURL, self.relatedPath]; // [[NSURL URLWithString:path relativeToURL:baseURL] absoluteString];
    } else {
        // absolute path
        urlString = self.relatedPath;
    }
    
    // add default parameters
    NSDictionary *defaultParameters = [LCQuery defaultParameters];
    if (defaultParameters != nil) {
        for (NSString *key in defaultParameters.allKeys) {
            NSString *parameterValue = [defaultParameters[key] description];
            
            // Skip, if the key already in the current parameters.
            if (self.parameters[key] == nil) {
                [self.parameters setObject:parameterValue forKey:key];
            }
        }
    }
    
    if (!self.appendData) {
        request = [manager.requestSerializer requestWithMethod:requestMethod
                                                     URLString:urlString
                                                    parameters:self.parameters
                                                         error:nil];
    } else {
        request = [manager.requestSerializer multipartFormRequestWithMethod:requestMethod
                                                                  URLString:urlString
                                                                 parameters:self.parameters
                                                  constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
                                                      [formData appendPartWithFileData:self.appendData name:@"file" fileName:@"file.png" mimeType:@"image/png"];
                                                  }
                                                                      error:nil];
    }
    
    NSLog(@"[%@] %@", requestMethod, urlString);
    NSLog(@"\nparameters: %@", self.parameters);
    
    // add header
    // installation id
    NSDictionary *defaultHeader = [LCQuery defaultHeaderFields];
    NSLog(@"defaultHeader: %@", defaultHeader);
    if (defaultHeader != nil) {
        for (NSString *key in defaultHeader.allKeys) {
            NSString *value = [defaultHeader[key] description];
            
            // Skip, if the key already in the current parameters.
            if (self.header[key] == nil) {
                [self.header setObject:value forKey:key];
            }
        }
    }
    
    if (self.header.allKeys.count > 0) {
        [self handleHeader:self.header forRequest:request];
    }
    
    NSURLSessionDataTask *task = [manager dataTaskWithRequest:request uploadProgress:nil downloadProgress:nil completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        if (error) {
            // failed
            completion(responseObject, error);
        } else {
            // succeed
            if ([responseObject isKindOfClass:[NSArray class]]) {
                // if response is an array, we make it an array of LCModelObject
                NSArray *objects = [self.targetClass convertResultsToLCObjects:(NSArray *)responseObject];
                completion(objects, nil);
            } else if ([responseObject isKindOfClass:[NSDictionary class]]) {
                // if response is a dictionary, we transform it to LCModelObject
                LCModelObject *object = [[self.targetClass alloc] initWithStorage:responseObject];
                completion(object, nil);
            }
            
        }
    }];
    
    [request setTimeoutInterval:self.timeoutInterval];
    
    [task resume];
}

- (void)handleHeader:(NSDictionary *)header forRequest:(NSMutableURLRequest *)request {
    if (header != nil && [header isKindOfClass:[NSDictionary class]]) {
        NSArray *allKeys = header.allKeys;
        for (NSString *key in allKeys) {
            [request addValue:[header objectForKey:key] forHTTPHeaderField:key];
        }
    }
}

@end
