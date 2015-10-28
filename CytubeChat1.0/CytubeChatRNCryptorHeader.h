//
//  CytubeChatRNCryptorHeader.h
//  CytubeChat
//
//

#import "RNEncryptor.h"

@interface CytubeChatRNCryptor : RNEncryptor

+ (NSData *)encryptData:(NSData * __nullable)data password:(NSString * __nonnull)password error:(NSError ** __nullable)error;

@end
