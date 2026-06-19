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

fn is_ascii_digit(ch : Char) -> Bool {
  let code = ch.to_int()
  code >= b'0'.to_int() && code <= b'9'.to_int()
}

fn ascii_lower(ch : Char) -> Char {
  let code = ch.to_int()
  if code >= b'A'.to_int() && code <= b'Z'.to_int() {
    Int::unsafe_to_char(code + 32)
  } else {
    ch
  }
}

fn count_digits(value : String) -> Int {
  let mut total = 0
  for ch in value {
    if is_ascii_digit(ch) {
      total = total + 1
    }
  }
  total
}

fn token_prefix_length(token : String) -> Int {
  let dash = token.find("-")
  let underscore = token.find("_")
  let cutoff = 6
  match (dash, underscore) {
    (Some(left), Some(right)) =>
      if left < right && left > 0 && left <= cutoff {
        left + 1
      } else if right > 0 && right <= cutoff {
        right + 1
      } else {
        0
      }
    (Some(index), None) =>
      if index > 0 && index <= cutoff { index + 1 } else { 0 }
    (None, Some(index)) =>
      if index > 0 && index <= cutoff { index + 1 } else { 0 }
    (None, None) => 0
  }
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

/// Mask all but the last four digits of a phone-like string.
pub fn mask_phone(phone : String) -> String {
  let digit_count = count_digits(phone)
  if phone == "" {
    return ""
  }
  if digit_count <= 4 {
    return redact_full(phone)
  }
  let buffer = Buffer(size_hint=phone.length())
  let mut digits_left = digit_count
  for ch in phone {
    if is_ascii_digit(ch) {
      if digits_left > 4 {
        buffer.write_char_utf16le(Int::unsafe_to_char(b'*'.to_int()))
      } else {
        buffer.write_char_utf16le(ch)
      }
      digits_left = digits_left - 1
    } else {
      buffer.write_char_utf16le(ch)
    }
  }
  buffer.contents().to_unchecked_string()
}

/// Mask tokens while preserving a recognizable prefix and suffix.
pub fn mask_token(token : String) -> String {
  if token == "" {
    return ""
  }
  if token.length() <= 8 {
    return redact_full(token)
  }
  let prefix_len = token_prefix_length(token)
  if prefix_len == 0 {
    return mask_keep_edges(token, 4, 4)
  }
  if token.length() <= prefix_len + 4 {
    return redact_full(token)
  }
  token[:prefix_len].to_owned() +
  repeat_mask(token.length() - prefix_len - 4) +
  token[token.length() - 4:].to_owned()
}

/// Normalize a key name for case-insensitive sensitive-field matching.
pub fn normalize_key_name(name : String) -> String {
  let trimmed = name.trim().to_owned()
  let buffer = Buffer(size_hint=trimmed.length())
  let mut last_was_separator = false
  for ch in trimmed {
    let lowered = ascii_lower(ch)
    if lowered == '-' || lowered == '.' || lowered == ' ' {
      if !last_was_separator {
        buffer.write_char_utf16le('_')
        last_was_separator = true
      }
    } else {
      buffer.write_char_utf16le(lowered)
      last_was_separator = false
    }
  }
  buffer.contents().to_unchecked_string().trim(char_set="_").to_owned()
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

test "mask_phone preserves formatting while masking leading digits" {
  inspect(mask_phone("+86 138-0013-8000"), content="+** ***-****-8000")
}

test "mask_phone falls back to full redaction for short numbers" {
  inspect(mask_phone("1234"), content="[REDACTED]")
}

test "mask_token preserves known prefixes and suffixes" {
  inspect(mask_token("sk-prod-secret-1234"), content="sk-************1234")
}

test "mask_token keeps edges for unprefixed tokens" {
  inspect(mask_token("abcdef1234567890"), content="abcd********7890")
}

test "normalize_key_name lowers case and unifies separators" {
  inspect(normalize_key_name(" X-Api.Key "), content="x_api_key")
}
