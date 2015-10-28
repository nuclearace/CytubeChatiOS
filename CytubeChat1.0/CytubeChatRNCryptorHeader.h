//
//  CytubeChatRNCryptorHeader.h
//  CytubeChat
//
//

#import "RNEncryptor.h"

@interface CytubeChatRNCryptor : RNEncryptor

+ (NSData * __null_unspecified)encryptData:(NSData * __nullable)data password:(NSString * __nonnull)password error:(NSError * __null_unspecified * __nullable)error;

@end
