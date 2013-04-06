global snme, inme, x, y, NPIT, NPSP

on run
	try
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
				set ans to button returned of (display dialog "Would you like to set this app as a login item?" buttons {"No", "Yes"} default button 2 with title "MusiNotify")
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
				display dialog "Please restart MusiNotify to finish installation." buttons ("Quit") default button 1 with title "MusiNotify"
				try
					set the_pid to (do shell script "ps ax | grep " & (quoted form of (POSIX path of (path to me))) & " | grep -v grep | awk '{print $1}'")
					if the_pid is not "" then do shell script ("kill -9 " & the_pid)
				end try
			end if
		end try
	end try
	set snme to ""
	set inme to ""
	set x to 0
	set y to 0
	set NPIT to (POSIX path of (path to me)) & "Contents/Resources/iTunes.app/Contents/MacOS/iTunes"
	set NPSP to (POSIX path of (path to me)) & "Contents/Resources/Spotify.app/Contents/MacOS/Spotify"
end run

on idle
	delay 0.1
	tell application "System Events"
		set applist to (name of every process)
		if applist contains "Spotify" then -- Check to see if Spotify is running
			try
				tell application "Spotify"
					set strk to name of current track -- Get Track info
					set sart to artist of current track
					set pop to popularity of current track
				end tell
				if pop is not 0 then -- If the track is not an ad...
					if strk is not equal to snme then -- If track has changed...
						set snme to strk
						set x to (x + 1)
						if x is greater than 3 then set x to x - 3
						set xid to x as text
						do shell script NPSP & " -title \"" & snme & "\" -subtitle \"By " & sart & "\" -message \"\" -group SP" & xid & " -execute 'open /Applications/Spotify.app'" -- Display the notification
					end if
				end if
			end try
		else
			tell application "Finder"
				do shell script NPSP & " -remove SP1"
				do shell script NPSP & " -remove SP2"
				do shell script NPSP & " -remove SP3"
			end tell
		end if
		if applist contains "iTunes" then -- Check to see if iTunes is running
			try
				tell application "iTunes"
					if current track exists then
						set itrk to name of current track -- Get Track info
						set iart to artist of current track
					end if
				end tell
				if itrk is not equal to inme then -- If track has changed...
					set inme to itrk
					set x to (x + 1)
					if x is greater than 3 then set x to x - 3
					set xid to x as text
					tell application (POSIX path of (path to me))
						do shell script NPIT & " -title \"" & inme & "\" -subtitle \"By " & iart & "\" -message \"\" -group IT" & xid & " -execute 'open /Applications/iTunes.app'" -- Display the notification
					end tell
				end if
			end try
		else
			tell application "Finder"
				do shell script NPIT & " -remove IT1"
				do shell script NPIT & " -remove IT2"
				do shell script NPIT & " -remove IT3"
			end tell
		end if
	end tell
	return 0.1
end idle
on quit
	continue quit
end quit