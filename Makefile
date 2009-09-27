MenuMonitor:
	gcc -g -Werror -framework Foundation -framework AppKit -framework ScriptingBridge -framework WebKit -lobjc -lcrypto *.m -o MenuMonitor
