###iOS IRC Client
***
A less shitty IRC Client for iOS devices.

#####Building
***
Clone it with git, change directory into IRCClient, and:

    $ git submodule update --init
    $ pod install
    $ open IRCCLient.xcworkspace

The libffi static library probably won't be found the first time you build, I have no idea how to fix that right now, but you can correct it by building the libffi target, and replacing libffi static library under IRCClient.xcodeproj->build phases->link with the one under the libffi target.

