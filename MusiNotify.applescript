global DispArt, DispAlb, NumOfNot, RemoveOnQuit, sid, iid, x, y, NPSP, NPIT, thanked, preffile, spotgroups, Itungroups, CurrentAppVersion, spotinotify, itunotify

try
	CheckSystemVersion() -- Check to make sure that the user is running OS X 10.8
	set preffile to "com.BenB116.MusiNotify.plist"
	set CurrentAppVersion to "4.5.1.2"
	
	do shell script "open " & POSIX path of (path to me) & quoted form of ("Contents/Resources/MusiNotify Updater.app")
end try
try
	if not CheckPrefFile() then FirstPrefSetup() -- If the preference fle doesn't exist, then make one and do a first-run setup
	
	InitialSetup() -- Set up variables
end try

repeat -- Main Loop
	ReadPrefs() -- Read preference values
	
	try
		tell application "System Events" to set applist to (name of every process whose background only = false) -- See which apps are running
	end try
	if applist contains "Spotify" and spotinotify = "1" then
		CheckSpotify() -- Check if the song has changed
	else
		if RemoveOnQuit = "1" and (count of spotgroups) is not equal to 0 then -- If app isn't running and RemoveOnQuit is set to 1 then...
			repeat with a in spotgroups
				do shell script quoted form of NPSP & " -remove SP" & a -- Remove notifications
			end repeat
			set spotgroups to {} -- Clear
			do shell script "defaults write com.BenB116.MusiNotify.plist 'SpotifyCurrentGroups' ''"
		end if
		set sid to ""
	end if
	if applist contains "iTunes" and itunotify = "1" then
		CheckiTunes() -- Check if the song has changed
	else
		if RemoveOnQuit = "1" and (count of Itungroups) is not equal to 0 then -- If app isn't running and RemoveOnQuit is set to 1 then...
			repeat with b in Itungroups
				do shell script quoted form of NPIT & " -remove IT" & b -- Remove notifications
			end repeat
			set Itungroups to {} -- Clear
			do shell script "defaults write com.BenB116.MusiNotify.plist 'iTunesCurrentGroups' ''"
		end if
		set iid to ""
	end if
	delay 0.01
end repeat

on CheckSystemVersion()
	try
		set vers to (do shell script "sw_vers -productVersion") -- Get Version of OS X
		set pte to (do shell script "echo " & vers & " | cut -d '.' -f 1-2")
		if pte is not equal to "10.8" and pte is not equal to "10.9" then
			display dialog "Sorry. This app requires OSX 10.8+" buttons ("OK") with icon (path to resource "applet.icns")
			KillMusiNotify()
		end if
	on error msg
		display dialog "CheckSystemVersion - " & msg with title "Error - MusiNotify" with icon (path to resource "applet.icns")
		return
	end try
end CheckSystemVersion

on CheckPrefFile()
	try
		set prefFilePath to "~/Library/Preferences/" & preffile
		repeat
			tell application "System Events"
				if exists file prefFilePath then -- Does the pref file exist?
					return true
				else
					return false
				end if
			end tell
			exit repeat
		end repeat
	on error msg
		display dialog "CheckPrefFile - " & msg with title "Error - MusiNotify" with icon (path to resource "applet.icns")
		KillMusiNotify()
	end try
end CheckPrefFile

on FirstPrefSetup()
	try
		do shell script "touch ~/Library/Preferences/" & preffile -- Make the pref file
		
		-- Set initial settings
		do shell script "defaults write " & preffile & " 'SpotiNotify' '1'"
		do shell script "defaults write " & preffile & " 'iTuNotify' '1'"
		
		do shell script "defaults write " & preffile & " 'login' '0'"
		set ans to button returned of (display dialog "Would you like to set this app as a login item?" buttons {"No", "Yes"} default button 2 with title "MusiNotify" with icon (path to resource "applet.icns"))
		if ans = "Yes" then
			do shell script "defaults write " & preffile & " 'login' '1'"
			set mypath to (POSIX path of (path to me))
			tell application "System Events" to make login item at end with properties {path:mypath} -- Add to login items
		end if
		do shell script "defaults write " & preffile & " 'DispArt' '1'"
		do shell script "defaults write " & preffile & " 'DispAlb' '0'"
		do shell script "defaults write " & preffile & " 'NumOfNot' '3'"
		do shell script "defaults write " & preffile & " 'RemoveOnQuit' '1'"
		
		try
			iTunes11dot1()
		end try
		
		try
			set prefreso to (POSIX path of (path to me) & "Contents/Resources/MusiNotify Preferences.scpt")
			do shell script "cp " & prefreso & " ~/Library/Scripts/" -- Install the preference script
		end try
		-- Run the notifiers to reset their icons
		try
			do shell script quoted form of ((POSIX path of (path to me)) & "Contents/Resources/MusiNotify - iTunes.app/Contents/MacOS/MusiNotify - iTunes")
		end try
		try
			do shell script quoted form of ((POSIX path of (path to me)) & "Contents/Resources/MusiNotify - Spotify.app/Contents/MacOS/MusiNotify - Spotify")
		end try
		
		display dialog "You're all set! Play a song in iTunes or Spotify to test it out." buttons {"Awesome!"} default button 1 with title "MusiNotify" with icon (path to resource "applet.icns") giving up after 5
		
	on error msg
		display dialog "FirstPrefSetup - " & msg with title "Error - MusiNotify" with icon (path to resource "applet.icns")
		KillMusiNotify()
	end try
end FirstPrefSetup

on InitialSetup()
	try
		do shell script "defaults write " & preffile & " 'loginPath' '" & (POSIX path of (path to me)) & "'" -- Update login path
	end try
	try
		set sid to ""
		set iid to ""
		set x to 0
		set y to 0
		set NPIT to (POSIX path of (path to me)) & "Contents/Resources/MusiNotify - iTunes .app/Contents/MacOS/MusiNotify - iTunes"
		set NPSP to (POSIX path of (path to me)) & "/Contents/Resources/MusiNotify - Spotify.app/Contents/MacOS/MusiNotify - Spotify"
		
		try
			set previousspotgroups to do shell script "defaults read " & preffile & " 'SpotifyCurrentGroups'" -- Read Previous Notifications
			set newgrop to paragraphs 2 thru -2 of previousspotgroups as list
			set spotgroups to {}
			repeat with t in newgrop
				set newraw to do shell script "echo '" & t & "' | cut -d ' ' -f 5 | cut -d ',' -f 1"
				set end of spotgroups to (newraw as integer)
			end repeat
			set end of spotgroups to (first item of spotgroups)
			set spotgroups to (items 2 thru -1 of spotgroups)
		on error
			set spotgroups to {}
		end try
		
		log spotgroups
		
		try
			set previousitungroups to do shell script "defaults read " & preffile & " 'iTunesCurrentGroups'"
			set newgrop to paragraphs 2 thru -2 of previousitungroups as list
			set Itungroups to {}
			repeat with t in newgrop
				set newraw to do shell script "echo '" & t & "' | cut -d ' ' -f 5 | cut -d ',' -f 1"
				set end of Itungroups to (newraw as integer)
			end repeat
			set end of Itungroups to (first item of Itungroups)
			set Itungroups to (items 2 thru -1 of Itungroups)
		on error
			set Itungroups to {}
		end try
		
		try
			iTunes11dot1()
		end try
		
		try
			do shell script "defaults write " & preffile & " 'CurrentAppVersion' '" & CurrentAppVersion & "'"
		end try
	on error msg
		display dialog "InitialSetup - " & msg with title "Error - MusiNotify" with icon (path to resource "applet.icns")
		KillMusiNotify()
	end try
end InitialSetup

on ReadPrefs()
	try
		set spotinotify to (do shell script "defaults read " & preffile & " 'SpotiNotify'")
		set itunotify to (do shell script "defaults read " & preffile & " 'iTuNotify'")
		set DispArt to (do shell script "defaults read " & preffile & " 'DispArt'")
		set DispAlb to (do shell script "defaults read " & preffile & " 'DispAlb'")
		set NumOfNot to (do shell script "defaults read " & preffile & " 'NumOfNot'")
		set RemoveOnQuit to (do shell script "defaults read " & preffile & " 'RemoveOnQuit'")
	on error msg
		display dialog "ReadPrefs - " & msg with title "Error - MusiNotify" with icon (path to resource "applet.icns")
		KillMusiNotify()
	end try
end ReadPrefs

on CheckSpotify()
	try
		tell application "Spotify"
			-- Get Track info
			set strk to name of current track
			set tart to artist of current track
			set talb to album of current track
			set tid to id of current track
		end tell
		if talb does not contain "http" and talb does not contain "spotify:" then -- If the track is not an ad...
			set thanked to false
			if tid is not equal to sid then -- If track has changed...
				try
					set sart to " "
					if DispArt = "1" and tart is not equal to "" then set sart to "By " & tart
					set salb to " "
					if DispAlb = "1" and talb is not equal to "" then set salb to "On " & talb
					
					set theID to SpotDet() -- Get the ID
					set xid to "-group SP" & theID as text
					
					do shell script quoted form of NPSP & " -title " & (quoted form of strk) & " -subtitle " & (quoted form of sart) & " -message " & (quoted form of salb) & " " & xid & " -execute 'open /Applications/Spotify.app'" -- Display the notification
					if NumOfNot = "0" then
						try
							repeat with a in spotgroups
								do shell script quoted form of NPSP & " -remove SP" & a -- Remove notifications
							end repeat
							set spotgroups to {} -- Clear
						end try
						do shell script quoted form of NPSP & " -remove SP0"
					end if
					
					set Formspotgroups to ""
					repeat with z in spotgroups
						set Formspotgroups to Formspotgroups & ((z as text) & ", ")
					end repeat
					do shell script "defaults write " & preffile & " 'SpotifyCurrentGroups' '(" & Formspotgroups & ")'" -- Record Current Groups
					
					set sid to tid
				end try
			end if
		else
			try
				if thanked is false then
					do shell script quoted form of NPSP & " -title " & (quoted form of "Thanks for using MusiNotify!") & " -subtitle " & (quoted form of "You're awesome!") & " -message \"\" -group TH -open " & quoted form of ("https://github.com/benb116/MusiNotify")
					set thanked to true
					do shell script quoted form of NPSP & " -remove TH"
				end if
			end try
		end if
	end try
end CheckSpotify

on SpotDet()
	try
		if NumOfNot = "0" then
			return 0
		else
			log spotgroups
			if (count of spotgroups) = NumOfNot as integer then -- If full
				set x to last item of spotgroups
				try
					set spotgroups to (items 1 thru -2 of spotgroups)
				on error
					set spotgroups to {}
				end try
			else if (count of spotgroups) < NumOfNot as integer then -- If not full
				repeat
					set x to x + 1
					if spotgroups does not contain x then exit repeat
				end repeat
			else if (count of spotgroups) > NumOfNot as integer then -- If over-filled
				repeat with a from NumOfNot + 1 to (count of spotgroups)
					do shell script quoted form of NPSP & " -remove SP" & (item a of spotgroups)
				end repeat
				set spotgroups to (items 1 thru NumOfNot of spotgroups)
				set x to last item of spotgroups
				try
					set spotgroups to (items 1 thru -2 of spotgroups)
				on error
					set spotgroups to {}
				end try
			end if
			set beginning of spotgroups to x
			
			return (first item of spotgroups) as integer
		end if
	on error msg
		display dialog "SpotDet - " & msg with title "Error - MusiNotify" with icon (path to resource "applet.icns")
		KillMusiNotify()
	end try
end SpotDet

on CheckiTunes()
	try
		tell application "iTunes"
			-- Get Track info
			set itrk to name of current track
			set tart to artist of current track
			set talb to album of current track
			set tid to persistent ID of current track
		end tell
		if tid is not equal to iid then -- If track has changed...
			try
				set iart to " "
				if DispArt = "1" and tart is not equal to "" then set iart to "By " & tart
				set ialb to " "
				if DispAlb = "1" and talb is not equal to "" then set ialb to "On " & talb
				
				set theID to ItunDet() -- Get the ID
				set yid to "-group IT" & theID as text
				
				do shell script quoted form of NPIT & " -title " & (quoted form of itrk) & " -subtitle " & (quoted form of iart) & " -message " & (quoted form of ialb) & " " & yid & " -execute 'open /Applications/iTunes.app'" -- Display the notification
				if NumOfNot = "0" then
					try
						repeat with b in Itungroups
							do shell script quoted form of NPIT & " -remove IT" & b -- Remove notifications
						end repeat
						set Itungroups to {} -- Clear
					end try
					do shell script quoted form of NPIT & " -remove IT0"
				end if
				
				set Formitungroups to ""
				repeat with z in Itungroups
					set Formitungroups to Formitungroups & ((z as text) & ", ")
				end repeat
				do shell script "defaults write com.benb116.musinotify.plist 'iTunesCurrentGroups' '(" & Formitungroups & ")'" -- Record Current Groups
				
				set iid to tid
			end try
		end if
	end try
end CheckiTunes

on ItunDet()
	try
		-- Same as SpotDet(), converted to iTunes
		if NumOfNot = "0" then
			return 0
		else
			if (count of Itungroups) = NumOfNot as integer then
				set y to last item of Itungroups
				try
					set Itungroups to (items 1 thru -2 of Itungroups)
				on error
					set Itungroups to {}
				end try
			else if (count of Itungroups) < NumOfNot as integer then
				repeat
					set y to y + 1
					if Itungroups does not contain y then exit repeat
				end repeat
			else if (count of Itungroups) > NumOfNot as integer then
				repeat with b from NumOfNot + 1 to (count of Itungroups)
					do shell script quoted form of NPIT & " -remove IT" & (item b of Itungroups)
				end repeat
				set Itungroups to (items 1 thru NumOfNot of Itungroups)
				set y to last item of Itungroups
				try
					set Itungroups to (items 1 thru -2 of Itungroups)
				on error
					set Itungroups to {}
				end try
			end if
			set beginning of Itungroups to y
			
			set Formitungroups to ""
			repeat with z in Itungroups
				set Formitungroups to Formitungroups & ((z as text) & ", ")
			end repeat
			
			return (first item of Itungroups) as integer
		end if
	on error msg
		display dialog "iTunDet - " & msg with title "Error - MusiNotify" with icon (path to resource "applet.icns")
		KillMusiNotify()
	end try
end ItunDet

on KillMusiNotify()
	try -- Kill MusiNotify
		tell application "System Events"
			set theID to (unix id of processes whose name is "MusiNotify")
			do shell script "kill -9 " & theID
		end tell
	end try
end KillMusiNotify

on iTunes11dot1()
	try -- Check current iTunes version
		try
			set asked to (do shell script "defaults read " & preffile & " '11.1_Ask'")
		on error
			set asked to "0"
		end try
		if asked is not equal to "1" then
			set currentiTunesversion to (do shell script "defaults read /Applications/iTunes.app/Contents/Info.plist 'CFBundleShortVersionString'")
			if currentiTunesversion contains "11.1" then -- Version 11.1 has built-in notifications
				set iTuneschoice to button returned of (display dialog Â
					"Hi there, it looks like you're using iTunes 11.1. " & return & return & Â
					"This version of iTunes has notifications built in, so you don't NEED to use MusiNotify. However, MusiNotify is much more customizable and (in the opinion of the developer) better." & return & return & Â
					"Would you like to use MusiNotify for iTunes?" buttons {"Don't use MusiNotify for iTunes", "Use MusiNotify for iTunes"} default button 2)
				if iTuneschoice = "Don't use MusiNotify for iTunes" then
					do shell script "defaults write " & preffile & " 'iTuNotify' '0'"
				end if
				do shell script "defaults write " & preffile & " '11.1_Ask' '1'"
			end if
		end if
	end try
end iTunes11dot1