#!/usr/bin/php
<?

$git_dir = "/Users/dgrace/Desktop/Crazy Projects/MenuMonitor/";

switch ($argv[1]) {
	case "update":
		chdir($git_dir);
		$result = shell_exec("git diff | diffstat | tail -n 1");
		echo basename($git_dir) . ": ";
		echo trim($result);
		break;
	case "level":
		chdir($git_dir);
		$result = trim(shell_exec("git diff | diffstat | tail -n 1"));
		if ($result == "0 files changed")
			echo "4";
		else
			echo "24";
		break;
}

?>
