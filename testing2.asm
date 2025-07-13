; Login System with Animated Burger Banner in TASM
.model small
.stack 100h

.data
    ; File handling
    filename db "users.txt", 0
    filehandle dw 0
    buffer db 100 dup(0)
    
    ; User input
    inputUser db 20 dup(0)
    inputPass db 20 dup(0)
    
    ; File reading variables
    fileUser db 20 dup(0)
    filePass db 20 dup(0)
    
    ; Login attempt counter
    attemptCount db 0
    
    ; Burger sprite data
    ; NEW (replace with these):
    burger_line1 DB ' .~"""~. ', 0
    burger_line2 DB '|#######|', 0
    burger_line3 DB '|~~~~~~~|', 0
    burger_line4 DB ' `~"""~` ', 0
    
    ; Animation variables - burgers move across banner area
    burger1_x DW 0             ; Burger 1 X position
    burger1_y DW 4             ; Burger 1 Y position (above banner)
    burger2_x DW 24            ; Burger 2 X position
    burger2_y DW 4             ; Burger 2 Y position
    burger3_x DW 48            ; Burger 3 X position
    burger3_y DW 4             ; Burger 3 Y position
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
    msgSuccess db 13,10,"Login Successful! Welcome to the system.$"
    msgFail db 13,10,"Invalid credentials.$"
    msgFileError db 13,10,"Error: Cannot open users.txt file.$"
    msgLockout db 13,10,"Locking Account.$"
    msgPress db 13,10,"Press any key to try again...$"
    
    ; Sample menu after login
    msgMenu db 13,10,13,10,"=== Main Menu ===",13,10
           db "1. View Profile",13,10
           db "2. Settings",13,10
           db "3. Logout",13,10
           db "Enter choice: $"
    msgLogout db 13,10,"Logging out...$"

.code
main:
    mov ax, @data
    mov ds, ax

    call ClearScreen
    call ShowStaticBanner
    
    ; Initialize burger positions for continuous animation
    call InitializeBurgerPositions
    
;--------------------------------------------------
; Modified main login loop to handle logout properly
;--------------------------------------------------
; Replace your existing StartLogin section with this:
StartLogin:
    ; Clear input buffers before each login attempt
    call ClearInputBuffers
    
    ; Position cursor for username prompt
    mov ah, 02h
    mov bh, 0
    mov dh, 7          ; Row 12 (below banner)
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
    lea dx, msgSuccess
    call PrintString
    call ShowMenuWithAnimation
    ; After menu returns (including logout), go back to login
    jmp StartLogin

AccountLocked:
    lea dx, msgLockout
    call PrintString
    ; Wait a moment with animation before exit
    call DelayWithAnimation
    ; Exit program
    mov ah, 4Ch
    int 21h

;--------------------------------------------------
; Clear input buffers
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
; Clear login area of screen
;--------------------------------------------------
ClearLoginArea:
    push ax
    push bx
    push cx
    push dx
    
    ; Clear from row 12 to row 20 (login area)
    mov cx, 9           ; Number of rows to clear
    mov dh, 12          ; Start row
    
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
    jle continue_bg_animation
    mov burger3_x, 0
    
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

; Function to parse file content and check credentials
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

; Function to parse a word from file
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

; Function to skip to next line
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
; Show menu with continuous animation
;--------------------------------------------------
ShowMenuWithAnimation:
    call NewLine
    lea dx, msgMenu
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
    
    cmp al, '3'
    je DoLogoutWithAnimation
    
    ; Handle other menu options here
    call NewLine
    lea dx, msgPress
    call PrintString
    call WaitKeyWithAnimation
    ret

;--------------------------------------------------
; Logout with screen clear and return to login
;--------------------------------------------------
DoLogoutWithAnimation:
    lea dx, msgLogout
    call PrintString
    call WaitKeyWithAnimation
    
    ; Clear everything except banner and burger animation
    call ClearAllExceptBanner
    
    ; Reset login attempt counter
    mov byte ptr [attemptCount], 0
    
    ; Return to login (no need to jump, just return to main loop)
    ret
    
;--------------------------------------------------
; Clear all screen content except banner area and burger animation area
;--------------------------------------------------
ClearAllExceptBanner:
    push ax
    push bx
    push cx
    push dx
    
    ; Clear from row 11 to bottom of screen (leaving banner at row 10)
    ; Banner is at row 10, burgers are at rows 2-8, so clear from row 11 down
    mov dh, 11          ; Start row (after banner)
    mov cx, 14          ; Number of rows to clear (11 to 24)
    
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
    mov burger2_x, 24
    mov burger3_x, 48
    mov burger1_y, 2
    mov burger2_y, 2
    mov burger3_y, 2
    ret

; Utility Functions
; Fixed GetInput function with proper cursor management
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
    jle cont_animation_done
    mov burger3_x, 0
    
cont_animation_done:
    pop cx
    pop bx
    pop ax
    ret

end main

; Instructions for creating users.txt file:
; Create a text file named "users.txt" in the same directory as your program
; Format each line as: username password
; Example content:
; John 1234
; Jeff 1234
; admin secret
; user1 pass123