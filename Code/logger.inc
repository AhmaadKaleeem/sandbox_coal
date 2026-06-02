; logger.inc
; Phase 7 - Audit Logger constants and data layout

LOG_ENTRY_SIZE equ 8
MAX_LOG_ENTRIES equ 64

logCounter dw 0
prevHash   dw 0
auditLog   db LOG_ENTRY_SIZE * MAX_LOG_ENTRIES dup(0)
