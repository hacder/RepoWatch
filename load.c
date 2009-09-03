#include <stdlib.h>
#include <stdio.h>

int main(int argc, char *argv[]) {
	double loads[3];
	getloadavg(loads, 3);
	
	if (strcmp("update", argv[1]) == 0) {
		printf("Load: %0.3f %0.3f %0.3f", loads[0], loads[1], loads[2]);
	} else if (strcmp("level", argv[1]) == 0) {
		if (loads[0] < 0.1 && loads[1] < 0.1 && loads[2] < 0.1)
			printf("6");
		else if (loads[0] < 1.0 && loads[1] < 1.0 && loads[2] < 1.0)
			printf("14");
		else
			printf("30");
	}
}