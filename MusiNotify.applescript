set vers to (do shell script "sw_vers -productVersion")
set pte to (do shell script "echo " & vers & " | cut -d '.' -f 1-2")
if pte is not equal to "10.8" then -- Check to make sure that the user is running OSX 10.8 or higher
	display dialog "Sorry. This app requires OSX 10.8 or higher." buttons ("OK")
	try
		set the_pid to (do shell script "ps ax | grep " & (quoted form of (POSIX path of (path to me))) & " | grep -v grep | awk '{print $1}'")
		if the_pid is not "" then do shell script ("kill -9 " & the_pid)
	end try
end if

try
	set preffile to (POSIX path of (path to me) & "Contents/Resources/pref.txt")
	try
		do shell script "touch " & preffile
	end try
	set pref to (do shell script "cat " & preffile) -- Read the preference file
	
	if pref = "" then
		set inst to button returned of (display dialog "Click OK to install necessary plugins" buttons {"Quit", "OK"} with title "SpotiNotify" default button 2)
		if inst = "Quit" then
			try
				set the_pid to (do shell script "ps ax | grep " & (quoted form of (POSIX path of (path to me))) & " | grep -v grep | awk '{print $1}'")
				if the_pid is not "" then do shell script ("kill -9 " & the_pid)
			end try
		end if
		try
			do shell script "gem install terminal-notifier" -- Install terminal-notifier
		end try
		
		set ans to button returned of (display dialog "Would you like to set this app as a login item?" buttons {"No", "Yes"} default button 2 with title "SpotiNotify")
		if ans = "Yes" then
			set reso to (POSIX path of (path to me))
			tell application "System Events" to make login item at end with properties {path:reso, kind:application} -- Make application a login item
			do shell script "echo 1 > " & preffile
		else
			do shell script "echo 0 > " & preffile
		end if
		
		set infile to (POSIX path of (path to me) & "Contents/Info.plist")
		set newfile to (POSIX path of (path to me) & "Contents/Resources/Info.plist")
		do shell script "mv " & newfile & " " & infile -- Make the Dock icon hidden
		display dialog "Please restart SpotiNotify to finish installation." buttons ("Quit") default button 1 with title "SpotiNotify"
		try
			set the_pid to (do shell script "ps ax | grep " & (quoted form of (POSIX path of (path to me))) & " | grep -v grep | awk '{print $1}'")
			if the_pid is not "" then do shell script ("kill -9 " & the_pid)
		end try
	end if
end try
set snme to ""
set inme to ""
repeat
	delay 0.1
	tell application "System Events"
		set applist to (name of every process)
		if applist contains "Spotify" then -- Check to see if Spotify is running
			try
				delay 0.1
				tell application "Spotify"
					set strk to name of current track -- Get Track info
					set sart to artist of current track
					set adlist to {"Spotify", "Universal Music", "Temple University", "Warner Music", "Nettwerk", "Sony Music"}
				end tell
				if adlist does not contain sart then -- If the track is not an ad...
					if strk is not equal to snme then -- If track has changed...
						set snme to strk
						tell application (POSIX path of (path to me))
							do shell script "terminal-notifier -subtitle \"" & snme & "\" -title \"Spotify - Now Playing\" -message \"By " & sart & "\" -group SP -execute \"open /Applications/Spotify.app\"" -- Display the notification
						end tell
					end if
				end if
			end try
		end if
		if applist contains "iTunes" then -- Check to see if Spotify is running
			try
				delay 0.1
				tell application "iTunes"
					if current track exists then
						set itrk to name of current track -- Get Track info
						set iart to artist of current track
					end if
				end tell
				if itrk is not equal to inme then -- If track has changed...
					set inme to itrk
					tell application (POSIX path of (path to me))
						do shell script "terminal-notifier -subtitle \"" & inme & "\" -title \"iTunes - Now Playing\" -message \"By " & iart & "\" -group IT -execute \"open /Applications/iTunes.app\"" -- Display the notification
					end tell
				end if
			end try
		end if
	end tell
end repeat