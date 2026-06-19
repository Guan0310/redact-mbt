# redact-mbt

`redact-mbt` is a lightweight MoonBit utility library for masking sensitive values before they are printed, logged, or exposed in debug output.

It focuses on one clear job:

- redact values before output
- preserve enough structure for troubleshooting
- keep rules simple and deterministic
- stay small enough for direct reuse in CLI tools, services, and scripts

## Why This Project Exists

Many projects need to print request headers, callback URLs, `.env` snippets, or error context during development. Those outputs are useful for debugging, but they often contain:

- API keys
- bearer tokens
- phone numbers
- email addresses
- passwords
- cookies

`redact-mbt` provides a pure MoonBit implementation for these common redaction tasks so that applications can keep observability without leaking secrets.

## MVP Scope

This MVP covers:

- full-value masking
- edge-preserving masking
- email masking
- phone masking
- token masking
- sensitive key detection
- header value redaction
- header map redaction
- query pair redaction
- query string redaction
- URL query redaction
- dotenv line redaction
- multi-line dotenv text redaction

Out of scope for the MVP:

- cryptographic storage or secret management
- encrypted config files
- JSON parser integration
- reversible masking
- customizable rule engines
- locale-specific phone parsing

## Installation

Add the package to your MoonBit project in the usual way for your workspace setup.

Package metadata:

- package name: `guan0310/redact`
- source package path: `guan0310/redact/src`

## Quick Start

```moonbit
let masked_email = @guan0310/redact/src.mask_email("alice@example.com")
let masked_token = @guan0310/redact/src.mask_token("sk-prod-secret-1234")
let masked_url = @guan0310/redact/src.redact_url(
  "https://example.com/callback?access_token=abcdef1234567890&page=2",
)
```

Expected output style:

- `a***e@example.com`
- `sk-************1234`
- `https://example.com/callback?access_token=abcd********7890&page=2`

## API Overview

### Primitive Masking

- `redact_full(value : String) -> String`
  Replace any non-empty value with `[REDACTED]`.

- `mask_keep_edges(value : String, left : Int, right : Int) -> String`
  Keep the left and right edges visible and mask the middle with `*`.

### Specialized Value Masking

- `mask_email(email : String) -> String`
  Preserve the domain and partially mask the account part.

- `mask_phone(phone : String) -> String`
  Preserve separators and the last 4 digits.

- `mask_token(token : String) -> String`
  Preserve a recognizable prefix such as `sk-` or `ghp_`, and the last 4 characters.

### Rule Helpers

- `normalize_key_name(name : String) -> String`
  Convert key names to a normalized lowercase underscore form.

- `is_sensitive_key(name : String) -> Bool`
  Detect whether a field name is likely to contain secret material.

- `redact_key_value(key : String, value : String) -> String`
  Choose a masking strategy based on the key name.

### HTTP Helpers

- `redact_header_value(name : String, value : String) -> String`
  Special-cases `Authorization` style headers and preserves the auth scheme.

- `redact_headers(headers : Map[String, String]) -> Map[String, String]`
  Apply header redaction across an entire map.

### URL and Query Helpers

- `redact_query_pair(pair : String) -> String`
  Redact a single `key=value` pair.

- `redact_query_string(query : String) -> String`
  Redact a full query string such as `a=1&token=...`.

- `redact_url(url : String) -> String`
  Redact only the query section of a URL and preserve the path and fragment.

### Dotenv Helpers

- `redact_env_line(line : String) -> String`
  Redact a single dotenv-style assignment.

- `redact_env_text(text : String) -> String`
  Redact all dotenv-style assignments inside a multi-line text block.

## Usage Examples

### 1. Masking a single secret

```moonbit
inspect(@guan0310/redact/src.redact_full("super-secret"), content="[REDACTED]")
```

### 2. Redacting headers before logging

```moonbit
let headers : Map[String, String] = Map([])
headers.set("Authorization", "Bearer sk-prod-secret-1234")
headers.set("X-Request-Id", "req-123")

let safe_headers = @guan0310/redact/src.redact_headers(headers)
```

Result:

- `Authorization` becomes `Bearer sk-************1234`
- `X-Request-Id` remains unchanged

### 3. Redacting callback URLs

```moonbit
let safe_url = @guan0310/redact/src.redact_url(
  "https://example.com/callback?api_key=sk-prod-secret-1234&page=2#done",
)
```

Result:

- `https://example.com/callback?api_key=sk-************1234&page=2#done`

### 4. Redacting dotenv content

```moonbit
let safe_env = @guan0310/redact/src.redact_env_text(
  "# local env\nAPI_KEY=sk-prod-secret-1234\nTRACE_ID=req-123",
)
```

Result:

- `# local env`
- `API_KEY=sk-************1234`
- `TRACE_ID=req-123`

## Redaction Strategy

The library intentionally uses simple, explicit rules:

- passwords are fully replaced with `[REDACTED]`
- tokens and API keys keep partial structure for debugging
- email addresses preserve the domain
- phone numbers preserve formatting and the last 4 digits
- authorization headers preserve the scheme, such as `Bearer`

This makes logs safer while still leaving enough information to answer questions like:

- which environment key was used
- whether the token prefix looks correct
- whether the callback URL shape is correct
- which email domain or phone suffix was involved

## Project Structure

```text
redact-mbt/
|-- moon.mod.json
|-- README.md
|-- ARCHITECTURE.md
`-- src/
    |-- moon.pkg.json
    `-- redact.mbt
```

File roles:

- `moon.mod.json`: package metadata
- `README.md`: user-facing overview and usage guide
- `ARCHITECTURE.md`: design notes and internal structure
- `src/moon.pkg.json`: MoonBit package config
- `src/redact.mbt`: implementation and tests

## Validation

The project is validated with:

```powershell
moon check
moon test
```

Current MVP test coverage includes:

- malformed input fallback behavior
- short-value redaction behavior
- email masking
- phone masking
- token masking
- key normalization
- sensitive key detection
- header redaction
- query redaction
- URL redaction
- dotenv redaction

## Limitations

- Query parsing is intentionally lightweight and does not decode percent-encoding.
- Token detection is heuristic-based rather than format-validated.
- Phone masking treats any ASCII digits as maskable digits.
- Dotenv helpers operate on plain text and do not preserve original spacing exactly.
- JSON text redaction is not included in this MVP.

## Roadmap Ideas

- configurable placeholder text
- custom sensitive-key registries
- JSON object and JSON text redaction
- cookie attribute-aware masking
- structured logging adapters
- more specialized secret patterns

## License

MIT
