# Performance Analysis

1. Native flow
   Native DOS calls execute immediately after INT 21h. There is no checking overhead.

2. Sandboxed flow
   The sandboxed flow intercepts the request, looks up the policy, calculates a hash, stores an audit log, and then conditionally forwards the request. 

3. Why overhead increases
   Overhead comes from linear policy searching, string scanning for masking, memory writes for the audit log, and bitwise operations for the hash.

4. Why memory usage increases
   Memory usage increases because the sandbox must keep the audit log resident in the data segment.

5. Why checksum overhead is acceptable
   The XOR and bit rotation operations used for the educational hash chain are extremely fast and add practically zero noticeable delay on modern hardware, and remain fast even inside an emulator.

6. Why RDTSC is not used
   The RDTSC instruction is a Pentium feature and does not exist on the 8086 processor. We must rely on instruction counts rather than exact clock cycles.

7. Limitations of estimates
   All performance estimates are theoretical. The emulator does not simulate exact 8086 cycle timing perfectly, and caching effects are ignored.

8. Summary table

| Operation | Native | Sandboxed | Reason for Difference |
| --------- | ------ | --------- | --------------------- |
| Print string | Fast | Slower | Policy lookup and log update |
| Sensitive print | Fast | Much slower | Policy lookup, string scan, and log update |
| Create file | Fast | Fast block | Policy lookup and immediate block |
