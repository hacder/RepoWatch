.PHONY: clean

SRC = icons.m ButtonDelegate.m RepoButtonDelegate.m Scanner.m \
	MainController.m MercurialDiffButtonDelegate.m GitDiffButtonDelegate.m \
	BugController.m BubbleFactory.m RepoHelper.m RepoMenuItem.m \
	TaskQueue.m DiffSet.m Diff.m FileDiff.m TaskSwitcher.m MainMenu.m \
	HotKey.m
PRO_SRC = TimeTracker.m

CFLAGS=-F./RepoWatch.app/Contents/Frameworks -Wall -Werror -g -arch x86_64 -arch i386
OBJ = $(addsuffix .o, $(basename $(SRC)))
PRO_OBJ = $(addsuffix .o, $(basename $(PRO_SRC)))

RepoWatch: $(OBJ) Info.plist
	gcc -Wall -Werror -F./RepoWatch.app/Contents/Frameworks -framework Growl -framework Sparkle -framework Carbon -framework Foundation \
		-framework AppKit -lobjc $(OBJ) -g -o RepoWatch -arch x86_64 -arch i386
	cp RepoWatch RepoWatch.app/Contents/MacOS/
	cp Info.plist RepoWatch.app/Contents/

RepoWatchPro: $(OBJ) $(PRO_OBJ) Info.plist
	gcc -Wall -Werror -F./RepoWatch.app/Contents/Frameworks -framework Growl -framework Sparkle -framework Carbon -framework Foundation \
		-framework AppKit -lobjc $(OBJ) $(PRO_OBJ) -g -o RepoWatchPro -arch x86_64 -arch i386
	cp RepoWatchPro RepoWatch.app/Contents/MacOS/RepoWatch
	cp Info.plist RepoWatch.app/Contents/
	

clean:
	rm -f *.o RepoWatch RepoWatchPro
