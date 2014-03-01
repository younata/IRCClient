(class inlineImages is RBScript
    (+ (id)configurationItems is (NSDictionary dictionaryWithObjects:'("switch") forKeys:'("Load Images Inline")))
    (- (id) matchesForMessage:(id)message
        ((NSDataDetector dataDectorWithTypes:(NSTextCheckingTypesClass link) error:nil) matchesInString:msg options:0 range:'(0 (msg length))))

    (- (void) enumerateMatches:(id)matches message:(id)message is
        (set enum (matches objectEnumerator))
        (set i (enum nextObject))
        (while (i)
            (self loadImage:(i url) forMessage:message)
            (set i (enum nextObject))))
    (- (void) loadImage:(id)imageLoc forMessage:(id)message is
        (set img ((imageLoc absoluteString) lowercasestring))
        (set msg ((NSMutableAttributedString alloc) initWithAttributedString:(message attributedString)))
        (if (or (img hasSuffix:".png")
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
        (message setAttributedMessage:msg)

    (- (void) server:(id)server didReceiveMessage:(id)message is
        (set msg (message message))
        (if (or (not (msg containsSubstring:"nsfw")) (((NSUserDefaults standardUserDefaults) objectForKey:"Load Images Inline") boolValue))
            (self enumerateMatches:(self matchesForMessage:msg) message:message)))
