//
//  TweakCompiler-Bridging-Header.h
//  TweakCompiler
//

#import <Foundation/Foundation.h>

// MobileContainerManager private API
@interface MCMContainer : NSObject
+ (instancetype)containerWithIdentifier:(NSString *)identifier
                      createIfNecessary:(BOOL)createIfNecessary
                                existed:(BOOL *)existed
                                  error:(NSError **)error;
@property (nonatomic, readonly) NSURL *url;
@end

@interface MCMAppDataContainer : MCMContainer
@end

