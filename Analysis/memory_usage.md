# Memory Usage Analysis

1. Policy table size
   9 entries of 2 bytes each equals 18 bytes.

2. Audit log entry size
   Each entry takes 8 bytes: 2 bytes entry index, 1 byte service, 1 byte decision, 2 bytes previous hash, 2 bytes current hash.

3. Total audit log memory
   64 entries times 8 bytes equals 512 bytes.

4. Core checksum and counter variables
   prevHash takes 2 bytes. logCounter takes 2 bytes. policyMeasurement takes 2 bytes.

5. Fail closed flag
   failClosed takes 1 byte.

6. Admin security state
   adminFailedAttempts takes 1 byte. adminLocked takes 1 byte. adminLockCount takes 2 bytes.

7. Stats counters
   allowedStats, deniedStats, tamperStats, and maskedStats each take 2 bytes. Total 8 bytes.

8. Decimal print scratch buffer
   decBuf takes 6 bytes.

9. Input buffer for REPL
   inputBuffer maximum capacity is 64 bytes. inputLength takes 1 byte. inputString takes 64 bytes.

10. String storage estimate
    Original display messages approximately 400 bytes. New admin subsystem messages (prompts, auth messages, log header, stats labels) approximately 380 bytes. Total string storage approximately 780 bytes.

11. Total approximate data overhead
    Roughly 1475 bytes. This fits well within the 64 KB data segment limit.

12. Code segment overhead of new procedures
    AdminAuthenticate, DoLogsCommand, DisplayLog, PrintHex8, PrintDecimal, DoStatsCommand, and DoClearLogsCommand together add approximately 450 bytes of compiled code to the code segment.
