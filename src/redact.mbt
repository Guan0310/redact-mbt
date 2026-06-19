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

fn repeat_mask(count : Int) -> String {
  let mask_char = Int::unsafe_to_char(b'*'.to_int())
  let buffer = Buffer(size_hint=count)
  for _ in 0..<count {
    buffer.write_char_utf16le(mask_char)
  }
  buffer.contents().to_unchecked_string()
}

/// Preserve the left and right edges of a string while masking the middle.
pub fn mask_keep_edges(value : String, left : Int, right : Int) -> String {
  if value == "" {
    return ""
  }
  if value.length() <= left + right {
    return redact_full(value)
  }
  value[:left].to_owned() +
  repeat_mask(value.length() - left - right) +
  value[value.length() - right:].to_owned()
}

/// Mask the local part of an email address while preserving the domain.
pub fn mask_email(email : String) -> String {
  match email.find("@") {
    Some(at) => {
      if at == 0 || at == email.length() - 1 {
        return redact_full(email)
      }
      let account = email[:at].to_owned()
      let domain = email[at:].to_owned()
      let masked_local = if account.length() == 1 {
        "*"
      } else if account.length() == 2 {
        account[:1].to_owned() + "*"
      } else {
        mask_keep_edges(account, 1, 1)
      }
      masked_local + domain
    }
    None => redact_full(email)
  }
}

test "redact_full keeps empty values untouched" {
  inspect(redact_full(""), content="")
}

test "redact_full masks non-empty values" {
  inspect(redact_full("secret-token"), content="[REDACTED]")
}

test "mask_keep_edges preserves prefix and suffix" {
  inspect(mask_keep_edges("abcdefghi", 2, 2), content="ab*****hi")
}

test "mask_keep_edges falls back to full redaction for short values" {
  inspect(mask_keep_edges("abc", 2, 2), content="[REDACTED]")
}

test "mask_email preserves domain and masks local part" {
  inspect(mask_email("alice@example.com"), content="a***e@example.com")
}

test "mask_email handles short local parts" {
  inspect(mask_email("ab@example.com"), content="a*@example.com")
  inspect(mask_email("a@example.com"), content="*@example.com")
}

test "mask_email rejects malformed inputs" {
  inspect(mask_email("not-an-email"), content="[REDACTED]")
  inspect(mask_email("@example.com"), content="[REDACTED]")
}
