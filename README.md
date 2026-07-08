📞 Phone Number Validator – Multi‑Language Edition

A comprehensive **phone number validator** that validates, normalizes, and identifies the country for phone numbers worldwide.  
Supports E.164 format and popular national formats (US, UK, Germany, France, Russia, Ukraine, etc.).  
Built in **7 programming languages** – perfect for learning or integration.

## ✨ Features
- **Syntax validation** – supports various formats:
  - International: `+1 555-123-4567`, `+44 20 7946 0958`
  - National: `(555) 123-4567`, `02 1234 5678`
  - With or without country code, parentheses, hyphens, spaces, dots.
- **Country detection** – identifies the country based on the country calling code.
- **Normalization** – converts any valid number to the E.164 format (e.g., `+14155552671`).
- **Strict checks** – validates length, prefix, and digit patterns according to country‑specific rules.
- **Batch validation** – process multiple numbers from a file.
- **Statistics** – track valid/invalid counts.
- **Extensible** – easily add more countries or modify rules.

## 🗂 Languages & Files
| Language          | File                      |
|-------------------|---------------------------|
| Python            | `phone_validator.py`      |
| Go                | `phone_validator.go`      |
| JavaScript        | `phone_validator.js`      |
| C#                | `PhoneValidator.cs`       |
| Java              | `PhoneValidator.java`     |
| Ruby              | `phone_validator.rb`      |
| Swift             | `phone_validator.swift`   |

## 🚀 How to Run
Each file is standalone – run it with the appropriate interpreter/compiler:

| Language | Command |
|----------|---------|
| Python   | `python phone_validator.py` |
| Go       | `go run phone_validator.go` |
| JavaScript | `node phone_validator.js` |
| C#       | `dotnet run` (or `csc PhoneValidator.cs`) |
| Java     | `javac PhoneValidator.java && java PhoneValidator` |
| Ruby     | `ruby phone_validator.rb` |
| Swift    | `swift phone_validator.swift` |

## 📊 Example Session
=== Phone Number Validator ===

Validate single number

Validate from file

Show statistics

Exit
Choose: 1

Enter phone number: +1 (555) 123-4567
Valid: true
Normalized: +15551234567
Country: United States

Enter phone number: +44 20 7946 0958
Valid: true
Normalized: +442079460958
Country: United Kingdom

text

## 📁 Batch File Format
A plain text file with one phone number per line:
+1 555-123-4567
+44 20 7946 0958
+7 123 456-78-90

text

## 🔧 Technical Details
- **Supported countries** (expandable):
  - USA/Canada: +1
  - UK: +44
  - Germany: +49
  - France: +33
  - Russia: +7
  - Ukraine: +380
  - Australia: +61
  - India: +91
  - Brazil: +55
  - China: +86
  - Japan: +81
  - South Korea: +82
- **Validation rules**:
  - Length checks (country‑specific)
  - Prefix checks (e.g., US numbers start with 2‑9)
  - Format normalization using configurable patterns.
- **Regular expressions** – flexible parsing with `/^(?:\+?(\d{1,3})?[-.\s]?)?(?:\(?(\d{1,4})?\)?[-.\s]?)?(\d{1,4})[-.\s]?(\d{1,4})[-.\s]?(\d{1,9})$`

## 🤝 Contributing
Add more countries, improve country‑specific rules, or integrate with external lookup APIs – PRs welcome!

## 📜 License
MIT – use freely.
