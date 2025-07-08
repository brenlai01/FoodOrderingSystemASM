; APU Food Store System in TASM - Login + Menu + Food List Display (No Decimal)
.model small
.stack 100h

.data
    correctUser db "admin",0
    correctPass db "1234",0
    inputUser db 10 dup(0)
    inputPass db 10 dup(0)

    ; Menu messages
    msgWelcome db "=== Login System ===$"
    msgUser db 13,10,"Username: $"
    msgPass db 13,10,"Password: $"
    msgSuccess db 13,10,"Login Successful!$"
    msgFail db 13,10,"Login Failed. Try again.$"

    msgMenuTitle db 13,10, "=== APU Food Store System ===", 13,10, "$"
    msgMenu1 db "1. View Menu", 13,10, "$"
    msgMenu2 db "2. Order Food", 13,10, "$"
    msgMenu3 db "3. Calculate Total (with Tax)", 13,10, "$"
    msgMenu4 db "4. Restock", 13,10, "$"
    msgMenu5 db "5. Logout", 13,10, "$"
    msgPrompt db "Enter your choice: $"
    msgInvalid db 13,10, "Invalid choice. Try again.", 13,10, "$"
    msgLogout db 13,10, "Logging out to login screen...", 13,10, "$"

    header db 10, "------------------------------------------------------------", 13,10
       db "                   Fast Food Inventory               ",13,10
       db "------------------------------------------------------------",13,10
       db "ID",9, "Name",9,9, "Qty",9, "Price(RM)",13,10, "$"

    ; Food items
    FoodNames db "Burger        ",  "Hot Dog       ", "Fried Chicken ", "French Fries  ", "Hashbrowns    "
    FoodPrice dw 4, 8, 7, 5, 7
    FoodQty dw 15, 10, 20, 20, 18
    
    ; Order Food
    msgOrderTitle db 13,10, "=== Order Food ===", 13,10, "$"
    msgSelectFood db "Enter Food ID (0-4) or 9 to finish: $"
    msgOrderSuccess db 13,10, "Item added to cart!", 13,10, "$"
    msgOutOfStock db 13,10, "Sorry, this item is out of stock!", 13,10, "$"
    msgInvalidID db 13,10, "Invalid Food ID! Please enter 0-4 or 9.", 13,10, "$"
    msgPressKey db "Press any key to continue...", 13,10, "$"
    msgNoOrders db 13,10, "No items in cart!", 13,10, "$"
    
    ; Restock messages
    msgRestockTitle db 13,10, "=== Restock Inventory ===", 13,10, "$"
    msgSelectRestock db "Enter Food ID (0-4) or 9 to finish: $"
    msgRestockSuccess db 13,10, "Item restocked!", 13,10, "$"
    msgRestockInvalidID db 13,10, "Invalid Food ID! Please enter 0-4 or 9.", 13,10, "$"

    ; Checkout messages
    msgCheckoutTitle db 13,10, "=== Checkout ===", 13,10, "$"
    msgCartHeader db "Your Cart:", 13,10, "$"
    msgCartItem db "Item: $"
    msgQuantity db " | Qty: $"
    msgItemPrice db " | Price: RM$"
    msgTotalPrice db 13,10, "Subtotal: RM$"
    msgTaxAmount db 13,10, "Tax (6%): RM$"
    msgFinalTotal db 13,10, "Total Amount: RM$"
    msgThankYou db 13,10, "Thank you for your order!", 13,10, "$"

    ; Cart tracking arrays
    CartItems db 5 dup(0)      ; Track quantity of each item in cart
    CartTotal dw 0             ; Total amount

    TempSubtotal dw 0
    TempTax dw 0

.code
main:
    mov ax, @data
    mov ds, ax

StartLogin:
    lea dx, msgWelcome
    call PrintString

    lea dx, msgUser
    call PrintString
    lea bx, inputUser
    call GetInput

    lea dx, msgPass
    call PrintString
    lea bx, inputPass
    call GetMaskedInput

    lea si, inputUser
    lea di, correctUser
    call StrCompare
    cmp al, 1
    jne LoginFail

    lea si, inputPass
    lea di, correctPass
    call StrCompare
    cmp al, 1
    jne LoginFail

    lea dx, msgSuccess
    call PrintString
    call MainMenu
    jmp StartLogin

LoginFail:
    lea dx, msgFail
    call PrintString
    jmp StartLogin

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
    jmp DoLogout

InvalidChoice:
    lea dx, msgInvalid
    call PrintString
    jmp MenuLoop

ShowFoodMenu:
    lea dx, header
    call PrintString

    xor si, si  ; si = index

NextItem:
    cmp si, 5
    jge EndShow

    ; === Print ID ===
    mov ax, si
    push si
    call PrintNum
    pop si
    call PrintTab

    ; === Print Name ===
    mov ax, si
    mov bx, 14
    mul bx
    mov dx, offset FoodNames
    add dx, ax
    call PrintText
    call PrintTab

    ; === Print Quantity ===
    mov bx, si
    shl bx, 1
    mov ax, [FoodQty + bx]
    push si
    call PrintNum
    pop si
    call PrintTab

    ; === Print Price ===
    mov bx, si
    shl bx, 1
    mov ax, [FoodPrice + bx]
    push si
    call PrintNum
    pop si
    call NewLine

    inc si
    jmp NextItem

EndShow:
    jmp MenuLoop

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

; FUNCTION TO ADD RESTOCK ITEM
AddRestockItem:
    ; Add 10 units to inventory
    mov bx, si
    shl bx, 1
    mov ax, [FoodQty + bx]
    add ax, 10           ; Add 10 units
    mov [FoodQty + bx], ax
    
    ; Show success message
    lea dx, msgRestockSuccess
    call PrintString
    ret

DoLogout:
    lea dx, msgLogout
    call PrintString
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

; CHECKOUT FUNCTION (REPLACES CalculateTotal)
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
    call ClearCart
    
    lea dx, msgThankYou
    call PrintString
    ret

NoItemsCheckout:
    lea dx, msgNoOrders
    call PrintString
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
    mov dl, ' '
    mov ah, 02h
    int 21h
    mov dl, '('
    mov ah, 02h
    int 21h
    
    ; Print "Total: RM"
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

; FUNCTION TO SHOW CHECKOUT TOTAL WITH TAX - COMPLETELY REWRITTEN
ShowCheckoutTotalDecimal:
    ; Show subtotal with decimals
    lea dx, msgTotalPrice
    call PrintString
    mov ax, [CartTotal]
    mov bx, 100          ; Convert to cents
    mul bx               ; ax = CartTotal * 100 (in cents)
    mov [TempSubtotal], ax  ; Store subtotal in cents
    call PrintDecimalFixed
    call NewLine
    
    ; Calculate tax (6% of CartTotal)
    ; Tax = (CartTotal * 6) cents 
    mov ax, [CartTotal]
    mov bx, 6
    mul bx              ; ax = CartTotal * 6 (this is 6% in cents)
    mov [TempTax], ax   ; Store tax in cents
    
    ; Show tax amount
    lea dx, msgTaxAmount
    call PrintString
    mov ax, [TempTax]
    call PrintDecimalFixed
    call NewLine
    
    ; Calculate final total: subtotal_cents + tax_cents
    mov ax, [TempSubtotal]  ; Get subtotal in cents
    add ax, [TempTax]       ; Add tax in cents
    
    ; Show final total
    lea dx, msgFinalTotal
    call PrintString
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

; HELPER FUNCTIONS FOR CART SUMMARY
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

; DISPLAY ALL ITEMS FUNCTION (NO CHANGES)
DisplayAllItems:
    xor si, si
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
    
; ========== Utility Functions ==========

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

; FUNCTION TO PRINT DECIMAL NUMBER (2 decimal places) - FIXED VERSION
PrintDecimalFixed:
    push ax
    push bx
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
    pop ax              ; Get cents back into ax
    
    ; Print tens digit of cents
    mov bl, 10
    mov ah, 0           ; Clear high byte properly
    div bl              ; al = tens digit, ah = ones digit
    
    ; Print tens digit
    push ax             ; Save both digits
    add al, '0'         ; Convert tens digit to ASCII
    mov dl, al
    mov ah, 02h
    int 21h
    
    ; Print ones digit
    pop ax
    mov al, ah          ; Get ones digit from ah
    add al, '0'         ; Convert ones digit to ASCII
    mov dl, al
    mov ah, 02h
    int 21h
    
    pop dx
    pop cx
    pop bx
    pop ax
    ret

end main