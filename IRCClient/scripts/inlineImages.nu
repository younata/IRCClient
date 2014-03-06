(class InlineImages is RBScript
    (+ (id)description is "Inline Image Viewer")
    ;(+ (id)configurationItems is (NSDictionary dictionaryWithObjects:'("switch") forKeys:'("Load NSFW Images")))
    (- (id) matchesForMessage:(id)message is
        ((NSDataDetector dataDetectorWithTypes:(NSTextCheckingTypesClass link) error:nil) matchesInString:message options:0 range:'(0 (msg length))))

    (- (void) enumerateMatches:(id)matches message:(id)message is
        (set enum (matches objectEnumerator))
        (set i (enum nextObject))
        (while (i)
            (self loadImage:(i url) forMessage:message)
            (set i (enum nextObject))))

    (- (void) loadImage:(id)imageLoc forMessage:(id)message is
        (set img ((imageLoc absoluteString) lowercasestring))
        (set msg ((NSMutableAttributedString alloc) initWithAttributedString:(message attributedString)))
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
            (msg addAttribute:(NSAttributedStringAttributes NSAttachmentAttributeName) value:(UIImage imageWithData:(NSData dataWithContentsOfURL:imageLoc)) range:'((msg count) 0)))
        (message setAttributedMessage:msg))

    (- (void) server:(id)server didReceiveMessage:(id)message is
        (set msg (message message))
        (if (or (not (msg containsSubstring:"nsfw")) (((NSUserDefaults standardUserDefaults) objectForKey:"Load NSFW Images") boolValue))
            (self enumerateMatches:(self matchesForMessage:msg) message:message))))
