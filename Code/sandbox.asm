; sandbox.asm

.model small
.stack 100h

.data
    titleMsg    db '=== EMU86 Sandbox Demo ===$'
    initMsg     db '[Sandbox] Initialized$'
    measurePrefix db '[Sandbox] Policy Measurement = $'
    auditMsg    db '[Sandbox] Audit Log Ready$'
    policyMeasurement dw 0
    statusMsg   db '[Phase 7] Audit Logger is running$'
    exitMsg     db 'Program exited safely$'
    newlineStr  db 13, 10, '$'

    testMsg09   db '[Policy Test] AH 09h checked$'
    testMsg3C   db '[Policy Test] AH 3Ch checked$'
    testMsg40   db '[Policy Test] AH 40h checked$'
    testMsg99   db '[Policy Test] Unknown AH checked$'

    requestedService   db ?
    lastDecision       db ?
    requestedDX        dw ?
    requestedDL        db ?

    gatewayMsg         db '[Gateway] Request received$'
    forwardMsg         db '[Gateway] Forwarding allowed request$'
    blockedMsg         db '[Gateway] Request blocked$'
    approvalBlockedMsg db '[Gateway] Blocked approval required request$'
    notForwardedMsg    db '[Gateway] Allowed service not forwarded in this demo$'

    guestNormalMsg     db 'Hello from sandboxed guest$'
    guestChar          db 'A'

    guestReq09         db '[Guest] Request AH 09h$'
    guestReq02         db '[Guest] Request AH 02h$'
    guestReq3C         db '[Guest] Request AH 3Ch$'
    guestReq40         db '[Guest] Request AH 40h$'
    guestReq99         db '[Guest] Request AH 99h$'
    guestReqMask       db '[Guest] Sensitive print request$'
    redactedMsg        db '[REDACTED]$'
    guestSecretMsg     db 'SECRET data from guest$'
    wordSecret         db 'secret$'
    wordPassword       db 'password$'
    wordToken          db 'token$'
    
    interactivePrompt  db 'Enter string to evaluate (or /tamper, /file, /quit): $'
    cmdTamper          db '/tamper$'
    cmdFile            db '/file$'
    cmdQuit            db '/quit$'
    
    inputBuffer        db 64
    inputLength        db 0
    inputString        db 64 dup('$')

    failClosed         db 0
    tamperMsg          db '[Sandbox] Simulating tamper$'
    tamperDetectedMsg  db '[Sandbox] TAMPER DETECTED$'
    selfCheckPassMsg   db '[Sandbox] Self check passed$'
    failClosedMsg      db '[Sandbox] FAIL CLOSED MODE ENABLED$'
    failClosedBlockMsg db '[Sandbox] DENIED Fail closed mode active$'
    postTamperReqMsg   db '[Guest] Protected request after tamper$'
    tamperLogMsg       db '[Log] TAMPER event recorded$'

    ; --- policy.inc inlined ---
    DOS_PRINT_STRING equ 09h
    DOS_READ_CHAR    equ 01h
    DOS_PRINT_CHAR   equ 02h
    DOS_CREATE_FILE  equ 3Ch
    DOS_OPEN_FILE    equ 3Dh
    DOS_CLOSE_FILE   equ 3Eh
    DOS_READ_FILE    equ 3Fh
    DOS_WRITE_FILE   equ 40h
    DOS_EXIT         equ 4Ch

    POLICY_ALLOW     equ 0
    POLICY_DENY      equ 1
    POLICY_MASK      equ 2
    POLICY_APPROVE   equ 3
    POLICY_TAMPER    equ 4

    PolicyTable label byte
        db 09h, 0
        db 01h, 0
        db 02h, 0
        db 3Ch, 1
        db 3Dh, 0
        db 3Eh, 0
        db 3Fh, 0
        db 40h, 3
        db 4Ch, 0
    PolicyTableEnd label byte

    POLICY_ENTRY_SIZE equ 2
    POLICY_TABLE_COUNT equ 9

    ; --- logger.inc inlined ---
    LOG_ENTRY_SIZE equ 8
    MAX_LOG_ENTRIES equ 64

    logCounter dw 0
    prevHash   dw 0
    auditLog   db 512 dup(0)

.code
main proc
    mov ax, @data
    mov ds, ax

    call ShowHeader
    call InitSandbox
    call InteractivePromptLoop
    call ShowPhaseStatus
    call ExitProgram
main endp

; --- checksum.inc inlined ---

ComputeLogHash proc
    push bx

    mov ax, prevHash

    mov bx, 0
    mov bl, byte ptr requestedService
    xor ax, bx

    mov bl, byte ptr lastDecision
    xor ax, bx

    xor ax, logCounter

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

ShowHeader proc
    lea dx, titleMsg
    call PrintString
    call NewLine
    call NewLine
    ret
ShowHeader endp

InitSandbox proc
    lea dx, initMsg
    call PrintString
    call NewLine

    call ComputePolicyChecksum
    mov policyMeasurement, ax

    lea dx, measurePrefix
    call PrintString

    mov ax, policyMeasurement
    call PrintHexWord
    call NewLine

    lea dx, auditMsg
    call PrintString
    call NewLine
    ret
InitSandbox endp

ShowPhaseStatus proc
    lea dx, statusMsg
    call PrintString
    call NewLine
    ret
ShowPhaseStatus endp

PrintString proc
    mov ah, DOS_PRINT_STRING
    int 21h
    ret
PrintString endp

NewLine proc
    lea dx, newlineStr
    call PrintString
    ret
NewLine endp

PrintHexWord proc
    push ax
    push bx
    push cx
    push dx

    mov bx, ax
    mov cx, 4
HexLoop:
    rol bx, 1
    rol bx, 1
    rol bx, 1
    rol bx, 1
    mov dl, bl
    and dl, 0Fh
    cmp dl, 9
    jle HexDigit
    add dl, 7
HexDigit:
    add dl, '0'
    mov ah, DOS_PRINT_CHAR
    int 21h
    loop HexLoop

    pop dx
    pop cx
    pop bx
    pop ax
    ret
PrintHexWord endp

ExitProgram proc
    call NewLine
    lea dx, exitMsg
    call PrintString
    call NewLine
    mov ah, DOS_EXIT
    int 21h
ExitProgram endp

InteractivePromptLoop proc
InputLoop:
    call NewLine
    lea dx, interactivePrompt
    mov ah, DOS_PRINT_STRING
    int 21h

    ; Read user input
    lea dx, inputBuffer
    mov ah, 0Ah
    int 21h
    call NewLine

    ; Check if empty input (length == 0)
    cmp inputLength, 0
    je InputLoop

    ; Null-terminate string
    mov bl, inputLength
    mov bh, 0
    lea di, inputString
    add di, bx
    mov byte ptr [di], '$'

    ; Convert the entire input string to canonical lowercase
    lea dx, inputString
    call InPlaceLowercase

    ; Check for /quit
    lea di, cmdQuit
    mov cx, 5
    lea si, inputString
    call MatchExactString
    cmp al, 1
    je EndInteractive

    ; Check for /TAMPER
    lea di, cmdTamper
    mov cx, 7
    lea si, inputString
    call MatchExactString
    cmp al, 1
    je DoTamper

    ; Check for /FILE
    lea di, cmdFile
    mov cx, 5
    lea si, inputString
    call MatchExactString
    cmp al, 1
    je DoFileTest

    ; Evaluate normal string
    mov ah, DOS_PRINT_STRING
    lea dx, inputString
    call SandboxHandler
    jmp InputLoop

DoTamper:
    call SimulateTamper
    jmp InputLoop

DoFileTest:
    lea dx, guestReq3C
    call PrintString
    call NewLine
    mov ah, DOS_CREATE_FILE
    call SandboxHandler
    call NewLine

    lea dx, guestReq40
    call PrintString
    call NewLine
    mov ah, DOS_WRITE_FILE
    call SandboxHandler
    call NewLine
    jmp InputLoop

EndInteractive:
    ret
InteractivePromptLoop endp

SandboxHandler proc
    mov byte ptr requestedService, ah
    mov requestedDX, dx
    mov requestedDL, dl

    cmp failClosed, 1
    jne NormalHandler

    cmp byte ptr requestedService, DOS_EXIT
    je NormalHandler

    lea dx, failClosedBlockMsg
    call PrintString
    call NewLine
    mov byte ptr lastDecision, POLICY_DENY
    call AddLogEntry
    ret

NormalHandler:
    lea dx, gatewayMsg
    call PrintString
    call NewLine

    mov ah, byte ptr requestedService
    call CheckPolicy
    mov byte ptr lastDecision, al

    cmp byte ptr requestedService, DOS_PRINT_STRING
    jne Phase9Done
    cmp byte ptr lastDecision, POLICY_ALLOW
    jne Phase9Done

    mov dx, word ptr requestedDX
    call CheckSensitiveString
    cmp al, 1
    jne Phase9Done
    mov byte ptr lastDecision, POLICY_MASK
Phase9Done:

    call AddLogEntry

    mov al, byte ptr lastDecision
    cmp al, POLICY_ALLOW
    je PrintAllow
    cmp al, POLICY_DENY
    je PrintDeny
    cmp al, POLICY_APPROVE
    je PrintApprove
    cmp al, POLICY_MASK
    je PrintMask

    lea dx, blockedMsg
    jmp PrintDecision

PrintAllow:
    lea dx, forwardMsg
    call PrintString
    call NewLine
    call ForwardAllowedRequest
    ret

PrintDeny:
    lea dx, blockedMsg
    jmp PrintDecision

PrintApprove:
    lea dx, approvalBlockedMsg
    jmp PrintDecision

PrintMask:
    lea dx, redactedMsg

PrintDecision:
    call PrintString
    call NewLine
    ret
SandboxHandler endp

ForwardAllowedRequest proc
    mov ah, byte ptr requestedService

    cmp ah, DOS_PRINT_STRING
    je Forward09
    cmp ah, DOS_PRINT_CHAR
    je Forward02

    lea dx, notForwardedMsg
    call PrintString
    call NewLine
    ret

Forward09:
    mov ah, DOS_PRINT_STRING
    mov dx, word ptr requestedDX
    int 21h
    call NewLine
    ret

Forward02:
    mov ah, DOS_PRINT_CHAR
    mov dl, requestedDL
    int 21h
    call NewLine
    ret
ForwardAllowedRequest endp

CheckPolicy proc
    push bx
    push cx
    push si

    lea si, PolicyTable
    mov cx, POLICY_TABLE_COUNT

SearchPolicyLoop:
    cmp ah, [si]
    je PolicyFound
    add si, POLICY_ENTRY_SIZE
    loop SearchPolicyLoop

    mov al, POLICY_DENY
    jmp PolicyDone

PolicyFound:
    mov al, [si+1]

PolicyDone:
    pop si
    pop cx
    pop bx
    ret
CheckPolicy endp

AddLogEntry proc
    push ax
    push bx
    push cx
    push di

    mov ax, logCounter
    cmp ax, MAX_LOG_ENTRIES
    jge AddLogDone

    mov bx, ax
    shl bx, 1
    shl bx, 1
    shl bx, 1

    lea di, auditLog
    add di, bx

    mov ax, logCounter
    mov [di], ax

    mov al, byte ptr requestedService
    mov [di+2], al

    mov al, byte ptr lastDecision
    mov [di+3], al

    mov ax, prevHash
    mov [di+4], ax

    call ComputeLogHash
    mov [di+6], ax
    mov prevHash, ax

    inc logCounter

AddLogDone:
    pop di
    pop cx
    pop bx
    pop ax
    ret
AddLogEntry endp

CheckSensitiveString proc
    push bx
    push cx
    push si
    push di

    mov si, dx
ScanLoop:
    mov al, [si]
    cmp al, '$'
    je NotFound

    lea di, wordSecret
    mov cx, 6
    call MatchExactString
    cmp al, 1
    je Found

    lea di, wordPassword
    mov cx, 8
    call MatchExactString
    cmp al, 1
    je Found

    lea di, wordToken
    mov cx, 5
    call MatchExactString
    cmp al, 1
    je Found

    inc si
    jmp ScanLoop

Found:
    mov al, 1
    jmp DoneScan

NotFound:
    mov al, 0

DoneScan:
    pop di
    pop si
    pop cx
    pop bx
    ret
CheckSensitiveString endp

MatchExactString proc
    push si
    push di
    push cx
MatchLoop:
    mov al, [si]
    cmp al, '$'
    je MatchFail
    
    mov bl, [di]
    cmp al, bl
    jne MatchFail
    inc si
    inc di
    loop MatchLoop

    mov al, 1
    pop cx
    pop di
    pop si
    ret

MatchFail:
    mov al, 0
    pop cx
    pop di
    pop si
    ret
MatchExactString endp

InPlaceLowercase proc
    push ax
    push si
    mov si, dx
LowerLoop:
    mov al, [si]
    cmp al, '$'
    je LowerDone
    cmp al, 'A'
    jb LowerNext
    cmp al, 'Z'
    ja LowerNext
    add al, 32
    mov [si], al
LowerNext:
    inc si
    jmp LowerLoop
LowerDone:
    pop si
    pop ax
    ret
InPlaceLowercase endp

end main
