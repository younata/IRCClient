; TODO: load nick color names from some sort of user-facing attribute list.
(class Hilight is RBScript
    (- (void) messageLogged:(id)message server:(id)server is
        (set channel (server objectForKeyedSubscript:((message targets) objectAtIndex:0)))
        (set msg ((NSMutableAttributedString alloc) initWithAttributedString:(message attributedMessage)))
        (if (or (== (message command) 3) (== (message command) 4))
            (for ((set i 0) (< i ((channel names) count)) (set i (+ i 1)))
                 (set name ((channel names) objectAtIndex:i))
                 (if ((message message) containsSubstring:name)
                     (msg addAttribute:(NSAttributedStringAttributes NSForegroundColorAttributeName) value:(UIColor redColor) range:((message message) rangeOfString:name))))
            (message setAttributedMessage:msg))))