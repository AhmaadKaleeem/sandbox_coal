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
    
    interactivePrompt  db 'Enter string (or /tamper, /file, /logs, /stats, /clrlogs, /quit): $'
    cmdTamper          db '/tamper$'
    cmdFile            db '/file$'
    cmdQuit            db '/quit$'
    cmdLogs            db '/logs$'
    cmdStats           db '/stats$'
    cmdClearLogs       db '/clrlogs$'
    
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

    ; --- Admin security state ---
    adminFailedAttempts db 0
    adminLocked         db 0
    adminLockCount      dw 0

    ; --- Stats counters ---
    allowedStats        dw 0
    deniedStats         dw 0
    tamperStats         dw 0
    maskedStats         dw 0

    ; --- Admin auth messages ---
    passPrompt        db 'Enter sysadmin password: $'
    passDeniedMsg     db '[Auth] Access Denied: Wrong password$'
    lockoutMsg        db '[SECURITY ALERT] Admin access locked$'
    lockedBlockMsg    db '[Auth] Admin locked. Session reset required$'
    integrityChkMsg   db '[SysAdmin] Verifying Integrity...$'
    failClosedAdmMsg  db '[SysAdmin] Fail-closed active. Log access blocked$'
    authSuccessMsg    db '[Auth] Authentication successful$'
    sysAdminPass      db 'ddsadmin$'

    ; --- Log display messages ---
    logHeaderMsg   db '=== AUDIT LOG ===$'
    logColHeader   db ' #  SVC DEC HASH$'
    logSepMsg      db '--------------------$'
    logClearedMsg  db '[SysAdmin] Audit log cleared$'
    logEntryPfx    db ' $'
    logSpacePfx    db '  $'

    ; --- Stats display messages ---
    statsHeader    db '=== SANDBOX STATS ===$'
    statsAllowed   db '  Allowed  : $'
    statsDenied    db '  Denied   : $'
    statsTamper    db '  Tamper   : $'
    statsMasked    db '  Masked   : $'
    statsRecords   db '  Records  : $'
    statsFailedAth db '  Bad Auth : $'
    statsLockouts  db '  Lockouts : $'

    ; --- Decimal print scratch buffer ---
    decBuf db '00000$'

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

    ; Check for /logs (admin only)
    lea di, cmdLogs
    mov cx, 5
    lea si, inputString
    call MatchExactString
    cmp al, 1
    je DoLogsCmd

    ; Check for /stats
    lea di, cmdStats
    mov cx, 6
    lea si, inputString
    call MatchExactString
    cmp al, 1
    je DoStatsCmd

    ; Check for /clrlogs (admin only)
    lea di, cmdClearLogs
    mov cx, 8
    lea si, inputString
    call MatchExactString
    cmp al, 1
    je DoClearCmd

    ; Evaluate normal string
    mov ah, DOS_PRINT_STRING
    lea dx, inputString
    call SandboxHandler
    jmp InputLoop

DoLogsCmd:
    call DoLogsCommand
    jmp InputLoop

DoStatsCmd:
    call DoStatsCommand
    jmp InputLoop

DoClearCmd:
    call DoClearLogsCommand
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

    ; --- Update stats counters ---
    mov al, byte ptr lastDecision
    cmp al, POLICY_ALLOW
    jne SH_ChkDeny
    inc allowedStats
    jmp SH_StatsEnd
SH_ChkDeny:
    cmp al, POLICY_DENY
    jne SH_ChkMask
    inc deniedStats
    jmp SH_StatsEnd
SH_ChkMask:
    cmp al, POLICY_MASK
    jne SH_ChkTamper
    inc maskedStats
    jmp SH_StatsEnd
SH_ChkTamper:
    cmp al, POLICY_TAMPER
    jne SH_StatsEnd
    inc tamperStats
SH_StatsEnd:
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

; ================================================================
; AdminAuthenticate
; Prompts for password, validates against sysAdminPass ('ddsadmin').
; Handles lockout after 3 failures.
; Returns: AL = 1 if authenticated, AL = 0 if denied / locked.
; ================================================================
AdminAuthenticate proc
    push bx
    push cx
    push dx
    push si
    push di

    ; Check lockout flag first
    cmp adminLocked, 1
    jne AA_NotLocked

    lea dx, lockedBlockMsg
    call PrintString
    call NewLine
    mov al, 0
    jmp AA_Done

AA_NotLocked:
    ; Print password prompt
    lea dx, passPrompt
    call PrintString

    ; Read password into inputBuffer
    lea dx, inputBuffer
    mov ah, 0Ah
    int 21h
    call NewLine

    ; Null-terminate the input
    mov bl, inputLength
    mov bh, 0
    lea di, inputString
    add di, bx
    mov byte ptr [di], '$'

    ; Compare against 'ddsadmin' (7 chars, case-sensitive — no lowercase fold here)
    lea di, sysAdminPass
    mov cx, 7
    lea si, inputString
    call MatchExactString
    cmp al, 1
    je AA_Success

    ; Wrong password
    lea dx, passDeniedMsg
    call PrintString
    call NewLine

    ; Log AUTH_FAILURE (service=FEh, decision=POLICY_DENY)
    mov byte ptr requestedService, 0FEh
    mov byte ptr lastDecision, POLICY_DENY
    call AddLogEntry
    inc deniedStats

    ; Increment failed attempts
    inc adminFailedAttempts
    cmp adminFailedAttempts, 3
    jl AA_NotLocked2

    ; Lockout triggered
    mov adminLocked, 1
    inc adminLockCount
    lea dx, lockoutMsg
    call PrintString
    call NewLine

    ; Log AUTH_LOCKOUT (service=FDh, decision=POLICY_TAMPER)
    mov byte ptr requestedService, 0FDh
    mov byte ptr lastDecision, POLICY_TAMPER
    call AddLogEntry
    inc tamperStats

AA_NotLocked2:
    mov al, 0
    jmp AA_Done

AA_Success:
    ; Reset failed counter on success
    mov adminFailedAttempts, 0
    lea dx, authSuccessMsg
    call PrintString
    call NewLine

    ; Log AUTH_SUCCESS (service=FCh, decision=POLICY_ALLOW)
    mov byte ptr requestedService, 0FCh
    mov byte ptr lastDecision, POLICY_ALLOW
    call AddLogEntry
    inc allowedStats

    mov al, 1

AA_Done:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    ret
AdminAuthenticate endp

; ================================================================
; DoLogsCommand
; Admin-only. Authenticates, verifies integrity, then shows audit log.
; ================================================================
DoLogsCommand proc
    push ax
    push dx

    call AdminAuthenticate
    cmp al, 1
    jne DL_Deny

    ; Integrity verification
    lea dx, integrityChkMsg
    call PrintString
    call NewLine
    call SelfCheck

    ; Block if fail-closed is active
    cmp failClosed, 1
    jne DL_ShowLog

    lea dx, failClosedAdmMsg
    call PrintString
    call NewLine
    jmp DL_Done

DL_ShowLog:
    call DisplayLog

    ; Log LOG_ACCESS (service=FBh, decision=POLICY_ALLOW)
    mov byte ptr requestedService, 0FBh
    mov byte ptr lastDecision, POLICY_ALLOW
    call AddLogEntry
    inc allowedStats
    jmp DL_Done

DL_Deny:
    lea dx, logDeniedMsg
    call PrintString
    call NewLine

    ; Log LOG_DENIED (service=FAh, decision=POLICY_DENY)
    mov byte ptr requestedService, 0FAh
    mov byte ptr lastDecision, POLICY_DENY
    call AddLogEntry
    inc deniedStats

DL_Done:
    pop dx
    pop ax
    ret
DoLogsCommand endp

; ================================================================
; DisplayLog
; Iterates auditLog and prints each 8-byte entry as a table row.
; Format: " #  SVC DEC HASH"
;   #   = entry index (decimal)
;   SVC = requested service (hex byte)
;   DEC = policy decision (hex byte)
;   HASH= current hash (hex word)
; ================================================================
DisplayLog proc
    push ax
    push bx
    push cx
    push dx
    push di

    lea dx, logHeaderMsg
    call PrintString
    call NewLine
    lea dx, logColHeader
    call PrintString
    call NewLine
    lea dx, logSepMsg
    call PrintString
    call NewLine

    mov cx, logCounter
    cmp cx, 0
    je DLP_Done

    lea di, auditLog
    mov bx, 0              ; entry index

DLP_Loop:
    ; Print entry index (decimal)
    lea dx, logEntryPfx
    call PrintString
    mov ax, bx
    call PrintDecimal

    ; Print space separator
    lea dx, logSpacePfx
    call PrintString

    ; Print Service byte (offset +2)
    mov al, [di+2]
    call PrintHex8

    ; Print space
    lea dx, logSpacePfx
    call PrintString

    ; Print Decision byte (offset +3)
    mov al, [di+3]
    call PrintHex8

    ; Print space
    lea dx, logSpacePfx
    call PrintString

    ; Print current hash word (offset +6)
    mov ax, word ptr [di+6]
    call PrintHexWord

    call NewLine

    add di, 8              ; next 8-byte entry
    inc bx
    loop DLP_Loop

DLP_Done:
    lea dx, logSepMsg
    call PrintString
    call NewLine

    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret
DisplayLog endp

; ================================================================
; PrintHex8
; Prints AL as a 2-digit uppercase hex string (e.g. AL=0Ah → "0A").
; ================================================================
PrintHex8 proc
    push ax
    push bx
    push dx

    mov bh, al

    ; High nibble
    mov dl, bh
    shr dl, 1
    shr dl, 1
    shr dl, 1
    shr dl, 1
    and dl, 0Fh
    cmp dl, 9
    jle PH8_HighOk
    add dl, 7
PH8_HighOk:
    add dl, '0'
    mov ah, DOS_PRINT_CHAR
    int 21h

    ; Low nibble
    mov dl, bh
    and dl, 0Fh
    cmp dl, 9
    jle PH8_LowOk
    add dl, 7
PH8_LowOk:
    add dl, '0'
    mov ah, DOS_PRINT_CHAR
    int 21h

    pop dx
    pop bx
    pop ax
    ret
PrintHex8 endp

; ================================================================
; PrintDecimal
; Prints AX as unsigned decimal (0-65535). Uses decBuf scratch area.
; ================================================================
PrintDecimal proc
    push ax
    push bx
    push cx
    push dx
    push di

    ; Fill decBuf with '0' digits, null-terminated with '$'
    lea di, decBuf
    mov byte ptr [di],   '0'
    mov byte ptr [di+1], '0'
    mov byte ptr [di+2], '0'
    mov byte ptr [di+3], '0'
    mov byte ptr [di+4], '0'
    mov byte ptr [di+5], '$'

    ; If AX=0 print single '0' and exit
    cmp ax, 0
    jne PD_Convert
    mov dl, '0'
    mov ah, DOS_PRINT_CHAR
    int 21h
    jmp PD_Done

PD_Convert:
    ; Build digits right-to-left into decBuf[0..4]
    mov bx, 10
    mov cx, 4          ; position index (0-based), start at rightmost digit [4]
    add di, 4          ; point di to decBuf[4]

PD_Loop:
    cmp ax, 0
    je PD_Print
    mov dx, 0
    div bx             ; AX = quotient, DX = remainder
    mov byte ptr [di], dl
    add byte ptr [di], '0'
    dec di
    dec cx
    cmp cx, 0
    jge PD_Loop

PD_Print:
    ; Find first non-'0' character and print from there
    lea di, decBuf
    mov cx, 5
PD_SkipLeading:
    cmp byte ptr [di], '0'
    jne PD_PrintFrom
    inc di
    loop PD_SkipLeading
    dec di             ; print at least one '0'

PD_PrintFrom:
    ; DX = di (address to start printing)
    mov dx, di
    call PrintString

PD_Done:
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret
PrintDecimal endp

; ================================================================
; DoStatsCommand
; Displays sandbox statistics. No auth required.
; ================================================================
DoStatsCommand proc
    push ax
    push dx

    lea dx, statsHeader
    call PrintString
    call NewLine

    lea dx, statsAllowed
    call PrintString
    mov ax, allowedStats
    call PrintDecimal
    call NewLine

    lea dx, statsDenied
    call PrintString
    mov ax, deniedStats
    call PrintDecimal
    call NewLine

    lea dx, statsTamper
    call PrintString
    mov ax, tamperStats
    call PrintDecimal
    call NewLine

    lea dx, statsMasked
    call PrintString
    mov ax, maskedStats
    call PrintDecimal
    call NewLine

    lea dx, statsRecords
    call PrintString
    mov ax, logCounter
    call PrintDecimal
    call NewLine

    lea dx, statsFailedAth
    call PrintString
    mov al, adminFailedAttempts
    mov ah, 0
    call PrintDecimal
    call NewLine

    lea dx, statsLockouts
    call PrintString
    mov ax, adminLockCount
    call PrintDecimal
    call NewLine

    pop dx
    pop ax
    ret
DoStatsCommand endp

; ================================================================
; DoClearLogsCommand
; Admin-only. Authenticates, then zeros auditLog buffer + resets counter.
; ================================================================
DoClearLogsCommand proc
    push ax
    push cx
    push di
    push dx

    call AdminAuthenticate
    cmp al, 1
    jne DCL_Deny

    ; Zero the auditLog buffer
    lea di, auditLog
    mov cx, 512
    mov al, 0
DCL_ZeroLoop:
    mov [di], al
    inc di
    loop DCL_ZeroLoop

    ; Reset counters
    mov logCounter, 0
    mov prevHash, 0

    ; Reset stats counters too
    mov allowedStats, 0
    mov deniedStats, 0
    mov tamperStats, 0
    mov maskedStats, 0

    lea dx, logClearedMsg
    call PrintString
    call NewLine
    jmp DCL_Done

DCL_Deny:
    lea dx, logDeniedMsg
    call PrintString
    call NewLine

DCL_Done:
    pop dx
    pop di
    pop cx
    pop ax
    ret
DoClearLogsCommand endp

end main

