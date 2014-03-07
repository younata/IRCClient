(class ServerReconnectButton is RBScript
    (- (id) propertyKey is "server")
    (- (void) reconnect:(id)button is
        (let (server (button server))
             (server quit)
             (server connect)))

    (- (void) serverList:(id)serverList didCreateServerCell:(id)cell forServer:(id)server is
        (let (button (UIButton systemButtonWithTitle:"Reconnect"))
             (cell setAccessoryView:button)
             (cell layoutSubviews)
             (button setServer:server)
             ((button titleLabel) setTextAlignment:2) ; NSTextAlignmentRight
             (button addTarget:self action:"reconnect:" forControlEvents:(UIControlEventsClass UIControlEventTouchUpInside))

             (button setTranslatesAutoresizingMaskIntoConstraints:0)
             (button autoPinEdgeToSuperviewEdge:(ALLayoutAttributes edgeRight) withInset:0)
             (button autoPinEdgeToSuperviewEdge:(ALLayoutAttributes edgeBottom) withInset:0)
             (button autoPinEdgeToSuperviewEdge:(ALLayoutAttributes edgeTop) withInset:0)
             (button autoSetDimension:(ALLayoutAttributes dimensionWidth) toSize:80))))
