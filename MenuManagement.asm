;===========================================
; SmartDine - Feature 1 (Rohan)
; Menu Management: Add / Remove / Update / Show
;===========================================

.MODEL SMALL
.STACK 100h

;-------------------------------------------
; CONSTANTS
;-------------------------------------------
MAX_DISHES  EQU 10
NAME_LEN    EQU 16          

.DATA
;-------------------------------------------
; STRINGS
;-------------------------------------------

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

;-------------------------------------------
; MENU DATA
;-------------------------------------------
menu_count      DB 0                        
menu_names      DB MAX_DISHES*NAME_LEN DUP('$')
menu_prices     DW MAX_DISHES DUP(0)

; input buffers for DOS 0Ah (still used for numbers)
name_buffer     DB 15
name_len        DB ?
name_data       DB 15 DUP(?)

num_buffer      DB 5
num_len         DB ?
num_data        DB 5 DUP(?)

num_out         DB 6 DUP('$') 

;-------------------------------------------
; MACROS
;-------------------------------------------
.CODE

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
; HELPER: PrintZString DS:SI until '$'
;-------------------------------------------
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

;-------------------------------------------
; HELPER: ReadNumber -> AX
;-------------------------------------------
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
    xor ax, ax           

rn_loop:
    cmp cx, 0
    je  rn_done

    mov dl, [si]
    cmp dl, 0DH       
    je  rn_done

    cmp dl, '0'
    jb  rn_next
    cmp dl, '9'
    ja  rn_next

    sub dl, '0'
    mov bx, 0
    mov bl, dl        

    xor dx, dx
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
; HELPER: PrintNumber AX
;-------------------------------------------
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
    div bx             
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

;-------------------------------------------
; HELPER: Problem hoise
;-------------------------------------------
ReadNameToDest PROC
    push ax
    push cx
    push dx

    mov cx, 0                   

rnt_loop:
    mov ah, 01h                  
    int 21h                      

    cmp al, 0Dh                 
    je  rnt_done

    cmp cx, NAME_LEN-1          
    jae rnt_flush                

    mov [di], al                
    inc di
    inc cx
    jmp rnt_loop

rnt_flush:
    ; we've reached max length; just flush the rest of the line
    jmp rnt_loop

rnt_done:
    mov byte ptr [di], '$'      

    pop dx
    pop cx
    pop ax
    ret
ReadNameToDest ENDP

;-------------------------------------------
; ShowMenu
;-------------------------------------------
ShowMenu PROC
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
    mov bl, 0          

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
    shl ax, 1           
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
    shl ax, 1          
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
ShowMenu ENDP

;-------------------------------------------
; AddDish
;-------------------------------------------
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
    shl ax, 1           
    lea di, menu_names
    add di, ax

    call ReadNameToDest ; <-- now correct

    PRINT msg_enter_price
    call ReadNumber      

    mov bl, menu_count
    xor bh, bh
    mov dx, ax
    mov ax, bx
    shl ax, 1            
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

;-------------------------------------------
; UpdateDishPrice
;-------------------------------------------
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
    call ShowMenu
    PRINT msg_select_dish
    call ReadNumber      

    cmp ax, 1
    jb  udp_invalid
    mov bl, menu_count
    xor bh, bh
    cmp ax, bx
    ja  udp_invalid

    dec ax              
    mov bl, al

    PRINT msg_enter_price
    call ReadNumber      
    mov dx, ax

    xor bh, bh
    mov ax, bx
    shl ax, 1            
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

;-------------------------------------------
; RemoveDish
;-------------------------------------------
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
    call ShowMenu
    PRINT msg_select_dish
    call ReadNumber      

    cmp ax, 1
    jb  rd_invalid
    mov bl, menu_count
    xor bh, bh
    cmp ax, bx
    ja  rd_invalid

    dec ax               
    mov bl, al

    ; last index = menu_count - 1
    mov al, menu_count
    dec al
    cmp bl, al
    jae rd_skip_shift  

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
    add si, ax         

    ; dest index = BL
    mov ax, bx
    shl ax, 1
    shl ax, 1
    shl ax, 1
    shl ax, 1
    lea di, menu_names
    add di, ax         

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
    add di, ax          

    mov ax, bx
    inc ax
    shl ax, 1
    lea si, menu_prices
    add si, ax          

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

;-------------------------------------------
; MenuManagement main loop
;-------------------------------------------
MenuManagement PROC
mm_loop:
    PRINT msg_menu_title
    PRINT msg_menu_options
    PRINT msg_choice
    call ReadNumber      

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
    call ShowMenu
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

;-------------------------------------------
; MAIN (entry point)
;-------------------------------------------
MAIN PROC
    mov ax, @DATA
    mov ds, ax

main_loop:
    PRINT msg_main_title
    PRINT msg_main_menu
    PRINT msg_choice
    call ReadNumber     

    cmp ax, 1
    je  go_menu
    cmp ax, 0
    je  quit

    PRINT msg_invalid
    jmp main_loop

go_menu:
    call MenuManagement
    jmp main_loop

quit:
    mov ax, 4C00h
    int 21h
MAIN ENDP

END MAIN
