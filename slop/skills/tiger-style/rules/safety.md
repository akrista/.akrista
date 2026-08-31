# Safety Rules

Safety is the #1 priority. These rules prevent bugs before they happen, in any language.

## Assertions (CRITICAL)

### Minimum 2 Assertions Per Function

Every function must have at least 2 assertions. Assertions are:
- A force multiplier for fuzzing and testing
- Living documentation of invariants
- A downgrade of catastrophic bugs to liveness bugs (a crash you can fix vs. silent corruption)

```text
// GOOD: Multiple assertions guard inputs and outputs
function processMessage(msg, buffer):
    assert(msg.length > 0)              // Input validation
    assert(buffer.length >= msg.length)  // Capacity check
    // ... process ...
    assert(result.length == msg.length)  // Postcondition

// BAD: No assertions, no safety net
function processMessage(msg, buffer):
    // just processing, no checks
```

**Language notes:** Use your language's assertion mechanism — PHP `assert()`, Python `assert`, Java `assert`, C `assert()`, Rust `assert!()`, Go `require.True()`. In languages where assertions can be disabled (e.g., PHP, Java), pair them with explicit runtime checks for production-critical paths.

### Pair Assertions

For every property you want to enforce, find at least **two different code paths** to assert it:

```text
// Assert before write
assert(isValidData(data))
write(data)

// Assert after read (paired — catches corruption in storage)
loaded = read()
assert(isValidData(loaded))
```

### Split Compound Assertions

```text
// GOOD: When one fails, you know which
assert(a)
assert(b)

// BAD: Compound hides which condition failed
assert(a and b)
```

### Assert Implications

```text
// Use single-line guard for implications
if isLeader then assert(hasQuorum)
```

### Compile-Time / Static Assertions

Assert relationships between constants at compile time, where your language supports it:

```text
// At compile time
assert(BUFFER_SIZE >= MAX_MESSAGE_SIZE)
assert(sizeof(Header) == 64)
```

**Language notes:** PHP has `assert()` at runtime only — use PHPStan/rector-level static analysis for compile-time equivalents. Rust has `const _: () = assert!(...)`. C has `static_assert`. Java has no direct equivalent but unit tests serve this purpose.

### The Golden Rule: Assert Positive AND Negative Space

Assert the values you **do** expect AND the values you **do not** expect — bugs live at the boundary between valid and invalid. Tests must cover both valid and invalid inputs.

## Control Flow

### Every `if` Has an `else`

Handle both branches explicitly. Missing `else` branches are how "goto fail"-class bugs happen:

```text
// GOOD: Both branches handled
if isValid:
    process()
else:
    reportError()

// BAD: What happens when isValid is false?
if isValid:
    process()
```

### Braces on All Control Structures

Always use braces or explicit delimiters, even for single-statement bodies. Exception: single-line assertion guards.

```text
// GOOD
if ready:
    send()

// BAD: invites maintenance mistakes
if ready:
    send()
```

### No Recursion

Recursion makes bounding execution difficult. Use explicit iteration with a bounded stack:

```text
// GOOD: Bounded iteration
function traverse(nodes):
    stack = Stack(capacity: MAX_DEPTH)
    // iterative traversal

// BAD: Unbounded recursion depth
function traverse(node):
    for child in node.children:
        traverse(child)  // Can overflow the call stack
```

### Split Compound Conditions

```text
// GOOD: Nested structure makes all cases visible
if a:
    if b:
        // a and b
    else:
        // a and not b
else:
    // not a

// BAD: Compound condition hides cases
if a and b:
    // ...
```

### State Invariants Positively

```text
// GOOD: Positive form, natural to read
if index < length:
    // The invariant holds
else:
    // The invariant doesn't hold

// BAD: Negation, harder to reason about
if index >= length:
    // Invalid case (but this form makes you think harder)
```

## Limits on Everything

### Loops Must Have Bounds

Every loop must have an explicit upper bound. If a loop is intentionally unbounded (e.g., an event loop), this must be documented and asserted:

```text
// GOOD: Explicit bound
for item in items[0:MAX_ITEMS]:
    process(item)

// GOOD: Event loop — intentional, documented
loop:
    assert(isEventLoop)  // This is intentionally unbounded
    pollAndProcess()
```

### Queues and Buffers Have Fixed Upper Bounds

```text
// GOOD: Fixed capacity, statically bounded
queue = RingBuffer(capacity: 1024)

// BAD: Unbounded, grows under load spike
queue = DynamicArray()  // No max — OOM risk
```

## Memory

### Bounded Allocation

All large allocations should happen at initialization, not on hot paths:

```text
// GOOD: Allocate once at init
function init():
    buffer = allocate(BUFFER_SIZE)

// BAD: Dynamic allocation during operation
function process(data):
    temp = allocate(data.length)  // Sizing from untrusted input
```

### Group Allocation and Deallocation

Pair allocation with its corresponding deallocation. Use whitespace to make the pair visually obvious:

```text
// GOOD: Paired, leaks are visible
function init():
    buffer = allocate(BUFFER_SIZE)
    defer free(buffer)

    index = allocate(COUNT)
    defer free(index)

// BAD: Dispersed — easy to miss a free
function init():
    buffer = allocate(BUFFER_SIZE)
    // ... 20 lines ...
    index = allocate(COUNT)
    // ... 20 lines ...
    free(buffer)
    // ... 5 lines ...
    free(index)
```

### No Buffer Bleeds

A partially filled buffer with unzeroed padding leaks sensitive data (cf. Heartbleed). Always initialize buffers fully:

```text
// GOOD: Zero the entire buffer, then fill
buffer = zeroed(BUFFER_SIZE)
copy(buffer[0:data.length], data)

// BAD: Unzeroed tail may leak previous contents
buffer = uninitialized(BUFFER_SIZE)
copy(buffer[0:data.length], data)   // buffer[data.length:] contains garbage
```

## Types and Bounds

### Use Explicit-Sized Types

Prefer types with explicit sizes (e.g., `i32`, `u64`, `float32`) over architecture-dependent types where the width matters:

```text
// GOOD: Every developer knows the width
count: i32
offset: i64

// BAD: Architecture-dependent width
count: int   // 32-bit on some platforms, 64-bit on others
```

### Compile-Time Sanity Checks

Assert relationships between constants at compile time where possible:

```text
// GOOD: Caught before the program runs
assert(BUFFER_SIZE >= MAX_MESSAGE_SIZE)
assert(capacity isPowerOfTwo)  // Enables fast modulo
```

## Function Size

### Maximum 70 Lines

If a function exceeds ~70 lines, split it. Art is born of constraints. A hard limit forces you to find the right abstractions:

```text
// GOOD: Small focused functions
function handleMessage(msg):
    validateMessage(msg)
    processPayload(msg)
    sendResponse(msg)

// Parent handles control flow, helpers handle logic
```

### Push `if`s Up, `for`s Down

- **Parent functions** handle branching (control flow)
- **Helper functions** handle iteration and computation (logic)
- **Leaf functions** stay pure — no side effects

## External Events

### Process at Your Own Pace

Don't react immediately to external events. Buffer them and process at the application's pace. This keeps control flow predictable and enables batching:

```text
// GOOD: Buffer events, process in batches
function tick():
    events = pollEvents()
    queue.pushAll(events)
    processBatch()

// BAD: React to each event immediately
function onEvent(event):
    handle(event)  // External actor controls your tempo
```

## Error Handling

### All Errors Must Be Handled

Research (USENIX OSDI '14) found that 92% of catastrophic failures came from incorrect handling of explicitly signaled errors:

```text
// GOOD: Handle or propagate
result = operation()
if result.isError:
    log("Operation failed: {result.error}")
    return result.error

// BAD: Silence the error
operation()  // Return value discarded — silent failure
```

Never use empty catch blocks. Never discard error return values. If an error is truly expected and benign, document why explicitly.
