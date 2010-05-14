.PHONY: clean

SRC = icons.m Scanner.m MainController.m BugController.m BubbleFactory.m \
	RepoHelper.m RepoMenuItem.m TaskQueue.m DiffSet.m Diff.m FileDiff.m \
	MainMenu.m HotKey.m BaseRepositoryType.m GitRepository.m \
	MercurialRepository.m RepoList.m RepoTypeList.m RepoInstance.m \
	LogMenuView.m CommitWindowController.m FileDiffListCell.m

CFLAGS=-F./RepoWatch.app/Contents/Frameworks -Wall -Werror -g -arch x86_64 -arch i386
OBJ = $(addsuffix .o, $(basename $(SRC)))
PRO_OBJ = $(addsuffix .o, $(basename $(PRO_SRC)))

RepoWatch: $(OBJ) Info.plist
	gcc -Wall -Werror -F./RepoWatch.app/Contents/Frameworks -framework Growl -framework Sparkle -framework Carbon -framework Foundation \
		-framework AppKit -lobjc $(OBJ) -g -o RepoWatch -arch x86_64 -arch i386
	cp RepoWatch RepoWatch.app/Contents/MacOS/
	cp Info.plist RepoWatch.app/Contents/

clean:
	rm -f *.o RepoWatch RepoWatchPro
