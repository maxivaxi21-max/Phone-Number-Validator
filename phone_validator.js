// phone_validator.js
const readline = require('readline');
const fs = require('fs');

const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
});

function ask(question) {
    return new Promise(resolve => rl.question(question, resolve));
}

const countryData = {
    '1':   { name: 'United States/Canada', minLen: 10, maxLen: 10, regex: /^[2-9]\d{9}$/ },
    '44':  { name: 'United Kingdom', minLen: 10, maxLen: 10, regex: /^[1-9]\d{9}$/ },
    '49':  { name: 'Germany', minLen: 10, maxLen: 11, regex: /^[1-9]\d{9,10}$/ },
    '33':  { name: 'France', minLen: 9, maxLen: 10, regex: /^[1-9]\d{8,9}$/ },
    '7':   { name: 'Russia/Kazakhstan', minLen: 10, maxLen: 10, regex: /^[78]\d{9}$/ },
    '380': { name: 'Ukraine', minLen: 9, maxLen: 9, regex: /^[0-9]{9}$/ },
    '61':  { name: 'Australia', minLen: 9, maxLen: 10, regex: /^[0-9]{9,10}$/ },
    '91':  { name: 'India', minLen: 10, maxLen: 10, regex: /^[6-9]\d{9}$/ },
    '55':  { name: 'Brazil', minLen: 10, maxLen: 11, regex: /^[1-9]\d{9,10}$/ },
    '86':  { name: 'China', minLen: 11, maxLen: 11, regex: /^1\d{10}$/ },
    '81':  { name: 'Japan', minLen: 10, maxLen: 10, regex: /^[0-9]{10}$/ },
    '82':  { name: 'South Korea', minLen: 10, maxLen: 11, regex: /^[0-9]{10,11}$/ }
};

class PhoneValidator {
    constructor() {
        this.stats = { total: 0, valid: 0, invalid: 0 };
    }

    validateNumber(raw) {
        this.stats.total++;
        raw = raw.trim();
        if (!raw) {
            this.stats.invalid++;
            return { valid: false, normalized: null, country: null, error: "Empty input" };
        }
        // Remove all non-digit except leading plus
        let cleaned = raw.replace(/[^\d+]/g, '');
        if (!cleaned) {
            this.stats.invalid++;
            return { valid: false, normalized: null, country: null, error: "No digits found" };
        }
        let countryCode = null;
        let restDigits = null;
        if (cleaned.startsWith('+')) {
            for (let i = 1; i <= 3 && i < cleaned.length; i++) {
                const cc = cleaned.substring(1, i+1);
                if (countryData[cc]) {
                    countryCode = cc;
                    restDigits = cleaned.substring(i+1);
                    break;
                }
            }
            if (!countryCode) {
                this.stats.invalid++;
                return { valid: false, normalized: null, country: null, error: "Unknown country code" };
            }
        } else {
            // No country code: try US national format
            const digits = raw.replace(/\D/g, '');
            if (digits.length === 10 && /^[2-9]\d{9}$/.test(digits)) {
                const normalized = '+1' + digits;
                this.stats.valid++;
                return { valid: true, normalized, country: "United States/Canada", error: null };
            }
            this.stats.invalid++;
            return { valid: false, normalized: null, country: null, error: "Could not determine country code; use + prefix" };
        }

        const info = countryData[countryCode];
        if (!info) {
            this.stats.invalid++;
            return { valid: false, normalized: null, country: null, error: "Unknown country code" };
        }
        if (!restDigits) {
            this.stats.invalid++;
            return { valid: false, normalized: null, country: info.name, error: "Missing subscriber number" };
        }
        if (restDigits.length < info.minLen || restDigits.length > info.maxLen) {
            this.stats.invalid++;
            return { valid: false, normalized: null, country: info.name, error: `Invalid length: ${restDigits.length} (expected ${info.minLen}-${info.maxLen})` };
        }
        if (!info.regex.test(restDigits)) {
            this.stats.invalid++;
            return { valid: false, normalized: null, country: info.name, error: "Invalid digit pattern" };
        }
        const normalized = '+' + countryCode + restDigits;
        this.stats.valid++;
        return { valid: true, normalized, country: info.name, error: null };
    }

    batchValidate(numbers) {
        const results = [];
        for (const n of numbers) {
            const raw = n.trim();
            if (!raw) continue;
            const result = this.validateNumber(raw);
            results.push({ original: raw, ...result });
        }
        return results;
    }

    showStats() {
        console.log(`\nStatistics: Total: ${this.stats.total}, Valid: ${this.stats.valid}, Invalid: ${this.stats.invalid}`);
    }
}

async function main() {
    const validator = new PhoneValidator();
    console.log("=== Phone Number Validator ===");
    while (true) {
        console.log("\n1. Validate single number");
        console.log("2. Validate from file");
        console.log("3. Show statistics");
        console.log("4. Exit");
        const choice = await ask("Choose: ");
        switch (choice.trim()) {
            case '1': {
                const num = await ask("Enter phone number: ");
                const result = validator.validateNumber(num);
                console.log(`Valid: ${result.valid}`);
                if (result.valid) {
                    console.log(`Normalized: ${result.normalized}`);
                    console.log(`Country: ${result.country}`);
                } else {
                    console.log(`Error: ${result.error}`);
                }
                break;
            }
            case '2': {
                const fname = await ask("Enter file path: ");
                try {
                    const data = fs.readFileSync(fname, 'utf8');
                    const numbers = data.split('\n');
                    const results = validator.batchValidate(numbers);
                    console.log("\nBatch results:");
                    for (const r of results) {
                        const status = r.valid ? '✓' : '✗';
                        console.log(`${status} ${r.original}: ${r.error || 'OK'}`);
                        if (r.valid) {
                            console.log(`   Normalized: ${r.normalized}, Country: ${r.country}`);
                        }
                    }
                } catch (e) {
                    console.log("File not found or error.");
                }
                break;
            }
            case '3':
                validator.showStats();
                break;
            case '4':
                console.log("Goodbye!");
                rl.close();
                return;
            default:
                console.log("Invalid choice.");
        }
    }
}

main().catch(console.error);
