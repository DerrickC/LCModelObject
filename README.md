
# LCModelObject

## Description
This object helps you to send request to your server easily. Get response from the server and transfer to model object altomatically. You don't need to deal with the NSDictionary object! This object also helps to save data locally. Don't need to know anything about CoreData or SQLite.

## Dependency

This object rely on 2 frameworks.
- AFNetworking
- FMDB

Please install these frameworks ready.

## Usage
`LCModelObject` is the basic object. Create a custom object then inherit from this object.
```objective-c
@interface User : LCModelObject
```



### Create the properties
in .h file
```objective-c
@property (strong, nonatomic) NSString *firstName;
@property (strong, nonatomic) NSString *lastName;
@property (strong, nonatomic) NSString *email;
@property (strong, nonatomic) NSDate *birthday;
@property (strong, nonatomic) NSNumber *age;
@property (strong, nonatomic) NSArray *cars;
@property (strong, nonatomic) NSArray *houses;
@property (strong, nonatomic) OtherInfo *info; // custom object
```

in .m file
```objective-c
@dynamic firstName;
@dynamic lastName;
@dynamic email;
@dynamic birthday;
@dynamic age;
@dynamic cars;
@dynamic houses;
@dynamic info;
```

### Override this to tell what's the model of an array


### Example: GET request
```objective-c
+ (void)getUserById:(NSString *)userId completion:(LCResultBlock)completion {
    NSString *relativePath = [NSString stringWithFormat:@"users/%@", userId];
    
    // create a query
    // you can also create query instance by [LCQuery queryWithClass:[User class] requestMethod:requestMethod relatedPath:relatedPath parameters:parameters];
    LCQuery *query = [[self class] queryWithRequestMethod:LCRequestMethodGET relatedPath:relativePath];
    
    // send
    [query sendWithCompletion:^(id responseObject, NSError *error) {
        if (error) {
            NSLog(@"findUserById error: %@", error);
            NSLog(@"findUserById error responseObject: %@", responseObject);
        }
        
        completion(responseObject, error);
    }];
}
```

### Provide base URL
```objective-c
NSString *baseURL = @"https://www.bigcompany.com";
[LCQuery setBaseURL:baseURL];
```

### Provide security certificate file if needed
```objective-c
[LCQuery enableCerFile:@"fileName"];
```

### Provide date format
```objective-c
[LCModelObject datePropertyFromDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"];
// or [LCModelObject datePropertyFromTimestampMS];
// or [LCModelObject datePropertyFromTimestampS];
```

### Example: POST request with data
```objective-c
- (void)uploadAvatarImage:(UIImage *)image userId:(NSString *)userId completion:(LCResultBlock)completion {
    NSString *relativePath = [NSString stringWithFormat:@"users/%@/avatar", userId];
    
    LCQuery *query = [[self class] queryWithRequestMethod:LCRequestMethodPOST relatedPath:relativePath];
    query.appendData = UIImagePNGRepresentation(image);
    
    [query sendWithCompletion:^(id responseObject, NSError *error) {
        if (error) {
            NSLog(@"upload avatar error: %@", error);
            NSLog(@"upload avatar responseObject: %@", responseObject);
        }
        
        if (completion) {
            completion(responseObject, error);
        }
    }];
}
```

### Example: request with parameters
```objective-c
NSString *firstName = @"firstName";
NSString *lastName = @"lastName";
NSNumber *age = @(20);
NSDictionary *parameters = @{@"firstName": firstName, @"lastName": lastName, @"age": age};
    
LCQuery *query = [[self class] queryWithRequestMethod:LCRequestMethodPUT relatedPath:relativePath parameters:parameters];
```

### Default parameters or header values
If you need some data every request, like token or something else...
Use `[LCQuery setDefaultValue:value forHeaderField:headerField]`
or
`[LCQuery setDefaultParameter:parameter forKey:key;]`
```objective-c
// default header
[LCQuery setDefaultValue:token forHeaderField:@"access_token"];
// default parameter
[LCQuery setDefaultParameter:currentUserId forKey:@"userId"];
```



## Local Storage
Save and load data from the local database.

### Register models
```objective-c
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // register models
    [User registerModel];
    [House registerModel];
    [Car registerModel];
    ...

    // if we know there is a many to many relationship between models
    [LCModelObject setManyToManyBetweenModel:NSStringFromClass([User class])
                                    andModel:NSStringFromClass([House class])];
                                    
    // then prepare the database
    [LCModelObject prepareLocalDatabase];
}
```

### Examples

Save Data
```objective-c
[LCModelObject pinAll:cars completion:^(BOOL succeeded, NSError *error) {
   // do something after save data.
}];
```

Load Data
```objective-c
// after get all cars data from server, then save them.

[Car findAllFromLocalWithCompletion:^(NSArray *cars, NSError *error) {
    // do something
}];
```

```objective-c
NSArray *cars = [Car findAllFromLocal];
```
or
```objective-c
[Car findAllFromLocalWithCompletion:^(NSArray *objects, NSError *error) {
    if (!error) {
        NSArray *cars = objects;
    }
}];
```

