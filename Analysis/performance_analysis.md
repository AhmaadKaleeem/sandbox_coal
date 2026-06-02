# Performance Analysis

1. Native flow
   Native DOS calls execute immediately after INT 21h. There is no checking overhead.

2. Sandboxed gateway flow
   The sandboxed flow intercepts the request, looks up the policy, calculates a hash, stores an audit log entry, and then conditionally forwards the request.

3. Interactive REPL overhead
   Each loop iteration calls InPlaceLowercase on the entire input buffer before dispatch. For a 64-character string this adds up to 192 comparison and assignment instructions. This cost is paid once per user input and does not compound across requests.

4. Why masking overhead increased
   The original system compared only exact uppercase keyword strings. The new system first folds the entire input to lowercase in memory, then scans for lowercase root keywords. The folding step adds a linear pass over the input buffer. The benefit is that all case variations and root-substring misspellings are caught reliably without any additional comparison branches.

5. Admin subsystem overhead
   The admin operations (AdminAuthenticate, DisplayLog, DoStatsCommand, DoClearLogsCommand) are invoked only on explicit command. They add zero overhead to normal string evaluation and gateway decisions. The largest cost is DoClearLogsCommand, which performs a 512-byte zero loop and should only be called during maintenance.

6. Why memory usage increased
   Memory usage increased because the admin subsystem added approximately 380 bytes of new string literals, 14 bytes of new counter and state variables, 6 bytes for the decimal print scratch buffer, and approximately 450 bytes of code for the new procedures.

7. Why checksum overhead is acceptable
   The XOR and bit rotation operations used for the educational hash chain are extremely fast and add practically zero noticeable delay on modern hardware and remain fast even inside an emulator.

8. Why RDTSC is not used
   The RDTSC instruction is a Pentium feature and does not exist on the 8086 processor. We must rely on instruction counts rather than exact clock cycles.

9. Limitations of estimates
   All performance estimates are theoretical. The emulator does not simulate exact 8086 cycle timing perfectly, and caching effects are ignored.

10. Summary table

| Operation | Native | Sandboxed | Reason for Difference |
| --- | --- | --- | --- |
| Print string | Fast | Slower | Policy lookup, log update |
| Sensitive print (exact) | Fast | Much slower | Policy lookup, string scan, log update |
| Sensitive print (mixed-case) | Fast | Slowest | Policy lookup, full fold, string scan, log update |
| Create file | Fast | Fast block | Policy lookup and immediate block |
| Admin /logs (success) | N/A | High one-time cost | Password read, auth, integrity check, log iteration |
| Admin /stats | N/A | Low | Seven counter reads and decimal prints |
| Admin /clrlogs | N/A | High one-time cost | 512-byte zero loop and counter resets |
