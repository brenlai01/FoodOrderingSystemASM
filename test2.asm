; APU Food Store System in TASM - Fixed Jump Range Issues
; Features: Login, Menu Display, Ordering, Payment with Decimal Support, Restocking
.model small
.stack 100h

.data
    ; ========== LOGIN CREDENTIALS ==========
    correctUser db "admin",0
    correctPass db "1234",0
    inputUser db 10 dup(0)
    inputPass db 10 dup(0)

    ; ========== LOGIN MESSAGES ==========
    msgWelcome db "=== Login System ===$"
    msgUser db 13,10,"Username: $"
    msgPass db 13,10,"Password: $"
    msgSuccess db 13,10,"Login Successful!$"
    msgFail db 13,10,"Login Failed. Try again.$"

    ; ========== MAIN MENU MESSAGES ==========
    msgMenuTitle db 13,10, "=== APU Food Store System ===", 13,10, "$"
    msgMenu1 db "1. View Menu", 13,10, "$"
    msgMenu2 db "2. Order Food", 13,10, "$"
    msgMenu3 db "3. Calculate Total (with Tax)", 13,10, "$"
    msgMenu4 db "4. Restock", 13,10, "$"
    msgMenu5 db "5. Logout", 13,10, "$"
    msgPrompt db "Enter your choice: $"
    msgInvalid db 13,10, "Invalid choice. Try again.", 13,10, "$"
    msgLogout db 13,10, "Logging out to login screen...", 13,10, "$"

    ; ========== INVENTORY DISPLAY ==========
    header db 10, "------------------------------------------------------------", 13,10
           db "                   Fast Food Inventory               ",13,10
           db "------------------------------------------------------------",13,10
           db "ID",9, "Name",9,9, "Qty",9, "Price(RM)",13,10, "$"

    ; ========== FOOD INVENTORY ==========
    FoodNames db "Burger        ",  "Hot Dog       ", "Fried Chicken ", "French Fries  ", "Hashbrowns    "
    FoodPrice dw 4, 8, 7, 5, 7
    FoodQty dw 15, 10, 20, 20, 18
    
    ; ========== ORDERING MESSAGES ==========
    msgOrderTitle db 13,10, "=== Order Food ===", 13,10, "$"
    msgSelectFood db "Enter Food ID (0-4) or 9 to finish: $"
    msgOrderSuccess db 13,10, "Item added to cart!", 13,10, "$"
    msgOutOfStock db 13,10, "Sorry, this item is out of stock!", 13,10, "$"
    msgInvalidID db 13,10, "Invalid Food ID! Please enter 0-4 or 9.", 13,10, "$"
    msgNoOrders db 13,10, "No items in cart!", 13,10, "$"
    
    ; ========== RESTOCK MESSAGES ==========
    msgRestockTitle db 13,10, "=== Restock Inventory ===", 13,10, "$"
    msgSelectRestock db "Enter Food ID (0-4) or 9 to finish: $"
    msgRestockSuccess db 13,10, "Item restocked!", 13,10, "$"
    msgRestockInvalidID db 13,10, "Invalid Food ID! Please enter 0-4 or 9.", 13,10, "$"

    ; ========== CHECKOUT MESSAGES ==========
    msgCheckoutTitle db 13,10, "=== Checkout ===", 13,10, "$"
    msgCartHeader db "Your Cart:", 13,10, "$"
    msgCartItem db "Item: $"
    msgQuantity db " | Qty: $"
    msgItemPrice db " | Price: RM$"
    msgTotalPrice db 13,10, "Subtotal: RM$"
    msgTaxAmount db 13,10, "Tax (6%): RM$"
    msgFinalTotal db 13,10, "Total Amount: RM$"
    
    ; ========== PAYMENT MESSAGES ==========
    msgPaymentPrompt db 13,10, "Enter amount paid by customer: RM$"
    msgAmountPaid db 13,10, "Amount Paid: RM$"
    msgChangeAmount db 13,10, "Change: RM$"
    msgInsufficientFunds db 13,10, "Insufficient payment! Please collect more money.", 13,10, "$"
    msgExactAmount db 13,10, "Exact amount paid. No change required.", 13,10, "$"
    msgThankYou db 13,10, "Thank you for your order!", 13,10, "$"
    msgReceiptComplete db 13,10, "Transaction completed successfully!", 13,10, "$"
    msgPressKey db "Press any key to continue...", 13,10, "$"

    ; ========== CART AND PAYMENT VARIABLES ==========
    CartItems db 5 dup(0)      ; Track quantity of each item in cart
    CartTotal dw 0             ; Total amount
    FinalTotal dw 0            ; Total with tax (in cents)
    AmountPaid dw 0            ; Amount paid by customer (in cents)
    ChangeAmount dw 0          ; Change to give back
    inputBuffer db 10 dup(0)   ; Buffer for decimal input

.code
main:
    mov ax, @data
    mov ds, ax

; ========== LOGIN SYSTEM ==========
StartLogin:
    lea dx, msgWelcome
    call PrintString

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

    ; Validate username
    lea si, inputUser
    lea di, correctUser
    call StrCompare
    cmp al, 1
    jne LoginFail

    ; Validate password
    lea si, inputPass
    lea di, correctPass
    call StrCompare
    cmp al, 1
    jne LoginFail

    ; Login successful
    lea dx, msgSuccess
    call PrintString
    call MainMenu
    jmp StartLogin

LoginFail:
    lea dx, msgFail
    call PrintString
    jmp StartLogin

; ========== MAIN MENU SYSTEM ==========
MainMenu:
MenuLoop:
    ; Display menu options
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

    ; Get user choice
    mov ah, 01h
    int 21h
    mov bl, al
    call NewLine

    ; Process menu choice - Fixed jump range issues
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
    jmp DoLogout

InvalidChoice:
    ; Invalid choice
    lea dx, msgInvalid
    call PrintString
    jmp MenuLoop

; ========== MENU DISPLAY ==========
ShowFoodMenu:
    lea dx, header
    call PrintString
    call DisplayAllItems
    jmp MenuLoop

; ========== ORDERING SYSTEM ==========
OrderFood:
    lea dx, msgOrderTitle
    call PrintString
    call OrderFoodLoop
    jmp MenuLoop

OrderFoodLoop:
    ; Display inventory and cart
    lea dx, header
    call PrintString
    call DisplayAllItems
    call ShowCartSummary
    
    ; Get food selection
    lea dx, msgSelectFood
    call PrintString
    
    mov ah, 01h
    int 21h
    mov bl, al
    call NewLine
    
    ; Check if finished ordering
    cmp bl, '9'
    je OrderFinish
    
    ; Process order
    call ProcessOrder
    jmp OrderFoodLoop

OrderFinish:
    call CheckEmptyCart
    ret

ProcessOrder:
    ; Validate food ID
    cmp bl, '0'
    jb OrderInvalid
    cmp bl, '4'
    ja OrderInvalid
    
    ; Convert to index
    sub bl, '0'
    mov si, bx
    call CheckStockAndOrder
    ret

OrderInvalid:
    lea dx, msgInvalidID
    call PrintString
    ret

CheckStockAndOrder:
    ; Check if item is in stock
    mov bx, si
    shl bx, 1
    mov ax, [FoodQty + bx]
    cmp ax, 0
    je OrderOutOfStock
    
    ; Decrease stock
    dec ax
    mov [FoodQty + bx], ax
    
    ; Add to cart
    mov bx, si
    inc byte ptr [CartItems + bx]
    
    ; Update total
    mov bx, si
    shl bx, 1
    mov ax, [FoodPrice + bx]
    add [CartTotal], ax
    
    lea dx, msgOrderSuccess
    call PrintString
    ret

OrderOutOfStock:
    lea dx, msgOutOfStock
    call PrintString
    ret

; ========== RESTOCK SYSTEM ==========
Restock:
    lea dx, msgRestockTitle
    call PrintString
    call RestockLoop
    jmp MenuLoop

RestockLoop:
    ; Display current inventory
    lea dx, header
    call PrintString
    call DisplayAllItems
    
    ; Get restock selection
    lea dx, msgSelectRestock
    call PrintString
    
    mov ah, 01h
    int 21h
    mov bl, al
    call NewLine
    
    ; Check if finished restocking
    cmp bl, '9'
    je RestockFinish
    
    call ProcessRestock
    jmp RestockLoop

RestockFinish:
    ret

ProcessRestock:
    ; Validate food ID
    cmp bl, '0'
    jb RestockInvalid
    cmp bl, '4'
    ja RestockInvalid
    
    ; Convert to index and restock
    sub bl, '0'
    mov si, bx
    call AddRestockItem
    ret

RestockInvalid:
    lea dx, msgRestockInvalidID
    call PrintString
    ret

AddRestockItem:
    ; Add 10 units to stock
    mov bx, si
    shl bx, 1
    mov ax, [FoodQty + bx]
    add ax, 10
    mov [FoodQty + bx], ax
    
    lea dx, msgRestockSuccess
    call PrintString
    ret

; ========== CHECKOUT SYSTEM ==========
CalculateTotal:
    lea dx, msgCheckoutTitle
    call PrintString
    call ProcessCheckout
    jmp MenuLoop

ProcessCheckout:
    ; Check if cart is empty
    call CheckEmptyCart
    
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
    
    ; Show completion message
    lea dx, msgThankYou
    call PrintString
    lea dx, msgReceiptComplete
    call PrintString
    ret

; ========== PAYMENT PROCESSING ==========
ProcessPayment:
    ; Get payment amount from cashier
    call GetPaymentAmount
    
    ; Compare payment with total
    mov ax, [AmountPaid]
    mov bx, [FinalTotal]
    
    ; Check if payment is sufficient
    cmp ax, bx
    jb InsufficientPayment
    
    ; Calculate change
    sub ax, bx
    mov [ChangeAmount], ax
    
    ; Display payment details
    call ShowPaymentDetails
    ret

InsufficientPayment:
    lea dx, msgInsufficientFunds
    call PrintString
    jmp ProcessPayment

GetPaymentAmount:
    lea dx, msgPaymentPrompt
    call PrintString
    call GetDecimalInput
    mov [AmountPaid], ax
    ret

; ========== DECIMAL INPUT HANDLING ==========
GetDecimalInput:
    ; Clear input buffer
    mov cx, 10
    mov si, offset inputBuffer
    mov al, 0
ClearDecimalBuffer:
    mov [si], al
    inc si
    loop ClearDecimalBuffer
    
    ; Get string input
    mov si, offset inputBuffer
    mov cx, 0
    
GetDecimalString:
    mov ah, 01h
    int 21h
    
    cmp al, 13              ; Enter key?
    je ConvertDecimalToNumber
    cmp al, '.'             ; Decimal point?
    je StoreDecimalPoint
    cmp al, '0'             ; Valid digit?
    jb GetDecimalString
    cmp al, '9'
    ja GetDecimalString
    
    ; Store valid character
    mov [si], al
    inc si
    inc cx
    cmp cx, 8
    jb GetDecimalString
    jmp GetDecimalString
    
StoreDecimalPoint:
    mov [si], al
    inc si
    inc cx
    cmp cx, 8
    jb GetDecimalString
    
ConvertDecimalToNumber:
    ; Convert string to number in cents
    mov ax, 0               ; Whole part
    mov bx, 0               ; Decimal part
    mov si, offset inputBuffer
    mov dl, 0               ; Decimal flag
    mov cl, 0               ; Decimal digit counter
    
ConvertDecimalLoop:
    mov dh, [si]
    cmp dh, 0
    je DecimalConversionDone
    
    cmp dh, '.'
    je SetDecimalFlag
    
    ; Process valid digits
    cmp dh, '0'
    jb NextDecimalChar
    cmp dh, '9'
    ja NextDecimalChar
    
    sub dh, '0'
    
    cmp dl, 0
    je ProcessWholePart
    
    ; Process decimal digits (first 2 only)
    cmp cl, 0
    je FirstDecimalDigit
    cmp cl, 1
    je SecondDecimalDigit
    jmp NextDecimalChar
    
FirstDecimalDigit:
    mov al, dh
    mov bl, 10
    mul bl
    mov bx, ax
    inc cl
    jmp NextDecimalChar
    
SecondDecimalDigit:
    mov al, dh
    add bx, ax
    inc cl
    jmp NextDecimalChar
    
ProcessWholePart:
    ; Multiply by 10 and add digit
    push dx
    mov dx, 10
    mul dx
    pop dx
    
    push bx
    mov bl, dh
    mov bh, 0
    add ax, bx
    pop bx
    jmp NextDecimalChar
    
SetDecimalFlag:
    mov dl, 1
    mov cl, 0
    jmp NextDecimalChar
    
NextDecimalChar:
    inc si
    jmp ConvertDecimalLoop
    
DecimalConversionDone:
    ; Convert to cents
    push bx
    mov cx, 100
    mul cx
    pop bx
    
    ; Handle single decimal digit
    cmp cl, 1
    je OneDecimalDigit
    jmp AddDecimalPart
    
OneDecimalDigit:
    mov cx, 10
    push ax
    mov ax, bx
    mul cx
    mov bx, ax
    pop ax
    
AddDecimalPart:
    add ax, bx
    ret

; ========== DISPLAY FUNCTIONS ==========
ShowAllCartItems:
    mov si, 0
ShowCartLoop:
    cmp si, 5
    jge ShowCartEnd
    
    mov al, [CartItems + si]
    cmp al, 0
    je NextCartItem
    
    call PrintCartItem
    
NextCartItem:
    inc si
    jmp ShowCartLoop
ShowCartEnd:
    ret

PrintCartItem:
    ; Print item details
    lea dx, msgCartItem
    call PrintString
    
    ; Print item name
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
    
    ; Print unit price
    lea dx, msgItemPrice
    call PrintString
    mov bx, si
    shl bx, 1
    mov ax, [FoodPrice + bx]
    push si
    call PrintNum
    pop si
    
    ; Print item total
    call PrintItemTotal
    call NewLine
    ret

PrintItemTotal:
    ; Print " (Total: RM"
    mov dl, ' '
    mov ah, 02h
    int 21h
    mov dl, '('
    mov ah, 02h
    int 21h
    mov dl, 'T'
    mov ah, 02h
    int 21h
    mov dl, 'o'
    mov ah, 02h
    int 21h
    mov dl, 't'
    mov ah, 02h
    int 21h
    mov dl, 'a'
    mov ah, 02h
    int 21h
    mov dl, 'l'
    mov ah, 02h
    int 21h
    mov dl, ':'
    mov ah, 02h
    int 21h
    mov dl, ' '
    mov ah, 02h
    int 21h
    mov dl, 'R'
    mov ah, 02h
    int 21h
    mov dl, 'M'
    mov ah, 02h
    int 21h
    
    ; Calculate and print total
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

ShowCheckoutTotalDecimal:
    ; Show subtotal
    lea dx, msgTotalPrice
    call PrintString
    mov ax, [CartTotal]
    call PrintNum
    mov dl, '.'
    mov ah, 02h
    int 21h
    mov dl, '0'
    mov ah, 02h
    int 21h
    mov dl, '0'
    mov ah, 02h
    int 21h
    
    ; Calculate and show tax (6%)
    lea dx, msgTaxAmount
    call PrintString
    mov ax, [CartTotal]
    mov bx, 6
    mul bx
    call PrintDecimalFixed
    
    ; Calculate and show final total
    lea dx, msgFinalTotal
    call PrintString
    mov ax, [CartTotal]
    mov bx, 106
    mul bx
    mov [FinalTotal], ax
    call PrintDecimalFixed
    call NewLine
    ret

ShowPaymentDetails:
    call NewLine
    call PrintSeparator
    
    ; Show amount paid
    lea dx, msgAmountPaid
    call PrintString
    mov ax, [AmountPaid]
    call PrintDecimalFixed
    
    ; Show change
    lea dx, msgChangeAmount
    call PrintString
    mov ax, [ChangeAmount]
    
    cmp ax, 0
    je ExactPayment
    
    call PrintDecimalFixed
    call NewLine
    call PrintSeparator
    ret

ExactPayment:
    lea dx, msgExactAmount
    call PrintString
    call PrintSeparator
    ret

ShowCartSummary:
    ; Count total items in cart
    mov cx, 5
    mov si, 0
    mov bl, 0
CountCartItems:
    add bl, [CartItems + si]
    inc si
    loop CountCartItems
    
    cmp bl, 0
    je NoCartSummary
    
    ; Display cart summary
    call NewLine
    call PrintCartSummaryText
    mov al, bl
    mov ah, 0
    call PrintNum
    call PrintItemsText
    call PrintTotalText
    mov ax, [CartTotal]
    call PrintNum
    call NewLine

NoCartSummary:
    ret

DisplayAllItems:
    mov si, 0
DisplayNext:
    cmp si, 5
    jge DisplayEnd
    
    ; Print ID
    mov ax, si
    push si
    call PrintNum
    pop si
    call PrintTab
    
    ; Print Name
    mov ax, si
    mov bx, 14
    mul bx
    mov dx, offset FoodNames
    add dx, ax
    call PrintText
    call PrintTab
    
    ; Print Quantity
    mov bx, si
    shl bx, 1
    mov ax, [FoodQty + bx]
    push si
    call PrintNum
    pop si
    call PrintTab
    
    ; Print Price
    mov bx, si
    shl bx, 1
    mov ax, [FoodPrice + bx]
    push si
    call PrintNum
    pop si
    call NewLine
    
    inc si
    jmp DisplayNext
DisplayEnd:
    call NewLine
    ret

; ========== UTILITY FUNCTIONS ==========
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

ClearCart:
    mov cx, 5
    mov si, 0
ClearCartLoop:
    mov byte ptr [CartItems + si], 0
    inc si
    loop ClearCartLoop
    
    mov word ptr [CartTotal], 0
    mov word ptr [FinalTotal], 0
    mov word ptr [AmountPaid], 0
    mov word ptr [ChangeAmount], 0
    ret

DoLogout:
    lea dx, msgLogout
    call PrintString
    ret

; ========== TEXT DISPLAY HELPERS ==========
PrintCartSummaryText:
    mov dl, 'C'
    mov ah, 02h
    int 21h
    mov dl, 'a'
    mov ah, 02h
    int 21h
    mov dl, 'r'
    mov ah, 02h
    int 21h
    mov dl, 't'
    mov ah, 02h
    int 21h
    mov dl, ':'
    mov ah, 02h
    int 21h
    mov dl, ' '
    mov ah, 02h
    int 21h
    ret

PrintItemsText:
    mov dl, ' '
    mov ah, 02h
    int 21h
    mov dl, 'i'
    mov ah, 02h
    int 21h
    mov dl, 't'
    mov ah, 02h
    int 21h
    mov dl, 'e'
    mov ah, 02h
    int 21h
    mov dl, 'm'
    mov ah, 02h
    int 21h
    mov dl, 's'
    mov ah, 02h
    int 21h
    ret

PrintTotalText:
    mov dl, ' '
    mov ah, 02h
    int 21h
    mov dl, '|'
    mov ah, 02h
    int 21h
    mov dl, ' '
    mov ah, 02h
    int 21h
    mov dl, 'T'
    mov ah, 02h
    int 21h
    mov dl, 'o'
    mov ah, 02h
    int 21h
    mov dl, 't'
    mov ah, 02h
    int 21h
    mov dl, 'a'
    mov ah, 02h
    int 21h
    mov dl, 'l'
    mov ah, 02h
    int 21h
    mov dl, ':'
    mov ah, 02h
    int 21h
    mov dl, ' '
    mov ah, 02h
    int 21h
    mov dl, 'R'
    mov ah, 02h
    int 21h
    mov dl, 'M'
    mov ah, 02h
    int 21h
    ret

PrintSeparator:
    mov cx, 50
    mov dl, '-'
PrintSep_Loop:
    mov ah, 02h
    int 21h
    loop PrintSep_Loop
    call NewLine
    ret

; ========== LOW-LEVEL I/O FUNCTIONS ==========
GetInput:
    mov cx, 0
GetInput_Loop:
    mov ah, 1
    int 21h
    cmp al, 13
    je GetInput_Done
    mov [bx], al
    inc bx
    inc cx
    jmp GetInput_Loop
GetInput_Done:
    mov al, 0
    mov [bx], al
    ret

GetMaskedInput:
    mov cx, 0
MaskedInput_Loop:
    mov ah, 08h
    int 21h
    cmp al, 13
    je MaskedInput_Done
    mov [bx], al
    inc bx
    inc cx
    mov dl, '*'
    mov ah, 02h
    int 21h
    jmp MaskedInput_Loop
MaskedInput_Done:
    mov al, 0
    mov [bx], al
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

PrintTab:
    mov dl, 9
    mov ah, 02h
    int 21h
    ret

NewLine:
    mov dl, 13
    mov ah, 02h
    int 21h
    mov dl, 10
    int 21h
    ret

PrintText:
    push dx
    push si
    mov si, dx
    mov cx, 14
PrintText_Loop:
    lodsb
    mov dl, al
    mov ah, 02h
    int 21h
    loop PrintText_Loop
    pop si
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

PrintDecimalFixed:
    push ax
    push cx
    push dx
    
    ; Separate dollars and cents
    mov bx, 100
    xor dx, dx
    div bx
    
    ; Print dollars
    push dx
    call PrintNum
    
    ; Print decimal point
    mov dl, '.'
    mov ah, 02h
    int 21h
    
    ; Print cents
    pop ax
    mov bl, 10
    xor ah, ah
    div bl
    
    ; Print tens digit
    push ax
    add al, '0'
    mov dl, al
    mov ah, 02h
    int 21h
    
    ; Print units digit
    pop ax
    mov al, ah
    add al, '0'
    mov dl, al
    mov ah, 02h
    int 21h
    
    pop dx
    pop cx
    pop ax
    ret
    
end main