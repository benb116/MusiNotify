set vers to (do shell script "sw_vers -productVersion")
set pte to (do shell script "echo " & vers & " | cut -d '.' -f 1-2")
if pte is not equal to "10.8" then
	display dialog "Sorry. This app requires OSX 10.8 or higher." buttons ("OK")
	tell application (path to me)
		quit
	end tell
end if
try
	set preffile to (POSIX path of (path to me) & "Contents/Resources/pref.txt")
	try
		do shell script "touch " & preffile
	end try
	set pref to (do shell script "cat " & preffile)
	
	if pref = "" then
		set inst to button returned of (display dialog "Click OK to install necessary plugins" buttons {"Quit", "OK"} with title "Spotify-Notifier" default button 2)
		if inst = "Quit" then
			tell application (path to me)
				quit
			end tell
		end if
		try
			do shell script "sudo gem install terminal-notifier" with administrator privileges
		end try
		set ans to button returned of (display dialog "Would you like to set this app as a login item?" buttons {"No", "Yes"} default button 2 with title "Spotify-Notifier")
		if ans = "Yes" then
			set reso to POSIX path of (path to me)
			tell application "System Events" to make login item at end with properties {path:reso, kind:application} -- Make application a login item
			do shell script "echo 1 > " & preffile
		else
			do shell script "echo 0 > " & preffile
		end if
		display dialog "Installation complete." buttons ("OK") default button 1 with title "Spotify-Notifier"
		do shell script "open /Applications/Spotify.app"
		delay
	end if
end try
set nme to ""
repeat
	tell application "System Events"
		set applist to (name of every process)
		if applist contains "Spotify" then
			try
				repeat
					tell application "Spotify"
						set trk to name of current track
						set art to artist of current track
					end tell
					if art is not equal to "Spotify" then
						if trk is not equal to nme then
							set nme to trk
							do shell script "terminal-notifier -subtitle \"" & nme & "\" -title \"Current Track on Spotify\" -message \"By " & art & "\" -group SP -activate /Applications/Spotify.app"
						end if
					end if
				end repeat
				exit repeat
			end try
		end if
	end tell
end repeat