# Architecture Notes

## Design Goal

`redact-mbt` is designed as a small, dependency-light redaction library for output safety. The architecture favors:

- deterministic behavior
- explicit heuristics
- pure string-based processing
- low integration cost

The current MVP keeps all implementation inside a single source file so that the package is easy to inspect, audit, and extend during the competition phase.

## Layering

The implementation in `src/redact.mbt` is organized in four practical layers.

### 1. Primitive Helpers

These functions provide reusable building blocks:

- `redact_full`
- `mask_keep_edges`
- `repeat_mask`
- `is_ascii_digit`
- `ascii_lower`
- `count_digits`
- `token_prefix_length`

They do not know anything about HTTP, dotenv, or specific business fields. Their only job is to transform strings consistently.

### 2. Specialized Value Maskers

These functions encapsulate domain-specific masking behavior:

- `mask_email`
- `mask_phone`
- `mask_token`

Each one applies a different balance between privacy and debugging usefulness.

### 3. Key-Based Rule Resolution

These functions decide which masking strategy to use:

- `normalize_key_name`
- `is_sensitive_key`
- `redact_key_value`

This layer is the routing core of the library. It normalizes field names and maps them to a redaction strategy.

### 4. Context-Specific Adapters

These functions apply the routing logic to common transport formats:

- `redact_header_value`
- `redact_headers`
- `redact_query_pair`
- `redact_query_string`
- `redact_url`
- `redact_env_line`
- `redact_env_text`

This separation keeps the code understandable:

- value masking stays reusable
- key rules stay centralized
- format adapters stay small

## Why Single-File for the MVP

For the competition MVP, a single-file layout has a few advantages:

- easier review by judges
- simpler commit history during early development
- fewer package boundaries while APIs are still stabilizing
- all tests stay close to the functions they validate

If the project grows later, a natural refactor path would be:

```text
src/
|-- core.mbt
|-- value_maskers.mbt
|-- key_rules.mbt
|-- http.mbt
|-- query.mbt
`-- dotenv.mbt
```

## Rule Philosophy

The package does not attempt to fully understand every possible data format. Instead, it follows a heuristic strategy:

- if the key name strongly implies a secret, redact it
- if the value type has a recognizable display pattern, preserve safe structure
- if the input is malformed or too short, prefer stronger masking

This leads to predictable behavior and avoids overengineering.

## Security Posture

This project is an output redaction library, not a cryptography or secret-storage library.

It helps reduce accidental exposure in:

- logs
- debug traces
- test snapshots
- config previews
- CLI output

It does not claim to:

- securely store secrets
- encrypt data at rest
- validate token authenticity
- parse every configuration grammar fully

## Testing Approach

The tests in `src/redact.mbt` are example-driven and behavior-focused.

They are written to prove:

- masking rules remain stable
- malformed input falls back safely
- context adapters preserve non-sensitive content
- format-specific helpers call the right masking logic

The project currently validates through:

- `moon check`
- `moon test`

## Extension Direction

The most likely next steps after the MVP are:

- JSON key/value traversal
- user-supplied custom redaction rules
- more precise cookie masking
- configurable visible prefix/suffix policies
- structured adapters for logging frameworks
