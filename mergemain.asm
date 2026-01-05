;======================================================
; SmartDine - Combined System
; - Admin / Waiter (tables, inventory, billing)
; - Menu Management (add / remove / update / show menu)
; - Sales & Report (simple sales system)
;======================================================

.MODEL SMALL
.STACK 100h

;======================================================
; DATA SEGMENT
;======================================================
.DATA

;---------------------------
; From SmartDine main (mergefinal.asm)
;---------------------------

HEADER_TXT      DB 0Dh, 0Ah, '=== SmartDine ===$'
MENU_TXT        DB 0Dh, 0Ah, '1. Admin Login', 0Dh, 0Ah, '2. Waiter Login', 0Dh, 0Ah, '3. Exit', 0Dh, 0Ah, 'Select Option: $'
PASS_PROMPT     DB 0Dh, 0Ah, 'Enter Password: $'
LOGIN_SUCCESS   DB 0Dh, 0Ah, 'Login Successful! Press any key...$'
LOGIN_FAIL      DB 0Dh, 0Ah, 'Wrong Password! Access Denied.$'
EXIT_MSG        DB 0Dh, 0Ah, 'Exiting System...$'
ADMIN_PASS      DB '1234'
WAITER_PASS     DB '5678'

MsgSubtotal    DB 10,13, 'Subtotal: $'
MsgTax         DB 10,13, 'Tax (5%): $'
MsgService     DB 10,13, 'Service (2%): $'
MsgGrandTotal  DB 10,13, 'Grand Total: $'
MsgPaid        DB 10,13, 'Bill Paid. Table Released.$'
DailyRevenue   DW 0
TotalOrders    DW 0

; MENU DATA FOR WAITER DISHES
NUM_DISHES EQU 3
DISH_NAME_LEN EQU 15

DishName DB 'Burger         '
         DB 'Pizza          '
         DB 'Pasta          '
DishPrice DW 8, 12, 15

; Two ingredients per dish
DishIng1 DB 0, 3, 4   ; First ingredient
DishIng2 DB 1, 2, 5   ; Second ingredient

; INGREDIENT DATA
NUM_INGS EQU 6
ING_NAME_LEN EQU 13

IngName DB 'Bun          '
        DB 'Patty        '
        DB 'Cheese       '
        DB 'Dough        '
        DB 'Spinach      '
        DB 'Pasta        '

IngQty DW 10, 20, 15, 12, 5, 8

; TABLE DATA
NUM_TABLES EQU 5
MAX_ORDERS_PER_TABLE EQU 10

TableStatus      DB 0,0,0,0,0       ; 0 = Available, 1 = Occupied
TableBill        DW 0,0,0,0,0 
TableOrderCounts DB 5 DUP(0)        ; Count of items per table
TableOrders      DB 50 DUP(0)       ; 5 tables * 10 items (stores Dish IDs) 

; MESSAGES
MsgNewline    DB 10, 13, '$'

; Table messages
MsgTableHeader DB 10, 13, '=== Available Tables ===$'
MsgTable       DB 10, 13, 'Table $'
MsgAvailable   DB ' - Available$'
MsgOccupied    DB ' - Occupied$'
MsgAskTable    DB 10, 13, 'Enter Table Num (1-5): $'
MsgTableOccErr DB 10, 13, 'Error: Table is occupied! $'

; Loop message
MsgOrderAnother DB 10, 13, 'Order another dish? (1:Yes, 2:No): $'

; Order messages
MsgOrderFor   DB 10, 13, '=== Order For Table $'
MsgFoodHeader DB 10, 13, '=== Food Items ===$'
MsgAskDish    DB 10, 13, 'Enter Dish Num (1-3): $'
MsgSuccess    DB 10, 13, 'Order Placed! Total: $'
MsgNoStock    DB 10, 13, 'Error: Insufficient ingredients! $'

; Inventory messages
MsgIngHeader  DB 10, 13, '=== Inventory ===$'
MsgIngNum     DB 10, 13, '$'
MsgQtyIs      DB ' Qty: $'
MsgAskIng     DB 10, 13, 'Increase Quantity Of (1-6): $'
MsgAskQty     DB 10, 13, 'Quantity to add: $'
MsgRestocked  DB 10, 13, 'Quantity Successfully increased!$'

; Menu item display
MsgDot        DB '. $'
MsgPrice      DB ' - $'
MsgDollar     DB '$'

; Dashboard Menus
AdminMenuTxt    DB 10,13,'=== SmartDine - Admin Dashboard ===',10,13
                DB '1. Show Inventory',10,13
                DB '2. Restock Inventory',10,13
                DB '3. Menu Management',10,13
                DB '4. Sales & Report',10,13
                DB '5. Logout',10,13
                DB 'Select: $'

WaiterMenuTxt   DB 10,13,'=== SmartDine - Waiter Dashboard ===',10,13
                DB '1. Show Tables',10,13
                DB '2. Take Order',10,13
                DB '3. Generate Bill',10,13
                DB '4. Logout',10,13
                DB 'Select: $'

; Temp storage
InputBuffer   DB 6 DUP(0)
TempNum       DW 0
CurrentTable  DW 0
CurrentDish   DW 0

;---------------------------
; From MenuManagement.asm (Feature 1)
;---------------------------

MAX_DISHES  EQU 10
NAME_LEN    EQU 16          ; 15 chars + '$'

msg_main_title  DB 0DH,0AH,'===== SmartDine - Menu Feature Test =====',0DH,0AH,'$'
msg_main_menu   DB '1. Menu Management',0DH,0AH,'0. Exit',0DH,0AH,'$'
msg_choice      DB 'Enter choice: ','$'
msg_invalid     DB 0DH,0AH,'Invalid choice! Try again.',0DH,0AH,'$'

msg_menu_title      DB 0DH,0AH,'--- Menu Management ---',0DH,0AH,'$'
msg_menu_options    DB '1. Show Menu',0DH,0AH,'2. Add Dish',0DH,0AH,'3. Update Dish Price',0DH,0AH,'4. Remove Dish',0DH,0AH,'0. Back',0DH,0AH,'$'
msg_menu_header     DB 0DH,0AH,'Current Menu:',0DH,0AH,'$'
msg_menu_empty      DB 'Menu is currently empty.',0DH,0AH,'$'
msg_menu_full       DB 'Menu is full. Cannot add more dishes.',0DH,0AH,'$'
msg_enter_name      DB 0DH,0AH,'Enter dish name: ','$'
msg_enter_price     DB 0DH,0AH,'Enter price (integer): ','$'
msg_dish_added      DB 0DH,0AH,'Dish added successfully.',0DH,0AH,'$'
msg_dish_updated    DB 0DH,0AH,'Price updated successfully.',0DH,0AH,'$'
msg_dish_removed    DB 0DH,0AH,'Dish removed successfully.',0DH,0AH,'$'
msg_select_dish     DB 0DH,0AH,'Enter dish number: ','$'
msg_invalid_dish    DB 0DH,0AH,'Invalid dish number.',0DH,0AH,'$'
msg_dash_space      DB ' - ','$'
msg_colon_space     DB ': ','$'

menu_count      DB 0                        ; how many dishes
menu_names      DB MAX_DISHES*NAME_LEN DUP('$')
menu_prices     DW MAX_DISHES DUP(0)

; input buffers for menu numbers
name_buffer     DB 15
name_len        DB ?
name_data       DB 15 DUP(?)

num_buffer      DB 5
num_len         DB ?
num_data        DB 5 DUP(?)

num_out         DB 6 DUP('$')  ; for PrintNumber

;---------------------------
; From Sales & Report (sales&report.asm) with renamed symbols
;---------------------------

MAX_SALES   EQU 50      ; maximum number of sales we store

ss_msg_main_title  DB 0DH,0AH,'===== Sales System Test =====',0DH,0AH,'$'
ss_msg_main_menu   DB '1. Add Sale',0DH,0AH,'2. Show Sales Report',0DH,0AH,'0. Back',0DH,0AH,'$'
ss_msg_choice      DB 'Enter choice: ','$'
ss_msg_invalid     DB 0DH,0AH,'Invalid choice! Try again.',0DH,0AH,'$'

msg_enter_amount    DB 0DH,0AH,'Enter sale amount: ','$'
msg_sales_full      DB 0DH,0AH,'Sales history is full. Cannot add more.',0DH,0AH,'$'
msg_sale_added      DB 0DH,0AH,'Sale recorded successfully.',0DH,0AH,'$'

msg_report_header   DB 0DH,0AH,'--- Sales Report ---',0DH,0AH,'$'
msg_no_sales        DB 'No sales recorded yet.',0DH,0AH,'$'
msg_total_count     DB 'Total sales count: ','$'
msg_total_revenue   DB 0DH,0AH,'Total revenue: ','$'
msg_list_header     DB 0DH,0AH,'Sales list:',0DH,0AH,'$'
ss_msg_colon_space  DB ': ','$'

sales_count     DW 0                    ; how many sales recorded
total_revenue   DW 0                    ; sum of all sales
sales_amounts   DW MAX_SALES DUP(0)     ; each sale amount

; menu input: max 3 chars (e.g. "12")

; number input: for sale amount, max 5 digits
num_buf_max     DB 5
num_buf_len     DB 0
num_buf_data    DB 5 DUP(0)

;======================================================
; CODE SEGMENT
;======================================================
.CODE

;---------------------------
; Common Macros
;---------------------------
PRINT MACRO text
    mov ah, 9
    lea dx, text
    int 21h
ENDM

NEWLINE MACRO
    mov ah, 2
    mov dl, 0DH
    int 21h
    mov dl, 0AH
    int 21h
ENDM

;======================================================
; MenuManagement.asm helper procedures (unchanged logic)
;======================================================

; PrintZString DS:SI until '$'
PrintZString PROC
    push ax
    push dx
pz_loop:
    mov al, [si]
    cmp al, '$'
    je  pz_done
    mov dl, al
    mov ah, 2
    int 21h
    inc si
    jmp pz_loop
pz_done:
    pop dx
    pop ax
    ret
PrintZString ENDP

; ReadNumber for Menu Management -> AX
ReadNumber PROC
    push bx
    push cx
    push dx
    push si

    lea dx, num_buffer
    mov ah, 0Ah
    int 21h

    mov cl, num_len
    mov ch, 0
    lea si, num_data
    xor ax, ax           ; result = 0

rn_loop:
    cmp cx, 0
    je  rn_done

    mov dl, [si]
    cmp dl, 0DH         ; CR
    je  rn_done

    cmp dl, '0'
    jb  rn_next
    cmp dl, '9'
    ja  rn_next

    sub dl, '0'
    mov bx, 0
    mov bl, dl          ; digit in BX

    xor dx, dx
    mov cx, 10
    mul cx              ; AX = AX * 10
    add ax, bx          ; + digit

rn_next:
    inc si
    dec cx
    jmp rn_loop

rn_done:
    pop si
    pop dx
    pop cx
    pop bx
    ret
ReadNumber ENDP

; PrintNumber (for Menu Management) - prints AX
PrintNumber PROC
    push ax
    push bx
    push cx
    push dx
    push si

    cmp ax, 0
    jne pn_not_zero
    mov dl, '0'
    mov ah, 2
    int 21h
    jmp pn_done

pn_not_zero:
    lea si, num_out
    mov cx, 6
pn_clear:
    mov byte ptr [si], '$'
    inc si
    loop pn_clear

    lea si, num_out+5
pn_loop:
    xor dx, dx
    mov bx, 10
    div bx              ; AX/10, remainder in DX
    add dl, '0'
    mov [si], dl
    dec si
    cmp ax, 0
    jne pn_loop

    inc si
    mov dx, si
    mov ah, 9
    int 21h

pn_done:
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
PrintNumber ENDP

; ReadNameToDest DS:DI (fixed version)
ReadNameToDest PROC
    push ax
    push cx
    push dx

    mov cx, 0                    ; number of chars stored

rnt_loop:
    mov ah, 01h                  ; read char with echo
    int 21h                      ; AL = char

    cmp al, 0Dh                  ; Enter pressed?
    je  rnt_done

    cmp cx, NAME_LEN-1           ; keep space for '$'
    jae rnt_flush                ; ignore extra chars but keep reading rest

    mov [di], al                 ; store character
    inc di
    inc cx
    jmp rnt_loop

rnt_flush:
    jmp rnt_loop

rnt_done:
    mov byte ptr [di], '$'       ; terminate string

    pop dx
    pop cx
    pop ax
    ret
ReadNameToDest ENDP

; Show menu items for MenuManagement (renamed to avoid clash with SHOW_MENU)
MM_ShowMenu PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    PRINT msg_menu_header

    mov al, menu_count
    cmp al, 0
    jne sm_has_items
    PRINT msg_menu_empty
    jmp sm_done

sm_has_items:
    mov cl, menu_count
    mov ch, 0
    mov bl, 0           ; index = 0

sm_loop:
    ; index (1-based)
    xor ax, ax
    mov al, bl
    inc ax
    call PrintNumber

    ; ". "
    mov dl, '.'
    mov ah, 2
    int 21h
    mov dl, ' '
    mov ah, 2
    int 21h

    ; name pointer
    push bx
    xor bh, bh
    mov ax, bx
    shl ax, 1
    shl ax, 1
    shl ax, 1
    shl ax, 1           ; *16
    lea di, menu_names
    add di, ax
    mov si, di
    call PrintZString

    ; " - "
    PRINT msg_dash_space

    ; price pointer
    pop bx
    xor bh, bh
    mov ax, bx
    shl ax, 1           ; *2
    lea si, menu_prices
    add si, ax
    mov ax, [si]
    call PrintNumber

    NEWLINE

    inc bl
    dec cl
    jnz sm_loop

sm_done:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
MM_ShowMenu ENDP

AddDish PROC
    push ax
    push bx
    push dx
    push si
    push di

    mov al, menu_count
    cmp al, MAX_DISHES
    jb  can_add
    PRINT msg_menu_full
    jmp ad_done

can_add:
    PRINT msg_enter_name

    mov bl, menu_count
    xor bh, bh
    mov ax, bx
    shl ax, 1
    shl ax, 1
    shl ax, 1
    shl ax, 1           ; *16
    lea di, menu_names
    add di, ax

    call ReadNameToDest

    PRINT msg_enter_price
    call ReadNumber      ; AX = price

    mov bl, menu_count
    xor bh, bh
    mov dx, ax
    mov ax, bx
    shl ax, 1            ; *2
    lea si, menu_prices
    add si, ax
    mov [si], dx

    inc menu_count
    PRINT msg_dish_added

ad_done:
    pop di
    pop si
    pop dx
    pop bx
    pop ax
    ret
AddDish ENDP

UpdateDishPrice PROC
    push ax
    push bx
    push dx
    push si

    mov al, menu_count
    cmp al, 0
    jne udp_has
    PRINT msg_menu_empty
    jmp udp_done

udp_has:
    call MM_ShowMenu
    PRINT msg_select_dish
    call ReadNumber      ; AX = dish number

    cmp ax, 1
    jb  udp_invalid
    mov bl, menu_count
    xor bh, bh
    cmp ax, bx
    ja  udp_invalid

    dec ax               ; 0-based
    mov bl, al

    PRINT msg_enter_price
    call ReadNumber      ; new price -> AX
    mov dx, ax

    xor bh, bh
    mov ax, bx
    shl ax, 1            ; *2
    lea si, menu_prices
    add si, ax
    mov [si], dx

    PRINT msg_dish_updated
    jmp udp_done

udp_invalid:
    PRINT msg_invalid_dish

udp_done:
    pop si
    pop dx
    pop bx
    pop ax
    ret
UpdateDishPrice ENDP

RemoveDish PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    mov al, menu_count
    cmp al, 0
    jne rd_has
    PRINT msg_menu_empty
    jmp rd_done

rd_has:
    call MM_ShowMenu
    PRINT msg_select_dish
    call ReadNumber      ; AX = dish number

    cmp ax, 1
    jb  rd_invalid
    mov bl, menu_count
    xor bh, bh
    cmp ax, bx
    ja  rd_invalid

    dec ax               ; 0-based
    mov bl, al

    ; last index = menu_count - 1
    mov al, menu_count
    dec al
    cmp bl, al
    jae rd_skip_shift    ; removing last

rd_outer:
    ; src index = BL + 1
    mov bh, 0
    mov ax, bx
    inc ax
    shl ax, 1
    shl ax, 1
    shl ax, 1
    shl ax, 1
    lea si, menu_names
    add si, ax          ; SI = name[BL+1]

    ; dest index = BL
    mov ax, bx
    shl ax, 1
    shl ax, 1
    shl ax, 1
    shl ax, 1
    lea di, menu_names
    add di, ax          ; DI = name[BL]

    mov cx, NAME_LEN
rd_copy_name:
    mov dl, [si]
    mov [di], dl
    inc si
    inc di
    loop rd_copy_name

    ; copy price
    mov bh, 0
    mov ax, bx
    shl ax, 1
    lea di, menu_prices
    add di, ax          ; dest

    mov ax, bx
    inc ax
    shl ax, 1
    lea si, menu_prices
    add si, ax          ; src

    mov ax, [si]
    mov [di], ax

    inc bl
    mov al, menu_count
    dec al
    cmp bl, al
    jb  rd_outer

rd_skip_shift:
    dec menu_count
    PRINT msg_dish_removed
    jmp rd_done

rd_invalid:
    PRINT msg_invalid_dish

rd_done:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
RemoveDish ENDP

; MenuManagement main loop (subsystem) - called from Admin Dashboard
MenuManagement PROC
mm_loop:
    PRINT msg_menu_title
    PRINT msg_menu_options
    PRINT msg_choice
    call ReadNumber      ; AX = choice

    cmp ax, 1
    je  mm_show
    cmp ax, 2
    je  mm_add
    cmp ax, 3
    je  mm_update
    cmp ax, 4
    je  mm_remove
    cmp ax, 0
    je  mm_exit

    PRINT msg_invalid
    jmp mm_loop

mm_show:
    call MM_ShowMenu
    jmp mm_loop

mm_add:
    call AddDish
    jmp mm_loop

mm_update:
    call UpdateDishPrice
    jmp mm_loop

mm_remove:
    call RemoveDish
    jmp mm_loop

mm_exit:
    ret
MenuManagement ENDP

;======================================================
; Sales & Report subsystem (sales&report.asm)
;======================================================

; ReadMenuChoice -> AL (first char)


; SS_ReadNumber -> AX (renamed to avoid clash)
SS_ReadNumber PROC
    push bx
    push cx
    push dx
    push si

    lea dx, num_buf_max
    mov ah, 0Ah
    int 21h

    mov cl, num_buf_len
    mov ch, 0
    lea si, num_buf_data
    xor ax, ax               ; AX = result = 0

ss_rn_loop:
    cmp cx, 0
    je  ss_rn_done

    mov dl, [si]

    cmp dl, '0'
    jb  ss_rn_next
    cmp dl, '9'
    ja  ss_rn_next

    sub dl, '0'              ; DL = digit 0..9
    mov dh, 0
    mov bx, dx               ; BX = digit

    mov dx, 0
    mov cx, 10
    mul cx                   ; DX:AX = AX * 10
    add ax, bx               ; AX = AX*10 + digit

ss_rn_next:
    inc si
    dec cx
    jmp ss_rn_loop

ss_rn_done:
    pop si
    pop dx
    pop cx
    pop bx
    ret
SS_ReadNumber ENDP

; S_PrintNumber - prints AX (renamed version)
S_PrintNumber PROC
    push bx
    push cx
    push dx

    cmp ax, 0
    jne ss_pn_convert
    ; print single '0'
    mov dl, '0'
    mov ah, 2
    int 21h
    jmp ss_pn_done

ss_pn_convert:
    mov cx, 0                ; digit count

ss_pn_div_loop:
    xor dx, dx
    mov bx, 10
    div bx                   ; AX = AX/10, DX = remainder
    push dx                  ; push remainder
    inc cx
    cmp ax, 0
    jne ss_pn_div_loop

ss_pn_print_loop:
    pop dx
    add dl, '0'              ; DL = '0' + digit
    mov ah, 2
    int 21h
    loop ss_pn_print_loop

ss_pn_done:
    pop dx
    pop cx
    pop bx
    ret
S_PrintNumber ENDP

; AddSale
AddSale PROC
    push ax
    push bx
    push dx
    push si

    mov ax, sales_count
    cmp ax, MAX_SALES
    jb  as_can
    PRINT msg_sales_full
    jmp as_done2

as_can:
    PRINT msg_enter_amount
    call SS_ReadNumber          ; AX = amount

    ; store AX into sales_amounts[sales_count]
    mov bx, sales_count
    shl bx, 1                ; *2 (word index)
    mov si, OFFSET sales_amounts
    add si, bx
    mov [si], ax

    ; sales_count++
    inc sales_count

    ; total_revenue += AX
    mov dx, total_revenue
    add dx, ax
    mov total_revenue, dx

    PRINT msg_sale_added

as_done2:
    pop si
    pop dx
    pop bx
    pop ax
    ret
AddSale ENDP

; ShowReport
ShowReport PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    PRINT msg_report_header

    mov ax, sales_count
    cmp ax, 0
    jne sr_has2
    PRINT msg_no_sales
    jmp sr_done2

sr_has2:
    ; total count
    PRINT msg_total_count
    mov ax, sales_count
    call S_PrintNumber

    ; total revenue
    PRINT msg_total_revenue
    mov ax, total_revenue
    call S_PrintNumber
    NEWLINE

    ; list
    PRINT msg_list_header

    mov cx, sales_count      ; CX = number of sales
    xor di, di               ; DI = index = 0

sr_loop2:
    cmp di, cx
    je  sr_done2

    ; print index (1-based)
    mov ax, di
    inc ax
    call S_PrintNumber
    PRINT ss_msg_colon_space

    ; print sales_amounts[di]
    mov bx, di
    shl bx, 1                ; *2
    mov si, OFFSET sales_amounts
    add si, bx
    mov ax, [si]
    call S_PrintNumber
    NEWLINE

    inc di
    jmp sr_loop2

sr_done2:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
ShowReport ENDP

; Sales & Report main loop (called from Admin dashboard)


;======================================================
; SmartDine main program (mergefinal.asm)
;======================================================


; Waiter/Admin feature procedures

SHOW_TABLES PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    
    LEA DX, MsgTableHeader
    MOV AH, 9
    INT 21H
    
    MOV CX, NUM_TABLES
    MOV BX, 0           
    
SHOW_TABLE_LOOP:
    LEA DX, MsgTable
    MOV AH, 9
    INT 21H
    
    MOV AX, BX
    INC AX              ; Convert to 1-based
    CALL PRINT_NUMBER
    
    ;table status check and print Available/Occupied
    MOV AL, TableStatus[BX]
    CMP AL, 0
    JNE PRINT_OCCUPIED2
    
    LEA DX, MsgAvailable
    JMP PRINT_STATUS2
    
PRINT_OCCUPIED2:
    LEA DX, MsgOccupied
    
PRINT_STATUS2:
    MOV AH, 9
    INT 21H
    
    INC BX
    LOOP SHOW_TABLE_LOOP
    
    POP DX
    POP CX
    POP BX
    POP AX
    RET
SHOW_TABLES ENDP

TAKE_ORDER PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    
GET_TABLE2:
    LEA DX, MsgAskTable
    MOV AH, 9
    INT 21H
    
    ;read table num
    MOV AH, 01H
    INT 21H
    
    SUB AL, '1' 
    MOV BL, AL
    MOV BH, 0
    
    ;If outside valid table num, ask again
    CMP BX, NUM_TABLES
    JAE GET_TABLE2 
    
    ; Check if table is available
    MOV AL, TableStatus[BX]
    CMP AL, 0
    JE TABLE_OK2
    
    ;table occupied error
    LEA DX, MsgTableOccErr
    MOV AH, 9
    INT 21H
    JMP GET_TABLE2
    
TABLE_OK2:
    ;save current table index
    MOV CurrentTable, BX
    
    ;order header
    LEA DX, MsgOrderFor
    MOV AH, 9
    INT 21H
    
    ;print table num
    MOV AX, BX
    INC AX              ; 1-based for display
    CALL PRINT_NUMBER
    
    ;show food menu
    CALL SHOW_MENU

GET_DISH2:
    ;ask for dish number
    LEA DX, MsgAskDish
    MOV AH, 9
    INT 21H
    
    MOV AH, 01H
    INT 21H
    
    SUB AL, '1'  
    MOV BL, AL
    MOV BH, 0
    
    ;check if dish within range
    CMP BX, NUM_DISHES
    JAE GET_DISH2       
    
    ;save dish index
    MOV CurrentDish, BX
    
    ;check inventory for both ingredients
    ;get first ingredient index
    MOV SI, BX
    MOV AL, DishIng1[SI]
    MOV AH, 0
    MOV SI, AX
    SHL SI, 1    
    MOV AX, IngQty[SI]
    CMP AX, 1
    JB NO_STOCK2         

    ;get second ingredient index
    MOV SI, CurrentDish
    MOV AL, DishIng2[SI]
    MOV AH, 0
    MOV SI, AX
    SHL SI, 1
    MOV AX, IngQty[SI]
    CMP AX, 1
    JB NO_STOCK2         

    ;both ingredients available - deduct inventory
    ;deduct first ingredient
    MOV SI, CurrentDish
    MOV AL, DishIng1[SI]
    MOV AH, 0
    MOV SI, AX
    SHL SI, 1
    DEC IngQty[SI]
    
    ;deduct second ingredient
    MOV SI, CurrentDish
    MOV AL, DishIng2[SI]
    MOV AH, 0
    MOV SI, AX
    SHL SI, 1
    DEC IngQty[SI]
    
    ;update table status and bill
    MOV BX, CurrentTable
    MOV TableStatus[BX], 1      ;mark as occupied
    
    ;add dish price to table bill
    MOV SI, CurrentDish
    SHL SI, 1                             
    MOV AX, DishPrice[SI]
    SHL BX, 1                    
    ADD TableBill[BX], AX
    
    ;store order details
    MOV BX, CurrentTable
    MOV AL, TableOrderCounts[BX]
    MOV AH, 0
    
    ;check max orders
    CMP AL, MAX_ORDERS_PER_TABLE
    JAE SKIP_STORAGE2    
    
    PUSH AX             
    MOV AX, CurrentTable
    MOV CX, MAX_ORDERS_PER_TABLE
    MUL CX              
    POP DX              
    ADD AX, DX          
    MOV SI, AX
    
    ;store dish id
    MOV AX, CurrentDish
    MOV TableOrders[SI], AL
    
    ;increment count
    MOV BX, CurrentTable
    INC TableOrderCounts[BX]
    
SKIP_STORAGE2:
    
    ;print success message with total (running total)
    LEA DX, MsgSuccess
    MOV AH, 9
    INT 21H
    
    MOV BX, CurrentTable
    SHL BX, 1
    MOV AX, TableBill[BX]
    CALL PRINT_NUMBER
    
    LEA DX, MsgDollar
    MOV AH, 9
    INT 21H
    
    ;ask to order another
    LEA DX, MsgOrderAnother
    MOV AH, 9
    INT 21H
    
    MOV AH, 01H
    INT 21H
    
    CMP AL, '1'
    JE GET_DISH_JUMP2
    JMP ORDER_DONE2

GET_DISH_JUMP2:
    JMP GET_DISH2
    
NO_STOCK2:
    LEA DX, MsgNoStock
    MOV AH, 9
    INT 21H
    JMP ORDER_DONE2
    
ORDER_DONE2:
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
TAKE_ORDER ENDP

SHOW_MENU PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI

    LEA DX, MsgFoodHeader
    MOV AH, 9
    INT 21H

    MOV CX, NUM_DISHES
    MOV BX, 0           ; Dish index
    
SHOW_DISH_LOOP2:
    LEA DX, MsgNewline
    MOV AH, 9
    INT 21H
    MOV AX, BX
    INC AX
    CALL PRINT_NUMBER
    
    LEA DX, MsgDot
    MOV AH, 9
    INT 21H
    
    ;print dish name (15 chars)
    MOV SI, BX
    MOV AX, DISH_NAME_LEN
    MUL SI 
    MOV SI, AX
    
    MOV CX, DISH_NAME_LEN
PRINT_DISH_NAME2:
    MOV DL, DishName[SI]
    MOV AH, 2
    INT 21H
    INC SI
    LOOP PRINT_DISH_NAME2
    
    MOV CX, NUM_DISHES
    SUB CX, BX
    
    LEA DX, MsgPrice
    MOV AH, 9
    INT 21H
    
    ;print price
    PUSH BX
    SHL BX, 1           
    MOV AX, DishPrice[BX]
    CALL PRINT_NUMBER
    POP BX
    
    INC BX
    LOOP SHOW_DISH_LOOP2
    
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
SHOW_MENU ENDP

SHOW_INVENTORY PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    
    LEA DX, MsgIngHeader
    MOV AH, 9
    INT 21H

    MOV CX, NUM_INGS
    MOV BX, 0      
    
SHOW_ING_LOOP2:
    LEA DX, MsgNewline
    MOV AH, 9
    INT 21H
    
    MOV AX, BX
    INC AX
    CALL PRINT_NUMBER
    
    LEA DX, MsgDot
    MOV AH, 9
    INT 21H
    
    MOV SI, BX
    MOV AX, ING_NAME_LEN
    MUL SI              ; AX = offset into IngName
    MOV SI, AX
    
    PUSH CX
    MOV CX, ING_NAME_LEN
PRINT_ING_NAME2:
    MOV DL, IngName[SI]
    MOV AH, 2
    INT 21H
    INC SI
    LOOP PRINT_ING_NAME2
    POP CX
    
    LEA DX, MsgQtyIs
    MOV AH, 9
    INT 21H
    
    PUSH BX
    SHL BX, 1        
    MOV AX, IngQty[BX]
    CALL PRINT_NUMBER
    POP BX
    
    INC BX
    LOOP SHOW_ING_LOOP2
    
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
SHOW_INVENTORY ENDP

RESTOCK_INVENTORY PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    
GET_ING2:
    ;ask for ingredient number
    LEA DX, MsgAskIng
    MOV AH, 9
    INT 21H
    
    MOV AH, 01H
    INT 21H
    
    SUB AL, '1'         ; Convert ASCII to 0-based index
    MOV BL, AL
    MOV BH, 0
    
    ; check if ing within range
    CMP BX, NUM_INGS
    JAE GET_ING2         ; If >= NUM_INGS, ask again
    
    ;save ingredient index
    PUSH BX
    
    ;ask for quantity
    LEA DX, MsgAskQty
    MOV AH, 9
    INT 21H
    
    ;read quantity
    MOV AH, 01H
    INT 21H
    
    ;convert to number
    SUB AL, '0'         
    MOV AH, 0
    MOV CX, AX 
    
    ;update inventory
    POP BX
    SHL BX, 1        
    ADD IngQty[BX], CX
    
    LEA DX, MsgRestocked
    MOV AH, 9
    INT 21H
    
    POP DX
    POP CX
    POP BX
    POP AX
    RET
RESTOCK_INVENTORY ENDP

; PRINT_NUMBER - original SmartDine version (unchanged)
PRINT_NUMBER PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    
    MOV BX, 10         
    MOV CX, 0           
    
CONVERT_LOOP3:
    MOV DX, 0           
    DIV BX              
    PUSH DX            
    INC CX
    CMP AX, 0
    JNE CONVERT_LOOP3
    
PRINT_LOOP3:
    POP DX              
    ADD DL, '0'         
    MOV AH, 2
    INT 21H
    LOOP PRINT_LOOP3
    
    POP DX
    POP CX
    POP BX
    POP AX
    RET
PRINT_NUMBER ENDP

GENERATE_BILL PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI

    LEA DX, MsgAskTable
    MOV AH, 9
    INT 21H

    MOV AH, 1
    INT 21H
    SUB AL, '1'
    MOV AH, 0
    MOV DI, AX
           
    MOV SI, DI
    ADD SI, SI

    MOV AX, TableBill[SI]
    CMP AX, 0
    JE GB_EXIT2

    MOV TempNum, AX   

    LEA DX, MsgSubtotal
    MOV AH, 9
    INT 21H
    MOV AX, TempNum
    CALL PRINT_NUMBER

    LEA DX, MsgTax
    MOV AH, 9
    INT 21H
    MOV AX, TempNum
    MOV CX, 5
    MUL CX               
    MOV CX, 100
    DIV CX              
    PUSH AX
    CALL PRINT_NUMBER

    LEA DX, MsgService
    MOV AH, 9
    INT 21H
    MOV AX, TempNum
    MOV CX, 2
    MUL CX
    MOV CX, 100
    DIV CX               
    PUSH AX
    CALL PRINT_NUMBER

    LEA DX, MsgGrandTotal
    MOV AH, 9
    INT 21H
    POP CX            
    POP BX               
    MOV AX, TempNum
    ADD AX, BX
    ADD AX, CX
    PUSH AX
    CALL PRINT_NUMBER

    POP AX
    ADD DailyRevenue, AX
    INC TotalOrders

    LEA DX, MsgPaid
    MOV AH, 9
    INT 21H

    MOV TableStatus[DI], 0
    MOV TableBill[SI], 0
    MOV TableOrderCounts[DI], 0

GB_EXIT2:
    POP DI
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
GENERATE_BILL ENDP

;======================================================
; MAIN ENTRY
;======================================================

MAIN PROC

    MOV AX,@DATA
    MOV DS,AX
 
;Main Menu
MAIN_MENU:
    LEA DX, HEADER_TXT
    MOV AH, 9
    INT 21H

    LEA DX, MENU_TXT
    MOV AH, 9
    INT 21H

    MOV AH, 1
    INT 21H

    CMP AL, '1'
    JE ADMIN_LOGIN
    CMP AL, '2'
    JE WAITER_LOGIN
    CMP AL, '3'
    JE EXIT_PROGRAM
    JMP MAIN_MENU

ADMIN_LOGIN:
    ; prompt for admin password
    LEA DX, PASS_PROMPT
    MOV AH, 9
    INT 21H

    MOV CX, 4              ; password length
    LEA SI, ADMIN_PASS     ; correct password "1234"

AL_ADMIN_LOOP:
    MOV AH, 1              ; read char with echo
    INT 21H                ; AL = typed char
    CMP AL, [SI]           ; compare to stored char
    JNE ACCESS_DENIED      ; mismatch -> fail
    INC SI                 ; next stored char
    LOOP AL_ADMIN_LOOP     ; repeat 4 times

    ; all 4 characters matched
    JMP ADMIN_GRANTED


WAITER_LOGIN:
    ; prompt for waiter password
    LEA DX, PASS_PROMPT
    MOV AH, 9
    INT 21H

    MOV CX, 4              ; password length
    LEA SI, WAITER_PASS    ; correct password "5678"

AL_WAITER_LOOP:
    MOV AH, 1
    INT 21H
    CMP AL, [SI]
    JNE ACCESS_DENIED
    INC SI
    LOOP AL_WAITER_LOOP

    JMP WAITER_GRANTED


ADMIN_GRANTED:
    LEA DX, LOGIN_SUCCESS
    MOV AH, 9
    INT 21H
    MOV AH, 1               
    INT 21H
    JMP ADMIN_DASHBOARD

WAITER_GRANTED:
    LEA DX, LOGIN_SUCCESS
    MOV AH, 9
    INT 21H
    MOV AH, 1               
    INT 21H
    JMP WAITER_DASHBOARD

ADMIN_DASHBOARD:
    LEA DX, AdminMenuTxt
    MOV AH, 9
    INT 21H
    
    MOV AH, 1
    INT 21H
    
    CMP AL, '1'
    JE CALL_SHOW_INV
    CMP AL, '2'
    JE CALL_RESTOCK
    CMP AL, '3'
    JE CALL_MENU_MGMT
    CMP AL, '4'
    JE CALL_SALES_SYS
    CMP AL, '5'
    JE MAIN_MENU
    JMP ADMIN_DASHBOARD
    
CALL_SHOW_INV:
    CALL SHOW_INVENTORY
    JMP ADMIN_DASHBOARD
    
CALL_RESTOCK:
    CALL RESTOCK_INVENTORY
    JMP ADMIN_DASHBOARD

CALL_MENU_MGMT:
    CALL MenuManagement
    JMP ADMIN_DASHBOARD

; --- Admin option 4: Sales & Report ---
CALL_SALES_SYS:

SALES_MAIN_LOOP:
    PRINT ss_msg_main_title
    PRINT ss_msg_main_menu
    PRINT ss_msg_choice

    ; read ONE key (no Enter required for the menu choice)
    mov ah, 1
    int 21h                ; AL = key pressed

    cmp al, '1'
    je  SALES_DO_ADD
    cmp al, '2'
    je  SALES_DO_REPORT
    cmp al, '0'
    je  SALES_BACK

    PRINT ss_msg_invalid
    jmp SALES_MAIN_LOOP

SALES_DO_ADD:
    call AddSale
    jmp SALES_MAIN_LOOP

SALES_DO_REPORT:
    call ShowReport
    jmp SALES_MAIN_LOOP

SALES_BACK:
    jmp ADMIN_DASHBOARD

    
WAITER_DASHBOARD:
    LEA DX, WaiterMenuTxt
    MOV AH, 9
    INT 21H

    MOV AH, 1
    INT 21H

    CMP AL, '1'
    JE CALL_SHOW_TABLES
    CMP AL, '2'
    JE CALL_TAKE_ORDER
    CMP AL, '3'
    JE CALL_GENERATE_BILL
    CMP AL, '4'
    JE MAIN_MENU
    JMP WAITER_DASHBOARD

CALL_GENERATE_BILL:
    CALL GENERATE_BILL
    JMP WAITER_DASHBOARD

CALL_SHOW_TABLES:
    CALL SHOW_TABLES
    JMP WAITER_DASHBOARD
    
CALL_TAKE_ORDER:
    CALL TAKE_ORDER
    JMP WAITER_DASHBOARD        

ACCESS_DENIED:
    LEA DX, LOGIN_FAIL
    MOV AH, 9
    INT 21H
    MOV AH, 1              
    INT 21H
    JMP MAIN_MENU

EXIT_PROGRAM:
    LEA DX, EXIT_MSG
    MOV AH, 9
    INT 21H
               
    MOV AX,4C00H
    INT 21H

MAIN ENDP

END MAIN
