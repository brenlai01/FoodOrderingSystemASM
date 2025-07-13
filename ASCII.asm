; Login System with Animated Burger Banner in TASM - Fixed Version
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
    burger_line1 DB ' .~"""~. ', 0
    burger_line2 DB '|#######|', 0
    burger_line3 DB '|~~~~~~~|', 0
    burger_line4 DB ' `~"""~` ', 0
    
    ; Animation variables
    burger1_x DW 0
    burger1_y DW 2
    burger2_x DW 24
    burger2_y DW 2
    burger3_x DW 48
    burger3_y DW 2
    max_x DW 71
    delay_max DW 65000
    
    ; Clear line for burger (9 spaces)
    clear_line DB '         $'
    
    ; Messages
    msgWelcome db "============================ APU Food Store System =============================$"
    msgUser db 13,10,"Username: $"
    msgPass db 13,10,"Password: $"
    msgSuccess db 13,10,"Login Successful! Welcome to the system.$"
    msgFail db 13,10,"Invalid credentials.$"
    msgFileError db 13,10,"Error: Cannot open users.txt file.$"
    msgLockout db 13,10,"Locking Account.$"
    msgPress db 13,10,"Press any key to try again...$"
    
    ; Menu messages
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
    call InitializeBurgerPositions
    
StartLogin:
    call ClearInputBuffers
    
    ; Position cursor for username prompt
    mov ah, 02h
    mov bh, 0
    mov dh, 7
    mov dl, 0
    int 10h
    
    ; Get username with animation
    lea dx, msgUser
    call PrintString
    lea bx, inputUser
    call GetInputWithAnimation

    ; Get password with animation
    lea dx, msgPass
    call PrintString
    lea bx, inputPass
    call GetMaskedInputWithAnimation

    ; Validate credentials
    call ValidateLogin
    cmp al, 1
    je LoginSuccess
    
    ; Login failed
    inc byte ptr [attemptCount]
    lea dx, msgFail
    call PrintString
    
    ; Check if maximum attempts reached
    cmp byte ptr [attemptCount], 3
    je AccountLocked
    
    ; Wait for user to press a key
    lea dx, msgPress
    call PrintString
    call WaitKeyWithAnimation
    
    ; Clear the failed login messages
    call ClearLoginArea
    jmp StartLogin

LoginSuccess:
    lea dx, msgSuccess
    call PrintString
    call ShowMenuWithAnimation
    jmp StartLogin

AccountLocked:
    lea dx, msgLockout
    call PrintString
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
    
    ; Clear from row 7 to row 20 (login area)
    mov cx, 14
    mov dh, 7
    
ClearLoginLoop:
    push cx
    push dx
    
    ; Position cursor at start of row
    mov ah, 02h
    mov bh, 0
    mov dl, 0
    int 10h
    
    ; Clear the entire row (80 spaces)
    mov cx, 80
    mov al, ' '
ClearRowLoop:
    mov ah, 0Eh
    mov bh, 0
    int 10h
    loop ClearRowLoop
    
    pop dx
    pop cx
    inc dh
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
    mov dh, 6
    mov dl, 0
    int 10h
    
    lea dx, msgWelcome
    call PrintString
    
    pop dx
    pop bx
    pop ax
    ret

;--------------------------------------------------
; Initialize burger positions
;--------------------------------------------------
InitializeBurgerPositions:
    mov burger1_x, 0
    mov burger2_x, 24
    mov burger3_x, 48
    mov burger1_y, 2
    mov burger2_y, 2
    mov burger3_y, 2
    ret

;--------------------------------------------------
; Main animation routine
;--------------------------------------------------
ContinuousBackgroundAnimation:
    push ax
    push bx
    push cx
    
    ; Draw all burgers
    call draw_all_burgers
    call delay_frame
    call clear_all_burgers
    
    ; Move all burgers
    inc burger1_x
    inc burger2_x
    inc burger3_x
    
    ; Reset positions when reaching edge
    mov ax, burger1_x
    cmp ax, max_x
    jle check_burger2
    mov burger1_x, 0
    
check_burger2:
    mov ax, burger2_x
    cmp ax, max_x
    jle check_burger3
    mov burger2_x, 0
    
check_burger3:
    mov ax, burger3_x
    cmp ax, max_x
    jle animation_done
    mov burger3_x, 0
    
animation_done:
    pop cx
    pop bx
    pop ax
    ret

;--------------------------------------------------
; Draw all burgers
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
; Clear all burgers
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
draw_burger_at:
    push ax
    push bx
    push cx
    push dx
    push si
    
    mov cl, al         ; Save X position
    mov ch, bl         ; Save Y position
    
    ; Draw all 4 lines of the burger
    mov si, 0          ; Line counter
    
draw_burger_line:
    ; Set cursor position
    mov ah, 02h
    mov bh, 00h
    mov dh, ch
    mov ax, si         ; Move si to ax
    add dh, al         ; Add line offset (low byte of si)
    mov dl, cl
    int 10h
    
    ; Select appropriate line data
    cmp si, 0
    je draw_line1
    cmp si, 1
    je draw_line2
    cmp si, 2
    je draw_line3
    lea dx, burger_line4
    jmp print_line
    
draw_line1:
    lea dx, burger_line1
    jmp print_line
draw_line2:
    lea dx, burger_line2
    jmp print_line
draw_line3:
    lea dx, burger_line3
    
print_line:
    push si
    mov si, dx
    call print_string_burger
    pop si
    
    inc si
    cmp si, 4
    jl draw_burger_line
    
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

;--------------------------------------------------
; Clear burger at position AX=x, BX=y
;--------------------------------------------------
clear_burger_at:
    push ax
    push bx
    push cx
    push dx
    
    mov cl, al         ; Save X position
    mov ch, bl         ; Save Y position
    mov si, 0          ; Line counter
    
clear_burger_line:
    ; Set cursor position
    mov ah, 02h
    mov bh, 00h
    mov dh, ch
    mov ax, si         ; Move si to ax
    add dh, al         ; Add line offset (low byte of si)
    mov dl, cl
    int 10h
    
    ; Clear the line
    mov ah, 09h
    lea dx, clear_line
    int 21h
    
    inc si
    cmp si, 4
    jl clear_burger_line
    
    pop dx
    pop cx
    pop bx
    pop ax
    ret

;--------------------------------------------------
; Print null-terminated string for burgers
;--------------------------------------------------
print_string_burger:
    push ax
    push si
    
print_loop:
    lodsb
    cmp al, 0
    je print_done
    
    mov ah, 0Eh
    mov bh, 00h
    mov bl, 07h
    int 10h
    
    jmp print_loop
    
print_done:
    pop si
    pop ax
    ret

;--------------------------------------------------
; Delay frame for animation
;--------------------------------------------------
delay_frame:
    push ax
    push cx
    
    mov cx, delay_max
delay_loop:
    nop
    loop delay_loop
    
    pop cx
    pop ax
    ret

;--------------------------------------------------
; Enhanced input with animation
;--------------------------------------------------
GetInputWithAnimation:
    push bx
    mov si, bx
    mov cx, 0
    
GetInputLoop:
    ; Save cursor position
    mov ah, 03h
    mov bh, 0
    int 10h
    push dx
    
    ; Run animation
    call ContinuousBackgroundAnimation
    
    ; Restore cursor position
    pop dx
    mov ah, 02h
    mov bh, 0
    int 10h
    
    ; Check for keyboard input
    mov ah, 0Bh
    int 21h
    cmp al, 0
    je GetInputLoop
    
    ; Get the key
    mov ah, 08h
    int 21h
    cmp al, 13          ; Enter
    je InputDone
    cmp al, 8           ; Backspace
    je HandleBackspace
    cmp cx, 19
    jae GetInputLoop
    
    mov [si], al
    inc si
    inc cx
    mov dl, al
    mov ah, 02h
    int 21h
    jmp GetInputLoop
    
HandleBackspace:
    cmp cx, 0
    je GetInputLoop
    dec si
    dec cx
    mov byte ptr [si], 0
    mov dl, 8
    mov ah, 02h
    int 21h
    mov dl, ' '
    mov ah, 02h
    int 21h
    mov dl, 8
    mov ah, 02h
    int 21h
    jmp GetInputLoop
    
InputDone:
    mov byte ptr [si], 0
    pop bx
    ret

;--------------------------------------------------
; Masked input with animation
;--------------------------------------------------
GetMaskedInputWithAnimation:
    push bx
    mov si, bx
    mov cx, 0
    
MaskedLoop:
    ; Save cursor position
    mov ah, 03h
    mov bh, 0
    int 10h
    push dx
    
    ; Run animation
    call ContinuousBackgroundAnimation
    
    ; Restore cursor position
    pop dx
    mov ah, 02h
    mov bh, 0
    int 10h
    
    ; Check for keyboard input
    mov ah, 0Bh
    int 21h
    cmp al, 0
    je MaskedLoop
    
    ; Get the key
    mov ah, 08h
    int 21h
    cmp al, 13          ; Enter
    je MaskedDone
    cmp al, 8           ; Backspace
    je HandleMaskedBackspace
    cmp cx, 19
    jae MaskedLoop
    
    mov [si], al
    inc si
    inc cx
    mov dl, '*'
    mov ah, 02h
    int 21h
    jmp MaskedLoop
    
HandleMaskedBackspace:
    cmp cx, 0
    je MaskedLoop
    dec si
    dec cx
    mov byte ptr [si], 0
    mov dl, 8
    mov ah, 02h
    int 21h
    mov dl, ' '
    mov ah, 02h
    int 21h
    mov dl, 8
    mov ah, 02h
    int 21h
    jmp MaskedLoop
    
MaskedDone:
    mov byte ptr [si], 0
    pop bx
    ret

;--------------------------------------------------
; Show menu with animation
;--------------------------------------------------
ShowMenuWithAnimation:
    call NewLine
    lea dx, msgMenu
    call PrintString
    
MenuLoop:
    ; Save cursor position
    mov ah, 03h
    mov bh, 0
    int 10h
    push dx
    
    ; Run animation
    call ContinuousBackgroundAnimation
    
    ; Restore cursor position
    pop dx
    mov ah, 02h
    mov bh, 0
    int 10h
    
    ; Check for keyboard input
    mov ah, 0Bh
    int 21h
    cmp al, 0
    je MenuLoop
    
    ; Get the key
    mov ah, 01h
    int 21h
    
    cmp al, '3'
    je DoLogout
    
    ; Handle other menu options
    call NewLine
    lea dx, msgPress
    call PrintString
    call WaitKeyWithAnimation
    ret

DoLogout:
    lea dx, msgLogout
    call PrintString
    call WaitKeyWithAnimation
    call ClearAllExceptBanner
    mov byte ptr [attemptCount], 0
    ret

;--------------------------------------------------
; Clear all except banner
;--------------------------------------------------
ClearAllExceptBanner:
    push ax
    push bx
    push cx
    push dx
    
    mov dh, 7
    mov cx, 18
    
ClearAllLoop:
    push cx
    push dx
    
    mov ah, 02h
    mov bh, 0
    mov dl, 0
    int 10h
    
    push cx
    mov cx, 80
    mov al, ' '
ClearAllRowLoop:
    mov ah, 0Eh
    mov bh, 0
    int 10h
    loop ClearAllRowLoop
    pop cx
    
    pop dx
    pop cx
    inc dh
    loop ClearAllLoop
    
    pop dx
    pop cx
    pop bx
    pop ax
    ret

;--------------------------------------------------
; Wait for key with animation
;--------------------------------------------------
WaitKeyWithAnimation:
WaitLoop:
    ; Save cursor position
    mov ah, 03h
    mov bh, 0
    int 10h
    push dx
    
    ; Run animation
    call ContinuousBackgroundAnimation
    
    ; Restore cursor position
    pop dx
    mov ah, 02h
    mov bh, 0
    int 10h
    
    ; Check for keyboard input
    mov ah, 0Bh
    int 21h
    cmp al, 0
    je WaitLoop
    
    ; Get the key
    mov ah, 08h
    int 21h
    ret

;--------------------------------------------------
; Delay with animation
;--------------------------------------------------
DelayWithAnimation:
    push cx
    mov cx, 30
    
DelayLoop:
    push cx
    call ContinuousBackgroundAnimation
    call delay_frame
    pop cx
    loop DelayLoop
    
    pop cx
    ret

;--------------------------------------------------
; File validation functions
;--------------------------------------------------
ValidateLogin:
    ; Open file for reading
    mov ah, 3Dh
    mov al, 0
    lea dx, filename
    int 21h
    jc FileError
    
    mov [filehandle], ax
    
    ; Read file content
    mov ah, 3Fh
    mov bx, [filehandle]
    mov cx, 100
    lea dx, buffer
    int 21h
    jc FileError
    
    ; Close file
    mov ah, 3Eh
    mov bx, [filehandle]
    int 21h
    
    ; Parse and check credentials
    call ParseAndCheck
    ret

FileError:
    lea dx, msgFileError
    call PrintString
    mov al, 0
    ret

ParseAndCheck:
    lea si, buffer
    
ParseLoop:
    cmp byte ptr [si], 0
    je ParseFailed
    
    call SkipWhitespace
    cmp byte ptr [si], 0
    je ParseFailed
    
    call ClearFileCredentials
    
    ; Parse username
    lea di, fileUser
    call ParseWord
    cmp byte ptr [fileUser], 0
    je ParseFailed
    
    ; Skip spaces
    call SkipSpaces
    
    ; Parse password
    lea di, filePass
    call ParseWord
    cmp byte ptr [filePass], 0
    je NextLine
    
    ; Compare credentials
    push si
    
    lea si, inputUser
    lea di, fileUser
    call StrCompare
    cmp al, 1
    jne NextCredential
    
    lea si, inputPass
    lea di, filePass
    call StrCompare
    cmp al, 1
    jne NextCredential
    
    pop si
    mov al, 1
    ret
    
NextCredential:
    pop si
    
NextLine:
    call SkipToNextLine
    jmp ParseLoop
    
ParseFailed:
    mov al, 0
    ret

ClearFileCredentials:
    push ax
    push cx
    push di
    
    lea di, fileUser
    mov cx, 20
    mov al, 0
    rep stosb
    
    lea di, filePass
    mov cx, 20
    mov al, 0
    rep stosb
    
    pop di
    pop cx
    pop ax
    ret

ParseWord:
    push cx
    mov cx, 0
    
ParseWordLoop:
    mov al, [si]
    cmp al, 0
    je ParseWordDone
    cmp al, 13
    je ParseWordDone
    cmp al, 10
    je ParseWordDone
    cmp al, ' '
    je ParseWordDone
    cmp al, 9
    je ParseWordDone
    
    mov [di], al
    inc si
    inc di
    inc cx
    cmp cx, 19
    jb ParseWordLoop
    
ParseWordDone:
    mov byte ptr [di], 0
    pop cx
    ret

SkipWhitespace:
    push ax
SkipWhitespaceLoop:
    mov al, [si]
    cmp al, 0
    je SkipWhitespaceDone
    cmp al, ' '
    je SkipWhitespaceChar
    cmp al, 9
    je SkipWhitespaceChar
    cmp al, 13
    je SkipWhitespaceChar
    cmp al, 10
    je SkipWhitespaceChar
    jmp SkipWhitespaceDone
    
SkipWhitespaceChar:
    inc si
    jmp SkipWhitespaceLoop
    
SkipWhitespaceDone:
    pop ax
    ret

SkipSpaces:
    push ax
SkipSpacesLoop:
    mov al, [si]
    cmp al, ' '
    je SkipSpace
    cmp al, 9
    je SkipSpace
    jmp SkipSpacesDone
    
SkipSpace:
    inc si
    jmp SkipSpacesLoop
    
SkipSpacesDone:
    pop ax
    ret

SkipToNextLine:
    push ax
SkipNextLoop:
    mov al, [si]
    cmp al, 0
    je SkipNextDone
    inc si
    cmp al, 10
    jne SkipNextLoop
    
SkipNextDone:
    pop ax
    ret

;--------------------------------------------------
; Utility functions
;--------------------------------------------------
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

ClearScreen:
    mov ah, 06h
    mov al, 0
    mov bh, 07h
    mov cx, 0
    mov dx, 184Fh
    int 10h
    
    mov ah, 02h
    mov bh, 0
    mov dx, 0
    int 10h
    ret

end main