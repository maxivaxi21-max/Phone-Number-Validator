// phone_validator.swift
import Foundation

class PhoneValidator {
    struct CountryInfo {
        let name: String
        let minLen: Int
        let maxLen: Int
        let regex: NSRegularExpression
    }

    private static let countryData: [String: CountryInfo] = {
        var dict: [String: CountryInfo] = [:]
        let patterns: [(String, String, Int, Int, String)] = [
            ("1", "United States/Canada", 10, 10, "^[2-9]\\d{9}$"),
            ("44", "United Kingdom", 10, 10, "^[1-9]\\d{9}$"),
            ("49", "Germany", 10, 11, "^[1-9]\\d{9,10}$"),
            ("33", "France", 9, 10, "^[1-9]\\d{8,9}$"),
            ("7", "Russia/Kazakhstan", 10, 10, "^[78]\\d{9}$"),
            ("380", "Ukraine", 9, 9, "^[0-9]{9}$"),
            ("61", "Australia", 9, 10, "^[0-9]{9,10}$"),
            ("91", "India", 10, 10, "^[6-9]\\d{9}$"),
            ("55", "Brazil", 10, 11, "^[1-9]\\d{9,10}$"),
            ("86", "China", 11, 11, "^1\\d{10}$"),
            ("81", "Japan", 10, 10, "^[0-9]{10}$"),
            ("82", "South Korea", 10, 11, "^[0-9]{10,11}$")
        ]
        for (code, name, min, max, pattern) in patterns {
            let regex = try! NSRegularExpression(pattern: pattern)
            dict[code] = CountryInfo(name: name, minLen: min, maxLen: max, regex: regex)
        }
        return dict
    }()

    private(set) var stats: (total: Int, valid: Int, invalid: Int) = (0, 0, 0)

    func validateNumber(_ raw: String) -> (valid: Bool, normalized: String?, country: String?, error: String?) {
        stats.total += 1
        let trimmed = raw.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty {
            stats.invalid += 1
            return (false, nil, nil, "Empty input")
        }
        let cleaned = trimmed.replacingOccurrences(of: "[^\\d+]", with: "", options: .regularExpression)
        if cleaned.isEmpty {
            stats.invalid += 1
            return (false, nil, nil, "No digits found")
        }
        var countryCode: String? = nil
        var restDigits: String? = nil
        if cleaned.hasPrefix("+") {
            for i in 1...3 {
                guard i < cleaned.count else { break }
                let cc = String(cleaned.prefix(i+1).dropFirst())
                if PhoneValidator.countryData.keys.contains(cc) {
                    countryCode = cc
                    restDigits = String(cleaned.suffix(cleaned.count - (i+1)))
                    break
                }
            }
            if countryCode == nil {
                stats.invalid += 1
                return (false, nil, nil, "Unknown country code")
            }
        } else {
            let digits = trimmed.replacingOccurrences(of: "\\D", with: "", options: .regularExpression)
            if digits.count == 10 && digits.range(of: "^[2-9]\\d{9}$", options: .regularExpression) != nil {
                let normalized = "+1" + digits
                stats.valid += 1
                return (true, normalized, "United States/Canada", nil)
            }
            stats.invalid += 1
            return (false, nil, nil, "Could not determine country code; use + prefix")
        }

        guard let cc = countryCode, let info = PhoneValidator.countryData[cc] else {
            stats.invalid += 1
            return (false, nil, nil, "Unknown country code")
        }
        guard let rest = restDigits, !rest.isEmpty else {
            stats.invalid += 1
            return (false, nil, info.name, "Missing subscriber number")
        }
        if rest.count < info.minLen || rest.count > info.maxLen {
            stats.invalid += 1
            return (false, nil, info.name, "Invalid length: \(rest.count) (expected \(info.minLen)-\(info.maxLen))")
        }
        let range = NSRange(rest.startIndex..., in: rest)
        if info.regex.firstMatch(in: rest, range: range) == nil {
            stats.invalid += 1
            return (false, nil, info.name, "Invalid digit pattern")
        }
        let normalized = "+" + cc + rest
        stats.valid += 1
        return (true, normalized, info.name, nil)
    }

    func batchValidate(_ numbers: [String]) -> [(original: String, valid: Bool, normalized: String?, country: String?, error: String?)] {
        var results: [(String, Bool, String?, String?, String?)] = []
        for n in numbers {
            let raw = n.trimmingCharacters(in: .whitespaces)
            if raw.isEmpty { continue }
            let result = validateNumber(raw)
            results.append((raw, result.valid, result.normalized, result.country, result.error))
        }
        return results
    }

    func showStats() {
        print("\nStatistics: Total: \(stats.total), Valid: \(stats.valid), Invalid: \(stats.invalid)")
    }
}

func main() {
    let validator = PhoneValidator()
    print("=== Phone Number Validator ===")
    while true {
        print("\n1. Validate single number")
        print("2. Validate from file")
        print("3. Show statistics")
        print("4. Exit")
        print("Choose: ", terminator: "")
        guard let choice = readLine()?.trimmingCharacters(in: .whitespaces) else { continue }
        switch choice {
        case "1":
            print("Enter phone number: ", terminator: "")
            guard let num = readLine()?.trimmingCharacters(in: .whitespaces) else { break }
            let result = validator.validateNumber(num)
            print("Valid: \(result.valid)")
            if result.valid {
                print("Normalized: \(result.normalized ?? "")")
                print("Country: \(result.country ?? "")")
            } else {
                print("Error: \(result.error ?? "")")
            }
        case "2":
            print("Enter file path: ", terminator: "")
            guard let fname = readLine()?.trimmingCharacters(in: .whitespaces) else { break }
            let fileURL = URL(fileURLWithPath: fname)
            guard let content = try? String(contentsOf: fileURL, encoding: .utf8) else {
                print("File not found or unreadable.")
                break
            }
            let numbers = content.components(separatedBy: .newlines)
            let results = validator.batchValidate(numbers)
            print("\nBatch results:")
            for r in results {
                let status = r.valid ? "✓" : "✗"
                print("\(status) \(r.original): \(r.error ?? "OK")")
                if r.valid {
                    print("   Normalized: \(r.normalized ?? ""), Country: \(r.country ?? "")")
                }
            }
        case "3":
            validator.showStats()
        case "4":
            print("Goodbye!")
            return
        default:
            print("Invalid choice.")
        }
    }
}

main()
