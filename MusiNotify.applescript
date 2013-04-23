global snme, inme, x, y, NPIT, NPSP, preffile

try
	-- Check to make sure that the user is running OSX 10.8
	set vers to (do shell script "sw_vers -productVersion")
	set pte to (do shell script "echo " & vers & " | cut -d '.' -f 1-2")
	if pte is not equal to "10.8" then
		display dialog "Sorry. This app requires OSX 10.8+" buttons ("OK")
		try
			set the_pid to (do shell script "ps ax | grep " & (quoted form of (POSIX path of (path to me))) & " | grep -v grep | awk '{print $1}'")
			if the_pid is not "" then do shell script ("kill -9 " & the_pid)
		end try
	end if
	
	try
		-- Read the preference file
		try
			do shell script "mkdir ~/Library/MusiNotify"
		end try
		try
			do shell script "touch ~/Library/MusiNotify/pref.txt"
		end try
		set preffile to "~/Library/MusiNotify/pref.txt"
		set pref to (do shell script "cat " & preffile)
		if pref = "" then
			
			-- If first run...	
			set ans to button returned of (display dialog "Would you like to set this app as a login item?" buttons {"No", "Yes"} default button 2 with title "MusiNotify")
			if ans = "Yes" then
				-- Make the app a login item
				set reso to (POSIX path of (path to me))
				tell application "System Events" to make login item at end with properties {path:reso, kind:application}
				-- Record the choice
				do shell script "echo login:1 > " & preffile
			else
				do shell script "echo login:0 > " & preffile
			end if
			
			-- Set preset settings
			do shell script "echo DispArt:1 >> " & preffile
			do shell script "echo DispAlb:0 >> " & preffile
			do shell script "echo NumOfNot:3 >> " & preffile
			
			-- Hide the Dock icon
			set infile to (POSIX path of (path to me) & "Contents/Info.plist")
			set pars to paragraphs of (do shell script "cat " & infile)
			try
				do shell script "rm " & infile
			end try
			do shell script "touch " & infile
			repeat with a from 1 to ((count of pars) - 2)
				do shell script "echo " & quoted form of (item a of pars) & " >> " & infile
			end repeat
			do shell script "echo '<key>NSUIElement</key>' >> " & infile
			do shell script "echo '<string>1</string>' >> " & infile
			do shell script "echo " & quoted form of (item -2 of pars) & " >> " & infile
			do shell script "echo " & quoted form of (item -1 of pars) & " >> " & infile
			
			-- Install the preference script
			try
				set prefreso to (POSIX path of (path to me) & "Contents/Resources/MusiNotify-Preferences.scpt")
				do shell script "cp " & prefreso & " ~/Library/Scripts/"
			end try
			
			display dialog "Please restart MusiNotify to finish installation." buttons ("Quit") default button 1 with title "MusiNotify"
			
			-- Quit
			try
				set the_pid to (do shell script "ps ax | grep " & (quoted form of (POSIX path of (path to me))) & " | grep -v grep | awk '{print $1}'")
				if the_pid is not "" then do shell script ("kill -9 " & the_pid)
			end try
		end if
	end try
end try

-- Set up variables
set snme to ""
set inme to ""
set x to 0
set y to 0
set NPIT to (POSIX path of (path to me)) & "Contents/Resources/ITN.app/Contents/MacOS/ITN"
set NPSP to (POSIX path of (path to me)) & "Contents/Resources/SPN.app/Contents/MacOS/SPN"
-- Update app path in preffile
try
	set preffile to "~/Library/MusiNotify/pref.txt"
	set prevtext to paragraphs of (do shell script "cat " & preffile)
	do shell script "cat /dev/null >  " & preffile
	repeat with p in prevtext
		if p does not contain "/" then do shell script "echo " & p & " >> " & preffile
	end repeat
	do shell script "echo Apppath:" & (POSIX path of (path to me)) & " >> " & preffile
end try
on idle
	delay 0.1
	-- Read preferences
	set DispArt to (do shell script "cat " & preffile & " | grep 'DispArt' | cut -d ':' -f 2")
	set DispAlb to (do shell script "cat " & preffile & " | grep 'DispAlb' | cut -d ':' -f 2")
	set NumOfNot to (do shell script "cat " & preffile & " | grep 'NumOfNot' | cut -d ':' -f 2")
	
	tell application "System Events"
		set applist to (name of every process) -- See which apps are running
		if applist contains "Spotify" then
			
			try
				tell application "Spotify"
					-- Get Track info
					set strk to name of current track
					set isad to album of current track
					if DispArt = "1" then
						set sart to "By " & (artist of current track)
					else
						set sart to ""
					end if
					if DispAlb = "1" then
						set salb to "On " & (album of current track)
					else
						set salb to ""
					end if
					set pop to popularity of current track
					set dur to duration of current track
				end tell
				if isad does not contain "ad.doubleclick.net" then -- If the track is not an ad...
					if strk is not equal to snme then -- If track has changed...
						set snme to strk
						-- Determine the notification to replace
						set x to (x + 1)
						if x is greater than NumOfNot then set x to x - NumOfNot
						set xid to x as text
						do shell script NPSP & " -title " & (quoted form of snme) & " -subtitle " & (quoted form of sart) & " -message " & (quoted form of salb) & " -group SP" & xid & " -execute 'open /Applications/Spotify.app'" -- Display the notification
					end if
				end if
			end try
		else
			tell application "Finder"
				-- Remove previous notifications
				repeat with n from 1 to NumOfNot
					try
						do shell script NPSP & " -remove SP" & n
					end try
				end repeat
			end tell
			set snme to ""
		end if
		
		if applist contains "iTunes" then
			
			try
				tell application "iTunes"
					-- Get Track info
					set itrk to name of current track
					if DispArt = "1" then
						set iart to "By " & (artist of current track)
					else
						set iart to ""
					end if
					if DispAlb = "1" then
						set ialb to "On " & (album of current track)
					else
						set ialb to ""
					end if
				end tell
				if itrk is not equal to inme then -- If track has changed...
					-- Determine the notification to replace
					set inme to itrk
					set y to (y + 1)
					if y is greater than NumOfNot then set y to y - NumOfNot
					set yid to y as text
					do shell script NPIT & " -title " & (quoted form of inme) & " -subtitle " & (quoted form of iart) & " -message " & (quoted form of ialb) & " -group IT" & yid & " -execute 'open /Applications/iTunes.app'" -- Display the notification
				end if
			end try
		else
			tell application "Finder"
				-- Remove previous notifications
				repeat with o from 1 to NumOfNot
					try
						do shell script NPIT & " -remove IT" & o
					end try
				end repeat
			end tell
			set inme to ""
		end if
	end tell
	return 0.1
end idle

on quit
	continue quit
end quit