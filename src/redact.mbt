/// Default placeholder used by full-value redaction helpers.
pub let default_placeholder : String = "[REDACTED]"

/// Replace an entire value with the default placeholder when it is non-empty.
pub fn redact_full(value : String) -> String {
  if value == "" {
    ""
  } else {
    default_placeholder
  }
}

test "redact_full keeps empty values untouched" {
  inspect(redact_full(""), content="")
}

test "redact_full masks non-empty values" {
  inspect(redact_full("secret-token"), content="[REDACTED]")
}
