# Memory Usage Analysis

1. Policy table size
   9 entries of 2 bytes each equals 18 bytes.

2. Audit log entry size
   Each entry takes 8 bytes.

3. Total audit log memory
   64 entries times 8 bytes equals 512 bytes.

4. Checksum variables
   prevHash takes 2 bytes. logCounter takes 2 bytes. policyMeasurement takes 2 bytes.

5. Fail closed flag
   failClosed takes 1 byte.

6. String storage estimate
   Approximately 400 bytes for all display messages.

7. Total approximate data overhead
   Roughly 935 bytes. This fits well within the 64 KB data segment limit.
