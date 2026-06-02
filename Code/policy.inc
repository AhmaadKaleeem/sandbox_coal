; policy.inc
; Phase 3 - Policy Constants and Policy Table

; DOS Service Constants
DOS_PRINT_STRING equ 09h
DOS_READ_CHAR    equ 01h
DOS_PRINT_CHAR   equ 02h
DOS_CREATE_FILE  equ 3Ch
DOS_OPEN_FILE    equ 3Dh
DOS_CLOSE_FILE   equ 3Eh
DOS_READ_FILE    equ 3Fh
DOS_WRITE_FILE   equ 40h
DOS_EXIT         equ 4Ch

; Policy Decision Constants
POLICY_ALLOW     equ 0
POLICY_DENY      equ 1
POLICY_MASK      equ 2
POLICY_APPROVE   equ 3
POLICY_TAMPER    equ 4

; Policy table containing monitored DOS services and their decisions
PolicyTable label byte
    db DOS_PRINT_STRING, POLICY_ALLOW
    db DOS_READ_CHAR,    POLICY_ALLOW
    db DOS_PRINT_CHAR,   POLICY_ALLOW
    db DOS_CREATE_FILE,  POLICY_DENY
    db DOS_OPEN_FILE,    POLICY_ALLOW
    db DOS_CLOSE_FILE,   POLICY_ALLOW
    db DOS_READ_FILE,    POLICY_ALLOW
    db DOS_WRITE_FILE,   POLICY_APPROVE
    db DOS_EXIT,         POLICY_ALLOW
PolicyTableEnd label byte

POLICY_ENTRY_SIZE equ 2
POLICY_TABLE_COUNT equ 9
