(class ServerReconnectButton is RBScript
    (+ (id) description is "Button to (re)connect to a server")
    (- (void) reconnectServer:(id)button is
        (set server (button getCustomPropertyForKey:"server"))
        (if (server connected) (server quit))
        (server connect))

    (- (void) serverList:(id)serverList didCreateServerCell:(id)cell forServer:(id)server is
        (set button (UIButton systemButtonWithTitle:"Reconnect"))
        (cell setAccessoryView:button)
        (cell layoutSubviews)
        (button setCustomProperty:server forKey:"server")
        ((button titleLabel) setTextAlignment:2) ; NSTextAlignmentRight
        (button addTarget:self action:"reconnectServer:" forControlEvents:(UIControlEventsClass UIControlEventTouchUpInside))
        (button setTranslatesAutoresizingMaskIntoConstraints:0)
        (button autoPinEdge:(ALLayoutAttributes edgeRight) toEdge:(ALLayoutAttributes edgeRight) ofView:cell)
        (button autoPinEdge:(ALLayoutAttributes edgeBottom) toEdge:(ALLayoutAttributes edgeBottom) ofView:cell)
        (button autoPinEdge:(ALLayoutAttributes edgeTop) toEdge:(ALLayoutAttributes edgeTop) ofView:cell)
        (button autoSetDimension:(ALLayoutAttributes dimensionWidth) toSize:80)
        (cell layoutSubviews)))
