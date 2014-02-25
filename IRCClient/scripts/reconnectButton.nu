(class ServerReconnectButton is RBScript
    (+ (id) description is "Button to (re)connect to a server")
    (- (void) reconnectServer:(id)button is
        (set server (button getCustomPropertyForKey:"server"))
        (if (server connected) (server quit))
        (server connect))

    (- (void) serverList:(id)serverList didCreateServerCell:(id)cell forServer:(id)server is
        (set button (UIButton systemButtonWithTitle:"Reconnect"))
        (button setCustomProperty:server forKey:"server")
        (button addTarget:self action:"reconnectServer:" forControlEvents:(RBScriptHelpers UIControlEventTouchUpInside))
        (cell setAccessoryView:button)))
