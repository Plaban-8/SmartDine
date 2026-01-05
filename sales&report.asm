;===========================================
; Simple Sales System
; - Add sale amounts
; - Keep history
; - Show total count and total revenue
;===========================================

.MODEL SMALL
.STACK 100h

;-------------------------------------------
; CONSTANTS
;-------------------------------------------
MAX_SALES   EQU 50    

.DATA
;-------------------------------------------
; STRINGS
;-------------------------------------------

msg_main_title  DB 0DH,0AH,'===== Sales System Test =====',0DH,0AH,'$'
msg_main_menu   DB '1. Add Sale',0DH,0AH,'2. Show Sales Report',0DH,0AH,'0. Exit',0DH,0AH,'$'
msg_choice      DB 'Enter choice: ','$'
msg_invalid     DB 0DH,0AH,'Invalid choice! Try again.',0DH,0AH,'$'

msg_enter_amount    DB 0DH,0AH,'Enter sale amount: ','$'
msg_sales_full      DB 0DH,0AH,'Sales history is full. Cannot add more.',0DH,0AH,'$'
msg_sale_added      DB 0DH,0AH,'Sale recorded successfully.',0DH,0AH,'$'

msg_report_header   DB 0DH,0AH,'--- Sales Report ---',0DH,0AH,'$'
msg_no_sales        DB 'No sales recorded yet.',0DH,0AH,'$'
msg_total_count     DB 'Total sales count: ','$'
msg_total_revenue   DB 0DH,0AH,'Total revenue: ','$'
msg_list_header     DB 0DH,0AH,'Sales list:',0DH,0AH,'$'
msg_colon_space     DB ': ','$'

;-------------------------------------------
; SALES DATA
;-------------------------------------------

sales_count     DW 0                    
total_revenue   DW 0                    
sales_amounts   DW MAX_SALES DUP(0)    

;-------------------------------------------
; INPUT BUFFERS
;-------------------------------------------

; menu input: max 3 chars (e.g. "12")
menu_buf_max    DB 3
menu_buf_len    DB 0
menu_buf_data   DB 3 DUP(0)

; number input: for sale amount, max 5 digits
num_buf_max     DB 5
num_buf_len     DB 0
num_buf_data    DB 5 DUP(0)

.CODE

;-------------------------------------------
; MACROS
;-------------------------------------------

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

;-------------------------------------------
; ReadMenuChoice
; - Uses DOS 0Ah buffer
; - Reads a whole line like "1?"
; - Returns first character in AL
;-------------------------------------------
ReadMenuChoice PROC
    push dx

    lea dx, menu_buf_max
    mov ah, 0Ah
    int 21h

    mov al, menu_buf_data    

    pop dx
    ret
ReadMenuChoice ENDP

;-------------------------------------------
; ReadNumber
; - Uses DOS 0Ah into num_buf_*
; - Converts all digits to AX
; - Ignores non-digits
;-------------------------------------------
ReadNumber PROC
    push bx
    push cx
    push dx
    push si

    ; buffered input
    lea dx, num_buf_max
    mov ah, 0Ah
    int 21h

    mov cl, num_buf_len
    mov ch, 0
    lea si, num_buf_data
    xor ax, ax               

rn_loop:
    cmp cx, 0
    je  rn_done

    mov dl, [si]

    cmp dl, '0'
    jb  rn_next
    cmp dl, '9'
    ja  rn_next

    sub dl, '0'              
    mov dh, 0
    mov bx, dx               

    mov dx, 0
    mov cx, 10
    mul cx                   
    add ax, bx              

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

;-------------------------------------------
; PrintNumber
; - Prints AX as unsigned decimal
; - Uses stack to store digits
;-------------------------------------------
PrintNumber PROC
    push bx
    push cx
    push dx

    cmp ax, 0
    jne pn_convert
    ; print single '0'
    mov dl, '0'
    mov ah, 2
    int 21h
    jmp pn_done

pn_convert:
    mov cx, 0                

pn_div_loop:
    xor dx, dx
    mov bx, 10
    div bx                  
    push dx                  
    inc cx
    cmp ax, 0
    jne pn_div_loop

pn_print_loop:
    pop dx
    add dl, '0'             
    mov ah, 2
    int 21h
    loop pn_print_loop

pn_done:
    pop dx
    pop cx
    pop bx
    ret
PrintNumber ENDP

;-------------------------------------------
; AddSale
; - reads sale amount
; - stores in array
; - updates sales_count and total_revenue
;-------------------------------------------
AddSale PROC
    push ax
    push bx
    push dx
    push si

    mov ax, sales_count
    cmp ax, MAX_SALES
    jb  as_can
    PRINT msg_sales_full
    jmp as_done

as_can:
    PRINT msg_enter_amount
    call ReadNumber          

    ; store AX into sales_amounts[sales_count]
    mov bx, sales_count
    shl bx, 1               
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

as_done:
    pop si
    pop dx
    pop bx
    pop ax
    ret
AddSale ENDP

;-------------------------------------------
; ShowReport
; - Prints total count, total revenue, list of sales
;-------------------------------------------
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
    jne sr_has
    PRINT msg_no_sales
    jmp sr_done

sr_has:
    ; total count
    PRINT msg_total_count
    mov ax, sales_count
    call PrintNumber

    ; total revenue
    PRINT msg_total_revenue
    mov ax, total_revenue
    call PrintNumber
    NEWLINE

    ; list
    PRINT msg_list_header

    mov cx, sales_count     
    xor di, di              

sr_loop:
    cmp di, cx
    je  sr_done

    ; print index (1-based)
    mov ax, di
    inc ax
    call PrintNumber
    PRINT msg_colon_space

    ; print sales_amounts[di]
    mov bx, di
    shl bx, 1                
    mov si, OFFSET sales_amounts
    add si, bx
    mov ax, [si]
    call PrintNumber
    NEWLINE

    inc di
    jmp sr_loop

sr_done:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
ShowReport ENDP

;-------------------------------------------
; MAIN MENU LOOP
;-------------------------------------------
MAIN PROC
    mov ax, @DATA
    mov ds, ax

main_loop:
    PRINT msg_main_title
    PRINT msg_main_menu
    PRINT msg_choice
    call ReadMenuChoice      

    cmp al, '1'
    je  do_add
    cmp al, '2'
    je  do_report
    cmp al, '0'
    je  do_exit

    PRINT msg_invalid
    jmp main_loop

do_add:
    call AddSale
    jmp main_loop

do_report:
    call ShowReport
    jmp main_loop

do_exit:
    mov ax, 4C00h
    int 21h
MAIN ENDP

END MAIN
