// PhoneValidator.cs
using System;
using System.Collections.Generic;
using System.IO;
using System.Text.RegularExpressions;

class CountryInfo {
    public string Name { get; set; }
    public int MinLen { get; set; }
    public int MaxLen { get; set; }
    public Regex Regex { get; set; }
}

class PhoneValidator {
    private static readonly Dictionary<string, CountryInfo> CountryData = new Dictionary<string, CountryInfo>
    {
        {"1", new CountryInfo{Name="United States/Canada", MinLen=10, MaxLen=10, Regex=new Regex(@"^[2-9]\d{9}$")}},
        {"44", new CountryInfo{Name="United Kingdom", MinLen=10, MaxLen=10, Regex=new Regex(@"^[1-9]\d{9}$")}},
        {"49", new CountryInfo{Name="Germany", MinLen=10, MaxLen=11, Regex=new Regex(@"^[1-9]\d{9,10}$")}},
        {"33", new CountryInfo{Name="France", MinLen=9, MaxLen=10, Regex=new Regex(@"^[1-9]\d{8,9}$")}},
        {"7", new CountryInfo{Name="Russia/Kazakhstan", MinLen=10, MaxLen=10, Regex=new Regex(@"^[78]\d{9}$")}},
        {"380", new CountryInfo{Name="Ukraine", MinLen=9, MaxLen=9, Regex=new Regex(@"^[0-9]{9}$")}},
        {"61", new CountryInfo{Name="Australia", MinLen=9, MaxLen=10, Regex=new Regex(@"^[0-9]{9,10}$")}},
        {"91", new CountryInfo{Name="India", MinLen=10, MaxLen=10, Regex=new Regex(@"^[6-9]\d{9}$")}},
        {"55", new CountryInfo{Name="Brazil", MinLen=10, MaxLen=11, Regex=new Regex(@"^[1-9]\d{9,10}$")}},
        {"86", new CountryInfo{Name="China", MinLen=11, MaxLen=11, Regex=new Regex(@"^1\d{10}$")}},
        {"81", new CountryInfo{Name="Japan", MinLen=10, MaxLen=10, Regex=new Regex(@"^[0-9]{10}$")}},
        {"82", new CountryInfo{Name="South Korea", MinLen=10, MaxLen=11, Regex=new Regex(@"^[0-9]{10,11}$")}}
    };

    public (int Total, int Valid, int Invalid) Stats { get; private set; }

    public PhoneValidator() {
        Stats = (0, 0, 0);
    }

    public (bool valid, string normalized, string country, string error) ValidateNumber(string raw) {
        Stats.Total++;
        raw = raw.Trim();
        if (string.IsNullOrEmpty(raw)) {
            Stats.Invalid++;
            return (false, null, null, "Empty input");
        }
        string cleaned = Regex.Replace(raw, @"[^\d+]", "");
        if (string.IsNullOrEmpty(cleaned)) {
            Stats.Invalid++;
            return (false, null, null, "No digits found");
        }
        string countryCode = null;
        string restDigits = null;
        if (cleaned.StartsWith("+")) {
            for (int i = 1; i <= 3 && i < cleaned.Length; i++) {
                string cc = cleaned.Substring(1, i);
                if (CountryData.ContainsKey(cc)) {
                    countryCode = cc;
                    restDigits = cleaned.Substring(i + 1);
                    break;
                }
            }
            if (countryCode == null) {
                Stats.Invalid++;
                return (false, null, null, "Unknown country code");
            }
        } else {
            // No country code: try US
            string digits = Regex.Replace(raw, @"\D", "");
            if (digits.Length == 10 && Regex.IsMatch(digits, @"^[2-9]\d{9}$")) {
                string normalized = "+1" + digits;
                Stats.Valid++;
                return (true, normalized, "United States/Canada", null);
            }
            Stats.Invalid++;
            return (false, null, null, "Could not determine country code; use + prefix");
        }

        if (!CountryData.ContainsKey(countryCode)) {
            Stats.Invalid++;
            return (false, null, null, "Unknown country code");
        }
        var info = CountryData[countryCode];
        if (string.IsNullOrEmpty(restDigits)) {
            Stats.Invalid++;
            return (false, null, info.Name, "Missing subscriber number");
        }
        if (restDigits.Length < info.MinLen || restDigits.Length > info.MaxLen) {
            Stats.Invalid++;
            return (false, null, info.Name, $"Invalid length: {restDigits.Length} (expected {info.MinLen}-{info.MaxLen})");
        }
        if (!info.Regex.IsMatch(restDigits)) {
            Stats.Invalid++;
            return (false, null, info.Name, "Invalid digit pattern");
        }
        string normalized = "+" + countryCode + restDigits;
        Stats.Valid++;
        return (true, normalized, info.Name, null);
    }

    public List<(string original, bool valid, string normalized, string country, string error)> BatchValidate(string[] numbers) {
        var results = new List<(string, bool, string, string, string)>();
        foreach (var n in numbers) {
            string raw = n.Trim();
            if (string.IsNullOrEmpty(raw)) continue;
            var res = ValidateNumber(raw);
            results.Add((raw, res.valid, res.normalized, res.country, res.error));
        }
        return results;
    }

    public void ShowStats() {
        Console.WriteLine($"\nStatistics: Total: {Stats.Total}, Valid: {Stats.Valid}, Invalid: {Stats.Invalid}");
    }

    static void Main() {
        var validator = new PhoneValidator();
        Console.WriteLine("=== Phone Number Validator ===");
        while (true) {
            Console.WriteLine("\n1. Validate single number");
            Console.WriteLine("2. Validate from file");
            Console.WriteLine("3. Show statistics");
            Console.WriteLine("4. Exit");
            Console.Write("Choose: ");
            string choice = Console.ReadLine()?.Trim() ?? "";
            switch (choice) {
                case "1":
                    Console.Write("Enter phone number: ");
                    string num = Console.ReadLine()?.Trim() ?? "";
                    var result = validator.ValidateNumber(num);
                    Console.WriteLine($"Valid: {result.valid}");
                    if (result.valid) {
                        Console.WriteLine($"Normalized: {result.normalized}");
                        Console.WriteLine($"Country: {result.country}");
                    } else {
                        Console.WriteLine($"Error: {result.error}");
                    }
                    break;
                case "2":
                    Console.Write("Enter file path: ");
                    string fname = Console.ReadLine()?.Trim() ?? "";
                    if (!File.Exists(fname)) {
                        Console.WriteLine("File not found.");
                        break;
                    }
                    string[] lines = File.ReadAllLines(fname);
                    var results = validator.BatchValidate(lines);
                    Console.WriteLine("\nBatch results:");
                    foreach (var r in results) {
                        string status = r.valid ? "✓" : "✗";
                        Console.WriteLine($"{status} {r.original}: {r.error ?? "OK"}");
                        if (r.valid) {
                            Console.WriteLine($"   Normalized: {r.normalized}, Country: {r.country}");
                        }
                    }
                    break;
                case "3":
                    validator.ShowStats();
                    break;
                case "4":
                    Console.WriteLine("Goodbye!");
                    return;
                default:
                    Console.WriteLine("Invalid choice.");
                    break;
            }
        }
    }
}
