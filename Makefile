.PHONY: clean

SRC = icons.m ButtonDelegate.m RepoButtonDelegate.m Scanner.m \
	MainController.m MercurialDiffButtonDelegate.m GitDiffButtonDelegate.m \
	QuitButtonDelegate.m BugController.m TimeTracker.m \
	BubbleFactory.m RepoHelper.m TaskQueue.m DiffSet.m Diff.m FileDiff.m

CFLAGS=-F./RepoWatch.app/Contents/Frameworks -Wall -Werror -g -arch x86_64 -arch i386
OBJ = $(addsuffix .o, $(basename $(SRC)))

RepoWatch: $(OBJ) Info.plist
	gcc -Wall -Werror -F./RepoWatch.app/Contents/Frameworks -framework Growl -framework Sparkle -framework Carbon -framework Foundation \
		-framework AppKit -lobjc *.o -g -o RepoWatch -arch x86_64 -arch i386
	cp RepoWatch RepoWatch.app/Contents/MacOS/
	cp Info.plist RepoWatch.app/Contents/

clean:
	rm -f *.o RepoWatch
