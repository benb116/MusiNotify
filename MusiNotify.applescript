global DispArt, DispAlb, NumOfNot, RemoveOnQuit, snme, inme, x, y, NPSP, NPIT, thanked, SpotifyRemoved, iTunesRemoved, preffile

try
	CheckSystemVersion() -- Check to make sure that the user is running OSX 10.8
	set preffile to "com.BenB116.MusiNotify.plist"
	
	-- If the preference fle doesn't exist, then make one and do a first-run setup
	if not CheckPrefFile() then FirstPrefSetup()
	
	InitialSetup() -- Set up variables
end try

repeat
	delay 0.1
	try
		ReadPrefs() -- Read preference values
		tell application "System Events" to set applist to (name of every process) -- See which apps are running
		if applist contains "Spotify" then
			CheckSpotify() -- Check if the song has changed
		else
			RemoveSpotify() -- Remove notifications
		end if
		if applist contains "iTunes" then
			CheckiTunes() -- Check if the song has changed
		else
			RemoveiTunes() -- Remove notifications
		end if
	end try
end repeat

on CheckSystemVersion()
	set vers to (do shell script "sw_vers -productVersion")
	set pte to (do shell script "echo " & vers & " | cut -d '.' -f 1-2")
	if pte is not equal to "10.8" then
		display dialog "Sorry. This app requires OSX 10.8+" buttons ("OK")
		try
			set the_pid to (do shell script "ps ax | grep " & (quoted form of (POSIX path of (path to me))) & " | grep -v grep | awk '{print $1}'")
			if the_pid is not "" then do shell script ("kill -9 " & the_pid)
		end try
	end if
end CheckSystemVersion

on CheckPrefFile()
	-- Check if the preference file exists
	try
		set prefFilePath to "~/Library/Preferences/" & preffile
		tell application "System Events"
			if exists file prefFilePath then
				return true
			else
				return false
			end if
		end tell
	end try
end CheckPrefFile

on FirstPrefSetup()
	try
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
	end try
end FirstPrefSetup

on InitialSetup()
	try
		set snme to ""
		set inme to ""
		set x to 0
		set y to 0
		set NPIT to "/Applications/MusiNotify.app/Contents/Resources/MusiNotify - iTunes.app/Contents/MacOS/MusiNotify - iTunes"
		set NPSP to "/Applications/MusiNotify.app/Contents/Resources/MusiNotify - Spotify.app/Contents/MacOS/MusiNotify - Spotify"
		set preffile to "com.BenB116.MusiNotify.plist"
		set SpotifyRemoved to false
		set iTunesRemoved to false
	end try
end InitialSetup

on ReadPrefs()
	set DispArt to (do shell script "defaults read " & preffile & " 'DispArt'")
	set DispAlb to (do shell script "defaults read " & preffile & " 'DispAlb'")
	set NumOfNot to (do shell script "defaults read " & preffile & " 'NumOfNot'")
	set RemoveOnQuit to (do shell script "defaults read " & preffile & " 'RemoveOnQuit'")
end ReadPrefs

on CheckSpotify()
	try
		tell application "Spotify"
			-- Get Track info
			set strk to name of current track
			set tart to artist of current track
			set talb to album of current track
		end tell
		if talb does not contain "http" and talb does not contain "spotify:" then -- If the track is not an ad...
			if strk is not equal to snme then -- If track has changed...
				set thanked to false
				set snme to strk
				
				set sart to " "
				if DispArt = "1" and tart is not equal to "" then set sart to "By " & tart
				set salb to " "
				if DispAlb = "1" and talb is not equal to "" then set salb to "On " & talb
				
				-- Determine the notification to replace
				set x to (x + 1)
				if x is greater than NumOfNot then set x to x - NumOfNot
				set xid to x as text
				do shell script quoted form of NPSP & " -title " & (quoted form of strk) & " -subtitle " & (quoted form of sart) & " -message " & (quoted form of salb) & " -group SP" & xid & " -execute 'open /Applications/Spotify.app'" -- Display the notification
				
				set SpotifyRemoved to false
			end if
			
		else
			try
				if thanked is not equal to true then do shell script quoted form of NPSP & " -title " & (quoted form of "Thanks for using MusiNotify!") & " -subtitle " & (quoted form of "You're Awesome!") & " -message \"\" -group TH"
				set thanked to true
				do shell script quoted form of NPSP & " -remove TH"
			end try
		end if
		
	end try
end CheckSpotify

on CheckiTunes()
	try
		tell application "iTunes"
			set inme to itrk
			-- Get Track info
			set itrk to name of current track
			set tart to (artist of current track)
			set talb to (album of current track)
		end tell
		
		if itrk is not equal to inme then -- If track has changed...
			set iart to " "
			if DispArt = "1" and tart is not equal to "" then set iart to "By " & tart
			set ialb to " "
			if DispAlb = "1" and talb is not equal to "" then set ialb to "On " & talb
			
			-- Determine the notification to replace
			set y to (y + 1)
			if y is greater than NumOfNot then set y to y - NumOfNot
			set yid to y as text
			do shell script quoted form of NPIT & " -title " & (quoted form of itrk) & " -subtitle " & (quoted form of iart) & " -message " & (quoted form of ialb) & " -group IT" & yid & " -execute 'open /Applications/iTunes.app'" -- Display the notification
			
			set SpotifyRemoved to false
		end if
	end try
end CheckiTunes

on RemoveSpotify()
	if RemoveOnQuit = "1" then
		if SpotifyRemoved is false then
			do shell script quoted form of NPSP & " -remove ALL"
			set SpotifyRemoved to true
		end if
	end if
	set snme to ""
end RemoveSpotify

on RemoveiTunes()
	if RemoveOnQuit = "1" then
		if iTunesRemoved is false then
			do shell script quoted form of NPIT & " -remove ALL"
			set iTunesRemoved to true
		end if
	end if
	set inme to ""
end RemoveiTunes