#import "TwitterBaseButtonDelegate.h"
#import <dispatch/dispatch.h>
#import <openssl/bio.h>
#import <openssl/evp.h>

@implementation TwitterBaseButtonDelegate

- initWithTitle: (NSString *)s menu: (NSMenu *)m script: (NSString *)sc statusItem: (NSStatusItem *)si mainController: (MainController *)mc {
	self = [super initWithTitle: s menu: m script: sc statusItem: si mainController: mc];
	return self;
}

- (NSString *) base64Username: (NSString *)u password: (NSString *)p {
	NSString *realData = [[[NSString alloc] initWithFormat: @"%@:%@", u, p] autorelease];
	const char *rd = [[realData dataUsingEncoding: NSASCIIStringEncoding allowLossyConversion: NO] bytes];

	BIO *mem = BIO_new(BIO_s_mem());
	BIO *b64 = BIO_new(BIO_f_base64());

	// use or not?
	BIO_set_flags(b64, BIO_FLAGS_BASE64_NO_NL);
	
	mem = BIO_push(b64, mem);
	BIO_write(mem, rd, [realData length]);
	int fb = BIO_flush(mem);
	if (fb != 1)
		return nil;
	
	char *base64Pointer;
	long base64Length = BIO_get_mem_data(mem, &base64Pointer);
	NSString *base64String = [[[NSString alloc] initWithCString: base64Pointer length: base64Length] autorelease];
	BIO_free_all(mem);
	return base64String;
}

- (NSData *)fetchDataForURL: (NSURL *)url {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL: url];

	// Only add the authorization key if twitter is enabled. Otherwise... I hope you do not need authorization!
	if ([defaults integerForKey: @"twitterEnabled"]) {
		NSString *username = [defaults stringForKey: @"twitterUsername"];
		NSString *password = [defaults stringForKey: @"twitterPassword"];
		if (username == nil || [username length] == 0 || password == nil || [password length] == 0)
			return nil;
	
		NSString *auth = [self base64Username: username password: password];
		if (auth != nil)
			[request setValue: [NSString stringWithFormat: @"Basic %@", auth] forHTTPHeaderField: @"Authorization"];
	}
	
	NSData *data = [NSURLConnection sendSynchronousRequest: request returningResponse: nil error: nil];
	return data;
}

@end