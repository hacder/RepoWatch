.PHONY: release clean

SRC = icons.m ButtonDelegate.m RepoButtonDelegate.m Scanner.m \
	MainController.m MercurialDiffButtonDelegate.m GitDiffButtonDelegate.m \
	QuitButtonDelegate.m SeparatorButtonDelegate.m BugController.m

CFLAGS=-F./RepoWatch.app/Contents/Frameworks -Wall -Werror -g -arch x86_64 -arch i386
OBJ = $(addsuffix .o, $(basename $(SRC)))

RepoWatch: $(OBJ) Info.plist
	gcc -F./RepoWatch.app/Contents/Frameworks -framework Growl -framework Sparkle -framework Carbon -framework Foundation -framework AppKit -lobjc *.o -g -o RepoWatch -arch x86_64 -arch i386
	cp RepoWatch RepoWatch.app/Contents/MacOS/
	cp Info.plist RepoWatch.app/Contents/

release: RepoWatch
	rm -f RepoWatch-go.dmg
	hdiutil attach RepoWatch.dmg -noautoopen -quiet -mountpoint /Volumes/MM-build
	cp -r RepoWatch.app /Volumes/MM-build
	hdiutil detach /Volumes/MM-build -quiet -force
	hdiutil convert RepoWatch.dmg -quiet -format UDZO -imagekey zlib-level=9 -o RepoWatch-go.dmg
	openssl dgst -sha1 -binary < RepoWatch-go.dmg | openssl dgst -dss1 -sign dsa_priv.pem | openssl enc -base64 > current-hash.txt

clean:
	rm -f *.o RepoWatch
