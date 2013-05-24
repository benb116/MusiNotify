global snme, inme, x, y, NPIT, NPSP, preffile, thanked

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
	
	-- Check if the preference file exists
	try
		set preffile to "com.BenB116.MusiNotify.plist"
		set prefFilePath to "~/Library/Preferences/" & preffile
		tell application "System Events"
			set isPrefFileExists to false
			if exists file prefFilePath then set isPrefFileExists to true
		end tell
	end try
	
	if isPrefFileExists is false then
		do shell script "touch ~/Library/Preferences/com.BenB116.MusiNotify.plist"
		-- Set initial settings
		do shell script "defaults write " & preffile & " 'login' '0'"
		set ans to button returned of (display dialog "Would you like to set this app as a login item?" buttons {"No", "Yes"} default button 2 with title "MusiNotify")
		if ans = "Yes" then do shell script "defaults write " & preffile & " 'login' '1'"
		do shell script "defaults write " & preffile & " 'DispArt' '1'"
		do shell script "defaults write " & preffile & " 'DispAlb' '0'"
		do shell script "defaults write " & preffile & " 'NumOfNot' '3'"
		do shell script "defaults write " & preffile & " 'RemoveOnQuit' '1'"
		do shell script "defaults write " & preffile & " 'AppVersion' '4.2'"
		
		-- Install the preference script
		try
			set prefreso to (POSIX path of (path to me) & "Contents/Resources/MusiNotify-Preferences.scpt")
			do shell script "cp " & prefreso & " ~/Library/Scripts/"
		end try
	end if
end try

try
	-- Set up variables
	set snme to ""
	set inme to ""
	set x to 0
	set y to 0
	set NPIT to (POSIX path of (path to me)) & "/Contents/Resources/MusiNotify - iTunes.app/Contents/MacOS/MusiNotify - iTunes"
	set NPSP to (POSIX path of (path to me)) & "Contents/Resources/MusiNotify - Spotify.app/Contents/MacOS/MusiNotify - Spotify"
	set thanked to false
	
	-- Update app path in preffile
	try
		do shell script "defaults write " & preffile & " 'loginPath' '" & quoted form of (POSIX path of (path to me)) & "'"
	end try
	set loginitem to (do shell script "defaults read " & preffile & " 'login'")
	if loginitem = "1" then
		try
			set apppath to (do shell script "defaults read " & preffile & " 'loginPath'")
			tell application "System Events" to make login item at end with properties {path:apppath, kind:application}
		end try
	end if
end try

on idle
	delay 0.1
	try
		-- Read preferences
		set DispArt to (do shell script "defaults read " & preffile & " 'DispArt'")
		set DispAlb to (do shell script "defaults read " & preffile & " 'DispAlb'")
		set NumOfNot to (do shell script "defaults read " & preffile & " 'NumOfNot'")
		set RemoveOnQuit to (do shell script "defaults read " & preffile & " 'RemoveOnQuit'")
		
		tell application "System Events" to set applist to (name of every process) -- See which apps are running
		if applist contains "Spotify" then
			try
				tell application "Spotify"
					-- Get Track info
					set strk to name of current track
					set sart to ""
					set tart to (artist of current track)
					if DispArt = "1" and tart is not equal to "" then set sart to "By " & tart
					set salb to ""
					set talb to (album of current track)
					if DispAlb = "1" and talb is not equal to "" then set salb to "On " & talb
				end tell
				if talb does not contain "http" and talb does not contain "spotify:" then -- If the track is not an ad...
					if strk is not equal to snme then -- If track has changed...
						set thanked to false
						set snme to strk
						-- Determine the notification to replace
						set x to (x + 1)
						if x is greater than NumOfNot then set x to x - NumOfNot
						set xid to x as text
						do shell script quoted form of NPSP & " -title " & (quoted form of snme) & " -subtitle " & (quoted form of sart) & " -message " & (quoted form of salb) & " -group SP" & xid & " -execute 'open /Applications/Spotify.app'" -- Display the notification
					end if
				else
					try
						if thanked = false then do shell script quoted form of NPSP & " -title " & (quoted form of "Thanks for using MusiNotify!") & " -subtitle " & (quoted form of "You're Awesome!") & " -message \"\" -group TH"
						set thanked to true
						do shell script quoted form of NPSP & " -remove TH"
					end try
				end if
			end try
		else
			if RemoveOnQuit = "1" then
				-- Remove previous notifications
				repeat with n from 1 to NumOfNot
					try
						do shell script quoted form of NPSP & " -remove SP" & n
					end try
				end repeat
				set snme to ""
			end if
		end if
		
		if applist contains "iTunes" then
			
			try
				tell application "iTunes"
					-- Get Track info
					set itrk to name of current track
					set iart to ""
					set tart to (artist of current track)
					if DispArt = "1" and tart is not equal to "" then set iart to "By " & tart
					set ialb to ""
					set talb to (album of current track)
					if DispAlb = "1" and talb is not equal to "" then set ialb to "On " & talb
				end tell
				if itrk is not equal to inme then -- If track has changed...
					-- Determine the notification to replace
					set inme to itrk
					set y to (y + 1)
					if y is greater than NumOfNot then set y to y - NumOfNot
					set yid to y as text
					do shell script quoted form of NPIT & " -title " & (quoted form of inme) & " -subtitle " & (quoted form of iart) & " -message " & (quoted form of ialb) & " -group IT" & yid & " -execute 'open /Applications/iTunes.app'" -- Display the notification
				end if
			end try
		else
			if RemoveOnQuit = "1" then
				-- Remove previous notifications
				repeat with o from 1 to NumOfNot
					try
						do shell script quoted form of NPIT & " -remove IT" & o
					end try
				end repeat
				set inme to ""
			end if
		end if
	end try
	return 0.1
end idle