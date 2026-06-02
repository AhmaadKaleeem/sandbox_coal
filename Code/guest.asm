; guest.asm
; Reference file for Guest Test Behavior
;
; Note: Actual guest behavior is implemented directly within sandbox.asm 
; inside the TestSandboxGateway procedure. This is done to ensure reliability 
; in the EMU8086 emulator without relying on complex TSR loading mechanisms.
; 
; Simulated Guest Actions implemented:
; 1. Normal print request (AH = 09h)
; 2. Sensitive print request (AH = 09h with 'SECRET')
; 3. Print character request (AH = 02h)
; 4. File create request (AH = 3Ch)
; 5. Write request (AH = 40h)
; 6. Unknown service request (AH = 99h)
; 7. Tamper simulation (Modifying policy table dynamically)
; 8. Protected request after tamper (AH = 09h after fail-closed)
; 9. Safe exit (AH = 4Ch)
