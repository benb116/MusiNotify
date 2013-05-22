BenB116's MusiNotify
======

This is a plugin for Mac OS X 10.8 and up. It displays a notification using two versions of [Terminal-Notifier](https://github.com/alloy/terminal-notifier) whenever the current track changes in iTunes or Spotify. The notification shows the name of the track and, optionally, the artist and album.

Mac OS X 10.8 or higher is required.
<br>
##How does it work?
MusiNotify checks ever .1 seconds to see if either iTunes or Spotify are running. If either is, MusiNotify will get the name, artist, and album of the current track. If the track changes, MusiNotify will display a notification with the app's icon.

###Current Features
* Optionally display the artist and/or album
* Change the number of notifications visible in the sidebar (the default is three)
* Optionally clear notifications from the sidebar when iTunes or Spotify is quit.
* Will not display a notification for audio ads in Spotify

<br>

<center>

![image](http://cl.ly/N8uV/iTunes%20Notification.png)
<br>
iTunes Notification

![image](http://cl.ly/N8vJ/Spotify%20Notification.png)
<br>
Spotify Notification

![image](http://cl.ly/O73L/Spotify%20With%20Album.png)
<br>
Spotify Notification with Album

![image](http://cl.ly/Oszm/Sidebar.png)
<br>
Sidebar with notifications from iTunes and Spotify