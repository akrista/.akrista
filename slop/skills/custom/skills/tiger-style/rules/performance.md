# Performance Rules

Performance is the #2 priority (after safety). The biggest wins come from design decisions, not micro-optimization.

## Design-Time Thinking

### Performance Starts at Design

The earlier you solve performance, the bigger the win:

| Phase | Typical improvement |
|-------|--------------------|
| Design | 1000x possible |
| Implementation | 10x possible |
| Profiling/tuning | 2x typical |

Think about performance **before** writing code. A bad design decision cannot be recovered by clever optimization.

### Back-of-Envelope Sketches

Before implementing, sketch resource usage to identify bottlenecks:

```text
Operation: Process 10k messages/sec
- Network: 10k * 100 bytes = 1 MB/s  (well within 1 Gbps)
- Disk:    10k * 100 bytes = 1 MB/s    (SSD can do 500 MB/s)
- Memory:  10k * 1 KB buffers = 10 MB  (fits in on-chip cache? depends)
- CPU:     10k * 1 us = 10 ms/s        (1% of one core)
```

This reveals where to optimize before you code. Sketches are cheap.

## Resource Priority

### Optimize Slowest Resources First

Order by typical latency, compensating for frequency of access:

| Resource | Typical Latency | Optimize priority |
|----------|-----------------|-------------------|
| Network | 1ms – 100ms | First |
| Disk | 100 us – 10 ms | Second |
| Memory | 100 ns – 1 us | Third |
| CPU | 1 ns – 100 ns | Last |

**But:** a memory cache miss repeated 1000x equals one disk fsync in cost. Consider frequency.

```text
// DESIGN-TIME SKETCH TEMPLATE
// For each operation, estimate:
//   latency: worst-case time per operation
//   bandwidth: throughput per second
//   frequency: operations per second
// Then: bottleneck = resource where (frequency × latency) is highest
```

## Batching

### Amortize Overhead

Batch operations to amortize fixed costs (syscalls, network round trips, allocations):

```text
// GOOD: Batch writes — one system call
function flushBatch(messages):
    buffer = []
    for msg in messages:
        buffer.append(msg.data)
    disk.writeAll(buffer)

// BAD: Individual writes — one system call per message
function processMessage(msg):
    disk.write(msg.data)
```

### Control Plane vs Data Plane

Separate infrequent control operations from hot data paths:

```text
// Control plane: Setup, config (can be slow, heavily validated)
function configure(options):
    assert(options.isValid())
    // complex setup — happens once

// Data plane: Hot path (fast, batched, minimal work)
function processData(data):
    // Pre-validated by control plane
    // Minimal branching, minimal allocation
}
```

### Separate Infrequent Paths from Hot Paths

Configuration and setup code should not share the same code paths as per-request processing.

## CPU Predictability

### Let the CPU Sprint

Give the CPU large chunks of predictable work with minimal branching:

```text
// GOOD: Predictable loop, no branches
function sumValues(values):
    sum = 0
    for v in values:
        sum += v
    return sum

// BAD: Unpredictable branches — branch mispredictions stall the pipeline
function sumValues(values):
    sum = 0
    for v in values:
        if v.isValid:      // Branch!
            if v.type == INT:  // Branch!
                sum += v.asInt()
    return sum
```

### Extract Hot Loops

Move hot loops to standalone functions with primitive arguments. This helps both the compiler (register allocation, inlining) and the human reviewer (spot redundant computations):

```text
// GOOD: Standalone function, primitive arguments, no self/this
function scanBuffer(buffer, length, needle):
    for i in 0..length:
        if buffer[i] == needle:
            return i
    return -1

// BAD: Method with indirect field access
// Harder for compiler to optimize, harder for human to audit
```

## Explicit over Implicit

### Don't Rely on Magic

Be explicit about what you want. Don't rely on defaults that could change:

```text
// GOOD: Explicit options
prefetch(pointer, cache: DATA, rw: READ, locality: 3)

// BAD: Rely on defaults — what if defaults change in version N+1?
prefetch(pointer)
```

### Explicit Memory Layout

Document struct/class layout, especially for serialization or shared memory:

```text
// GOOD: Explicit layout, documented padding
struct Entry:
    key: u64       // 8 bytes
    value: u64     // 8 bytes
    flags: u32     // 4 bytes
    _padding: u32  // 4 bytes (explicit)
// Total: 24 bytes

assert(sizeof(Entry) == 24)
```

### No Buffer Bleeds

A partially filled buffer with unzeroed padding is both a security leak (Heartbleed) and a correctness bug:

```text
// GOOD: Zero first, then fill
buffer = allocate(BUFFER_SIZE)
fill(buffer, 0)
copy(buffer[0:data.length], data)

// BAD: Unzeroed tail leaks previous data
buffer = allocate(BUFFER_SIZE)
copy(buffer[0:data.length], data)
// buffer[data.length:] contains whatever was there before
```
