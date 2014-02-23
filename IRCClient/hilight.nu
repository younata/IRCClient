; TODO: load nick color names from some sort of user-facing attribute list.
(class Hilight is RBScript
    (- (void) messageLogged:(id)message server:(id)server is
        (set msg ((NSMutableAttributedString alloc) initWithAttributedString:(message attributedMessage)))
        (if (and (or (== (message command) 3) (== (message command) 4))
           ((message message) containsSubstring:(server nick)))
       (msg addAttribute:(NSAttributedStringAttributes NSForegroundColorAttributeName)
                   value:(RBColorScheme primaryColor)
                   range:((message message) rangeOfString:(server nick))))
    (message setAttributedMessage:msg)))