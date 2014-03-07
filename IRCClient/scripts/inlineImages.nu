(class InlineImages is RBScript
    (- (id) matchesForMessage:(id)message is
        ((NSDataDetector dataDetectorWithTypes:(NSTextCheckingTypesClass link) error:nil) matchesInString:message options:0 range:(message fullString)))

    (- (void) enumerateMatches:(id)matches message:(id)message is
        (let (enum (matches objectEnumerator))
             (set i (enum nextObject))
             (while (i)
                 (self loadImage:(i URL) forMessage:message)
                 (set i (enum nextObject)))))

    (- (void) loadImage:(id)imageLoc forMessage:(id)message is
        (set img ((imageLoc absoluteString) lowercaseString))
        (set msg ((NSMutableAttributedString alloc) initWithAttributedString:(message attributedMessage)))
        (if (or (img hasSuffix:".png") ; A better solution would be to check if the filetype is an image...
                (img hasSuffix:".jpg")
                (img hasSuffix:".jpeg")
                (img hasSuffix:".tif")
                (img hasSuffix:".tiff")
                (img hasSuffix:".gif")
                (img hasSuffix:".bmp")
                (img hasSuffix:".bmpf")
                (img hasSuffix:".ico")
                (img hasSuffix:".cur")
                (img hasSuffix:".xbm"))
            (msg addAttribute:(NSAttributedStringAttributes NSAttachmentAttributeName) value:((NSTextAttachment alloc) initWithData:(NSData dataWithContentsOfURL:imageLoc) ofType:nil) range:((msg string) endOfString)))
        (message setAttributedMessage:msg))

    (- (void) server:(id)server didReceiveMessage:(id)message is
        (set msg (message message))
        (if (or (not (msg containsSubstring:"nsfw")) (((NSUserDefaults standardUserDefaults) objectForKey:"Load NSFW Images") boolValue))
            (self enumerateMatches:(self matchesForMessage:msg) message:message))))
