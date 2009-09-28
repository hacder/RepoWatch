.PHONY: release

MenuMonitor:
	gcc -g -Werror -F./MenuMonitor.app/Contents/Frameworks -framework Foundation -framework AppKit -framework Sparkle -framework ScriptingBridge -framework WebKit -lobjc -lcrypto *.m -o MenuMonitor
	cp MenuMonitor MenuMonitor.app/Contents/MacOS/

release: MenuMonitor
	rm -f MenuMonitor-go.dmg
	hdiutil attach MenuMonitor.dmg -noautoopen -quiet -mountpoint /Volumes/MM-build
	cp -r MenuMonitor.app /Volumes/MM-build
	hdiutil detach /Volumes/MM-build -quiet -force
	hdiutil convert MenuMonitor.dmg -quiet -format UDZO -imagekey zlib-level=9 -o MenuMonitor-go.dmg
	openssl dgst -sha1 -binary < MenuMonitor-go.dmg | openssl dgst -dss1 -sign dsa_priv.pem | openssl enc -base64 > current-hash.txt
	