#!/usr/bin/php
<?

$git_dir = "/Users/dgrace/fenceware-git/";

switch ($argv[1]) {
	case "update":
		chdir($git_dir);
		$result = shell_exec("git diff | diffstat | tail -n 1");
		echo "$git_dir: ";
		echo trim($result);
		break;
	case "level":
		chdir("/Users/dgrace/fenceware-git/");
		$result = trim(shell_exec("git diff | diffstat | tail -n 1"));
		if ($result == "0 files changed")
			echo "5";
		else
			echo "25";
		break;
}

?>