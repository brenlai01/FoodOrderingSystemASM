.model small
.stack 100h

.data
    ; File handling
    filename db "users.txt", 0
    auditfile db "audit.txt", 0
    filehandle dw 0
    audithandle dw 0
    buffer db 100 dup(0)
    
    
    ; User input
    inputUser db 20 dup(0)
    inputPass db 20 dup(0)
    
    ; File reading variables
    fileUser db 20 dup(0)
    filePass db 20 dup(0)
    
    ; Login attempt counter
    attemptCount db 0
    
    ; Audit logging variables
    auditBuffer db 200 dup(0)
    dateStr db 20 dup(0)
    timeStr db 20 dup(0)
    
    ; Burger sprite data
    burger_line1 DB ' .~"""~. ', 0
    burger_line2 DB '|#######|', 0
    burger_line3 DB '|~~~~~~~|', 0
    burger_line4 DB ' `~"""~` ', 0
    
    ; Animation variables - burgers move across banner area
    burger1_x DW 0             ; Burger 1 X position
    burger1_y DW 2             ; Burger 1 Y position (above banner)
    burger2_x DW 18            ; Burger 2 X position
    burger2_y DW 2             ; Burger 2 Y position
    burger3_x DW 36            ; Burger 3 X position
    burger3_y DW 2             ; Burger 3 Y position
    burger4_x DW 54            ; Burger 4 X position
    burger4_y DW 2             ; Burger 4 Y position
    max_x DW 71                ; Maximum X position
    delay_count DW 0           ; Delay counter
    delay_max DW 65000         ; Delay between frames (faster)
    animation_frames DW 50     ; Number of animation frames to show
    
    ; 2. Update the clear_line size (9 spaces for 9-character wide burger):
    clear_line DB '         $'  ; 9 spaces to clear burger
    
    ; Messages
    msgWelcome db "============================ APU Food Store System =============================$"
    msgUser db 13,10,"Username: $"
    msgPass db 13,10,"Password: $"
    msgSuccess db 13,10,"Login Successful! Welcome Back!$"
    msgFail db 13,10,"Invalid credentials. Login Failed. Try again.$"
    msgFileError db 13,10,"Error: Cannot open users.txt file.$"
    msgLockout db 13,10,"Locking Account.$"
    msgPress db 13,10,"Press any key to try again...$"

    msgMenuTitle db 13,10, "=== APU Food Store System ===", 13,10, "$"
    msgMenu1 db "1. View Menu", 13,10, "$"
    msgMenu2 db "2. Order Food", 13,10, "$"
    msgMenu3 db "3. Calculate Total (with Tax)", 13,10, "$"
    msgMenu4 db "4. Restock", 13,10, "$"
    msgMenu5 db "5. Logout", 13,10, "$"
    msgPrompt db "Enter your choice: $"
    msgInvalid db 13,10, "Invalid choice. Try again.", 13,10, "$"

    ; Audit message templates
    auditLoginSuccess db " - LOGIN SUCCESS - User: $"
    auditLoginFail db " - LOGIN FAILED - User: $"
    auditLockout db " - ACCOUNT LOCKED - User: $"
    auditLogout db " - LOGOUT - User: $"
    auditNewline db 13,10,"$"
    
    header db 10, "------------------------------------------------------------", 13,10
       db "                   Fast Food Inventory               ",13,10
       db "------------------------------------------------------------",13,10
       db "ID",9, "Name",9,9,9,"Qty",9,9, "Price(RM)",13,10, "$"

    ; Food items
    FoodNames db "Burger        ",  "Hot Dog       ", "Fried Chicken ", "French Fries  ", "Hashbrowns    "
    FoodPrice dw 4, 8, 7, 5, 7
    FoodQty dw 15, 10, 20, 5, 18
    
    ; Order Food
    msgOrderTitle db 13,10, "=== Order Food ===", 13,10, "$"
    msgSelectFood db "Enter Food ID (0-4) or 9 to finish: $"
    msgOrderSuccess db 13,10, "Item added to cart!", 13,10, "$"
    msgOutOfStock db 13,10, "Sorry, this item is out of stock!", 13,10, "$"
    msgInvalidID db 13,10, "Invalid Food ID! Please enter 0-4 or 9.", 13,10, "$"
    msgPressKey db "Press any key to continue...", 13,10, "$"
    msgNoOrders db 13,10, "No items in cart!", 13,10, "$"
    
    ; Restock messages
    msgCurrentStock db 'Current stock: $'
    msgRestockTitle db 13,10, "=== Restock Inventory ===", 13,10, "$"
    msgSelectRestock db "Enter Food ID (0-4) or 9 to finish: $"
    msgRestockSuccess db 13,10, "Item restocked!", 13,10, "$"
    msgRestockInvalidID db 13,10, "Invalid Food ID! Please enter 0-4 or 9.", 13,10, "$"

    ; Checkout messages
    msgCartSummary db 'Cart: $'
    msgItems db ' items$'
    msgTotal db ' | Total: RM$'
    msgItemTotal db ' (Total: RM$'
    msgCheckoutTitle db 13,10, "=== Checkout ===", 13,10, "$"
    msgCartHeader db "Your Cart:", 13,10, "$"
    msgCartItem db "Item: $"
    msgQuantity db " | Qty: $"
    msgItemPrice db " | Price: RM$"
    msgTotalPrice db 13,10, "Subtotal: RM$"
    msgTaxAmount db 13,10, "Tax (6%): RM$"
    msgFinalTotal db 13,10, "Total Amount: RM$"
    msgThankYou db 13,10, "Thank you for your order!", 13,10, "$"

    ; Payment messages
    msgPaymentPrompt db 13,10, "Enter amount paid in cents (e.g., 3300 for RM33.00): $"
    msgAmountPaid db 13,10, "Amount Paid: RM$"
    msgChangeAmount db 13,10, "Change: RM$"
    msgInsufficientFunds db 13,10, "Insufficient payment! Please pay at least RM$"
    msgExactPayment db 13,10, "Exact payment received. No change required.", 13,10, "$"
    msgPaymentError db 13,10, "Invalid payment amount. Please try again.", 13,10, "$"

    ; Cart tracking arrays
    CartItems db 5 dup(0)      ; Track quantity of each item in cart
    CartTotal dw 0             ; Total amount
    PaymentAmount dw 0         ; Amount paid by customer
    ChangeAmount dw 0          ; Change to give back
    FinalTotalWithTax dw 0     ; Final total including tax
    
    ; Add these new messages for restock quantity input
    msgRestockQty db 13,10, "Enter quantity to restock (1-99): $"
    msgRestockQtySuccess db 13,10, "Successfully added $"
    msgRestockQtyUnits db " units to inventory!", 13,10, "$"
    msgRestockQtyInvalid db 13,10, "Invalid quantity! Please enter 1-99.", 13,10, "$"   

.code
main:
    mov ax, @data
    mov ds, ax
    
    call ClearScreen
    call ShowStaticBanner
    
    ; Initialize burger positions for continuous animation
    call InitializeBurgerPositions
      
;--------------------------------------------------
; Modified StartLogin to ensure banner is always visible
;--------------------------------------------------
StartLogin:
    ; Clear input buffers before each login attempt
    call ClearInputBuffers
    
    ; Make sure banner is displayed (in case it was cleared)
    call ShowStaticBanner
    
    ; Position cursor for username prompt
    mov ah, 02h
    mov bh, 0
    mov dh, 7          ; Row 8 (below banner at row 7)
    mov dl, 0           ; Column 0
    int 10h
    
    ; Get username with continuous animation
    lea dx, msgUser
    call PrintString
    lea bx, inputUser
    call GetInputWithAnimation

    ; Get password (masked) with continuous animation
    lea dx, msgPass
    call PrintString
    lea bx, inputPass
    call GetMaskedInputWithAnimation

    ; Validate credentials from file
    call ValidateLogin
    cmp al, 1
    je LoginSuccess
    
    ; Login failed - log failed attempt
    lea dx, auditLoginFail
    call LogAuditEvent
    
    ; Login failed - increment attempt counter
    inc byte ptr [attemptCount]
    lea dx, msgFail
    call PrintString
    
    ; Check if maximum attempts reached
    cmp byte ptr [attemptCount], 3
    je AccountLocked
    
    ; Wait for user to press a key before next attempt (with animation)
    lea dx, msgPress
    call PrintString
    call WaitKeyWithAnimation
    
    ; Clear the failed login messages from screen
    call ClearLoginArea
    
    ; Continue to next attempt
    jmp StartLogin

LoginSuccess:
    lea dx, auditLoginSuccess
    call LogAuditEvent
    
    lea dx, msgSuccess
    call PrintString
    call ShowMenuWithAnimation
    ; After menu returns (including logout), go back to login
    jmp StartLogin

AccountLocked:
    lea dx, auditLockout
    call LogAuditEvent
    
    lea dx, msgLockout
    call PrintString
    ; Wait a moment with animation before exit
    call DelayWithAnimation
    ; Exit program
    mov ah, 4Ch
    int 21h
    
;--------------------------------------------------
; Show menu with continuous animation (clears screen first)
;--------------------------------------------------
ShowMenuWithAnimation:
    ; Clear everything except banner and burger animation
    call ClearScreen
    
    ; Redraw the banner at the correct position
    call ShowStaticBanner
    
    ; Position cursor after banner for menu display
    mov ah, 02h
    mov bh, 0
    mov dh, 8          ; Row 8 (closer to banner at row 7)
    mov dl, 0          ; Column 0
    int 10h
    
    ; Display menu options
    lea dx, msgMenu1
    call PrintString
    lea dx, msgMenu2
    call PrintString
    lea dx, msgMenu3
    call PrintString
    lea dx, msgMenu4
    call PrintString
    lea dx, msgMenu5
    call PrintString
    lea dx, msgPrompt
    call PrintString
    
MenuWaitLoop:
    ; Save current cursor position
    push dx
    mov ah, 03h         ; Get cursor position
    mov bh, 0
    int 10h
    push dx
    
    ; Run animation
    call ContinuousBackgroundAnimation
    
    ; Restore cursor position
    pop dx
    mov ah, 02h         ; Set cursor position
    mov bh, 0
    int 10h
    pop dx
    
    ; Check for keyboard input
    mov ah, 0Bh         ; Check keyboard status
    int 21h
    cmp al, 0           ; No key pressed
    je MenuWaitLoop     ; Continue animation
    
    ; Get the key
    mov ah, 01h
    int 21h
    
    ; Handle menu choices
    cmp al, '1'
    je HandleViewMenu
    cmp al, '2'
    je HandleOrderFood
    cmp al, '3'
    je HandleCalculateTotal
    cmp al, '4'
    je HandleRestock
    cmp al, '5'
    je DoLogoutWithAnimation
    
    ; Invalid choice
    call NewLine
    lea dx, msgInvalid
    call PrintString
    lea dx, msgPress
    call PrintString
    call WaitKeyWithAnimation
    
    ; Clear screen and redisplay menu
    call ClearAllExceptBanner
    jmp ShowMenuWithAnimation

HandleViewMenu:
    jmp ShowFoodMenu

HandleOrderFood:
    jmp OrderFood

HandleCalculateTotal:
    jmp CalculateTotal

HandleRestock:
    jmp Restock

;--------------------------------------------------
; Logout with screen clear and return to login
;--------------------------------------------------
DoLogoutWithAnimation:
    ; Clear the entire screen completely
    call ClearScreen
    
    ; Show the static banner again
    call ShowStaticBanner
    
    ; Clear input buffers to remove old username/password
    call ClearInputBuffers
    
    ; Reset login attempt counter
    mov byte ptr [attemptCount], 0
    
    ; Return to login (no need to jump, just return to main loop)
    ret
    
ClearAllExceptBanner:
    push ax
    push bx
    push cx
    push dx
    
    ; Clear from row 8 to bottom of screen (leaving banner at row 7)
    ; Banner is at row 7, burgers are at rows 2-6, so clear from row 8 down
    mov dh, 8          ; Start row (after banner)
    mov cx, 17         ; Number of rows to clear (8 to 24)
    
ClearAllLoop:
    push cx
    push dx
    
    ; Position cursor at start of row
    mov ah, 02h
    mov bh, 0
    mov dl, 0           ; Column 0
    int 10h
    
    ; Clear the entire row (80 spaces)
    push cx
    mov cx, 80
    mov al, ' '
ClearAllRowLoop:
    mov ah, 0Eh         ; Teletype output
    mov bh, 0
    int 10h
    loop ClearAllRowLoop
    pop cx
    
    pop dx
    pop cx
    inc dh              ; Next row
    loop ClearAllLoop
    
    pop dx
    pop cx
    pop bx
    pop ax
    ret   
 
;--------------------------------------------------
; Initialize burger positions for smoother animation
;--------------------------------------------------
InitializeBurgerPositions:
    mov burger1_x, 0
    mov burger2_x, 18
    mov burger3_x, 36
    mov burger4_x, 54
    mov burger1_y, 2
    mov burger2_y, 2
    mov burger3_y, 2
    mov burger4_y, 2
    ret

; Function to validate login credentials from file
ValidateLogin:
    ; Open file for reading
    mov ah, 3Dh         ; Open file
    mov al, 0           ; Read-only mode
    lea dx, filename
    int 21h
    jc FileOpenError
    
    mov [filehandle], ax
    
    ; Read file content
    mov ah, 3Fh         ; Read from file
    mov bx, [filehandle]
    mov cx, 100         ; Read up to 100 bytes
    lea dx, buffer
    int 21h
    jc FileReadError
    
    ; Close file
    mov ah, 3Eh
    mov bx, [filehandle]
    int 21h
    
    ; Parse file content and check credentials
    call ParseAndCheck
    ret

FileOpenError:
FileReadError:
    lea dx, msgFileError
    call PrintString
    mov al, 0           ; Return failure
    ret

; Function to parse file content and check credentials - FIXED JUMP RANGE
ParseAndCheck:
    lea si, buffer      ; Source: file buffer
    
ParseLoop:
    ; Check if we've reached end of buffer
    cmp byte ptr [si], 0
    jne ParseContinue
    jmp ParseFailed
    
ParseContinue:
    ; Skip empty lines and whitespace at start
    call SkipWhitespaceAndNewlines
    cmp byte ptr [si], 0
    jne ParseUserPass
    jmp ParseFailed
    
ParseUserPass:
    ; Clear previous username and password
    call ClearFileCredentials
    
    ; Parse username from current line
    lea di, fileUser
    call ParseWord
    
    ; Check if we got a username
    cmp byte ptr [fileUser], 0
    jne ParsePassword
    jmp ParseFailed
    
ParsePassword:
    ; Skip whitespace between username and password
    call SkipSpaces
    
    ; Parse password from current line
    lea di, filePass
    call ParseWord
    
    ; Check if we got a password
    cmp byte ptr [filePass], 0
    jne CompareCredentials
    jmp NextLine
    
CompareCredentials:
    ; Compare credentials
    push si             ; Save current position
    
    lea si, inputUser
    lea di, fileUser
    call StrCompare
    cmp al, 1
    jne CheckPassword
    jmp PasswordCheck
    
CheckPassword:
    jmp NextCredential
    
PasswordCheck:
    lea si, inputPass
    lea di, filePass
    call StrCompare
    cmp al, 1
    jne NextCredential
    jmp ParseSuccess
    
NextCredential:
    pop si              ; Restore current position
    jmp NextLine
    
NextLine:
    call SkipToNextLine
    jmp ParseLoop
    
ParseSuccess:
    pop si              ; Clean up stack
    mov al, 1
    ret
    
ParseFailed:
    mov al, 0
    ret

; Function to clear file credentials buffers
ClearFileCredentials:
    push ax
    push cx
    push di
    
    ; Clear fileUser
    lea di, fileUser
    mov cx, 20
    mov al, 0
    rep stosb
    
    ; Clear filePass
    lea di, filePass
    mov cx, 20
    mov al, 0
    rep stosb
    
    pop di
    pop cx
    pop ax
    ret

; Function to parse a word from file - SIMPLIFIED
ParseWord:
    push cx
    mov cx, 0
    
ParseWordLoop:
    mov al, [si]
    
    ; Check for end conditions
    cmp al, 0           ; End of buffer
    je ParseWordDone
    cmp al, 13          ; Carriage return
    je ParseWordDone
    cmp al, 10          ; Line feed
    je ParseWordDone
    cmp al, ' '         ; Space separator
    je ParseWordDone
    cmp al, 9           ; Tab separator
    je ParseWordDone
    
    ; Store character
    mov [di], al
    inc si
    inc di
    inc cx
    cmp cx, 19          ; Limit word length
    jb ParseWordLoop
    
ParseWordDone:
    mov byte ptr [di], 0    ; Null terminate
    pop cx
    ret

; Function to skip whitespace and newlines
SkipWhitespaceAndNewlines:
    push ax
SkipWhitespaceLoop:
    mov al, [si]
    cmp al, 0
    je SkipWhitespaceDone
    cmp al, ' '
    je SkipWhitespaceChar
    cmp al, 9           ; Tab
    je SkipWhitespaceChar
    cmp al, 13          ; CR
    je SkipWhitespaceChar
    cmp al, 10          ; LF
    je SkipWhitespaceChar
    jmp SkipWhitespaceDone
    
SkipWhitespaceChar:
    inc si
    jmp SkipWhitespaceLoop
    
SkipWhitespaceDone:
    pop ax
    ret

; Function to skip spaces only
SkipSpaces:
    push ax
SkipSpacesLoop:
    mov al, [si]
    cmp al, ' '
    je SkipSpace
    cmp al, 9           ; Tab
    je SkipSpace
    jmp SkipSpacesDone
    
SkipSpace:
    inc si
    jmp SkipSpacesLoop
    
SkipSpacesDone:
    pop ax
    ret

; Function to skip to next line - COMPACT VERSION
SkipToNextLine:
    push ax
SkipLoop:
    mov al, [si]
    cmp al, 0           ; End of buffer
    je SkipDone
    inc si
    cmp al, 10          ; Line feed
    jne SkipLoop
    
SkipDone:
    pop ax
    ret  

;--------------------------------------------------
; Enhanced input buffer clearing (memory only, no screen clearing)
;--------------------------------------------------
ClearInputBuffers:
    push ax
    push cx
    push di
    
    ; Clear inputUser buffer
    lea di, inputUser
    mov cx, 20
    mov al, 0
    rep stosb
    
    ; Clear inputPass buffer
    lea di, inputPass
    mov cx, 20
    mov al, 0
    rep stosb
    
    pop di
    pop cx
    pop ax
    ret

;--------------------------------------------------
; Clear login area of screen (updated for correct positioning)
;--------------------------------------------------
ClearLoginArea:
    push ax
    push bx
    push cx
    push dx
    
    ; Clear from row 8 to row 15 (login area after banner)
    mov cx, 8           ; Number of rows to clear
    mov dh, 8           ; Start row (after banner)
    
ClearLoginLoop:
    push cx
    push dx
    
    ; Position cursor at start of row
    mov ah, 02h
    mov bh, 0
    mov dl, 0           ; Column 0
    int 10h
    
    ; Clear the entire row (80 spaces)
    mov cx, 80
    mov al, ' '
ClearRowLoop:
    mov ah, 0Eh         ; Teletype output
    mov bh, 0
    int 10h
    loop ClearRowLoop
    
    pop dx
    pop cx
    inc dh              ; Next row
    loop ClearLoginLoop
    
    pop dx
    pop cx
    pop bx
    pop ax
    ret
    
;--------------------------------------------------
; Show static banner
;--------------------------------------------------
ShowStaticBanner:
    push ax
    push bx
    push dx
    
    ; Display the banner text
    mov ah, 02h
    mov bh, 00h
    mov dh, 7          ; Row 10 for banner
    mov dl, 0          
    int 10h
    
    lea dx, msgWelcome
    call PrintString
    
    pop dx
    pop bx
    pop ax
    ret

;--------------------------------------------------
; Start background animation (non-blocking)
;--------------------------------------------------
StartBackgroundAnimation:
    push ax
    push bx
    push cx
    
    ; Run a few animation frames
    mov cx, 5           ; Just a few frames per call
    
BackgroundAnimLoop:
    push cx
    
    ; Draw all burgers
    call draw_all_burgers
    call delay_frame
    call clear_all_burgers
    
    ; Move all burgers to the right
    inc burger1_x
    inc burger2_x
    inc burger3_x
    inc burger4_x
    
    ; Check and reset burger 1
    mov ax, burger1_x
    cmp ax, max_x
    jle check_bg_burger2
    mov burger1_x, 0
    
check_bg_burger2:
    ; Check and reset burger 2
    mov ax, burger2_x
    cmp ax, max_x
    jle check_bg_burger3
    mov burger2_x, 0
    
check_bg_burger3:
    ; Check and reset burger 3
    mov ax, burger3_x
    cmp ax, max_x
    jle check_bg_burger4
    mov burger3_x, 0

check_bg_burger4:
    ; Check and reset burger 4
    mov ax, burger4_x
    cmp ax, max_x
    jle continue_bg_animation
    mov burger4_x, 0
    
continue_bg_animation:
    pop cx
    loop BackgroundAnimLoop
    
    pop cx
    pop bx
    pop ax
    ret

;--------------------------------------------------
; Draw all burgers at their current positions
;--------------------------------------------------
draw_all_burgers:
    push ax
    push bx
    
    ; Draw burger 1
    mov ax, burger1_x
    mov bx, burger1_y
    call draw_burger_at
    
    ; Draw burger 2
    mov ax, burger2_x
    mov bx, burger2_y
    call draw_burger_at
    
    ; Draw burger 3
    mov ax, burger3_x
    mov bx, burger3_y
    call draw_burger_at
    
    ; Draw burger 4
    mov ax, burger4_x
    mov bx, burger4_y
    call draw_burger_at
    
    pop bx
    pop ax
    ret

;--------------------------------------------------
; Clear all burgers at their current positions
;--------------------------------------------------
clear_all_burgers:
    push ax
    push bx
    
    ; Clear burger 1
    mov ax, burger1_x
    mov bx, burger1_y
    call clear_burger_at
    
    ; Clear burger 2
    mov ax, burger2_x
    mov bx, burger2_y
    call clear_burger_at
    
    ; Clear burger 3
    mov ax, burger3_x
    mov bx, burger3_y
    call clear_burger_at
    
    ; Clear burger 4
    mov ax, burger4_x
    mov bx, burger4_y
    call clear_burger_at
    
    
    pop bx
    pop ax
    ret

;--------------------------------------------------
; Draw burger at position AX=x, BX=y
;--------------------------------------------------
; 3. Replace your draw_burger_at function with this simplified version:
draw_burger_at:
    push ax
    push bx
    push cx
    push dx
    push si
    
    mov cl, al         ; Save X position in CL
    mov ch, bl         ; Save Y position in CH
    
    ; Set cursor position for line 1
    mov ah, 02h
    mov bh, 00h        ; Page 0
    mov dh, ch         ; Row from saved Y
    mov dl, cl         ; Column from saved X
    int 10h
    
    ; Print line 1
    lea si, burger_line1
    call print_string_burger
    
    ; Set cursor position for line 2
    mov ah, 02h
    mov bh, 00h
    mov dh, ch         ; Base Y position
    inc dh             ; Next row
    mov dl, cl         ; X position
    int 10h
    
    ; Print line 2
    lea si, burger_line2
    call print_string_burger
    
    ; Set cursor position for line 3
    mov ah, 02h
    mov bh, 00h
    mov dh, ch         ; Base Y position
    add dh, 2          ; Next row
    mov dl, cl         ; X position
    int 10h
    
    ; Print line 3
    lea si, burger_line3
    call print_string_burger
    
    ; Set cursor position for line 4
    mov ah, 02h
    mov bh, 00h
    mov dh, ch         ; Base Y position
    add dh, 3          ; Next row
    mov dl, cl         ; X position
    int 10h
    
    ; Print line 4
    lea si, burger_line4
    call print_string_burger
    
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

;--------------------------------------------------
; Clear burger at position AX=x, BX=y
;--------------------------------------------------
; 4. Replace your clear_burger_at function with this simplified version:
clear_burger_at:
    push ax
    push bx
    push cx
    push dx
    
    ; Clear line 1
    mov ah, 02h
    mov bh, 00h
    mov dh, bl         ; Row from BX
    mov dl, al         ; Column from AX
    int 10h
    
    mov ah, 09h
    lea dx, clear_line
    int 21h
    
    ; Clear line 2
    mov ah, 02h
    mov bh, 00h
    mov dh, bl
    inc dh
    mov dl, al
    int 10h
    
    mov ah, 09h
    lea dx, clear_line
    int 21h
    
    ; Clear line 3
    mov ah, 02h
    mov bh, 00h
    mov dh, bl
    add dh, 2
    mov dl, al
    int 10h
    
    mov ah, 09h
    lea dx, clear_line
    int 21h
    
    ; Clear line 4
    mov ah, 02h
    mov bh, 00h
    mov dh, bl
    add dh, 3
    mov dl, al
    int 10h
    
    mov ah, 09h
    lea dx, clear_line
    int 21h
    
    pop dx
    pop cx
    pop bx
    pop ax
    ret

;--------------------------------------------------
; Delay frame for animation timing
;--------------------------------------------------
delay_frame:
    push ax
    push cx
    
    mov cx, delay_max
delay_loop:
    nop
    nop
    nop
    loop delay_loop
    
    pop cx
    pop ax
    ret

;--------------------------------------------------
; Print null-terminated string at DS:SI (for burgers)
;--------------------------------------------------
print_string_burger:
    push ax
    push si
    
print_loop_burger:
    lodsb              ; Load byte from DS:SI into AL, increment SI
    cmp al, 0          ; Check for null terminator
    je print_done_burger ; If null, we're done
    
    mov ah, 0Eh        ; BIOS teletype output
    mov bh, 00h        ; Page 0
    mov bl, 07h        ; Normal attribute
    int 10h            ; Print character
    
    jmp print_loop_burger ; Continue with next character
    
print_done_burger:
    pop si
    pop ax
    ret
    
; Main Menu
MainMenu:
MenuLoop:
    lea dx, msgMenuTitle
    call PrintString
    lea dx, msgMenu1
    call PrintString
    lea dx, msgMenu2
    call PrintString
    lea dx, msgMenu3
    call PrintString
    lea dx, msgMenu4
    call PrintString
    lea dx, msgMenu5
    call PrintString
    lea dx, msgPrompt
    call PrintString

    mov ah, 01h
    int 21h
    mov bl, al

    call NewLine

    cmp bl, '1'
    jne CheckOption2
    jmp ShowFoodMenu

CheckOption2:
    cmp bl, '2'
    jne CheckOption3
    jmp OrderFood

CheckOption3:
    cmp bl, '3'
    jne CheckOption4
    jmp CalculateTotal

CheckOption4:
    cmp bl, '4'
    jne CheckOption5
    jmp Restock

CheckOption5:
    cmp bl, '5'
    jne InvalidChoice
    jmp DoLogoutWithAnimation

InvalidChoice:
    lea dx, msgInvalid
    call PrintString
    jmp MenuLoop

ShowFoodMenu:
    lea dx, header
    call PrintString

    xor si, si  ; si = index

; FIXED - Replace the quantity printing section in NextItem loop:
NextItem:
    cmp si, 5
    jge EndShow

    call PrintItemDetails
    
    inc si
    jmp NextItem

EndShow:
    jmp MenuLoop

; Restock Function
Restock:
    lea dx, msgRestockTitle
    call PrintString
    call RestockLoop
    jmp MenuLoop  ; Return to main menu directly

RestockLoop:
    ; Show current menu
    lea dx, header
    call PrintString
    call DisplayAllItems
    
    ; Get user input
    lea dx, msgSelectRestock
    call PrintString
    
    mov ah, 01h
    int 21h
    mov bl, al
    call NewLine
    
    ; Check if user wants to finish
    cmp bl, '9'
    je RestockFinish
    
    ; Process the restock
    call ProcessRestock
    jmp RestockLoop

RestockFinish:
    ret

; SEPARATE FUNCTION FOR RESTOCK PROCESSING
ProcessRestock:
    ; Validate input (must be 0-4)
    cmp bl, '0'
    jb RestockInvalid
    cmp bl, '4'
    ja RestockInvalid
    
    ; Convert character to number
    sub bl, '0'
    mov si, bx
    
    ; Add 10 units to inventory
    call AddRestockItem
    ret

RestockInvalid:
    lea dx, msgRestockInvalidID
    call PrintString
    ret
    
; FUNCTION TO ADD RESTOCK ITEM WITH USER INPUT 
AddRestockItem:
    ; Get and save current quantity
    mov bx, si
    shl bx, 1
    mov ax, [FoodQty + bx]
    push si                 ; Save si (food item index)
    push ax                 ; Save current stock quantity
    
    ; Display current stock
    lea dx, msgCurrentStock
    call PrintString
    
    pop ax                  ; Get saved current stock quantity
    call PrintNum           ; Print current stock quantity
    call NewLine
    
    ; Get quantity to add
    lea dx, msgRestockQty
    call PrintString
    
    call GetRestockQuantity
    cmp ax, 0
    je RestockQtyInvalid
    
    ; Save the quantity to add for later display
    push ax                 ; Save quantity to add
    mov dx, ax              ; Save quantity to add in dx
    pop cx                  ; Get quantity to add in cx
    pop si                  ; Restore si (food item index)
    
    ; Add the quantity to existing stock
    mov bx, si
    shl bx, 1
    mov ax, [FoodQty + bx]  ; Get current stock
    add ax, cx              ; Add new quantity
    mov [FoodQty + bx], ax  ; Store new total
    
    ; Show success message with the quantity that was added
    lea dx, msgRestockQtySuccess
    call PrintString
    mov ax, cx              ; Print the quantity that was added
    call PrintNum
    lea dx, msgRestockQtyUnits
    call PrintString
    ret

RestockQtyInvalid:
    pop si                  ; Restore si
    lea dx, msgRestockQtyInvalid
    call PrintString
    ret

; FUNCTION TO GET RESTOCK QUANTITY INPUT
GetRestockQuantity:
    push bx
    push cx
    push dx
    push si
    
    mov ax, 0               ; Initialize result
    mov bx, 10              ; Base 10
    mov si, ax              ; Use si to track result
    
GetRestockQtyLoop:
    mov ah, 01h             ; Get character
    int 21h
    
    cmp al, 13              ; Enter key?
    je GetRestockQtyDone
    
    cmp al, '0'             ; Check if digit
    jb GetRestockQtyInvalid
    cmp al, '9'
    ja GetRestockQtyInvalid
    
    ; Convert and accumulate
    sub al, '0'             ; Convert to number
    mov cl, al              ; Save digit
    mov ax, si              ; Get current result
    mul bx                  ; Multiply by 10
    jc GetRestockQtyInvalid ; Check for overflow
    add ax, cx              ; Add new digit
    jc GetRestockQtyInvalid ; Check for overflow
    cmp ax, 99              ; Check if result > 99
    ja GetRestockQtyInvalid
    mov si, ax              ; Store back to si
    
    jmp GetRestockQtyLoop

GetRestockQtyDone:
    mov ax, si              ; Return result in ax
    cmp ax, 0               ; Make sure it's not 0
    je GetRestockQtyInvalid
    pop si
    pop dx
    pop cx
    pop bx
    ret

GetRestockQtyInvalid:
    mov ax, 0               ; Return 0 for invalid input
    pop si
    pop dx
    pop cx
    pop bx
    ret

; Order Function
OrderFood:
    lea dx, msgOrderTitle
    call PrintString
    call OrderFoodLoop
    jmp MenuLoop  ; Return to main menu directly

OrderFoodLoop:
    ; Show current menu
    lea dx, header
    call PrintString
    call DisplayAllItems
    call ShowCartSummary
    
    ; Get user input
    lea dx, msgSelectFood
    call PrintString
    
    mov ah, 01h
    int 21h
    mov bl, al
    call NewLine
    
    ; Check if user wants to finish
    cmp bl, '9'
    je OrderFinish
    
    ; Process the order
    call ProcessOrder
    jmp OrderFoodLoop

OrderFinish:
    call CheckEmptyCart
    ret

; SEPARATE FUNCTION FOR ORDER PROCESSING
ProcessOrder:
    ; Validate input (must be 0-4)
    cmp bl, '0'
    jb OrderInvalid
    cmp bl, '4'
    ja OrderInvalid
    
    ; Convert character to number
    sub bl, '0'
    mov si, bx
    
    ; Check stock and process order
    call CheckStockAndOrder
    ret

OrderInvalid:
    lea dx, msgInvalidID
    call PrintString
    ret

; FUNCTION TO CHECK STOCK AND ADD TO CART
CheckStockAndOrder:
    ; Check if item is in stock
    mov bx, si
    shl bx, 1
    mov ax, [FoodQty + bx]
    cmp ax, 0
    je OrderOutOfStock
    
    ; Reduce inventory quantity by 1
    dec ax
    mov [FoodQty + bx], ax
    
    ; Add item to cart
    mov bx, si
    inc byte ptr [CartItems + bx]
    
    ; Add price to total
    mov bx, si
    shl bx, 1
    mov ax, [FoodPrice + bx]
    add [CartTotal], ax
    
    ; Show success message
    lea dx, msgOrderSuccess
    call PrintString
    ret

OrderOutOfStock:
    lea dx, msgOutOfStock
    call PrintString
    ret

; FUNCTION TO CHECK IF CART IS EMPTY
CheckEmptyCart:
    mov cx, 5
    mov si, 0
    mov al, 0
    
CheckCartLoop:
    add al, [CartItems + si]
    inc si
    loop CheckCartLoop
    
    cmp al, 0
    je EmptyCartMsg
    ret

EmptyCartMsg:
    lea dx, msgNoOrders
    call PrintString
    ret

; ENHANCED CHECKOUT FUNCTION WITH PAYMENT PROCESSING
CalculateTotal:
    lea dx, msgCheckoutTitle
    call PrintString
    call ProcessCheckout
    jmp MenuLoop  ; Return to main menu directly

ProcessCheckout:
    ; Check if cart is empty
    mov cx, 5
    mov si, 0
    mov al, 0
    
CheckEmptyCheckout:
    add al, [CartItems + si]
    inc si
    loop CheckEmptyCheckout
    
    cmp al, 0
    je NoItemsCheckout
    
    ; Display cart contents
    lea dx, msgCartHeader
    call PrintString
    call NewLine
    call ShowAllCartItems
    call ShowCheckoutTotalDecimal
    
    ; Process payment
    call ProcessPayment
    
    ; Clear cart after successful payment
    call ClearCart
    
    lea dx, msgThankYou
    call PrintString
    ret

NoItemsCheckout:
    lea dx, msgNoOrders
    call PrintString
    ret

; NEW FUNCTION TO PROCESS PAYMENT
ProcessPayment:
    ; Calculate final total with tax (in cents)
    mov ax, [CartTotal]     ; Get cart total
    mov bx, 106             ; 100% + 6% tax
    mul bx                  ; ax = total with tax in cents
    mov [FinalTotalWithTax], ax
    
PaymentLoop:
    ; Prompt for payment
    lea dx, msgPaymentPrompt
    call PrintString
    
    ; Get payment amount
    call GetPaymentInput
    cmp ax, 0
    je PaymentError         ; Invalid input
    
    mov [PaymentAmount], ax
    
    ; Check if payment is sufficient
    mov ax, [PaymentAmount]
    cmp ax, [FinalTotalWithTax]
    jb InsufficientPayment
    
    ; Payment is sufficient, show payment details
    call ShowPaymentDetails
    
    ret

PaymentError:
    lea dx, msgPaymentError
    call PrintString
    jmp PaymentLoop

InsufficientPayment:
    lea dx, msgInsufficientFunds
    call PrintString
    mov ax, [FinalTotalWithTax]
    call PrintDecimalFixed
    call NewLine
    jmp PaymentLoop

; FUNCTION TO SHOW PAYMENT DETAILS
ShowPaymentDetails:
    ; Show amount paid
    lea dx, msgAmountPaid
    call PrintString
    mov ax, [PaymentAmount]
    call PrintDecimalFixed
    call NewLine
    
    ; Calculate and show change
    mov ax, [PaymentAmount]
    sub ax, [FinalTotalWithTax]
    mov [ChangeAmount], ax
    
    cmp ax, 0
    je ExactPayment
    
    ; Show change
    lea dx, msgChangeAmount
    call PrintString
    mov ax, [ChangeAmount]
    call PrintDecimalFixed
    call NewLine
    ret

ExactPayment:
    lea dx, msgExactPayment
    call PrintString
    ret

; FUNCTION TO GET PAYMENT INPUT (IN CENTS)
GetPaymentInput:
    push bx
    push cx
    push dx
    push si
    
    mov ax, 0               ; Initialize result
    mov bx, 10              ; Base 10
    mov si, ax              ; Use si to track result
    
GetPaymentLoop:
    mov ah, 01h             ; Get character
    int 21h
    
    cmp al, 13              ; Enter key?
    je GetPaymentDone
    
    cmp al, '0'             ; Check if digit
    jb GetPaymentInvalid
    cmp al, '9'
    ja GetPaymentInvalid
    
    ; Convert and accumulate
    sub al, '0'             ; Convert to number
    mov cl, al              ; Save digit
    mov ax, si              ; Get current result
    mul bx                  ; Multiply by 10
    jo GetPaymentInvalid    ; Overflow check
    add ax, cx              ; Add new digit (cx contains the digit)
    jc GetPaymentInvalid    ; Carry check
    mov si, ax              ; Store back to si
    
    jmp GetPaymentLoop

GetPaymentDone:
    mov ax, si              ; Return result in ax
    pop si
    pop dx
    pop cx
    pop bx
    ret

GetPaymentInvalid:
    mov ax, 0               ; Return 0 for invalid input
    pop si
    pop dx
    pop cx
    pop bx
    ret

; FUNCTION TO SHOW ALL CART ITEMS
ShowAllCartItems:
    mov si, 0
ShowCartLoop:
    cmp si, 5
    jge ShowCartEnd
    
    ; Check if this item is in cart
    mov al, [CartItems + si]
    cmp al, 0
    je NextCartItem
    
    call PrintCartItem
    
NextCartItem:
    inc si
    jmp ShowCartLoop
ShowCartEnd:
    ret

; FUNCTION TO PRINT INDIVIDUAL CART ITEM
PrintCartItem:
    ; Print item details
    lea dx, msgCartItem
    call PrintString
    
    ; Print food name
    mov ax, si
    mov bx, 14
    mul bx
    mov dx, offset FoodNames
    add dx, ax
    call PrintText
    
    ; Print quantity
    lea dx, msgQuantity
    call PrintString
    mov al, [CartItems + si]
    mov ah, 0
    push si
    call PrintNum
    pop si
    
    ; Print individual price
    lea dx, msgItemPrice
    call PrintString
    mov bx, si
    shl bx, 1
    mov ax, [FoodPrice + bx]
    push si
    call PrintNum
    pop si
    
    ; Print total for this item
    call PrintItemTotal
    call NewLine
    ret

; FUNCTION TO PRINT ITEM TOTAL
PrintItemTotal:
    
    ; Print " (Total: RM"
    lea dx, msgItemTotal
    call PrintString
    
    ; Calculate and print item total
    mov al, [CartItems + si]
    mov ah, 0
    mov bx, si
    shl bx, 1
    mov dx, [FoodPrice + bx]
    mul dx
    push si
    call PrintNum
    pop si
    
    mov dl, ')'
    mov ah, 02h
    int 21h
    ret

; FUNCTION TO SHOW CHECKOUT TOTAL WITH TAX - SIMPLIFIED VERSION
ShowCheckoutTotalDecimal:
    ; Show subtotal: CartTotal.00
    lea dx, msgTotalPrice
    call PrintString
    mov ax, [CartTotal]     ; Get cart total (e.g., 31)
    mov bx, 100
    mul bx                  ; ax = 3100 (31.00 in cents)
    call PrintDecimalFixed
    call NewLine
    
    ; Calculate and show tax: CartTotal * 6 (represents 6% in cents)
    lea dx, msgTaxAmount
    call PrintString
    mov ax, [CartTotal]     ; Get cart total again
    mov bx, 6
    mul bx                  ; ax = CartTotal * 6 (tax in cents)
    call PrintDecimalFixed
    call NewLine
    
    ; Calculate and show final total: CartTotal * 106 (100% + 6% tax)
    lea dx, msgFinalTotal
    call PrintString
    mov ax, [CartTotal]     ; Get cart total again
    mov bx, 106
    mul bx                  ; ax = CartTotal * 106 (total with tax in cents)
    call PrintDecimalFixed
    call NewLine
    ret

; FUNCTION TO SHOW CART SUMMARY - FIXED
ShowCartSummary:
    mov cx, 5
    mov si, 0
    mov bl, 0           ; Use bl instead of al to avoid conflicts
CountCartItems:
    add bl, [CartItems + si]
    inc si
    loop CountCartItems
    
    cmp bl, 0
    je NoCartSummary
    
    call NewLine
    call PrintCartSummaryText
    mov al, bl          ; Move count to al
    mov ah, 0           ; Clear high byte properly
    call PrintNum       ; Now ax contains the correct count
    call PrintItemsText
    call PrintTotalText
    mov ax, [CartTotal]
    call PrintNum
    call NewLine

NoCartSummary:
    ret

; SHORTENED HELPER FUNCTIONS FOR CART SUMMARY
PrintCartSummaryText:
    lea dx, msgCartSummary
    call PrintString
    ret

PrintItemsText:
    lea dx, msgItems
    call PrintString
    ret

PrintTotalText:
    lea dx, msgTotal
    call PrintString
    ret

; FUNCTION TO CLEAR CART
ClearCart:
    ; Clear cart items
    mov cx, 5
    mov si, 0
ClearCartLoop:
    mov byte ptr [CartItems + si], 0
    inc si
    loop ClearCartLoop
    
    ; Reset total
    mov word ptr [CartTotal], 0
    ret

; FIXED - Replace the quantity printing section in DisplayAllItems:
DisplayAllItems:
    xor si, si
DisplayNext:
    cmp si, 5
    jge DisplayEnd
    
    call PrintItemDetails
    
    inc si
    jmp DisplayNext
DisplayEnd:
    call NewLine
    ret 

; Create a reusable subroutine for printing item details
PrintItemDetails:
    ; Input: SI = item index
    ; Prints: ID, Name, Quantity (with low stock warning), Price
    
    push si
    
    ; === Print ID ===
    mov ax, si
    call PrintNum
    call PrintTab

    ; === Print Name ===
    mov ax, si
    mov bx, 14
    mul bx
    mov dx, offset FoodNames
    add dx, ax
    call PrintText
    call PrintTab
    call PrintTab

    ; === Print Quantity with Color and alignment ===
    mov bx, si
    shl bx, 1
    mov ax, [FoodQty + bx]

    ; Check if quantity is less than 5
    cmp ax, 5
    jae NormalColor      ; Jump if quantity >= 5

    ; Print with BLINKING LOW warning for low stock
    call PrintLowStockBlinking
    ; DON'T print tabs here - the alignment is handled below
    jmp SkipNormalQuantity

    NormalColor:
    call PrintNum       ; Print quantity in normal color
    call PrintTab
    call PrintTab
    jmp QuantityPrinted

    SkipNormalQuantity:
    ; For low stock items, we need fewer spaces since "(LOW!)" takes up space
    ; Adjust spacing to align with normal items
    mov cx, 8  ; Add fewer spaces to align with normal items
    SpaceLoop:
        mov dl, ' '
        mov ah, 02h
        int 21h
        loop SpaceLoop

    QuantityPrinted:
    ; === Print Price ===
    mov bx, si
    shl bx, 1
    mov ax, [FoodPrice + bx]
    call PrintNum
    call NewLine

    pop si
    ret

; FIXED BLINKING SOLUTION - Print number with blinking (LOW!) but maintain column alignment
PrintLowStockBlinking:
    push ax
    push bx
    push cx
    push dx
    
    ; First print the number normally
    call PrintNumRed
    
    ; Now print " (LOW!)" with blinking
    mov dl, ' '
    mov ah, 02h
    int 21h
    
    ; Print each character of "(LOW!)" with blinking attribute
    ; Print '('
    mov ah, 09h         ; Write character with attribute
    mov al, '('
    mov bh, 0           ; Page number
    mov bl, 8Ch         ; Blinking bright red (80h + 0Ch)
    mov cx, 1           ; Number of characters
    int 10h
    call MoveCursorRight
    
    ; Print 'L'
    mov ah, 09h
    mov al, 'L'
    mov bh, 0
    mov bl, 8Ch
    mov cx, 1
    int 10h
    call MoveCursorRight
    
    ; Print 'O'
    mov ah, 09h
    mov al, 'O'
    mov bh, 0
    mov bl, 8Ch
    mov cx, 1
    int 10h
    call MoveCursorRight
    
    ; Print 'W'
    mov ah, 09h
    mov al, 'W'
    mov bh, 0
    mov bl, 8Ch
    mov cx, 1
    int 10h
    call MoveCursorRight
    
    ; Print '!'
    mov ah, 09h
    mov al, '!'
    mov bh, 0
    mov bl, 8Ch
    mov cx, 1
    int 10h
    call MoveCursorRight
    
    ; Print ')'
    mov ah, 09h
    mov al, ')'
    mov bh, 0
    mov bl, 8Ch
    mov cx, 1
    int 10h
    call MoveCursorRight
    
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; Helper function to move cursor right
MoveCursorRight:
    push ax
    push bx
    push cx
    push dx
    
    mov ah, 03h         ; Get cursor position
    mov bh, 0
    int 10h
    inc dl              ; Move cursor right
    mov ah, 02h         ; Set cursor position
    int 10h
    
    pop dx
    pop cx
    pop bx
    pop ax
    ret
    
; Function to print number in red
PrintNumRed:
    push ax
    push bx
    push cx
    push dx
    
    xor cx, cx
.next_digit_red:
    xor dx, dx
    mov bx, 10
    div bx
    push dx
    inc cx
    test ax, ax
    jnz .next_digit_red
    
.print_loop_red:
    pop dx
    add dl, '0'
    
    ; Print character with red attribute
    mov ah, 09h         ; Write character with attribute
    mov al, dl
    mov bh, 0           ; Page number
    mov bl, 0Ch         ; Bright red (not blinking)
    mov cx, 1           ; Number of characters
    int 10h
    call MoveCursorRight
    
    loop .print_loop_red
    
    pop dx
    pop cx
    pop bx
    pop ax
    ret
    
; ========== Utility Functions ==========
;--------------------------------------------------
; Enhanced input function with continuous animation
;--------------------------------------------------
GetInputWithAnimation:
    push bx             ; Save original buffer pointer
    mov si, bx          ; Use SI to track current position
    mov cx, 0           ; Character counter
    
GetInputAnimLoop:
    ; Save current cursor position before animation
    push cx
    push dx
    mov ah, 03h         ; Get cursor position
    mov bh, 0           ; Page 0
    int 10h             ; Returns position in DH=row, DL=column
    push dx             ; Save cursor position
    
    ; Run continuous background animation
    call ContinuousBackgroundAnimation
    
    ; Restore cursor position after animation
    pop dx              ; Restore cursor position
    mov ah, 02h         ; Set cursor position
    mov bh, 0           ; Page 0
    int 10h             ; Set cursor back to saved position
    pop dx
    pop cx
    
    ; Check for keyboard input (non-blocking)
    mov ah, 0Bh         ; Check keyboard status
    int 21h
    cmp al, 0           ; No key pressed
    je GetInputAnimLoop ; Continue animation
    
    ; Get the actual key
    mov ah, 08h         ; Get character without echo
    int 21h
    cmp al, 13          ; Enter key
    je GetInputAnimDone
    cmp al, 8           ; Backspace key
    je HandleBackspaceAnim
    cmp cx, 19          ; Limit input length
    jae GetInputAnimLoop
    mov [si], al        ; Store character
    inc si
    inc cx
    ; Display the character
    mov dl, al
    mov ah, 02h
    int 21h
    jmp GetInputAnimLoop
    
HandleBackspaceAnim:
    cmp cx, 0           ; Check if buffer is empty
    je GetInputAnimLoop ; If empty, ignore backspace
    dec si              ; Move buffer pointer back
    dec cx              ; Decrease counter
    mov byte ptr [si], 0 ; Clear the character in buffer
    mov dl, 8           ; Print backspace
    mov ah, 02h
    int 21h
    mov dl, ' '         ; Print space to erase character
    mov ah, 02h
    int 21h
    mov dl, 8           ; Print backspace again to position cursor
    mov ah, 02h
    int 21h
    jmp GetInputAnimLoop
    
GetInputAnimDone:
    mov byte ptr [si], 0 ; Null terminate
    pop bx              ; Restore original buffer pointer
    ret

;--------------------------------------------------
; Enhanced masked input function with continuous animation
;--------------------------------------------------
GetMaskedInputWithAnimation:
    push bx             ; Save original buffer pointer
    mov si, bx          ; Use SI to track current position
    mov cx, 0           ; Character counter
    
MaskedAnimLoop:
    ; Save current cursor position before animation
    push cx
    push dx
    mov ah, 03h         ; Get cursor position
    mov bh, 0           ; Page 0
    int 10h             ; Returns position in DH=row, DL=column
    push dx             ; Save cursor position
    
    ; Run continuous background animation
    call ContinuousBackgroundAnimation
    
    ; Restore cursor position after animation
    pop dx              ; Restore cursor position
    mov ah, 02h         ; Set cursor position
    mov bh, 0           ; Page 0
    int 10h             ; Set cursor back to saved position
    pop dx
    pop cx
    
    ; Check for keyboard input (non-blocking)
    mov ah, 0Bh         ; Check keyboard status
    int 21h
    cmp al, 0           ; No key pressed
    je MaskedAnimLoop   ; Continue animation
    
    ; Get the actual key
    mov ah, 08h         ; Get character without echo
    int 21h
    cmp al, 13          ; Enter key
    je MaskedAnimDone
    cmp al, 8           ; Backspace key
    je HandleMaskedBackspaceAnim
    cmp cx, 19          ; Limit input length
    jae MaskedAnimLoop
    mov [si], al        ; Store character
    inc si
    inc cx
    mov dl, '*'         ; Show asterisk
    mov ah, 02h
    int 21h
    jmp MaskedAnimLoop
    
HandleMaskedBackspaceAnim:
    cmp cx, 0           ; Check if buffer is empty
    je MaskedAnimLoop   ; If empty, ignore backspace
    dec si              ; Move buffer pointer back
    dec cx              ; Decrease counter
    mov byte ptr [si], 0 ; Clear the character in buffer
    mov dl, 8           ; Print backspace
    mov ah, 02h
    int 21h
    mov dl, ' '         ; Print space to erase asterisk
    mov ah, 02h
    int 21h
    mov dl, 8           ; Print backspace again to position cursor
    mov ah, 02h
    int 21h
    jmp MaskedAnimLoop
    
MaskedAnimDone:
    mov byte ptr [si], 0 ; Null terminate
    pop bx              ; Restore original buffer pointer
    ret

StrCompare:
    mov al, 1
CompareLoop:
    mov bl, [si]
    mov bh, [di]
    cmp bl, bh
    jne NotEqual
    cmp bl, 0
    je CompareDone
    inc si
    inc di
    jmp CompareLoop
NotEqual:
    mov al, 0
CompareDone:
    ret

PrintString:
    mov ah, 09h
    int 21h
    ret

NewLine:
    mov dl, 13
    mov ah, 02h
    int 21h
    mov dl, 10
    int 21h
    ret

WaitKeyWithAnimation:
WaitKeyAnimLoop:
    ; Save current cursor position
    push dx
    mov ah, 03h         ; Get cursor position
    mov bh, 0
    int 10h
    push dx
    
    ; Run animation
    call ContinuousBackgroundAnimation
    
    ; Restore cursor position
    pop dx
    mov ah, 02h         ; Set cursor position
    mov bh, 0
    int 10h
    pop dx
    
    ; Check for keyboard input
    mov ah, 0Bh         ; Check keyboard status
    int 21h
    cmp al, 0           ; No key pressed
    je WaitKeyAnimLoop  ; Continue animation
    
    ; Get the key
    mov ah, 08h
    int 21h
    ret

ClearScreen:
    mov ah, 06h         ; Scroll window
    mov al, 0           ; Clear entire screen
    mov bh, 07h         ; Normal attribute
    mov cx, 0           ; Upper left corner
    mov dx, 184Fh       ; Lower right corner (80x25)
    int 10h
    
    ; Set cursor to top-left
    mov ah, 02h
    mov bh, 0
    mov dx, 0
    int 10h
    ret
    
PrintTab:
    mov dl, 9
    mov ah, 02h
    int 21h
    ret

PrintText:
    push dx
    push si     ; Save si register
    mov si, dx
    mov cx, 14
PrintText_Loop:
    lodsb
    mov dl, al
    mov ah, 02h
    int 21h
    loop PrintText_Loop
    pop si      ; Restore si register
    pop dx
    ret

PrintNum:
    push ax
    xor cx, cx
.next_digit:
    xor dx, dx
    mov bx, 10
    div bx
    push dx
    inc cx
    test ax, ax
    jnz .next_digit
.print_loop:
    pop dx
    add dl, '0'
    mov ah, 02h
    int 21h
    loop .print_loop
    pop ax
    ret

; FUNCTION TO PRINT DECIMAL NUMBER (2 decimal places)
PrintDecimalFixed:
    push ax
    push cx
    push dx
    
    ; ax contains value in cents (e.g., 1272 for 12.72)
    mov bx, 100
    xor dx, dx
    div bx              ; ax = dollars, dx = cents
    
    ; Print dollar part
    push dx             ; Save cents
    call PrintNum
    
    ; Print decimal point
    mov dl, '.'
    mov ah, 02h
    int 21h
    
    ; Print cents (always 2 digits)
    pop ax              ; Get cents back
    
    ; Print tens digit of cents
    mov bl, 10
    xor ah, ah
    div bl              ; al = tens, ah = ones
    
    push ax             ; Save both digits
    add al, '0'
    mov dl, al
    mov ah, 02h
    int 21h
    
    ; Print ones digit of cents
    pop ax
    mov al, ah          ; Get ones digit
    add al, '0'
    mov dl, al
    mov ah, 02h
    int 21h
    
    pop dx
    pop cx
    pop ax
    ret
    
;--------------------------------------------------
; Delay with animation (for various pauses)
;--------------------------------------------------
DelayWithAnimation:
    push cx
    mov cx, 30          ; Number of animation frames to show
    
DelayAnimLoop:
    push cx
    call ContinuousBackgroundAnimation
    call delay_frame    ; Use existing delay
    pop cx
    loop DelayAnimLoop
    
    pop cx
    ret

;--------------------------------------------------
; Continuous background animation (smoother than before)
;--------------------------------------------------
ContinuousBackgroundAnimation:
    push ax
    push bx
    push cx
    
    ; Draw all burgers at current positions
    call draw_all_burgers
    
    ; Small delay for smoother animation
    call delay_frame
    
    ; Clear all burgers
    call clear_all_burgers
    
    ; Move all burgers to the right
    inc burger1_x
    inc burger2_x
    inc burger3_x
    inc burger4_x
    
    ; Check and reset burger 1
    mov ax, burger1_x
    cmp ax, max_x
    jle check_cont_burger2
    mov burger1_x, 0
    
check_cont_burger2:
    ; Check and reset burger 2
    mov ax, burger2_x
    cmp ax, max_x
    jle check_cont_burger3
    mov burger2_x, 0
    
check_cont_burger3:
    ; Check and reset burger 3
    mov ax, burger3_x
    cmp ax, max_x
    jle check_cont_burger4
    mov burger3_x, 0
    
check_cont_burger4:
    ; Check and reset burger 3
    mov ax, burger4_x
    cmp ax, max_x
    jle cont_animation_done
    mov burger4_x, 0
    
cont_animation_done:
    pop cx
    pop bx
    pop ax
    ret

; Writing to audit.txt
; Function to log audit events
; Input: DX = pointer to audit message template
LogAuditEvent:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    
    ; Get current date and time
    call GetDateTime
    
    ; Build audit message
    call BuildAuditMessage
    
    ; Write to audit file
    call WriteAuditToFile
    
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; Function to get current date and time
GetDateTime:
    push ax
    push bx
    push cx
    push dx
    
    ; Get date
    mov ah, 2Ah         ; Get system date
    int 21h
    ; AL = day of week, CX = year, DH = month, DL = day
    
    ; Convert date to string format (YYYY-MM-DD)
    call FormatDate
    
    ; Get time
    mov ah, 2Ch         ; Get system time
    int 21h
    ; CH = hour, CL = minute, DH = second, DL = centisecond
    
    ; Convert time to string format (HH:MM:SS)
    call FormatTime
    
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; Function to format date as YYYY-MM-DD
FormatDate:
    push ax
    push bx
    push cx
    push dx
    push si
    
    lea si, dateStr
    
    ; Format year (CX contains year)
    mov ax, cx
    call NumToStr4      ; Convert 4-digit year
    
    ; Add dash
    mov byte ptr [si], '-'
    inc si
    
    ; Format month (DH contains month)
    mov al, dh
    call NumToStr2      ; Convert 2-digit month
    
    ; Add dash
    mov byte ptr [si], '-'
    inc si
    
    ; Format day (DL contains day)
    mov al, dl
    call NumToStr2      ; Convert 2-digit day
    
    ; Null terminate
    mov byte ptr [si], 0
    
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; Function to format time as HH:MM:SS
FormatTime:
    push ax
    push bx
    push cx
    push dx
    push si
    
    lea si, timeStr
    
    ; Format hour (CH contains hour)
    mov al, ch
    call NumToStr2      ; Convert 2-digit hour
    
    ; Add colon
    mov byte ptr [si], ':'
    inc si
    
    ; Format minute (CL contains minute)
    mov al, cl
    call NumToStr2      ; Convert 2-digit minute
    
    ; Add colon
    mov byte ptr [si], ':'
    inc si
    
    ; Format second (DH contains second)
    mov al, dh
    call NumToStr2      ; Convert 2-digit second
    
    ; Null terminate
    mov byte ptr [si], 0
    
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; Function to convert number to 4-digit string
NumToStr4:
    push ax
    push bx
    push cx
    push dx
    
    mov bx, 1000
    xor dx, dx
    div bx
    add al, '0'
    mov [si], al
    inc si
    
    mov ax, dx
    mov bx, 100
    xor dx, dx
    div bx
    add al, '0'
    mov [si], al
    inc si
    
    mov ax, dx
    mov bx, 10
    xor dx, dx
    div bx
    add al, '0'
    mov [si], al
    inc si
    
    add dl, '0'
    mov [si], dl
    inc si
    
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; Function to convert number to 2-digit string
NumToStr2:
    push ax
    push bx
    push dx
    
    mov bl, 10
    xor ah, ah
    div bl
    add al, '0'
    mov [si], al
    inc si
    
    add ah, '0'
    mov [si], ah
    inc si
    
    pop dx
    pop bx
    pop ax
    ret

; Function to build audit message
BuildAuditMessage:
    push ax
    push bx
    push cx
    push si
    push di
    
    lea di, auditBuffer
    
    ; Copy date
    lea si, dateStr
    call CopyString
    
    ; Add space
    mov byte ptr [di], ' '
    inc di
    
    ; Copy time
    lea si, timeStr
    call CopyString
    
    ; Copy audit message template (without the $ terminator)
    mov si, dx          ; DX contains pointer to message template
    call CopyStringNoTerminator
    
    ; Copy username
    lea si, inputUser
    call CopyString
    
    ; Add newline
    mov byte ptr [di], 13
    inc di
    mov byte ptr [di], 10
    inc di
    
    ; Null terminate
    mov byte ptr [di], 0
    
    pop di
    pop si
    pop cx
    pop bx
    pop ax
    ret

; Function to copy string with null terminator
CopyString:
    push ax
CopyStringLoop:
    mov al, [si]
    cmp al, 0
    je CopyStringDone
    mov [di], al
    inc si
    inc di
    jmp CopyStringLoop
CopyStringDone:
    pop ax
    ret

; Function to copy string without $ terminator
CopyStringNoTerminator:
    push ax
CopyStringNoTermLoop:
    mov al, [si]
    cmp al, 0
    je CopyStringNoTermDone
    cmp al, '$'
    je CopyStringNoTermDone
    mov [di], al
    inc si
    inc di
    jmp CopyStringNoTermLoop
CopyStringNoTermDone:
    pop ax
    ret

; Function to write audit message to file
WriteAuditToFile:
    push ax
    push bx
    push cx
    push dx
    push si
    
    ; Open audit file for append (or create if not exists)
    mov ah, 3Dh         ; Open file
    mov al, 2           ; Read/write mode
    lea dx, auditfile
    int 21h
    jnc FileOpenSuccess
    
    ; File doesn't exist, create it
    mov ah, 3Ch         ; Create file
    mov cx, 0           ; Normal file attribute
    lea dx, auditfile
    int 21h
    jc WriteAuditError
    
FileOpenSuccess:
    mov [audithandle], ax
    
    ; Seek to end of file
    mov ah, 42h         ; Seek
    mov al, 2           ; From end of file
    mov bx, [audithandle]
    mov cx, 0
    mov dx, 0
    int 21h
    
    ; Calculate message length
    lea si, auditBuffer
    call StrLen
    mov cx, ax          ; Message length in CX
    
    ; Write to file
    mov ah, 40h         ; Write to file
    mov bx, [audithandle]
    lea dx, auditBuffer
    int 21h
    jc WriteAuditError
    
    ; Close file
    mov ah, 3Eh
    mov bx, [audithandle]
    int 21h
    
WriteAuditError:
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; Function to calculate string length
StrLen:
    push bx
    push si
    mov bx, si
    mov ax, 0
StrLenLoop:
    cmp byte ptr [si], 0
    je StrLenDone
    inc si
    inc ax
    jmp StrLenLoop
StrLenDone:
    pop si
    pop bx
    ret
    
end main