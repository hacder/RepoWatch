MenuMonitor:
	gcc -g -Werror -framework Foundation -framework AppKit -framework ScriptingBridge -lobjc -lcrypto *.m -o MenuMonitor
