(class Highlight is RBScript
    (+ (id) description is "Highlight when your username is mentioned")
    (- (void) channel:(id)channel didLogMessage:(id)message is
        (set msg ((NSMutableAttributedString alloc) initWithAttributedString:(message attributedMessage)))
        (if (and (or (== (message command) 3) (== (message command) 4))
           ((message message) containsSubstring:((channel server) nick)))
       (msg addAttribute:(NSAttributedStringAttributes NSForegroundColorAttributeName)
                   value:(RBColorScheme primaryColor)
                   range:(((message attributedMessage) string) rangeOfString:(server nick))))
    (message setAttributedMessage:msg)))
