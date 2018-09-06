//
//  iTermStatusBarLayout.m
//  iTerm2SharedARC
//
//  Created by George Nachman on 6/28/18.
//

#import "iTermStatusBarLayout.h"

#import "DebugLogging.h"
#import "NSArray+iTerm.h"
#import "NSColor+iTerm.h"
#import "NSDictionary+iTerm.h"

NS_ASSUME_NONNULL_BEGIN

NSString *const iTermStatusBarLayoutKeyComponents = @"components";
NSString *const iTermStatusBarLayoutKeyAdvancedConfiguration = @"advanced configuration";
// NOTE: If you add keys you might also need to update the computed default value in iTermProfilePreferences

static NSString *const iTermStatusBarLayoutKeyConfiguration = @"configuration";
static NSString *const iTermStatusBarLayoutKeyClass = @"class";

@implementation iTermStatusBarAdvancedConfiguration

+ (instancetype)advancedConfigurationFromDictionary:(NSDictionary *)dict {
    iTermStatusBarAdvancedConfiguration *configuration = [[iTermStatusBarAdvancedConfiguration alloc] init];
    configuration.separatorColor = [dict[@"separator color"] colorValue];
    configuration.backgroundColor = [dict[@"background color"] colorValue];
    configuration.defaultTextColor = [dict[@"default text color"] colorValue];
    return configuration;
}

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        self.separatorColor = [[aDecoder decodeObjectOfClass:[NSDictionary class] forKey:@"separator color"] colorValue];
        self.backgroundColor = [[aDecoder decodeObjectOfClass:[NSDictionary class] forKey:@"background color"] colorValue];
        self.defaultTextColor = [[aDecoder decodeObjectOfClass:[NSDictionary class] forKey:@"default text color"] colorValue];
    }
    return self;
}

- (NSDictionary *)dictionaryValue {
    NSDictionary *dict = @{ @"separator color": [self.separatorColor dictionaryValue] ?: [NSNull null],
                            @"background color": [self.backgroundColor dictionaryValue] ?: [NSNull null],
                            @"default text color": [self.defaultTextColor dictionaryValue] ?: [NSNull null] };
    return [dict dictionaryByRemovingNullValues];
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:[self.separatorColor dictionaryValue] forKey:@"separator color"];
    [aCoder encodeObject:[self.backgroundColor dictionaryValue] forKey:@"background color"];
    [aCoder encodeObject:[self.defaultTextColor dictionaryValue] forKey:@"default text color"];
}

@end

@implementation iTermStatusBarLayout {
    NSMutableArray<id<iTermStatusBarComponent>> *_components;
}

+ (NSArray<id<iTermStatusBarComponent>> *)componentsArrayFromDictionary:(NSDictionary *)dictionary {
    NSMutableArray<id<iTermStatusBarComponent>> *result = [NSMutableArray array];
    for (NSDictionary *dict in dictionary[iTermStatusBarLayoutKeyComponents]) {
        NSString *className = dict[iTermStatusBarLayoutKeyClass];
        Class theClass = NSClassFromString(className);
        if (![theClass conformsToProtocol:@protocol(iTermStatusBarComponent)]) {
            DLog(@"Bogus class %@", theClass);
            continue;
        }
        NSDictionary *configuration = dict[iTermStatusBarLayoutKeyConfiguration];
        if (!configuration) {
            DLog(@"Missing configuration for %@", dict);
            continue;
        }
        configuration = [configuration dictionaryBySettingObject:dictionary[iTermStatusBarLayoutKeyAdvancedConfiguration] ?: @{}
                                                          forKey:iTermStatusBarComponentConfigurationKeyLayoutAdvancedConfigurationDictionaryValue];
        id<iTermStatusBarComponent> component = [[theClass alloc] initWithConfiguration:configuration];
        [result addObject:component];
    }
    return result;
}

- (instancetype)initWithDictionary:(NSDictionary *)layout {
    return [self initWithComponents:[iTermStatusBarLayout componentsArrayFromDictionary:layout]
                      advancedConfiguration:[iTermStatusBarAdvancedConfiguration advancedConfigurationFromDictionary:layout[iTermStatusBarLayoutKeyAdvancedConfiguration]]];
}

- (instancetype)initWithComponents:(NSArray<iTermStatusBarComponent> *)components
             advancedConfiguration:(iTermStatusBarAdvancedConfiguration *)advancedConfiguration {
    self = [super init];
    if (self) {
        _advancedConfiguration = advancedConfiguration;
        _components = [components mutableCopy];
    }
    return self;
}

- (instancetype)init {
    return [self initWithDictionary:@{}];
}

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder {
    return [self initWithComponents:[aDecoder decodeObjectOfClass:[NSArray class] forKey:@"components"]
              advancedConfiguration:[aDecoder decodeObjectOfClass:[iTermStatusBarAdvancedConfiguration class] forKey:@"advanced configuration"]];
}

- (void)setComponents:(NSArray<id<iTermStatusBarComponent>> *)components {
    _components = [components copy];
    [self.delegate statusBarLayoutDidChange:self];
}

- (NSArray *)arrayValue {
    return [_components mapWithBlock:^id(id<iTermStatusBarComponent> component) {
        return @{ iTermStatusBarLayoutKeyClass: NSStringFromClass([component class]),
                  iTermStatusBarLayoutKeyConfiguration: component.configuration };
    }];
}

- (NSDictionary *)dictionaryValue {
    return [@{ iTermStatusBarLayoutKeyComponents: [self arrayValue],
               iTermStatusBarLayoutKeyAdvancedConfiguration: [_advancedConfiguration dictionaryValue] ?: [NSNull null] } dictionaryByRemovingNullValues];
}


#pragma mark - NSSecureCoding

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:_components forKey:@"components"];
    [aCoder encodeObject:_advancedConfiguration forKey:@"advanced configuration"];
}

@end

NS_ASSUME_NONNULL_END