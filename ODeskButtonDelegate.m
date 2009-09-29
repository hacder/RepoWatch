#import "ODeskButtonDelegate.h"
#import <dispatch/dispatch.h>

@implementation ODeskButtonDelegate

- initWithTitle: (NSString *)s menu: (NSMenu *)m script: (NSString *)sc statusItem: (NSStatusItem *)si mainController: (MainController *)mc {
	self = [super initWithTitle: s menu: m script: sc statusItem: si mainController: mc];
	f = NULL;
	timeout = 10;
	start_time = 0;
	logged_time = 0;
	date = NULL;
	[self setHidden: YES];
	[self setupTimer];
	return self;
}

- (void) beep: (id) something {
}

- (void) fire {	
	struct tm *local;
	time_t t;
	t = time(NULL);
	local = localtime(&t);
	char *d2 = (char *)malloc(11);
	sprintf(d2, "%04d-%02d-%02d", local->tm_year + 1900, local->tm_mon + 1, local->tm_mday);
	
	if (date != NULL && strcmp(d2, date) != 0) {
		start_time = 0;
		logged_time = 0;
	}
	free(date);
	date = d2;

	if (f == 0) {
		NSString *filePath = [@"~/Library/Logs/oDesk Team.log" stringByStandardizingPath];
		f = fopen([filePath UTF8String], "r");
		if (f == 0) {
			[self setPriority: 1];
			[self setHidden: YES];
			return;
		}
	}
	
	dispatch_async(dispatch_get_global_queue(0, 0), ^{	
		int cur_time = 0;
		int running = 0;
		int logging = 0;
		BOOL today = NO;
		char *line = (char *)malloc(1024);

		while (fgets(line, 1000, f) != 0) {
			today = NO;
			if (strncmp(date, line, strlen(date)) == 0)
				today = YES;
			if (today) {
				cur_time = 
					(atoi(line + 11) * 60 * 60) +
					(atoi(line + 14) * 60) +
					(atoi(line + 17));
			}
			if (strstr(line, "is launched"))
				running = 1;
			if (strstr(line, "is terminating"))
				running = 0;
			if (strstr(line, "requested state [")) {
				char *state = strstr(line, "requested state [") + 17;
	
				if (logging == 0 && strncmp("CS_NORMAL", state, strlen("CS_NORMAL")) == 0) {
					logging = 1;
					if (today)
						start_time = cur_time;
				} else if (logging == 0 && strncmp("CS_RESUME", state, strlen("CS_RESUME")) == 0) {
					logging = 1;
					if (today)
						start_time = cur_time;
				} else if (logging == 1 && strncmp("CS_SUSPENDED", state, strlen("CS_SUSPENDED")) == 0) {
					logging = 0;
					if (today)
						logged_time += (cur_time - start_time);
				} else if (logging == 1 && strncmp("CS_DISCONNECTED", state, strlen("CS_DISCONNECTED")) == 0) {
					logging = 0;
					if (today)
						logged_time += (cur_time - start_time);
				}
			}
		}
		free(line);
	
		struct tm curtime;
		time_t now;
		time (&now);
		localtime_r(&now, &curtime);
		int seconds = curtime.tm_sec + curtime.tm_min * 60 + curtime.tm_hour * 3600;
		if (logging) {
			logged_time += (seconds - start_time);
			timeout = 1;
		} else {
			timeout = 10;
		}
		
		dispatch_async(dispatch_get_main_queue(), ^{
			NSString *status = [NSString stringWithFormat: @"%s: Logged %02d:%02d", logging ? "Working" : "Idle", 
					(int)floor(logged_time / 3600.0),
					(int)floor((logged_time -
						(floor(logged_time / 3600.0) * 3600)
					) / 60.0)];
			[self setShortTitle: status];
			[self setTitle: status];
			[self setHidden: NO];
			if (logging)
				[self setPriority: 30];
			else
				[self setPriority: 1];
		});
	});
}

@end