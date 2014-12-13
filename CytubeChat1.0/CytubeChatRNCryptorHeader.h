//
//  CytubeChatRNCryptorHeader.h
//  CytubeChat
//
//

#import "RNEncryptor.h"

@interface CytubeChatRNCryptor : RNEncryptor

+ (NSData *)encryptData:(NSData *)data password:(NSString *)password error:(NSError **)error;

@end
