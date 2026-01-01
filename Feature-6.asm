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
    ; Implement: JMP ADMIN_DASHBOARD
    ; For Now: JMP MAIN_MENU           

WAITER_GRANTED:
    LEA DX, LOGIN_SUCCESS
    MOV AH, 9
    INT 21H
    MOV AH, 1               
    INT 21H
    ; Implement: JMP WAITER_DASHBOARD 
    ; For Now: JMP MAIN_MENU        

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

    END MAIN