# Developer Experience Rules

DX is the #3 priority (after safety and performance). Good DX makes correctness easier to achieve and maintain.

## Naming

### Get Nouns and Verbs Right

Names capture the essence of a thing or action. Take time to find the perfect name — it provides a crisp mental model for the reader:

```text
// GOOD: Clear what it is and does
Connection
connect()
disconnect()

// BAD: Vague
Handler         // Handler of what?
process()       // Process what?
```

### Follow the Project's Naming Convention Consistently

The specific convention (`camelCase`, `snake_case`, `PascalCase`) matters less than consistency within the codebase. Check sibling files first. If the project uses `camelCase` for functions, use `camelCase` — don't mix.

```text
// PHP project using camelCase for methods
function readMessage(): Message

// Python project using snake_case for functions
def read_message() -> Message

// Java project using PascalCase for classes
class MessageParser
```

### No Abbreviations

Except for trivial loop indices (`i`, `j`, `k`):

```text
// GOOD
message
connection

// BAD
msg     // Abbreviated
conn    // Abbreviated
```

### Units and Qualifiers Last

Sort by descending significance, units last. This groups related variables and makes them line up:

```text
// GOOD: Most significant word first, units last
latencyMsMax
latencyMsMin
bufferSizeBytes
timeoutSeconds

// BAD: Units first or missing
maxLatencyMs      // Doesn't line up with min
latency           // Units missing!
```

### Same-Length Names for Related Variables

Related variables with the same character count line up in calculations, making them easier to scan and verify:

```text
// GOOD: Same length, lines up in code
source          target
sourceOffset    targetOffset

// BAD: Different lengths, harder to scan
src             dest
srcOffset       destOffset
```

### Semantic Richness

Use names that communicate more than just the type:

```text
// GOOD: Names communicate lifetime and cleanup behavior
generalAllocator       // Long-lived, must be freed
requestArena           // Short-lived, bulk freed

// BAD: Generic name hides important distinctions
allocator             // Which one? What's the lifetime?
```

### Named Parameters for Same-Typed Arguments

When two or more parameters share a type, use named parameters or an options object to prevent accidental swapping:

```text
// GOOD: Named fields prevent swapping
function read(options):
    // options.offset, options.length

// BAD: Easy to swap offset and length
function read(offset, length):
    // Which is which at the call site?
```

## Ordering

### Important Things Near Top

Files are read top-down. Put the important entry points first, implementation details later:

```text
// File structure:
function main()              // Entry point first
function init()              // Public API next
function helper()            // Implementation details last
```

### Struct/Class Order: Fields, Types, Methods

```text
class Client:
    # 1. Fields first

    state: State
    connection: Connection

    # 2. Types second (nested types, enums, constants)

    State = enum(DISCONNECTED, CONNECTED)

    # 3. Methods last

    method connect()
    method disconnect()
```

## Formatting

### Hard Column Limit

Set a hard column limit (80–100 characters) and enforce it with the project's formatter. Nothing should be hidden by a horizontal scrollbar. Two files side-by-side should fit on one screen.

**Enforce with:** PHP uses `php-cs-fixer` or Pint, Rust uses `rustfmt`, Go uses `gofmt`, Python uses `black`, TypeScript uses `prettier`.

### Use the Project's Formatter

Run the project's standard formatter before submitting. Do not fight it. Configure it once and let automation handle formatting.

### Comments Are Sentences

```text
// GOOD: Proper sentence, explains why
// We buffer messages to amortize syscall overhead.
buffer = allocate(BATCH_SIZE)

// BAD: Fragment, states the obvious
// buffer for messages
buffer = allocate(BATCH_SIZE)
```

### Explain Why, Not What

The code already says what it does. Comments should explain **why** the code is the way it is — the rationale, the trade-off, the alternative that was rejected:

```text
// GOOD: Explains the rationale
// This offset accounts for header size which varies by version.
offset = baseOffset + headerSize

// BAD: States the obvious
offset = baseOffset + headerSize // add header size to base offset
```

## Bug Prevention

### Off-By-One Prevention

Treat `index`, `count`, and `size` as distinct conceptual types, even if the language uses the same primitive type for all three. Include units or qualifiers to prevent confusion:

```text
// index:    0-based position
// count:    number of items (index + 1)
// size:     byte length (count × sizeof(entry))

index = 5
count = index + 1       // 6 items
size = count * ENTRY_SIZE  // bytes
```

### Explicit Division

Use the language's explicit integer division operations to show rounding intent:

```text
// GOOD: Intent is clear
pages = divideExact(bytes, PAGE_SIZE)
startPage = divideFloor(offset, PAGE_SIZE)
blocks = divideCeil(bytes, BLOCK_SIZE)

// BAD: Implicit rounding — which way does it round?
pages = bytes / PAGE_SIZE
```

**Language notes:** PHP has `intdiv()` for floor division. Python uses `//` for floor division. JavaScript's `/` gives floats — use `Math.floor()`, `Math.ceil()`, or `Number.isInteger()`.

### Variables Close to Use

Declare variables at their point of first use, not earlier. Don't leave them in scope where they're not needed:

```text
// GOOD: Declared where needed
function process():
    // ... other work ...

    result = compute()       // Declared here
    validate(result)         // Used immediately

// BAD: Declared too early — POCPOU gap
function process():
    result = compute()       // Declared early

    // ... 50 lines of other work ...

    validate(result)         // Used much later — was it modified?
```

### No Duplicated Variables or Aliases

Don't take multiple references to the same data. This reduces the probability that state gets out of sync:

```text
// GOOD: One reference to rule them all
data = loadData()

// BAD: Two names for the same thing — they can diverge
data = loadData()
alias = data  // No!
```

### Prefer Simple Return Types

Complex return types propagate complexity virally through call chains. Prefer simpler forms:

```text
Favor:  void > boolean > numeric > optional > result/error
```

Every union type or nullable return forces the caller to handle another case.

## Dependencies

### Zero Dependency Policy for Core Logic

Dependencies bring supply chain risk, safety/performance unknowns, and maintenance burden. For foundational code:

- Avoid adding dependencies unless the cost is clearly justified
- A small standardized toolbox is simpler than an array of specialized instruments

### One Toolchain

Standardize on one toolchain for scripting and automation. Avoid adding new languages or tools for auxiliary tasks — use what you already have.

**Language notes:** PHP projects should prefer PHP scripts over Bash/shell scripts for portability. Python projects should prefer Python scripts over Makefiles for cross-platform support.

## Commit Messages

### Rationale in Git History

Store design rationale in commit messages, not PR descriptions. PR descriptions are invisible in `git blame` — commit messages persist forever:

```text
// GOOD: Explains why
"Use fixed-size ring buffer instead of growable list.

Static allocation eliminates OOM during operation
and bounds worst-case latency to bufferSize × cost per entry."

// BAD: States the obvious, buries the rationale
"Change list to ring buffer"
// (The actual reasoning is on a PR that will be closed tomorrow)
```
