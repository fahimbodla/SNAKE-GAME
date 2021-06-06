[org 0x0100]
jmp start
oldkbisr: dd 0
oldtisr: dd 0
count: db 13
button: db 0
score: dw 0
level: db 0
lives: dw 3
fruit: db 0
gameend: db 0
randomno: dw 0
scoredis : db 0
msg1: db 'GAME OVER',0
msg2: db 'LIVES :',0
msg3: db 'PRESS ANY KEY TO CONTINUE',0
msg4: db 'STAGE 1',0
msg5: db 'STAGE 2',0
msg6: db 'STAGE 3',0
msg7: db 'SCORE:',0
msg10: db 'YOU HAVE WON',0
msg15: db 'PRESS 1 for LEVEL 1',0
msg16: db 'PRESS 2 for LEVEL 2',0
msg17:db'TOTAL LIVES : 3',0
ticker: dw 0
sec :db 0
min db 4
eat:db 0
loc :dw 0
counter :db 0
speed :db 0
scoredisplay:
push 25
push 50
push msg7
call printmsg
push es
push ax
push bx
push cx
push dx

mov ax, 0xb800
mov es, ax                       ; point es to video base
mov ax, [score]                ; load number in ax
mov bx, 10                       ; use base 10 for division
mov cx, 0                        ; initialize count of digits
nextdigit1:
mov dx, 0                        ; zero upper half of dividend
div bx                           ; divide by 10
add dl, 0x30                     ; convert digit into ascii value
push dx                          ; save ascii value on stack
inc cx                           ; increment count of values
cmp ax, 0                        ; is the quotient zero
jnz nextdigit1                  ; if no divide it again point di to top left column
mov bx,66

nextpos1: 
pop dx                           ; remove a digit from the stack
mov dh, 0x07                     ; use normal attribute
mov [es:bx], dx                  ; print char on screen
add bx, 2                        ; move to next screen location
loop nextpos1                   ; repeat for all digits on stack

pop dx
pop cx
pop bx
pop ax
pop es

ret 
;SAVE ALL COORDINATES OF VIDEO SCREEN BEFORE PRESSING BUTTONS FOR PROPER ERASING PURPOSES
time:
push 0xb800
pop es
push si
push ax
push bx
inc word[ticker]
cmp word[ticker],18
jne near exit

mov word[ticker],0
inc byte[counter]
cmp byte[counter],20 ;speed twice after every 20s
jne skii
add byte[speed],1
mov byte[counter],0
skii:
mov si,150
mov al,[sec]
mov ah,0
mov bl,0x10
div bl
add al,0x30
add ah,0x30
mov byte[es:si+2],al
mov byte[es:si+4],ah
mov byte[es:si],':'
mov al,[min]
add al,0x30
mov byte[es:si-2],al
cmp byte[sec],0
jne same1
cmp byte[min],0
jne noend 
mov byte[min],4
mov byte[sec],0
mov byte[speed],0
dec byte[lives]
jmp exit
noend:
mov byte[sec],0x59
dec byte[min]
jmp exit
same1:
mov ah,0
mov al,[sec]
mov bl,0x10
div bl
cmp ah,0
jne same
sub byte[sec],6
same:
dec byte[sec]
exit:
pop bx
pop ax
pop si
ret
fruits:
push es
push ax
push bx
push dx
push cx
shru:
mov ah,0
cli
int 1ah
sti
mov bx,dx
mov dx,[ds:bx]
cmp dx, 482
jl  shru
cmp dx,3838
ja shru
push 0xb800
pop es
mov bx,dx
test bx,0x0001
jz skip
inc bx
skip:
mov ax,0x3020
cmp [es:bx],ax
jne shru
mov ax,bx
mov dx,0
mov cx,7
div cx
cmp dx,0
je near dollar
mov ax,bx
mov dx,0
mov cx,3
div cx
cmp dx,0
je near percent
mov ax,bx
mov dx,0
mov cx,5
div cx
cmp dx,0
je hash
mov ax,bx
mov dx,0
mov cx,0x11
div cx
cmp dx,0
je rate
mov ax,bx
mov dx,0
mov cx,0x13
div cx
cmp dx,0
je power
mov ax,bx
mov dx,0
mov cx,0x17
div cx
cmp dx,0
je plus
mov ax,bx
mov dx,0
mov cx,0x19
div cx
cmp dx,0
je minus
minus:
mov al,'-'
mov ah,0x07
mov [es:bx],ax
mov word[loc],bx
jmp ending
plus:
mov al,'+'
mov ah,0xf0
mov [es:bx],ax
mov word[loc],bx
jmp ending
power:
mov al,'^'
mov ah,0xa0
mov [es:bx],ax
mov word[loc],bx
jmp ending
rate:
mov al,'@'
mov ah,0x90
mov [es:bx],ax
mov word[loc],bx
jmp ending
hash :
mov al,'#'
mov ah,0xe0
mov [es:bx],ax
mov word[loc],bx
jmp ending
percent:
mov al,'%'
mov ah,0xc0
mov [es:bx],ax
mov word[loc],bx
jmp ending
dollar:
mov al,'$'
mov ah,0x07
mov [es:bx],ax
mov word[loc],bx
jmp ending
ending:
pop cx
pop dx
pop bx
pop ax
pop es
ret
;TIME'S ISR
mytisr:
;push di
call time
;pop di
;call randomnogen
dec byte[count]
cmp byte[count],0               ;end tisr if a second has not passed
je caller
jmp endtisr

caller:
mov byte[count],13
push cx
mov cl,[speed]
sub [count],cl
pop cx
cmp byte[button],0
je near bridge                              ;end tisr if no button was pressed initially
 
cmp byte[button],0x48                  ;scan code of up
je movup
cmp byte[button],0x50                  ;scan code of down
je near movdown
cmp byte[button],0x4B                  ;scan code of left
je near movleft
cmp byte[button],0x4D                  ;scan code of right
je near movright
jmp endtisr

movup:                                 ;Use Frequency 9121 for movement
push 9121
call soundgen

mov ax,[es:di]

;call clrscreen
;call printboundary
;call backgroundcolor
call printlives
mov byte[es:di],'*'
sub di,160
cmp byte[es:di],'*'
jne space
dec byte[lives]
jmp endtisr
space:
mov [es:di],ax
cmp [loc],di
jne f1
mov byte[fruit],1
push 3224
call soundgen
add word[score],2
inc byte[gameend]
mov byte[eat],4
mov byte[scoredis],1
f1:
cmp byte[eat],0
ja sizeup
call eraser
jmp nosize
sizeup:
dec byte[eat]
nosize: 
call checkboundary
;call checkitself
cmp byte[level],1
jne next5
call hurdlecheck
jmp endtisr
next5:
cmp byte[level],2
jne next6
call stage3check
next6:
jmp endtisr

movdown:
push 9121
call soundgen
mov ax,[es:di]

;call clrscreen
;call printboundary
;call backgroundcolor
call printlives
mov byte[es:di],'*'
add di,160
cmp byte[es:di],'*'
jne space1
dec byte[lives]
jmp endtisr
space1:
mov [es:di],ax
cmp [loc],di
jne f2
mov byte[fruit],1
push 3224
call soundgen
add word[score],2
inc byte[gameend]
mov byte[eat],4
mov byte[scoredis],1
f2:
cmp byte[eat],0
ja sizeup1
call eraser
jmp nosize1
sizeup1:
dec byte[eat]
nosize1: 
call checkboundary
;call checkitself
cmp byte[level],1
jne next51
call hurdlecheck
jmp endtisr
next51:
cmp byte[level],2
jne next61
call stage3check
next61:
jmp endtisr

bridge:
jmp endtisr

movleft:
push 9121
call soundgen
mov ax,[es:di]

;call clrscreen
;call printboundary
;call backgroundcolor
call printlives
mov byte[es:di],'*'
sub di,2
cmp byte[es:di],'*'
jne space2
dec byte[lives]
jmp endtisr
space2:
mov [es:di],ax
cmp [loc],di
jne f3
mov byte[fruit],1
push 3224
call soundgen
add word[score],2
inc byte[gameend]
mov byte[eat],4
mov byte[scoredis],1
f3:
cmp byte[eat],0
ja sizeup2
call eraser
jmp nosize2
sizeup2:
dec byte[eat]
nosize2: 
call checkboundary
;call checkitself
cmp byte[level],1
jne next52
call hurdlecheck
jmp endtisr
next52:
cmp byte[level],2
jne next62
call stage3check
next62:
jmp endtisr

movright:
push 9121
call soundgen
mov ax,[es:di]
;call clrscreen
;call printboundary
;call backgroundcolor
call printlives
mov byte[es:di],'*'
add di,2
cmp byte[es:di],'*'
jne space4
dec byte[lives]
jmp endtisr
space4:
mov [es:di],ax
cmp [loc],di
jne f4
mov byte[fruit],1
push 3224
call soundgen
add word[score],2
inc byte[gameend]
mov byte[eat],4
mov byte[scoredis],1
f4:
cmp byte[eat],0
ja sizeup3
call eraser
jmp nosize3
sizeup3:
dec byte[eat]
nosize3: 
call checkboundary
;call checkitself
cmp byte[level],1
jne next53
call hurdlecheck
jmp endtisr
next53:
cmp byte[level],2
jne next63
call stage3check
next63:
jmp endtisr
endtisr:
mov byte[es:di],'o'
jmp far[cs:oldtisr]


;KB'S ISR
mykbisr:
push 0xb800
pop es


in al,0x60
test al,128                             ;check if its a press button
jnz near endkbisr

cmp al,0x48                             ;scan code of up
je up
cmp al,0x50                             ;scan code of down
je down
cmp al,0x4B                             ;scan code of left
je left
cmp al,0x4D                             ;scan code of right
je right
jmp endkbisr
up:
;mov byte[es:di],'U'
cmp byte[button],0x50
je endkbisr
mov byte[button],al
;mov ax,[es:di]
;call clrscreen
;sub di,160
;mov [es:di],ax
jmp endkbisr

down:
;mov byte[es:di],'D'
cmp byte[button],0x48
je endkbisr
mov byte[button],al
;mov ax,[es:di]
;call clrscreen
;add di,160
;mov [es:di],ax
jmp endkbisr

left:
;mov byte[es:di],'L'
cmp byte[button],0x4D
je endkbisr
mov byte[button],al

;mov ax,[es:di]
;call clrscreen
;sub di,2
;mov [es:di],ax
jmp endkbisr

right:
;mov byte[es:di],'R'
cmp byte[button],0x4B
je endkbisr
mov byte[button],al
;mov ax,[es:di]
;call clrscreen
;add di,2
;mov [es:di],ax
jmp endkbisr

endkbisr:
jmp far[cs:oldkbisr]


;CLEAR SCREEN FUNCTION
clrscreen:
push ax
push di
push es
push cx

push 0xb800
pop es
mov cx,2000
mov di,0
mov ax,0x0720
rep stosw

pop cx
pop es
pop di
pop ax
ret

;PRINT MESSAGE FUNCTION
printmsg:                                  ;takes attribute,location,offset as parameters respectively of a msg
push bp
mov bp,sp
push si
push di
push es
push ds
push ax

push 0xb800
pop es

mov si,[bp+4]
mov di,[bp+6]
mov ah,[bp+8]

l2:
lodsb
stosw
cmp byte[ds:si],0
jne l2


pop ax
pop ds
pop es
pop di
pop si
pop bp

ret 6

;PRINT BOUNDARY FUNCTION
printboundary:
push ax
push di
push es
push 0xb800
pop es
mov di,320
mov ah,01010000b
mov al,'-'
l3:
stosw
cmp di,480
jne l3
mov di,480
mov al,'|'
l4:
mov [es:di],ax
add di,160
cmp di,4000
jne l4
mov di,638
mov al,'|'
l5:
mov [es:di],ax
add di,160
cmp di,3998
jne l5
mov di,3840
mov al,'-'
l6:
stosw
cmp di,3998
jne l6
stosw
pop es
pop di
pop ax
ret

;TO PRINT BACKGROUND COLOR
backgroundcolor:
push es
push ax
push bx
mov ax, 0xb800
mov es, ax 
mov bx, 482
mov ax,638
next:
mov word [es:bx], 0011000000100000b
add bx, 2 ; move to next screen location
cmp ax,bx
jne ski
add bx,4
add ax,160
ski:
cmp bx, 3840 ; has the whole screen cleared
jb next ; if no clear next position
pop bx
pop ax
pop es
ret


;TO CHECK BOUNDARY HIT
checkboundary:
push ax
push bx
push dx
;CHECK UPPER BOUNDARY
UBslowerlim:
cmp di,320
jge UBshigherlim
jmp LBslowerlim

UBshigherlim:
cmp di,480
jle lifegone

;CHECK LOWER BOUNDARY
LBslowerlim:
cmp di,3838
jge LBshigherlim
jmp leftboundary

LBshigherlim:
cmp di,3998
jle lifegone
;CHECK LEFT BOUNDARY
leftboundary:
mov dx,0
mov ax,di
mov bx,160
div bx
cmp dx,0
je lifegone
;CHECK RIGHT BOUNDARY
rightboundary:
mov ax,di
l7:
sub ax,160
cmp ax,158
jg l7
cmp ax,158
je lifegone
jmp endcheckboundary

lifegone:
dec byte[lives]
cmp byte[lives],0
jne endcheckboundary

gameover:
push 0xF9
push 1990
push msg1
call printmsg

endcheckboundary:
pop dx
pop bx
pop ax

ret

;TO PRINT LIVES
printlives:

push ax
push bx
mov bx,16
mov ax,[lives]
add al,0x30
mov ah,0x07
mov [es:bx],ax
push 0x0E
push 0
push msg2
call printmsg
pop bx
pop ax

ret

;GENERATING SOUND
soundgen:                          ;Takes Frequence as Parameter on stack
push bp
mov bp,sp
push ax
push bx
push cx

mov al,182
out 43h,al
mov ax,[bp+4]

out 42h,al
mov al,ah
out 42h,al
in al,61h

or al,00000011b
out 61h,al
mov bx,1

pause1:
mov cx,65535
pause2:
dec cx
jne pause2
dec bx
jne pause1
in al,61h

and al,11111100b
out 61h,al

pop cx
pop bx
pop ax
pop bp

ret 2

;FUNCTION TO ERASE ASTERIKS
eraser:
push ax
push ds

push 0xb800
pop ds
mov ax,0x3020

;cmp byte[button],0x48
;je priority1
;cmp byte[button],0x50
;je priority1

;priority2:
cmp byte[ds:si-2],'*'
je onleft
cmp byte[ds:si+2],'*'
je onright
;priority1:
cmp byte[ds:si+160],'*'
je ondownside
cmp byte[ds:si-160],'*'
je onupside
;jmp priority2
;jmp enderaser

onleft:
mov [ds:si],ax
sub si,2
jmp enderaser

onright:
mov [ds:si],ax
add si,2
jmp enderaser

onupside:
mov [ds:si],ax
sub si,160
jmp enderaser

ondownside
mov [ds:si],ax
add si,160



enderaser:
pop ds
pop ax

ret

;CREATE THE HURDLE
hurdle:
push ax
push di
push es
push 0xb800
pop es
mov di,1790
mov ah,01000000b
mov al,'-'
mov cx,50
rep stosw
mov di,3070
mov cx,50
rep stosw
pop es
pop di
pop ax
ret

;CHECK THE HURDLE
hurdlecheck:
cmp di,1788
jbe nextcmp
cmp di,1890
jae nextcmp
dec byte[lives]
;mov byte[button],0
;mov word[loc],2500
jmp hurdleend
nextcmp:
cmp di,3068
jbe hurdleend
cmp di,3170
jae hurdleend
dec byte[lives]
;mov byte[button],0
;mov word[loc],2500
hurdleend
ret
stage3:
push ax
push di
push es
push 0xb800
pop es
mov ah,0x20
mov al,'-'
mov di,2760
mov cx,40
rep stosw
mov di,1480
mov cx,40
rep stosw
mov di,3400
mov cx,40
rep stosw
mov di,1160
mov cx,40
rep stosw
mov di,2280
mov cx,40
rep stosw
pop es
pop di
pop ax
ret
stage3check:
cmp di,1158
jbe sta11
cmp di,1240
jae sta11
dec byte[lives]
jmp khatam
sta11:
cmp di,1478
jbe sta12
cmp di,1560
jae sta12
dec byte[lives]
jmp khatam
sta12:
cmp di,2278
jbe sta13
cmp di,2360
jae sta13
dec byte[lives]
jmp khatam
sta13:
cmp di,2758
jbe sta14
cmp di,2840
jae sta14
dec byte[lives]
jmp khatam
sta14:
cmp di,3398
jbe khatam
cmp di,3480
jae khatam
dec byte[lives]
khatam:
ret


;INT MAIN()
start:
call clrscreen
push 0xF9
push 1990
push msg15
call printmsg
push 0xF9
push 2310
push msg16
call printmsg
mov ah,0
int 0x16
cmp al,0x31
jne next1
mov byte[level],1
jmp next2
next1:
cmp al,0x32
jne start
mov byte[level],2
next2:
mov byte[button],0x4B
xor ax,ax
mov es,ax
mov ax,[es:9*4]                            ;save real keyboard's offset
mov bx,[es:9*4+2]                          ;save real keyboard's segment
mov [oldkbisr],ax
mov [oldkbisr+2],bx

mov ax,[es:8*4]                            ;save real time's offset
mov bx,[es:8*4+2]                          ;save real time's segment
mov [oldtisr],ax
mov [oldtisr+2],bx

call clrscreen
call backgroundcolor
call printboundary
cmp byte[level],1
jne nexth5
call hurdle
nexth5:
cmp byte[level],2
jne nexth16
call stage3
nexth16:
;call backgroundcolor
call printlives
push 0x20
push 160
push msg17
call printmsg
call scoredisplay
;push 0xF9
;push 1990
;push msg1
;call printmsg

;HOOKING
cli
mov word[es:9*4],mykbisr                   ;hook offset of mykbisr
mov [es:9*4+2],cs                          ;hook segment of mykbisr
mov word[es:8*4],mytisr                    ;hook offset of mytisr
mov [es:8*4+2],cs                          ;hook segment of mytisr
sti

mov bl,3

reset:
;push 0x0E
;push 1976
;push msg3
;call printmsg
;mov word[loc],1628
cli
push ax
mov ah,0
int 0x16
pop ax
sti
call fruits
mov si,2158
mov di,2158
push 0xb800
pop es
mov byte[gameend],0
mov byte[es:di],'*'
sub di,2
mov byte[es:di],'*'
sub di,2
mov byte[es:di],'*'
sub di,2
mov byte[es:di],'*'
sub di,2
mov byte[es:di],'*'
sub di,2
mov byte[es:di],'*'
sub di,2
mov byte[es:di],'*'
sub di,2
mov byte[es:di],'*'
sub di,2
mov byte[es:di],'*'
sub di,2
mov byte[es:di],'*'
sub di,2
mov byte[es:di],'*'
sub di,2
mov byte[es:di],'*'
sub di,2
mov byte[es:di],'*'
sub di,2
mov byte[es:di],'*'
sub di,2
mov byte[es:di],'*'
sub di,2
mov byte[es:di],'*'
sub di,2
mov byte[es:di],'*'
sub di,2
mov byte[es:di],'*'
sub di,2
mov byte[es:di],'*'
sub di,2
mov byte[es:di],'o'
mov byte[button],0x4B

l1:

cmp byte[fruit],1
jne noeat
;push di
call fruits
;pop di
mov byte[fruit],0
noeat:
cmp byte[gameend],55
je near win
cmp byte[scoredis],1
jne noscore
call scoredisplay
mov byte[scoredis],0
noscore:
cmp byte[lives],bl
je l1

push 1140
call soundgen
call clrscreen
call backgroundcolor
cmp byte[level],1
jne nextcheck
call hurdle
jmp next23
nextcheck:
call stage3
next23:
call printboundary
cmp byte[level],1
jne nexth
call hurdle
nexth:
cmp byte[level],2
jne nexth1
call stage3
nexth1:
push 0x20
push 160
push msg17
call printmsg
call printlives
call scoredisplay
mov byte[min],4
mov byte[sec],0
mov byte[speed],0
dec bl
mov byte[es:di],'X'
mov byte[button],0
cmp byte[lives],0
jne reset

push 0xF9
push 1990
push msg1
call printmsg
jmp end4
win:
push 0xF9
push 1990
push msg10
call printmsg
end4:
cli
call printlives
mov byte[button],0
push ax
mov ah,0
int 0x16
pop ax
;UNHOOKING
xor ax,ax
mov es,ax
mov ax,[oldkbisr]                    ;restore real offset of kb
mov bx,[oldkbisr+2]                  ;restore real segment of kb
mov [es:9*4],ax
mov [es:9*4+2],bx
mov ax,[oldtisr]                     ;restore real offset of time
mov bx,[oldtisr+2]                   ;restore real segment of time
mov [es:8*4],ax
mov [es:8*4+2],bx
sti
mov ax,0x4c00
int 21h