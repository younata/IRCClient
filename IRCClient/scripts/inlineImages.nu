(class InlineImages is RBScript
    (- (id) matchesForMessage:(id)message is
        ((NSDataDetector dataDetectorWithTypes:(NSTextCheckingTypesClass link) error:nil) matchesInString:message options:0 range:(message fullString)))

    (- (void) enumerateMatches:(id)matches message:(id)message is
        (let (enum (matches objectEnumerator))
             (set i (enum nextObject))
             (while (i)
                 (self loadImage:(i URL) forMessage:message)
                 (set i (enum nextObject)))))

    (- (int) appropriateWidthForDevice is
        (if ((UIDevice currentDevice) userInterfaceIdiom)
            (740)
            (else 300)))

    (- (id) resizeImageIfAppropriate:(id)image is
        (let (maxWidth (self appropriateWidthForDevice))
             (if (> (car (image size)) maxWidth)
                 (image resizedImageByWidth:(maxWidth intValue))
                 (else image))))

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
            (let ((attach ((NSTextAttachment alloc) init))
                  (image (UIImage imageWithData:(NSData dataWithContentsOfURL:imageLoc)))) 
                 (if (!= image nil)
                     ;(set image (self resizeImageIfAppropriate:image))
                     (attach setImage:(UIImage imageWithData:(NSData dataWithContentsOfURL:imageLoc)))
                     (msg appendAttributedString:(NSAttributedString attributedStringWithAttachment:attach)))))
        (message setAttributedMessage:msg))

    (- (void) server:(id)server didReceiveMessage:(id)message is
        (set msg (message message))
        (if (or (not (msg containsSubstring:"nsfw")) (((NSUserDefaults standardUserDefaults) objectForKey:"Load NSFW Images") boolValue))
            (self enumerateMatches:(self matchesForMessage:msg) message:message))))
