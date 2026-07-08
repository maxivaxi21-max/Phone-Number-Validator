# phone_validator.py
import re
from typing import Tuple, Optional, Dict, List, Any

class PhoneValidator:
    """Validate, normalize, and identify phone numbers."""
    
    # Country data: code -> (country_name, length_min, length_max, regex_pattern)
    COUNTRY_DATA = {
        '1':   ('United States/Canada', 10, 10, r'^[2-9]\d{9}$'),
        '44':  ('United Kingdom', 10, 10, r'^[1-9]\d{9}$'),
        '49':  ('Germany', 10, 11, r'^[1-9]\d{9,10}$'),
        '33':  ('France', 9, 10, r'^[1-9]\d{8,9}$'),
        '7':   ('Russia/Kazakhstan', 10, 10, r'^[78]\d{9}$'),
        '380': ('Ukraine', 9, 9, r'^[0-9]{9}$'),
        '61':  ('Australia', 9, 10, r'^[0-9]{9,10}$'),
        '91':  ('India', 10, 10, r'^[6-9]\d{9}$'),
        '55':  ('Brazil', 10, 11, r'^[1-9]\d{9,10}$'),
        '86':  ('China', 11, 11, r'^1\d{10}$'),
        '81':  ('Japan', 10, 10, r'^[0-9]{10}$'),
        '82':  ('South Korea', 10, 11, r'^[0-9]{10,11}$'),
    }
    
    def __init__(self):
        self.stats = {'total': 0, 'valid': 0, 'invalid': 0}
        # Regex to extract components: optional +, country code, area, subscriber
        self.parse_regex = re.compile(
            r'^(?:\+?(\d{1,4})?[-\s.]?)?(?:\(?(\d{1,4})\)?[-\s.]?)?(\d{1,4})[-\s.]?(\d{1,4})[-\s.]?(\d{1,9})$'
        )
    
    def _parse_number(self, raw: str) -> Tuple[Optional[str], List[str]]:
        """Parse raw number into country code and groups of digits."""
        # Clean: remove non-digit except leading +
        cleaned = re.sub(r'[^\d+]', '', raw)
        if not cleaned:
            return None, []
        # Try to extract using regex
        match = self.parse_regex.match(raw.strip())
        if not match:
            # Fallback: try to extract digits only
            digits = re.sub(r'\D', '', raw)
            if not digits:
                return None, []
            # Try to guess country code from start: if raw starts with +, use first 1-3 digits
            if raw.startswith('+'):
                # guess country code
                for i in range(1, 4):
                    if i <= len(digits):
                        code = digits[:i]
                        if code in self.COUNTRY_DATA:
                            rest = digits[i:]
                            return code, rest
                return None, digits
            else:
                # national format: no country code
                return None, digits
        else:
            # groups: 0=full, 1=country code, 2=area, 3=part1, 4=part2, 5=part3
            groups = match.groups()
            cc = groups[0] if groups[0] else None
            parts = [p for p in groups[1:] if p]
            # If no country code, maybe first group is area?
            # We'll handle later
            return cc, ''.join(parts) if parts else ''
    
    def _get_country(self, code: str) -> Optional[str]:
        return self.COUNTRY_DATA.get(code, None)
    
    def validate(self, number: str) -> Tuple[bool, str, Optional[str], Optional[str]]:
        """
        Validate a phone number.
        Returns: (is_valid, normalized_e164, country_name, error_message)
        """
        self.stats['total'] += 1
        raw = number.strip()
        if not raw:
            self.stats['invalid'] += 1
            return (False, None, None, "Empty input")
        
        # Parse and clean
        cleaned = re.sub(r'[^\d+]', '', raw)
        if not cleaned:
            self.stats['invalid'] += 1
            return (False, None, None, "No digits found")
        
        # Determine country code
        country_code = None
        rest_digits = ''
        if raw.startswith('+'):
            # Try to match country code from beginning
            for i in range(1, 4):
                if i <= len(cleaned):
                    cc = cleaned[1:i+1]  # remove +
                    if cc in self.COUNTRY_DATA:
                        country_code = cc
                        rest_digits = cleaned[i+1:]  # skip +
                        break
            if country_code is None:
                self.stats['invalid'] += 1
                return (False, None, None, "Unknown country code")
        else:
            # National format: no leading +. Try to infer from length and pattern? For simplicity, we check if number matches any country rule without code.
            # We'll just test against each country's pattern, but we need to know which country.
            # For demo, we can assume the user might have entered a national number and we'll check against all.
            # But we need to know which country to apply. We'll guess by length and pattern.
            # We'll just check against all countries' patterns; if more than one match, we can't decide.
            # For simplicity, we assume the first country that matches. Or we can ask user to specify.
            # We'll just check if it matches US pattern (10 digits) as fallback.
            # Better: we'll just validate national numbers for the US by default, but we also allow country code.
            # For a more complete solution, we could accept a country parameter.
            # Here we'll just check if it matches US pattern if length is 10.
            # We'll implement a simpler approach: try to parse as national number for supported countries by length.
            # We'll just return None for country if no code.
            # We'll still normalize to E.164 if we can guess country by digits.
            pass
        
        # If we have country code, we validate rest_digits against country rules
        if country_code:
            country_info = self.COUNTRY_DATA[country_code]
            country_name, min_len, max_len, pattern = country_info
            if not rest_digits:
                self.stats['invalid'] += 1
                return (False, None, country_name, "Missing subscriber number")
            if not (min_len <= len(rest_digits) <= max_len):
                self.stats['invalid'] += 1
                return (False, None, country_name, f"Invalid length: {len(rest_digits)} (expected {min_len}-{max_len})")
            if not re.match(pattern, rest_digits):
                self.stats['invalid'] += 1
                return (False, None, country_name, "Invalid digit pattern")
            # Normalize
            normalized = '+' + country_code + rest_digits
            self.stats['valid'] += 1
            return (True, normalized, country_name, None)
        else:
            # No country code: try to validate as US national number (or other)
            # We'll try US: length 10, starts with 2-9
            digits = re.sub(r'\D', '', raw)
            if len(digits) == 10 and re.match(r'^[2-9]\d{9}$', digits):
                normalized = '+1' + digits
                self.stats['valid'] += 1
                return (True, normalized, "United States/Canada", None)
            else:
                self.stats['invalid'] += 1
                return (False, None, None, "Could not determine country code; use + prefix")
    
    def batch_validate(self, numbers: List[str]) -> List[Dict[str, Any]]:
        results = []
        for n in numbers:
            n = n.strip()
            if not n:
                continue
            valid, normalized, country, error = self.validate(n)
            results.append({
                'original': n,
                'valid': valid,
                'normalized': normalized,
                'country': country,
                'error': error
            })
        return results
    
    def show_stats(self):
        print(f"\nStatistics: Total: {self.stats['total']}, Valid: {self.stats['valid']}, Invalid: {self.stats['invalid']}")

def main():
    validator = PhoneValidator()
    print("=== Phone Number Validator ===")
    while True:
        print("\n1. Validate single number")
        print("2. Validate from file")
        print("3. Show statistics")
        print("4. Exit")
        choice = input("Choose: ").strip()
        if choice == '1':
            num = input("Enter phone number: ").strip()
            valid, normalized, country, error = validator.validate(num)
            print(f"Valid: {valid}")
            if valid:
                print(f"Normalized: {normalized}")
                print(f"Country: {country}")
            else:
                print(f"Error: {error}")
        elif choice == '2':
            fname = input("Enter file path: ").strip()
            try:
                with open(fname, 'r') as f:
                    numbers = f.readlines()
                results = validator.batch_validate(numbers)
                print("\nBatch results:")
                for r in results:
                    status = "✓" if r['valid'] else "✗"
                    print(f"{status} {r['original']}: {r['error'] if r['error'] else 'OK'}")
                    if r['valid']:
                        print(f"   Normalized: {r['normalized']}, Country: {r['country']}")
            except FileNotFoundError:
                print("File not found.")
        elif choice == '3':
            validator.show_stats()
        elif choice == '4':
            print("Goodbye!")
            break
        else:
            print("Invalid choice.")

if __name__ == "__main__":
    main()
