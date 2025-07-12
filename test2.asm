; APU Food Store System in TASM - Clean Version
; Features: Login, Menu Display, Ordering, Payment Processing, Inventory Management
.model small
.stack 100h

.data
    ; ===========================================
    ; LOGIN CREDENTIALS
    ; ===========================================
    correctUser     db "admin",0
    correctPass     db "1234",0
    inputUser       db 10 dup(0)
    inputPass       db 10 dup(0)

    ; ===========================================
    ; LOGIN MESSAGES
    ; ===========================================
    msgWelcome      db "=== APU Food Store Login System ===$"
    msgUser         db 13,10,"Username: $"
    msgPass         db 13,10,"Password: $"
    msgSuccess      db 13,10,"Login Successful!$"
    msgFail         db 13,10,"Login Failed. Try again.$"

    ; ===========================================
    ; MAIN MENU MESSAGES
    ; ===========================================
    msgMenuTitle    db 13,10,"=== APU Food Store System ===",13,10,"$"
    msgMenu1        db "1. View Menu",13,10,"$"
    msgMenu2        db "2. Order Food",13,10,"$"
    msgMenu3        db "3. Calculate Total (with Tax)",13,10,"$"
    msgMenu4        db "4. Restock Inventory",13,10,"$"
    msgMenu5        db "5. Logout",13,10,"$"
    msgPrompt       db "Enter your choice: $"
    msgInvalid      db 13,10,"Invalid choice. Try again.",13,10,"$"
    msgLogout       db 13,10,"Logging out...",13,10,"$"

    ; ===========================================
    ; INVENTORY DISPLAY
    ; ===========================================
    header          db 10,"------------------------------------------------------------",13,10
                    db "                   APU Food Store Inventory",13,10
                    db "------------------------------------------------------------",13,10
                    db "ID",9,"Name",9,9,"Qty",9,"Price(RM)",13,10,"$"

    ; ===========================================
    ; FOOD INVENTORY DATA
    ; ===========================================
    FoodNames       db "Burger        ","Hot Dog       ","Fried Chicken ","French Fries  ","Hashbrowns    "
    FoodPrice       dw 4, 8, 7, 5, 7
    FoodQty         dw 15, 10, 20, 5, 18
    FOOD_COUNT      equ 5

    ; ===========================================
    ; ORDER SYSTEM MESSAGES
    ; ===========================================
    msgOrderTitle   db 13,10,"=== Order Food ===",13,10,"$"
    msgSelectFood   db "Enter Food ID (0-4) or 9 to finish: $"
    msgOrderSuccess db 13,10,"Item added to cart!",13,10,"$"
    msgOutOfStock   db 13,10,"Sorry, this item is out of stock!",13,10,"$"
    msgInvalidID    db 13,10,"Invalid Food ID! Please enter 0-4 or 9.",13,10,"$"
    msgNoOrders     db 13,10,"No items in cart!",13,10,"$"

    ; ===========================================
    ; RESTOCK MESSAGES
    ; ===========================================
    msgRestockTitle db 13,10,"=== Restock Inventory ===",13,10,"$"
    msgSelectRestock db "Enter Food ID (0-4) or 9 to finish: $"
    msgRestockQty   db 13,10,"Enter quantity to restock (1-99): $"
    msgRestockSuccess db 13,10,"Successfully added $"
    msgRestockUnits db " units to inventory!",13,10,"$"
    msgRestockInvalid db 13,10,"Invalid Food ID! Please enter 0-4 or 9.",13,10,"$"
    msgRestockQtyInvalid db 13,10,"Invalid quantity! Please enter 1-99.",13,10,"$"

    ; ===========================================
    ; CHECKOUT & PAYMENT MESSAGES
    ; ===========================================
    msgCheckoutTitle db 13,10,"=== Checkout ===",13,10,"$"
    msgCartHeader   db "Your Cart:",13,10,"$"
    msgCartItem     db "Item: $"
    msgQuantity     db " | Qty: $"
    msgItemPrice    db " | Price: RM$"
    msgTotalPrice   db 13,10,"Subtotal: RM$"
    msgTaxAmount    db 13,10,"Tax (6%): RM$"
    msgFinalTotal   db 13,10,"Total Amount: RM$"
    msgThankYou     db 13,10,"Thank you for your order!",13,10,"$"

    msgPaymentPrompt db 13,10,"Enter amount paid in cents (e.g., 3300 for RM33.00): $"
    msgAmountPaid   db 13,10,"Amount Paid: RM$"
    msgChangeAmount db 13,10,"Change: RM$"
    msgInsufficientFunds db 13,10,"Insufficient payment! Please pay at least RM$"
    msgExactPayment db 13,10,"Exact payment received. No change required.",13,10,"$"
    msgPaymentError db 13,10,"Invalid payment amount. Please try again.",13,10,"$"

    ; ===========================================
    ; SYSTEM VARIABLES
    ; ===========================================
    CartItems       db FOOD_COUNT dup(0)    ; Track quantity of each item in cart
    CartTotal       dw 0                     ; Total amount
    PaymentAmount   dw 0                     ; Amount paid by customer
    ChangeAmount    dw 0                     ; Change to give back
    FinalTotalWithTax dw 0                   ; Final total including tax
    TAX_RATE        equ 6                    ; 6% tax rate
    LOW_STOCK_THRESHOLD equ 5                ; Red color when stock < 5

.code
main:
    mov ax, @data
    mov ds, ax
    jmp StartLogin

; ===========================================
; LOGIN SYSTEM
; ===========================================
StartLogin:
    call DisplayWelcome
    call GetCredentials
    call ValidateLogin
    jmp StartLogin

DisplayWelcome:
    lea dx, msgWelcome
    call PrintString
    ret

GetCredentials:
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
    ret

ValidateLogin:
    ; Check username
    lea si, inputUser
    lea di, correctUser
    call StrCompare
    cmp al, 1
    jne LoginFail

    ; Check password
    lea si, inputPass
    lea di, correctPass
    call StrCompare
    cmp al, 1
    jne LoginFail

    ; Login successful
    lea dx, msgSuccess
    call PrintString
    call MainMenu
    ret

LoginFail:
    lea dx, msgFail
    call PrintString
    ret

; ===========================================
; MAIN MENU SYSTEM
; ===========================================
MainMenu:
MenuLoop:
    call DisplayMainMenu
    call GetMenuChoice
    call ProcessMenuChoice
    jmp MenuLoop

DisplayMainMenu:
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
    ret

GetMenuChoice:
    mov ah, 01h
    int 21h
    mov bl, al
    call NewLine
    ret

ProcessMenuChoice:
    cmp bl, '1'
    je ShowFoodMenu
    cmp bl, '2'
    je OrderFood
    cmp bl, '3'
    je CalculateTotal
    cmp bl, '4'
    je RestockInventory
    cmp bl, '5'
    je DoLogout
    
    ; Invalid choice
    lea dx, msgInvalid
    call PrintString
    ret

ShowFoodMenu:
    call DisplayInventory
    ret

OrderFood:
    call ProcessOrdering
    ret

CalculateTotal:
    call ProcessCheckout
    ret

RestockInventory:
    call ProcessRestock
    ret

DoLogout:
    lea dx, msgLogout
    call PrintString
    ret

; ===========================================
; INVENTORY DISPLAY
; ===========================================
DisplayInventory:
    lea dx, header
    call PrintString
    
    mov si, 0
DisplayInventoryLoop:
    cmp si, FOOD_COUNT
    jge DisplayInventoryEnd
    
    call DisplayFoodItem
    inc si
    jmp DisplayInventoryLoop

DisplayInventoryEnd:
    ret

DisplayFoodItem:
    ; Print ID
    mov ax, si
    push si
    call PrintNum
    pop si
    call PrintTab
    
    ; Print Name
    call PrintFoodName
    call PrintTab
    
    ; Print Quantity (with color coding)
    call PrintQuantityWithColor
    call PrintTab
    
    ; Print Price
    call PrintFoodPrice
    call NewLine
    ret

PrintFoodName:
    push si
    mov ax, si
    mov bx, 14
    mul bx
    mov dx, offset FoodNames
    add dx, ax
    call PrintText
    pop si
    ret

PrintQuantityWithColor:
    push si
    mov bx, si
    shl bx, 1
    mov ax, [FoodQty + bx]
    
    ; Check if low stock
    cmp ax, LOW_STOCK_THRESHOLD
    jae NormalQuantityColor
    
    ; Print in red for low stock
    push ax
    mov al, 0Ch         ; Bright red
    call SetTextColor
    pop ax
    call PrintNum
    call ResetTextColor
    jmp QuantityPrinted
    
NormalQuantityColor:
    call PrintNum
    
QuantityPrinted:
    pop si
    ret

PrintFoodPrice:
    push si
    mov bx, si
    shl bx, 1
    mov ax, [FoodPrice + bx]
    call PrintNum
    pop si
    ret

; ===========================================
; ORDERING SYSTEM
; ===========================================
ProcessOrdering:
    lea dx, msgOrderTitle
    call PrintString
    
OrderLoop:
    call DisplayInventory
    call ShowCartSummary
    call GetOrderInput
    
    cmp bl, '9'
    je OrderComplete
    
    call ProcessOrderItem
    jmp OrderLoop

OrderComplete:
    call CheckEmptyCart
    ret

GetOrderInput:
    lea dx, msgSelectFood
    call PrintString
    mov ah, 01h
    int 21h
    mov bl, al
    call NewLine
    ret

ProcessOrderItem:
    ; Validate input
    cmp bl, '0'
    jb InvalidOrderID
    cmp bl, '4'
    ja InvalidOrderID
    
    ; Convert to index
    sub bl, '0'
    mov si, bx
    
    ; Check stock and add to cart
    call CheckStockAndAddToCart
    ret

InvalidOrderID:
    lea dx, msgInvalidID
    call PrintString
    ret

CheckStockAndAddToCart:
    ; Check if item is in stock
    mov bx, si
    shl bx, 1
    mov ax, [FoodQty + bx]
    cmp ax, 0
    je OutOfStock
    
    ; Update inventory
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
    
    ; Show success message
    lea dx, msgOrderSuccess
    call PrintString
    ret

OutOfStock:
    lea dx, msgOutOfStock
    call PrintString
    ret

CheckEmptyCart:
    mov cx, FOOD_COUNT
    mov si, 0
    mov al, 0
    
CheckCartLoop:
    add al, [CartItems + si]
    inc si
    loop CheckCartLoop
    
    cmp al, 0
    je EmptyCart
    ret

EmptyCart:
    lea dx, msgNoOrders
    call PrintString
    ret

ShowCartSummary:
    mov cx, FOOD_COUNT
    mov si, 0
    mov bl, 0
    
CountCartItems:
    add bl, [CartItems + si]
    inc si
    loop CountCartItems
    
    cmp bl, 0
    je NoCartItems
    
    call NewLine
    call PrintCartSummary
    ret

NoCartItems:
    ret

PrintCartSummary:
    mov dx, offset CartSummaryText
    call PrintString
    mov al, bl
    mov ah, 0
    call PrintNum
    mov dx, offset ItemsText
    call PrintString
    mov ax, [CartTotal]
    call PrintNum
    call NewLine
    ret

CartSummaryText db "Cart: $"
ItemsText db " items | Total: RM$"

; ===========================================
; RESTOCK SYSTEM
; ===========================================
ProcessRestock:
    lea dx, msgRestockTitle
    call PrintString
    
RestockLoop:
    call DisplayInventory
    call GetRestockInput
    
    cmp bl, '9'
    je RestockComplete
    
    call ProcessRestockItem
    jmp RestockLoop

RestockComplete:
    ret

GetRestockInput:
    lea dx, msgSelectRestock
    call PrintString
    mov ah, 01h
    int 21h
    mov bl, al
    call NewLine
    ret

ProcessRestockItem:
    ; Validate input
    cmp bl, '0'
    jb InvalidRestockID
    cmp bl, '4'
    ja InvalidRestockID
    
    ; Convert to index
    sub bl, '0'
    mov si, bx
    
    call AddRestockQuantity
    ret

InvalidRestockID:
    lea dx, msgRestockInvalid
    call PrintString
    ret

AddRestockQuantity:
    ; Show current stock
    push si
    mov bx, si
    shl bx, 1
    mov ax, [FoodQty + bx]
    mov dx, offset CurrentStockText
    call PrintString
    call PrintNum
    call NewLine
    pop si
    
    ; Get restock quantity
    lea dx, msgRestockQty
    call PrintString
    call GetRestockQuantity
    
    cmp ax, 0
    je InvalidRestockQty
    
    ; Add to inventory
    push ax
    mov bx, si
    shl bx, 1
    mov dx, [FoodQty + bx]
    add dx, ax
    mov [FoodQty + bx], dx
    
    ; Show success message
    lea dx, msgRestockSuccess
    call PrintString
    pop ax
    call PrintNum
    lea dx, msgRestockUnits
    call PrintString
    ret

InvalidRestockQty:
    lea dx, msgRestockQtyInvalid
    call PrintString
    ret

CurrentStockText db "Current stock: $"

GetRestockQuantity:
    push bx
    push cx
    push dx
    
    mov ax, 0
    mov bx, 10
    mov cx, 0
    
GetRestockLoop:
    mov ah, 01h
    int 21h
    
    cmp al, 13
    je RestockQtyDone
    
    cmp al, '0'
    jb InvalidRestockInput
    cmp al, '9'
    ja InvalidRestockInput
    
    ; Convert and accumulate
    sub al, '0'
    mov dl, al
    mov al, cl
    mul bl
    jc InvalidRestockInput
    add al, dl
    jc InvalidRestockInput
    cmp al, 99
    ja InvalidRestockInput
    mov cl, al
    
    jmp GetRestockLoop

RestockQtyDone:
    mov ax, cx
    cmp ax, 0
    je InvalidRestockInput
    jmp RestockQtyReturn

InvalidRestockInput:
    mov ax, 0

RestockQtyReturn:
    pop dx
    pop cx
    pop bx
    ret

; ===========================================
; CHECKOUT & PAYMENT SYSTEM
; ===========================================
ProcessCheckout:
    lea dx, msgCheckoutTitle
    call PrintString
    
    ; Check if cart is empty
    call CheckEmptyCart
    call DisplayCartContents
    call ShowCheckoutTotals
    call ProcessPayment
    call ClearCart
    
    lea dx, msgThankYou
    call PrintString
    ret

DisplayCartContents:
    lea dx, msgCartHeader
    call PrintString
    call NewLine
    
    mov si, 0
DisplayCartLoop:
    cmp si, FOOD_COUNT
    jge DisplayCartEnd
    
    mov al, [CartItems + si]
    cmp al, 0
    je NextCartItem
    
    call DisplayCartItem
    
NextCartItem:
    inc si
    jmp DisplayCartLoop
    
DisplayCartEnd:
    ret

DisplayCartItem:
    ; Print item details
    lea dx, msgCartItem
    call PrintString
    call PrintFoodName
    
    lea dx, msgQuantity
    call PrintString
    mov al, [CartItems + si]
    mov ah, 0
    push si
    call PrintNum
    pop si
    
    lea dx, msgItemPrice
    call PrintString
    call PrintFoodPrice
    
    ; Print item total
    call PrintCartItemTotal
    call NewLine
    ret

PrintCartItemTotal:
    mov dx, offset ItemTotalText
    call PrintString
    
    ; Calculate item total
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

ItemTotalText db " (Total: RM$"

ShowCheckoutTotals:
    ; Subtotal
    lea dx, msgTotalPrice
    call PrintString
    mov ax, [CartTotal]
    mov bx, 100
    mul bx
    call PrintDecimalFixed
    call NewLine
    
    ; Tax
    lea dx, msgTaxAmount
    call PrintString
    mov ax, [CartTotal]
    mov bx, TAX_RATE
    mul bx
    call PrintDecimalFixed
    call NewLine
    
    ; Final total
    lea dx, msgFinalTotal
    call PrintString
    mov ax, [CartTotal]
    mov bx, 106           ; 100% + 6% tax
    mul bx
    call PrintDecimalFixed
    call NewLine
    ret

ProcessPayment:
    ; Calculate final total with tax
    mov ax, [CartTotal]
    mov bx, 106
    mul bx
    mov [FinalTotalWithTax], ax
    
PaymentLoop:
    call GetPaymentAmount
    cmp ax, 0
    je PaymentError
    
    mov [PaymentAmount], ax
    
    ; Check if sufficient
    mov ax, [PaymentAmount]
    cmp ax, [FinalTotalWithTax]
    jb InsufficientPayment
    
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

GetPaymentAmount:
    lea dx, msgPaymentPrompt
    call PrintString
    
    push bx
    push cx
    push dx
    
    mov ax, 0
    mov bx, 10
    mov cx, 0
    
GetPaymentLoop:
    mov ah, 01h
    int 21h
    
    cmp al, 13
    je PaymentInputDone
    
    cmp al, '0'
    jb InvalidPaymentInput
    cmp al, '9'
    ja InvalidPaymentInput
    
    ; Convert and accumulate
    sub al, '0'
    mov dl, al
    mov ax, cx
    mul bx
    jc InvalidPaymentInput
    add ax, dx
    jc InvalidPaymentInput
    mov cx, ax
    
    jmp GetPaymentLoop

PaymentInputDone:
    mov ax, cx
    jmp PaymentInputReturn

InvalidPaymentInput:
    mov ax, 0

PaymentInputReturn:
    pop dx
    pop cx
    pop bx
    ret

ShowPaymentDetails:
    ; Amount paid
    lea dx, msgAmountPaid
    call PrintString
    mov ax, [PaymentAmount]
    call PrintDecimalFixed
    call NewLine
    
    ; Calculate change
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

ClearCart:
    mov cx, FOOD_COUNT
    mov si, 0
    
ClearCartLoop:
    mov byte ptr [CartItems + si], 0
    inc si
    loop ClearCartLoop
    
    mov word ptr [CartTotal], 0
    ret

; ===========================================
; UTILITY FUNCTIONS
; ===========================================

; Input Functions
GetInput:
    mov cx, 0
GetInputLoop:
    mov ah, 1
    int 21h
    cmp al, 13
    je GetInputDone
    mov [bx], al
    inc bx
    inc cx
    jmp GetInputLoop
GetInputDone:
    mov al, 0
    mov [bx], al
    ret

GetMaskedInput:
    mov cx, 0
MaskedInputLoop:
    mov ah, 08h
    int 21h
    cmp al, 13
    je MaskedInputDone
    mov [bx], al
    inc bx
    inc cx
    mov dl, '*'
    mov ah, 02h
    int 21h
    jmp MaskedInputLoop
MaskedInputDone:
    mov al, 0
    mov [bx], al
    ret

; String Functions
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

; Display Functions
PrintString:
    mov ah, 09h
    int 21h
    ret

PrintText:
    push dx
    push si
    mov si, dx
    mov cx, 14
PrintTextLoop:
    lodsb
    mov dl, al
    mov ah, 02h
    int 21h
    loop PrintTextLoop
    pop si
    pop dx
    ret

PrintNum:
    push ax
    push cx
    push dx
    xor cx, cx
NextDigit:
    xor dx, dx
    mov bx, 10
    div bx
    push dx
    inc cx
    test ax, ax
    jnz NextDigit
PrintLoop:
    pop dx
    add dl, '0'
    mov ah, 02h
    int 21h
    loop PrintLoop
    pop dx
    pop cx
    pop ax
    ret

PrintDecimalFixed:
    push ax
    push cx
    push dx
    
    ; ax contains value in cents
    mov bx, 100
    xor dx, dx
    div bx              ; ax = dollars, dx = cents
    
    ; Print dollar part
    push dx
    call PrintNum
    
    ; Print decimal point
    mov dl, '.'
    mov ah, 02h
    int 21h
    
    ; Print cents (always 2 digits)
    pop ax
    mov bl, 10
    xor ah, ah
    div bl              ; al = tens, ah = ones
    
    push ax
    add al, '0'
    mov dl, al
    mov ah, 02h
    int 21h
    
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

SetTextColor:
    push ax
    push bx
    mov ah, 09h
    mov bh, 0
    mov bl, al
    mov cx, 1
    int 10h
    pop bx
    pop ax
    ret

ResetTextColor:
    push ax
    mov al, 07h
    call SetTextColor
    pop ax
    ret

end main