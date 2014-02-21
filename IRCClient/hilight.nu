; TODO: load nick color names from some sort of user-facing attribute list.
(class Hilight is RBScript
    (- (void) messageLogged:(id)message server:(id)server is
        (if (or (eq (message command) IRCMessageTypePrivmsg) (eq (message command) IRCMessageTypeNotice))
            (set (channelName ((message target) objectAtIndex:0)))
            (set (channel (server objectForKeyedSubscript:channelName)))
            (set (m ((NSMutableAttributedString alloc) initWithAttributedString:(message attributedMessage))))
            (for ((set nameIdx i) (< i ((channel names) count)) (set i (+ i 1)))
                 (set name ((channel names) objectAtIndex:i))
                 (if ((message message) containsSubstring:name)
                     (m addAttribute:NSForegroundColorAttributeName value:(UIColor redColor) range:((message message) rangeOfString:name))))
            (message setAttributedMessage:m))))