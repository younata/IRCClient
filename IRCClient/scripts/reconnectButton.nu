(class ServerReconnectButton is RBScript
    (- (void) reconnectServer:(id)button is
        (set server (button getCustomPropertyForKey:"server"))
        (server quit)
        (server connect))

    (- (void) serverList:(id)serverList didCreateServerCell:(id)cell forServer:(id)server is
        (set button (UIButton systemButtonWithTitle:"Reconnect"))
        (cell setAccessoryView:button)
    (cell layoutSubviews)
        (button setCustomProperty:server forKey:"server")
        ((button titleLabel) setTextAlignment:2) ; NSTextAlignmentRight
        (button addTarget:self action:"reconnectServer:" forControlEvents:(UIControlEventsClass UIControlEventTouchUpInside))
        (button setTranslatesAutoresizingMaskIntoConstraints:0)
        (button autoPinEdgeToSuperviewEdge:(ALLayoutAttributes edgeRight) withInset:0)
        (button autoPinEdgeToSuperviewEdge:(ALLayoutAttributes edgeBottom) withInset:0)
        (button autoPinEdgeToSuperviewEdge:(ALLayoutAttributes edgeTop) withInset:0)
        (button autoSetDimension:(ALLayoutAttributes dimensionWidth) toSize:80)
        ((cell contentView) layoutSubviews)))
