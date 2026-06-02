; checksum.inc
; Educational hash for audit log chain

ComputeLogHash proc
    push bx

    ; Load prevHash into AX
    mov ax, prevHash

    ; XOR AX with requestedService
    mov bx, 0
    mov bl, byte ptr requestedService
    xor ax, bx

    ; XOR AX with lastDecision
    mov bl, byte ptr lastDecision
    xor ax, bx

    ; XOR AX with logCounter
    xor ax, logCounter

    ; Rotate AX left by 1 bit
    rol ax, 1

    pop bx
    ret
ComputeLogHash endp

ComputePolicyChecksum proc
    push bx
    push cx
    push si

    mov ax, 0
    lea si, PolicyTable
    mov cx, POLICY_TABLE_COUNT * POLICY_ENTRY_SIZE

ChecksumLoop:
    mov bx, 0
    mov bl, [si]
    add ax, bx
    rol ax, 1
    inc si
    loop ChecksumLoop

    pop si
    pop cx
    pop bx
    ret
ComputePolicyChecksum endp

SelfCheck proc
    push ax
    push bx
    push cx
    push dx

    call ComputePolicyChecksum
    cmp ax, policyMeasurement
    jne TamperFound

    lea dx, selfCheckPassMsg
    call PrintString
    call NewLine
    jmp SelfCheckDone

TamperFound:
    lea dx, tamperDetectedMsg
    call PrintString
    call NewLine
    
    mov failClosed, 1
    
    mov byte ptr requestedService, 0FFh
    mov byte ptr lastDecision, POLICY_TAMPER
    call AddLogEntry

    lea dx, tamperLogMsg
    call PrintString
    call NewLine

    lea dx, failClosedMsg
    call PrintString
    call NewLine

SelfCheckDone:
    pop dx
    pop cx
    pop bx
    pop ax
    ret
SelfCheck endp

SimulateTamper proc
    push ax
    push dx
    push si
    push cx

    lea dx, tamperMsg
    call PrintString
    call NewLine

    lea si, PolicyTable
    mov cx, POLICY_TABLE_COUNT
ScanTableLoop:
    mov al, [si]
    cmp al, DOS_CREATE_FILE
    je ModifyDecision
    add si, POLICY_ENTRY_SIZE
    loop ScanTableLoop
    jmp SimTamperDone

ModifyDecision:
    mov byte ptr [si+1], POLICY_ALLOW

SimTamperDone:
    call SelfCheck
    
    pop cx
    pop si
    pop dx
    pop ax
    ret
SimulateTamper endp
