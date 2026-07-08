// PhoneValidator.java
import java.io.*;
import java.util.*;
import java.util.regex.*;

public class PhoneValidator {
    private static class CountryInfo {
        String name;
        int minLen, maxLen;
        Pattern pattern;
        CountryInfo(String n, int min, int max, String regex) {
            name = n; minLen = min; maxLen = max; pattern = Pattern.compile(regex);
        }
    }

    private static final Map<String, CountryInfo> COUNTRY_DATA = new HashMap<>();
    static {
        COUNTRY_DATA.put("1", new CountryInfo("United States/Canada", 10, 10, "^[2-9]\\d{9}$"));
        COUNTRY_DATA.put("44", new CountryInfo("United Kingdom", 10, 10, "^[1-9]\\d{9}$"));
        COUNTRY_DATA.put("49", new CountryInfo("Germany", 10, 11, "^[1-9]\\d{9,10}$"));
        COUNTRY_DATA.put("33", new CountryInfo("France", 9, 10, "^[1-9]\\d{8,9}$"));
        COUNTRY_DATA.put("7", new CountryInfo("Russia/Kazakhstan", 10, 10, "^[78]\\d{9}$"));
        COUNTRY_DATA.put("380", new CountryInfo("Ukraine", 9, 9, "^[0-9]{9}$"));
        COUNTRY_DATA.put("61", new CountryInfo("Australia", 9, 10, "^[0-9]{9,10}$"));
        COUNTRY_DATA.put("91", new CountryInfo("India", 10, 10, "^[6-9]\\d{9}$"));
        COUNTRY_DATA.put("55", new CountryInfo("Brazil", 10, 11, "^[1-9]\\d{9,10}$"));
        COUNTRY_DATA.put("86", new CountryInfo("China", 11, 11, "^1\\d{10}$"));
        COUNTRY_DATA.put("81", new CountryInfo("Japan", 10, 10, "^[0-9]{10}$"));
        COUNTRY_DATA.put("82", new CountryInfo("South Korea", 10, 11, "^[0-9]{10,11}$"));
    }

    private int total, valid, invalid;

    public PhoneValidator() {
        total = valid = invalid = 0;
    }

    public Result validateNumber(String raw) {
        total++;
        raw = raw.trim();
        if (raw.isEmpty()) { invalid++; return new Result(false, null, null, "Empty input"); }
        String cleaned = raw.replaceAll("[^\\d+]", "");
        if (cleaned.isEmpty()) { invalid++; return new Result(false, null, null, "No digits found"); }
        String countryCode = null;
        String restDigits = null;
        if (cleaned.startsWith("+")) {
            for (int i = 1; i <= 3 && i < cleaned.length(); i++) {
                String cc = cleaned.substring(1, i+1);
                if (COUNTRY_DATA.containsKey(cc)) {
                    countryCode = cc;
                    restDigits = cleaned.substring(i+1);
                    break;
                }
            }
            if (countryCode == null) { invalid++; return new Result(false, null, null, "Unknown country code"); }
        } else {
            String digits = raw.replaceAll("\\D", "");
            if (digits.length() == 10 && digits.matches("^[2-9]\\d{9}$")) {
                String normalized = "+1" + digits;
                valid++;
                return new Result(true, normalized, "United States/Canada", null);
            }
            invalid++;
            return new Result(false, null, null, "Could not determine country code; use + prefix");
        }

        CountryInfo info = COUNTRY_DATA.get(countryCode);
        if (info == null) { invalid++; return new Result(false, null, null, "Unknown country code"); }
        if (restDigits == null || restDigits.isEmpty()) { invalid++; return new Result(false, null, info.name, "Missing subscriber number"); }
        if (restDigits.length() < info.minLen || restDigits.length() > info.maxLen) {
            invalid++;
            return new Result(false, null, info.name, "Invalid length: " + restDigits.length() + " (expected " + info.minLen + "-" + info.maxLen + ")");
        }
        if (!info.pattern.matcher(restDigits).matches()) {
            invalid++;
            return new Result(false, null, info.name, "Invalid digit pattern");
        }
        String normalized = "+" + countryCode + restDigits;
        valid++;
        return new Result(true, normalized, info.name, null);
    }

    public List<Result> batchValidate(String[] numbers) {
        List<Result> results = new ArrayList<>();
        for (String n : numbers) {
            String raw = n.trim();
            if (raw.isEmpty()) continue;
            Result r = validateNumber(raw);
            r.original = raw;
            results.add(r);
        }
        return results;
    }

    public void showStats() {
        System.out.printf("\nStatistics: Total: %d, Valid: %d, Invalid: %d\n", total, valid, invalid);
    }

    static class Result {
        boolean valid;
        String normalized;
        String country;
        String error;
        String original;
        Result(boolean v, String norm, String c, String e) { valid = v; normalized = norm; country = c; error = e; }
    }

    public static void main(String[] args) throws IOException {
        PhoneValidator validator = new PhoneValidator();
        BufferedReader reader = new BufferedReader(new InputStreamReader(System.in));
        System.out.println("=== Phone Number Validator ===");
        while (true) {
            System.out.println("\n1. Validate single number");
            System.out.println("2. Validate from file");
            System.out.println("3. Show statistics");
            System.out.println("4. Exit");
            System.out.print("Choose: ");
            String choice = reader.readLine().trim();
            switch (choice) {
                case "1":
                    System.out.print("Enter phone number: ");
                    String num = reader.readLine().trim();
                    Result res = validator.validateNumber(num);
                    System.out.println("Valid: " + res.valid);
                    if (res.valid) {
                        System.out.println("Normalized: " + res.normalized);
                        System.out.println("Country: " + res.country);
                    } else {
                        System.out.println("Error: " + res.error);
                    }
                    break;
                case "2":
                    System.out.print("Enter file path: ");
                    String fname = reader.readLine().trim();
                    File file = new File(fname);
                    if (!file.exists()) {
                        System.out.println("File not found.");
                        break;
                    }
                    List<String> lines = new ArrayList<>();
                    try (BufferedReader br = new BufferedReader(new FileReader(file))) {
                        String line;
                        while ((line = br.readLine()) != null) {
                            lines.add(line);
                        }
                    }
                    String[] arr = lines.toArray(new String[0]);
                    List<Result> results = validator.batchValidate(arr);
                    System.out.println("\nBatch results:");
                    for (Result r : results) {
                        String status = r.valid ? "✓" : "✗";
                        System.out.printf("%s %s: %s\n", status, r.original, r.error != null ? r.error : "OK");
                        if (r.valid) {
                            System.out.printf("   Normalized: %s, Country: %s\n", r.normalized, r.country);
                        }
                    }
                    break;
                case "3":
                    validator.showStats();
                    break;
                case "4":
                    System.out.println("Goodbye!");
                    return;
                default:
                    System.out.println("Invalid choice.");
            }
        }
    }
}
