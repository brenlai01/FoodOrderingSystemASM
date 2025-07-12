; Simple Login System with File Reading in TASM - Fixed Backspace
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
    
    ; Messages
    msgWelcome db "=== File-Based Login System ===$"
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
    lea dx, msgWelcome
    call PrintString

StartLogin:
    ; Get username
    lea dx, msgUser
    call PrintString
    lea bx, inputUser
    call GetInput

    ; Get password (masked)
    lea dx, msgPass
    call PrintString
    lea bx, inputPass
    call GetMaskedInput

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
    
    ; Continue to next attempt
    jmp StartLogin

LoginSuccess:
    lea dx, msgSuccess
    call PrintString
    call ShowMenu
    jmp StartLogin

AccountLocked:
    lea dx, msgLockout
    call PrintString
    ; Exit program
    mov ah, 4Ch
    int 21h

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
    ; Skip to next line if current character is newline
    cmp byte ptr [si], 0
    je ParseFailed
    cmp byte ptr [si], 10
    je NextLine
    cmp byte ptr [si], 13
    je NextLine
    
    ; Parse username from current line
    lea di, fileUser
    call ParseToken
    
    ; Parse password from current line
    lea di, filePass
    call ParseToken
    
    ; Compare credentials
    lea si, inputUser
    lea di, fileUser
    call StrCompare
    cmp al, 1
    jne NextCredential
    
    lea si, inputPass
    lea di, filePass
    call StrCompare
    cmp al, 1
    je ParseSuccess
    
NextCredential:
    ; Move to next line
    call SkipToNextLine
    jmp ParseLoop

NextLine:
    inc si
    jmp ParseLoop
    
ParseSuccess:
    mov al, 1
    ret
    
ParseFailed:
    mov al, 0
    ret

; Function to parse a token (username or password) from file
ParseToken:
    push di
    mov cx, 0
ParseTokenLoop:
    mov al, [si]
    cmp al, ' '         ; Space separator
    je ParseTokenDone
    cmp al, 9           ; Tab separator
    je ParseTokenDone
    cmp al, 13          ; Carriage return
    je ParseTokenDone
    cmp al, 10          ; Line feed
    je ParseTokenDone
    cmp al, 0           ; End of buffer
    je ParseTokenDone
    
    mov [di], al
    inc si
    inc di
    inc cx
    cmp cx, 19          ; Limit token length
    jb ParseTokenLoop
    
ParseTokenDone:
    mov byte ptr [di], 0    ; Null terminate
    ; Skip whitespace
    cmp byte ptr [si], ' '
    je SkipSpace
    cmp byte ptr [si], 9
    je SkipSpace
    jmp ParseTokenExit
    
SkipSpace:
    inc si
    
ParseTokenExit:
    pop di
    ret

; Function to skip to next line
SkipToNextLine:
SkipLoop:
    mov al, [si]
    cmp al, 0
    je SkipDone
    cmp al, 10
    je SkipDone
    inc si
    jmp SkipLoop
SkipDone:
    cmp byte ptr [si], 10
    jne SkipExit
    inc si
SkipExit:
    ret

; Function to show main menu
ShowMenu:
    call NewLine
    lea dx, msgMenu
    call PrintString
    
    mov ah, 01h
    int 21h
    
    cmp al, '3'
    je DoLogout
    
    ; Handle other menu options here
    call NewLine
    lea dx, msgPress
    call PrintString
    call WaitKey
    ret

DoLogout:
    lea dx, msgLogout
    call PrintString
    call WaitKey
    ret

; Utility Functions - FIXED VERSION
GetInput:
    push bx             ; Save original buffer pointer
    mov si, bx          ; Use SI to track current position
    mov cx, 0           ; Character counter
GetInputLoop:
    mov ah, 08h         ; Get character without echo (like password input)
    int 21h
    cmp al, 13          ; Enter key
    je GetInputDone
    cmp al, 8           ; Backspace key
    je HandleBackspace
    cmp cx, 19          ; Limit input length
    jae GetInputLoop
    mov [si], al        ; Store character
    inc si
    inc cx
    ; Display the character (since we're using non-echo input)
    mov dl, al
    mov ah, 02h
    int 21h
    jmp GetInputLoop
    
HandleBackspace:
    cmp cx, 0           ; Check if buffer is empty
    je GetInputLoop     ; If empty, ignore backspace
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
    jmp GetInputLoop
    
GetInputDone:
    mov byte ptr [si], 0 ; Null terminate
    pop bx              ; Restore original buffer pointer
    ret

GetMaskedInput:
    push bx             ; Save original buffer pointer
    mov si, bx          ; Use SI to track current position
    mov cx, 0           ; Character counter
MaskedLoop:
    mov ah, 08h         ; Get character without echo
    int 21h
    cmp al, 13          ; Enter key
    je MaskedDone
    cmp al, 8           ; Backspace key
    je HandleMaskedBackspace
    cmp cx, 19          ; Limit input length
    jae MaskedLoop
    mov [si], al        ; Store character
    inc si
    inc cx
    mov dl, '*'         ; Show asterisk
    mov ah, 02h
    int 21h
    jmp MaskedLoop
    
HandleMaskedBackspace:
    cmp cx, 0           ; Check if buffer is empty
    je MaskedLoop       ; If empty, ignore backspace
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
    jmp MaskedLoop
    
MaskedDone:
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

WaitKey:
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

end main

; Instructions for creating users.txt file:
; Create a text file named "users.txt" in the same directory as your program
; Format each line as: username password
; Example content:
; admin 1234
; user1 pass123
; john secret
; mary mypass