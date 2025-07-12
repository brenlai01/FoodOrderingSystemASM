; Sales Recording and Report Generation Test Program
; This program demonstrates:
; 1. Recording sales to sales.txt in format: DATE:TIME:ITEM_ID:QUANTITY:SUBTOTAL:TAX:TOTAL
; 2. Reading sales.txt and generating report.txt with daily sales summary
.model small
.stack 100h

.data
    ; File names
    salesFile db "sales.txt", 0
    reportFile db "report.txt", 0
    fileHandle dw 0
    
    ; Date/Time variables
    currentDate db 11 dup(0)    ; DD/MM/YYYY format
    currentTime db 9 dup(0)     ; HH:MM:SS format
    
    ; Sample sales data for testing
    testSales db 5 dup(0)       ; Track sales count for each food item
    
    ; Food item names for report
    foodNames db "Burger", 0, "Hot Dog", 0, "Fried Chicken", 0, "French Fries", 0, "Hashbrowns", 0
    foodPrices dw 4, 8, 7, 5, 7
    
    ; Sales recording variables
    salesLine db 100 dup(0)    ; Buffer for sales line
    readBuffer db 1000 dup(0)  ; Buffer for reading file
    
    ; Report generation variables
    dailySales dw 5 dup(0)     ; Daily sales count for each item
    totalRevenue dw 0          ; Total revenue for the day
    
    ; Messages
    msgMenu db "=== Sales Recording Test Program ===", 13, 10
           db "1. Record Sample Sales", 13, 10
           db "2. Generate Daily Report", 13, 10
           db "3. View Sales File", 13, 10
           db "4. View Report File", 13, 10
           db "5. Exit", 13, 10
           db "Choice: $"
    
    msgRecording db "Recording sample sales...", 13, 10, "$"
    msgGenerating db "Generating daily report...", 13, 10, "$"
    msgComplete db "Operation completed!", 13, 10, "$"
    msgError db "Error occurred!", 13, 10, "$"
    msgPress db "Press any key to continue...", 13, 10, "$"
    
    ; Report header
    reportHeader db "=== Daily Sales Report ===", 13, 10
                db "Date: $"
    
    ; Test data messages
    msgTestData db "Recording test sale: Item $"
    msgQuantity db ", Quantity: $"
    msgAmount db ", Amount: RM$"
    
    newline db 13, 10, "$"
    colon db ":$"
    
.code
main:
    mov ax, @data
    mov ds, ax
    
    ; Get current date and time
    call GetCurrentDateTime
    
MainLoop:
    call ClearScreen
    lea dx, msgMenu
    call PrintString
    
    ; Get user choice
    mov ah, 01h
    int 21h
    mov bl, al
    call PrintNewLine
    
    cmp bl, '1'
    je RecordSales
    cmp bl, '2'
    je GenerateReport
    cmp bl, '3'
    je ViewSalesFile
    cmp bl, '4'
    je ViewReportFile
    cmp bl, '5'
    je ExitProgram
    jmp MainLoop

RecordSales:
    lea dx, msgRecording
    call PrintString
    call RecordSampleSales
    lea dx, msgComplete
    call PrintString
    call WaitKey
    jmp MainLoop

GenerateReport:
    lea dx, msgGenerating
    call PrintString
    call GenerateDailyReport
    lea dx, msgComplete
    call PrintString
    call WaitKey
    jmp MainLoop

ViewSalesFile:
    call DisplaySalesFile
    call WaitKey
    jmp MainLoop

ViewReportFile:
    call DisplayReportFile
    call WaitKey
    jmp MainLoop

ExitProgram:
    mov ah, 4Ch
    int 21h

; Function to get current date and time
GetCurrentDateTime:
    ; Get date
    mov ah, 2Ah
    int 21h
    
    ; Format date as DD/MM/YYYY
    lea di, currentDate
    mov al, dl          ; Day
    call ConvertToASCII
    mov byte ptr [di], '/'
    inc di
    mov al, dh          ; Month
    call ConvertToASCII
    mov byte ptr [di], '/'
    inc di
    mov ax, cx          ; Year
    call ConvertYearToASCII
    
    ; Get time
    mov ah, 2Ch
    int 21h
    
    ; Format time as HH:MM:SS
    lea di, currentTime
    mov al, ch          ; Hour
    call ConvertToASCII
    mov byte ptr [di], ':'
    inc di
    mov al, cl          ; Minute
    call ConvertToASCII
    mov byte ptr [di], ':'
    inc di
    mov al, dh          ; Second
    call ConvertToASCII
    
    ret

; Function to convert number to ASCII (2 digits)
ConvertToASCII:
    push ax
    xor ah, ah
    mov bl, 10
    div bl
    add al, '0'
    mov [di], al
    inc di
    add ah, '0'
    mov [di], ah
    inc di
    pop ax
    ret

; Function to convert year to ASCII (4 digits)
ConvertYearToASCII:
    push ax
    push bx
    push cx
    push dx
    
    mov bx, 1000
    xor dx, dx
    div bx
    add al, '0'
    mov [di], al
    inc di
    
    mov ax, dx
    mov bx, 100
    xor dx, dx
    div bx
    add al, '0'
    mov [di], al
    inc di
    
    mov ax, dx
    mov bx, 10
    xor dx, dx
    div bx
    add al, '0'
    mov [di], al
    inc di
    
    add dl, '0'
    mov [di], dl
    inc di
    
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; Function to record sample sales
RecordSampleSales:
    ; Open sales file for append
    mov ah, 3Ch         ; Create file
    mov cx, 0           ; Normal file
    lea dx, salesFile
    int 21h
    jc RecordError
    
    mov [fileHandle], ax
    
    ; Record 5 sample sales
    mov si, 0           ; Item counter
    
RecordLoop:
    cmp si, 5
    jge RecordDone
    
    ; Display what we're recording
    lea dx, msgTestData
    call PrintString
    mov ax, si
    call PrintNumber
    lea dx, msgQuantity
    call PrintString
    mov ax, si
    inc ax              ; Quantity = item_id + 1
    call PrintNumber
    
    ; Calculate amount (price * quantity)
    mov bx, si
    shl bx, 1           ; bx = si * 2
    mov ax, [foodPrices + bx]
    mov dx, si
    inc dx              ; Quantity
    mul dx              ; ax = price * quantity
    
    lea dx, msgAmount
    call PrintString
    call PrintNumber
    call PrintNewLine
    
    ; Create sales line: DATE:TIME:ITEM_ID:QUANTITY:SUBTOTAL:TAX:TOTAL
    call CreateSalesLine
    
    ; Write to file
    mov ah, 40h         ; Write to file
    mov bx, [fileHandle]
    mov cx, 0           ; Calculate string length
    lea dx, salesLine
    call CalculateStringLength
    mov cx, ax          ; String length
    lea dx, salesLine
    int 21h
    
    inc si
    jmp RecordLoop

RecordDone:
    ; Close file
    mov ah, 3Eh
    mov bx, [fileHandle]
    int 21h
    ret

RecordError:
    lea dx, msgError
    call PrintString
    ret

; Function to create sales line
CreateSalesLine:
    push si
    push ax
    
    ; Clear sales line buffer
    lea di, salesLine
    mov cx, 100
    mov al, 0
    rep stosb
    
    ; Build line: DATE:TIME:ITEM_ID:QUANTITY:SUBTOTAL:TAX:TOTAL
    lea si, currentDate
    lea di, salesLine
    
    ; Copy date
    mov cx, 10
    rep movsb
    
    ; Add colon
    mov byte ptr [di], ':'
    inc di
    
    ; Copy time
    lea si, currentTime
    mov cx, 8
    rep movsb
    
    ; Add colon
    mov byte ptr [di], ':'
    inc di
    
    ; Add item ID
    pop ax              ; Get saved item ID
    push ax
    call AddNumberToBuffer
    
    ; Add colon
    mov byte ptr [di], ':'
    inc di
    
    ; Add quantity (item_id + 1)
    pop ax
    push ax
    inc ax
    call AddNumberToBuffer
    
    ; Add colon
    mov byte ptr [di], ':'
    inc di
    
    ; Add subtotal (price * quantity)
    pop ax
    push ax
    mov bx, ax
    shl bx, 1
    mov ax, [foodPrices + bx]
    pop bx
    push bx
    inc bx              ; Quantity
    mul bx              ; ax = subtotal
    push ax             ; Save subtotal
    call AddNumberToBuffer
    
    ; Add colon
    mov byte ptr [di], ':'
    inc di
    
    ; Add tax (6% of subtotal)
    pop ax              ; Get subtotal
    push ax
    mov bx, 6
    mul bx
    mov bx, 100
    div bx              ; ax = tax
    call AddNumberToBuffer
    
    ; Add colon
    mov byte ptr [di], ':'
    inc di
    
    ; Add total (subtotal + tax)
    pop ax              ; Get subtotal
    mov bx, ax
    mov cx, 6
    mul cx
    mov cx, 100
    div cx
    add ax, bx          ; ax = total
    call AddNumberToBuffer
    
    ; Add newline
    mov byte ptr [di], 13
    inc di
    mov byte ptr [di], 10
    inc di
    mov byte ptr [di], 0
    
    pop si
    ret

; Function to add number to buffer
AddNumberToBuffer:
    push ax
    push bx
    push cx
    push dx
    
    ; Convert number to string
    mov bx, 10
    mov cx, 0
    
ConvertLoop:
    xor dx, dx
    div bx
    add dl, '0'
    push dx
    inc cx
    test ax, ax
    jnz ConvertLoop
    
WriteLoop:
    pop dx
    mov [di], dl
    inc di
    loop WriteLoop
    
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; Function to calculate string length
CalculateStringLength:
    push dx
    push cx
    mov cx, 0
    
LengthLoop:
    mov al, [dx]
    cmp al, 0
    je LengthDone
    inc cx
    inc dx
    jmp LengthLoop
    
LengthDone:
    mov ax, cx
    pop cx
    pop dx
    ret

; Function to generate daily report
GenerateDailyReport:
    ; First, read sales file and parse data
    call ReadSalesFile
    
    ; Create report file
    mov ah, 3Ch         ; Create file
    mov cx, 0           ; Normal file
    lea dx, reportFile
    int 21h
    jc ReportError
    
    mov [fileHandle], ax
    
    ; Write report header
    call WriteReportHeader
    
    ; Write sales data
    call WriteSalesData
    
    ; Close file
    mov ah, 3Eh
    mov bx, [fileHandle]
    int 21h
    ret

ReportError:
    lea dx, msgError
    call PrintString
    ret

; Function to read and parse sales file
ReadSalesFile:
    ; Clear daily sales array
    mov cx, 5
    mov si, 0
    
ClearLoop:
    mov word ptr [dailySales + si], 0
    add si, 2
    loop ClearLoop
    
    mov word ptr [totalRevenue], 0
    
    ; Open sales file for reading
    mov ah, 3Dh         ; Open file
    mov al, 0           ; Read only
    lea dx, salesFile
    int 21h
    jc ReadError
    
    mov [fileHandle], ax
    
    ; Read file content
    mov ah, 3Fh         ; Read file
    mov bx, [fileHandle]
    mov cx, 1000        ; Read up to 1000 bytes
    lea dx, readBuffer
    int 21h
    
    ; Close file
    mov ah, 3Eh
    mov bx, [fileHandle]
    int 21h
    
    ; Parse the buffer
    call ParseSalesData
    ret

ReadError:
    ret

; Function to parse sales data
ParseSalesData:
    lea si, readBuffer
    
ParseLineLoop:
    ; Check if end of buffer
    mov al, [si]
    cmp al, 0
    je ParseDone
    
    ; Skip to item ID (3rd field)
    call SkipField      ; Skip date
    call SkipField      ; Skip time
    
    ; Get item ID
    call GetFieldValue
    mov bx, ax          ; Save item ID
    
    ; Skip quantity field
    call SkipField
    
    ; Skip subtotal field
    call SkipField
    
    ; Skip tax field
    call SkipField
    
    ; Get total amount
    call GetFieldValue
    
    ; Add to total revenue
    add [totalRevenue], ax
    
    ; Add to item sales count
    shl bx, 1           ; bx = item_id * 2
    inc word ptr [dailySales + bx]
    
    ; Move to next line
    call SkipToNextLine
    jmp ParseLineLoop
    
ParseDone:
    ret

; Function to skip field
SkipField:
    mov al, [si]
    cmp al, ':'
    je SkipFieldDone
    cmp al, 0
    je SkipFieldDone
    cmp al, 13
    je SkipFieldDone
    cmp al, 10
    je SkipFieldDone
    inc si
    jmp SkipField
    
SkipFieldDone:
    cmp byte ptr [si], ':'
    jne SkipFieldExit
    inc si              ; Skip the colon
    
SkipFieldExit:
    ret

; Function to get field value as number
GetFieldValue:
    mov ax, 0
    mov bx, 10
    
GetValueLoop:
    mov cl, [si]
    cmp cl, ':'
    je GetValueDone
    cmp cl, 0
    je GetValueDone
    cmp cl, 13
    je GetValueDone
    cmp cl, 10
    je GetValueDone
    
    sub cl, '0'
    mul bx
    add al, cl
    inc si
    jmp GetValueLoop
    
GetValueDone:
    ret

; Function to skip to next line
SkipToNextLine:
    mov al, [si]
    cmp al, 0
    je SkipNextDone
    cmp al, 10
    je SkipNextFound
    inc si
    jmp SkipToNextLine
    
SkipNextFound:
    inc si
    
SkipNextDone:
    ret

; Function to write report header
WriteReportHeader:
    ; Write header text
    lea dx, reportHeader
    call WriteStringToFile
    
    ; Write current date
    lea dx, currentDate
    call WriteStringToFile
    
    ; Write newlines
    lea dx, newline
    call WriteStringToFile
    lea dx, newline
    call WriteStringToFile
    
    ret

; Function to write sales data
WriteSalesData:
    mov si, 0           ; Item counter
    
WriteSalesLoop:
    cmp si, 5
    jge WriteTotalRevenue
    
    ; Write item name
    call WriteItemName
    
    ; Write " Sales: "
    mov byte ptr [salesLine], ' '
    mov byte ptr [salesLine + 1], 'S'
    mov byte ptr [salesLine + 2], 'a'
    mov byte ptr [salesLine + 3], 'l'
    mov byte ptr [salesLine + 4], 'e'
    mov byte ptr [salesLine + 5], 's'
    mov byte ptr [salesLine + 6], ':'
    mov byte ptr [salesLine + 7], ' '
    mov byte ptr [salesLine + 8], 0
    lea dx, salesLine
    call WriteStringToFile
    
    ; Write sales count
    mov bx, si
    shl bx, 1
    mov ax, [dailySales + bx]
    call WriteNumberToFile
    
    ; Write newline
    lea dx, newline
    call WriteStringToFile
    
    inc si
    jmp WriteSalesLoop
    
WriteTotalRevenue:
    ; Write total revenue
    mov byte ptr [salesLine], 'T'
    mov byte ptr [salesLine + 1], 'o'
    mov byte ptr [salesLine + 2], 't'
    mov byte ptr [salesLine + 3], 'a'
    mov byte ptr [salesLine + 4], 'l'
    mov byte ptr [salesLine + 5], ' '
    mov byte ptr [salesLine + 6], 'R'
    mov byte ptr [salesLine + 7], 'e'
    mov byte ptr [salesLine + 8], 'v'
    mov byte ptr [salesLine + 9], 'e'
    mov byte ptr [salesLine + 10], 'n'
    mov byte ptr [salesLine + 11], 'u'
    mov byte ptr [salesLine + 12], 'e'
    mov byte ptr [salesLine + 13], ':'
    mov byte ptr [salesLine + 14], ' '
    mov byte ptr [salesLine + 15], 'R'
    mov byte ptr [salesLine + 16], 'M'
    mov byte ptr [salesLine + 17], 0
    lea dx, salesLine
    call WriteStringToFile
    
    mov ax, [totalRevenue]
    call WriteNumberToFile
    
    lea dx, newline
    call WriteStringToFile
    
    ret

; Function to write item name
WriteItemName:
    push si
    
    ; Find item name in foodNames array
    mov cx, si
    lea di, foodNames
    
FindNameLoop:
    cmp cx, 0
    je FoundName
    
    ; Skip to next name
    mov al, [di]
    cmp al, 0
    je NextName
    inc di
    jmp FindNameLoop
    
NextName:
    inc di
    dec cx
    jmp FindNameLoop
    
FoundName:
    ; Copy name to sales line
    lea bx, salesLine
    
CopyNameLoop:
    mov al, [di]
    cmp al, 0
    je CopyNameDone
    mov [bx], al
    inc di
    inc bx
    jmp CopyNameLoop
    
CopyNameDone:
    mov byte ptr [bx], 0
    lea dx, salesLine
    call WriteStringToFile
    
    pop si
    ret

; Function to write string to file
WriteStringToFile:
    push ax
    push bx
    push cx
    push dx
    
    call CalculateStringLength
    mov cx, ax
    mov ah, 40h
    mov bx, [fileHandle]
    int 21h
    
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; Function to write number to file
WriteNumberToFile:
    push ax
    push bx
    push cx
    push dx
    
    ; Convert number to string
    lea di, salesLine
    mov bx, 10
    mov cx, 0
    
ConvertNumLoop:
    xor dx, dx
    div bx
    add dl, '0'
    push dx
    inc cx
    test ax, ax
    jnz ConvertNumLoop
    
WriteNumLoop:
    pop dx
    mov [di], dl
    inc di
    loop WriteNumLoop
    
    mov byte ptr [di], 0
    lea dx, salesLine
    call WriteStringToFile
    
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; Function to display sales file
DisplaySalesFile:
    call PrintNewLine
    mov dl, 'S'
    mov ah, 02h
    int 21h
    mov dl, 'a'
    mov ah, 02h
    int 21h
    mov dl, 'l'
    mov ah, 02h
    int 21h
    mov dl, 'e'
    mov ah, 02h
    int 21h
    mov dl, 's'
    mov ah, 02h
    int 21h
    mov dl, '.'
    mov ah, 02h
    int 21h
    mov dl, 't'
    mov ah, 02h
    int 21h
    mov dl, 'x'
    mov ah, 02h
    int 21h
    mov dl, 't'
    mov ah, 02h
    int 21h
    call PrintNewLine
    call PrintNewLine
    
    call ReadAndDisplayFile
    ret

; Function to display report file
DisplayReportFile:
    call PrintNewLine
    mov dl, 'R'
    mov ah, 02h
    int 21h
    mov dl, 'e'
    mov ah, 02h
    int 21h
    mov dl, 'p'
    mov ah, 02h
    int 21h
    mov dl, 'o'
    mov ah, 02h
    int 21h
    mov dl, 'r'
    mov ah, 02h
    int 21h
    mov dl, 't'
    mov ah, 02h
    int 21h
    mov dl, '.'
    mov ah, 02h
    int 21h
    mov dl, 't'
    mov ah, 02h
    int 21h
    mov dl, 'x'
    mov ah, 02h
    int 21h
    mov dl, 't'
    mov ah, 02h
    int 21h
    call PrintNewLine
    call PrintNewLine
    
    ; Open report file
    mov ah, 3Dh
    mov al, 0
    lea dx, reportFile
    int 21h
    jc DisplayError
    
    mov [fileHandle], ax
    
    ; Read and display
    mov ah, 3Fh
    mov bx, [fileHandle]
    mov cx, 1000
    lea dx, readBuffer
    int 21h
    
    ; Close file
    mov ah, 3Eh
    mov bx, [fileHandle]
    int 21h
    
    ; Display buffer
    lea si, readBuffer
    
DisplayLoop:
    mov al, [si]
    cmp al, 0
    je DisplayDone
    mov dl, al
    mov ah, 02h
    int 21h
    inc si
    jmp DisplayLoop
    
DisplayDone:
    call PrintNewLine
    lea dx, msgPress
    call PrintString
    ret

DisplayError:
    lea dx, msgError
    call PrintString
    ret

; Function to read and display file (generic)
ReadAndDisplayFile:
    ; Open sales file
    mov ah, 3Dh
    mov al, 0
    lea dx, salesFile
    int 21h
    jc ReadDisplayError
    
    mov [fileHandle], ax
    
    ; Read file
    mov ah, 3Fh
    mov bx, [fileHandle]
    mov cx, 1000
    lea dx, readBuffer
    int 21h
    
    ; Close file
    mov ah, 3Eh
    mov bx, [fileHandle]
    int 21h
    
    ; Display buffer
    lea si, readBuffer
    
ReadDisplayLoop:
    mov al, [si]
    cmp al, 0
    je ReadDisplayDone
    mov dl, al
    mov ah, 02h
    int 21h
    inc si
    jmp ReadDisplayLoop
    
ReadDisplayDone:
    call PrintNewLine
    lea dx, msgPress
    call PrintString
    ret

ReadDisplayError:
    lea dx, msgError
    call PrintString
    ret

; Utility Functions
PrintString:
    mov ah, 09h
    int 21h
    ret

PrintNewLine:
    mov dl, 13
    mov ah, 02h
    int 21h
    mov dl, 10
    mov ah, 02h
    int 21h
    ret

PrintNumber:
    push ax
    push bx
    push cx
    push dx
    
    mov bx, 10
    mov cx, 0
    
PrintNumLoop:
    xor dx, dx
    div bx
    add dl, '0'
    push dx
    inc cx
    test ax, ax
    jnz PrintNumLoop
    
PrintDigitLoop:
    pop dx
    mov ah, 02h
    int 21h
    loop PrintDigitLoop
    
    pop dx
    pop cx
    pop bx
    pop ax
    ret

WaitKey:
    lea dx, msgPress
    call PrintString
    mov ah, 08h
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