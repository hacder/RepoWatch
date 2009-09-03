#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

int main(int argc, char *argv[]) {
	char *line = (char *)malloc(1024);
	char *date = (char *)malloc(11);
	int running = 0;
	int logging = 0;
	int today = 0;
	int cur_time = 0;
	int start_time = 0;
	int logged_time = 0;
	
	struct tm *local;
	time_t t;
	
	t = time(NULL);
	local = localtime(&t);
	
	sprintf(date, "%04d-%02d-%02d", local->tm_year + 1900, local->tm_mon + 1, local->tm_mday);
	
	FILE *f = fopen("/Users/dgrace/Library/Logs/oDesk Team.log", "r");
	while (fgets(line, 1000, f) != 0) {
		today = 0;
		if (strncmp(date, line, strlen(date)) == 0)
			today = 1;
		
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
			if (strncmp("CS_NORMAL", state, strlen("CS_NORMAL")) == 0) {
				logging = 1;
				if (today)
					start_time = cur_time;
			} else if (strncmp("CS_RESUME", state, strlen("CS_RESUME")) == 0) {
				logging = 1;
				if (today)
					start_time = cur_time;
			} else if (strncmp("CS_SUSPENDED", state, strlen("CS_SUSPENDED")) == 0) {
				logging = 0;
				if (today)
					logged_time += (cur_time - start_time);
			} else if (strncmp("CS_DISCONNECTED", state, strlen("CS_DISCONNECTED")) == 0) {
				logging = 0;
				if (today)
					logged_time += (cur_time - start_time);
			}
		}
	}
	free(line);
	free(date);
	
	struct tm curtime;
	time_t now;
	time (&now);
	localtime_r(&now, &curtime);
	int seconds = curtime.tm_sec + curtime.tm_min * 60 + curtime.tm_hour * 3600;
	if (logging)
		logged_time += (seconds - start_time);
	
	if (strcmp("update", argv[1]) == 0) {
		printf("%s: Logged %02d:%02d", logging ? "Working" : "Idle", logged_time / (60 * 60), (logged_time - (logged_time / (60 * 60))) / 60);
	} else if (strcmp("level", argv[1]) == 0) {
		if (logging)
			printf("30");
		else
			printf("1");
	}
}