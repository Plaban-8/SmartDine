.MODEL SMALL
 
.STACK 100H

.DATA

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



; MENU DATA
NUM_DISHES EQU 3
DISH_NAME_LEN EQU 15

DishName DB 'Burger         '
         DB 'Pizza          '   
         DB 'Pasta          '
DishPrice DW 8, 12, 15

;Two ingredients per dish
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
AdminMenuTxt    DB 10, 13, '=== Admin Dashboard ===', 10, 13, '1. Show Inventory', 10, 13, '2. Restock Inventory', 10, 13, '3. Logout', 10, 13, 'Select: $'
WaiterMenuTxt   DB 10, 13, '=== Waiter Dashboard ===', 10, 13, '1. Show Tables', 10, 13, '2. Take Order', 10,13, '3. Generate Bill', 10, 13, '4. Logout', 10, 13, 'Select: $'

; Temp storage
InputBuffer   DB 6 DUP(0)
TempNum       DW 0
CurrentTable  DW 0
CurrentDish   DW 0

.CODE
MAIN PROC

; initialize DS

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
    LEA DX, PASS_PROMPT
    MOV AH, 9
    INT 21H

    LEA SI, ADMIN_PASS      
    MOV CX, 4               
    CALL CHECK_PASSWORD     

    CMP BX, 1             
    JE ADMIN_GRANTED
    JMP ACCESS_DENIED

WAITER_LOGIN:
    LEA DX, PASS_PROMPT
    MOV AH, 9
    INT 21H

    LEA SI, WAITER_PASS     
    MOV CX, 4               
    CALL CHECK_PASSWORD     

    CMP BX, 1
    JE WAITER_GRANTED
    JMP ACCESS_DENIED

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
    JE MAIN_MENU
    JMP ADMIN_DASHBOARD
    
CALL_SHOW_INV:
    CALL SHOW_INVENTORY
    JMP ADMIN_DASHBOARD
    
CALL_RESTOCK:
    CALL RESTOCK_INVENTORY
    JMP ADMIN_DASHBOARD
    
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

;exit to DOS
               
MOV AX,4C00H
INT 21H

MAIN ENDP


CHECK_PASSWORD PROC
    MOV BX, 1              

CHECK_LOOP:
    MOV AH, 1             
    INT 21H
 
    CMP AL, [SI]
    JNE SET_FAIL            
    
    INC SI                  
    JMP CONTINUE_LOOP

SET_FAIL:
    MOV BX, 0               
    INC SI                

CONTINUE_LOOP:
    LOOP CHECK_LOOP
    RET

CHECK_PASSWORD ENDP

;Waiter feature procedures

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
    JNE PRINT_OCCUPIED
    
    LEA DX, MsgAvailable
    JMP PRINT_STATUS
    
PRINT_OCCUPIED:
    LEA DX, MsgOccupied
    
PRINT_STATUS:
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
    
GET_TABLE:
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
    JAE GET_TABLE 
    
    ; Check if table is available
    MOV AL, TableStatus[BX]
    CMP AL, 0
    JE TABLE_OK
    
    ;table occupied error
    LEA DX, MsgTableOccErr
    MOV AH, 9
    INT 21H
    JMP GET_TABLE
    
TABLE_OK:
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

GET_DISH:
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
    JAE GET_DISH       
    
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
    JB NO_STOCK         
    
    ;get second ingredient index
    MOV SI, CurrentDish
    MOV AL, DishIng2[SI]
    MOV AH, 0
    MOV SI, AX
    SHL SI, 1
    MOV AX, IngQty[SI]
    CMP AX, 1
    JB NO_STOCK         
    
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
    JAE SKIP_STORAGE    
    
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
    
SKIP_STORAGE:
    
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
    JE GET_DISH_JUMP
    JMP ORDER_DONE

GET_DISH_JUMP:
    JMP GET_DISH
    
NO_STOCK:
    LEA DX, MsgNoStock
    MOV AH, 9
    INT 21H
    JMP ORDER_DONE
    
ORDER_DONE:
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
    
SHOW_DISH_LOOP:
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
PRINT_DISH_NAME:
    MOV DL, DishName[SI]
    MOV AH, 2
    INT 21H
    INC SI
    LOOP PRINT_DISH_NAME
    
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
    LOOP SHOW_DISH_LOOP
    
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
    
SHOW_ING_LOOP:
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
PRINT_ING_NAME:
    MOV DL, IngName[SI]
    MOV AH, 2
    INT 21H
    INC SI
    LOOP PRINT_ING_NAME
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
    LOOP SHOW_ING_LOOP
    
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
    
GET_ING:
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
    JAE GET_ING         ; If >= NUM_INGS, ask again
    
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
    
    ;iupdate inventory
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

PRINT_NUMBER PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    
    MOV BX, 10         
    MOV CX, 0           
    
CONVERT_LOOP:
    MOV DX, 0           
    DIV BX              
    PUSH DX            
    INC CX
    CMP AX, 0
    JNE CONVERT_LOOP
    
PRINT_LOOP:
    POP DX              
    ADD DL, '0'         
    MOV AH, 2
    INT 21H
    LOOP PRINT_LOOP
    
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
    JE GB_EXIT

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

GB_EXIT:
    POP DI
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
GENERATE_BILL ENDP


    END MAIN