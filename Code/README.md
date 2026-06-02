# EMU86 Sandbox Demo

## Overview
EMU86 Sandbox is an educational 8086 assembly project demonstrating a measured, policy-enforcing execution environment with a hash-chained audit trail. It functions as a simulated DOS interrupt gateway that validates service requests against a fixed policy table before forwarding them.

## Key Features
- **Simulated INT 21h Gateway**: Intercepts DOS function calls.
- **Policy Enforcement**: Grants or denies access based on predefined policies.
- **Audit Logging**: Maintains an in-memory audit log of all sandbox decisions.
- **Hash Chaining**: Uses an educational checksum to track audit log integrity.
- **Tamper Simulation & Detection**: Includes self-checking logic to detect modifications to the policy table.
- **Fail Closed Mode**: Automatically blocks sensitive requests upon integrity validation failure.

## Prerequisites
- **Emulator**: EMU8086 (Primary target)
- **Alternative**: TASM and DOSBox for native MS-DOS execution
- **Code Constraints**: Strict 16-bit 8086 assembly instructions only (no 32/64-bit registers or RDTSC).

## Getting Started

### Method 1: Running in EMU8086 (Recommended)

#### Step 1: Open the Project
1. Launch EMU8086.
2. Open the file `sandbox.asm` located in `Project/Code/`.

#### Step 2: Compile and Emulate
1. Click the **Compile** button in EMU8086.
2. Click **Emulate** to load the program into the emulator.

#### Step 3: Execute
1. Click **Run** in the emulator window.
2. The console window will open and output the sandbox initialization, policy measurement, and tests.
3. Wait for the tamper simulation step to complete.

### Method 2: Running via VS Code (Visual Studio Code)

If you prefer a modern IDE, you can compile and run this project in VS Code using a DOS emulator extension (such as the MASM/TASM extension).

#### Step 1: Open Folder
1. Open the `Project/Code` directory in VS Code.

#### Step 2: Build and Run
1. If using the **MASM/TASM** extension: Simply right-click `sandbox.asm` and select **Run ASM code**.
2. If using the integrated terminal with a manual DOSBox installation, launch DOSBox and follow the manual TASM instructions below.

### Method 3: Running with TASM and DOSBox

#### Step 1: Setup DOSBox
1. Mount your project directory inside DOSBox.
```bat
mount c d:\Ahmad\Startup\Sandbox_Actsurance\Project\Code
c:
```

#### Step 2: Compile and Link
1. Use TASM to assemble the code.
```bat
tasm sandbox.asm
```
2. Link the object file.
```bat
tlink sandbox.obj
```

#### Step 3: Run
1. Execute the built binary.
```bat
sandbox.exe
```

## Interactive Evaluation Mode
The demo now runs in an interactive REPL (Read-Eval-Print Loop) mode. After initializing the sandbox and computing the policy checksum, it will prompt you with:

`Enter string to evaluate (or /TAMPER, /FILE, /QUIT): `

You can type any string or command and the sandbox will intercept and evaluate it:

1. **Normal Strings:** Type any text (e.g., `hello world`) and press Enter. The sandbox will evaluate the policy and forward the request.
2. **Sensitive Strings:** Type a string containing sensitive keywords like `SECRET`, `PASSWORD`, or `TOKEN`. The sandbox will intercept this and print `[REDACTED]`.
3. **Command `/FILE`:** Triggers tests for blocked file creation (`AH 3Ch`) and approval-required file writing (`AH 40h`) operations.
4. **Command `/TAMPER`:** Simulates an integrity violation by modifying the policy table in memory. The self-check mechanism will detect the mismatch and enable Fail-Closed Mode, blocking any subsequent requests.
5. **Command `/QUIT`:** Safely exits the demo.

**Sample Output Flow:**
```
=== EMU86 Sandbox Demo ===

[Sandbox] Initialized
[Sandbox] Policy Measurement = 8F32
[Sandbox] Audit Log Ready

Enter string to evaluate (or /TAMPER, /FILE, /QUIT):
hello
[Gateway] Request received
[Gateway] Forwarding allowed request
hello

Enter string to evaluate (or /TAMPER, /FILE, /QUIT):
my PASSWORD is 123
[Gateway] Request received
[REDACTED]

Enter string to evaluate (or /TAMPER, /FILE, /QUIT):
/TAMPER
[Sandbox] Simulating tamper
[Sandbox] TAMPER DETECTED
[Log] TAMPER event recorded
[Sandbox] FAIL CLOSED MODE ENABLED

Enter string to evaluate (or /TAMPER, /FILE, /QUIT):
test
[Sandbox] DENIED Fail closed mode active

Enter string to evaluate (or /TAMPER, /FILE, /QUIT):
/QUIT
Program exited safely
```

## Troubleshooting
### Problem: Assembly Errors on Compilation
**Symptoms**: TASM or EMU8086 reports unknown instructions.
**Solution**: Ensure no 32-bit registers (e.g., `EAX`) or newer instructions (e.g., `RDTSC`) have been introduced. The codebase strictly adheres to 8086 instructions.

### Problem: Program Enters Infinite Loop or Crashes
**Symptoms**: The emulator hangs or DOSBox crashes.
**Solution**: Verify the registers are being preserved inside the procedures using `push` and `pop` (especially inside `SelfCheck` and `SimulateTamper`).

## Additional Resources
- For a comprehensive design overview, refer to `Project/Docs/ARCHITECTURE.md`.
- See `Project/Code/build_notes.txt` for compiler notes and rules.
