// phone_validator.go
package main

import (
	"bufio"
	"fmt"
	"os"
	"regexp"
	"strconv"
	"strings"
)

type CountryInfo struct {
	Name   string
	MinLen int
	MaxLen int
	Regex  *regexp.Regexp
}

var countryData = map[string]CountryInfo{
	"1":   {"United States/Canada", 10, 10, regexp.MustCompile(`^[2-9]\d{9}$`)},
	"44":  {"United Kingdom", 10, 10, regexp.MustCompile(`^[1-9]\d{9}$`)},
	"49":  {"Germany", 10, 11, regexp.MustCompile(`^[1-9]\d{9,10}$`)},
	"33":  {"France", 9, 10, regexp.MustCompile(`^[1-9]\d{8,9}$`)},
	"7":   {"Russia/Kazakhstan", 10, 10, regexp.MustCompile(`^[78]\d{9}$`)},
	"380": {"Ukraine", 9, 9, regexp.MustCompile(`^[0-9]{9}$`)},
	"61":  {"Australia", 9, 10, regexp.MustCompile(`^[0-9]{9,10}$`)},
	"91":  {"India", 10, 10, regexp.MustCompile(`^[6-9]\d{9}$`)},
	"55":  {"Brazil", 10, 11, regexp.MustCompile(`^[1-9]\d{9,10}$`)},
	"86":  {"China", 11, 11, regexp.MustCompile(`^1\d{10}$`)},
	"81":  {"Japan", 10, 10, regexp.MustCompile(`^[0-9]{10}$`)},
	"82":  {"South Korea", 10, 11, regexp.MustCompile(`^[0-9]{10,11}$`)},
}

type PhoneValidator struct {
	Stats struct{ Total, Valid, Invalid int }
}

func NewPhoneValidator() *PhoneValidator {
	return &PhoneValidator{}
}

func (v *PhoneValidator) validateNumber(raw string) (bool, string, string, string) {
	v.Stats.Total++
	raw = strings.TrimSpace(raw)
	if raw == "" {
		v.Stats.Invalid++
		return false, "", "", "Empty input"
	}
	// Remove all non-digit except leading plus
	cleaned := strings.Map(func(r rune) rune {
		if r == '+' {
			return r
		}
		if r >= '0' && r <= '9' {
			return r
		}
		return -1
	}, raw)
	if cleaned == "" {
		v.Stats.Invalid++
		return false, "", "", "No digits found"
	}
	var countryCode string
	var restDigits string
	if strings.HasPrefix(cleaned, "+") {
		// try to match country code
		for i := 1; i <= 3 && i < len(cleaned); i++ {
			cc := cleaned[1 : i+1]
			if _, ok := countryData[cc]; ok {
				countryCode = cc
				restDigits = cleaned[i+1:]
				break
			}
		}
		if countryCode == "" {
			v.Stats.Invalid++
			return false, "", "", "Unknown country code"
		}
	} else {
		// No country code: try US national format
		digits := regexp.MustCompile(`\D`).ReplaceAllString(raw, "")
		if len(digits) == 10 && regexp.MustCompile(`^[2-9]\d{9}$`).MatchString(digits) {
			normalized := "+1" + digits
			v.Stats.Valid++
			return true, normalized, "United States/Canada", ""
		}
		v.Stats.Invalid++
		return false, "", "", "Could not determine country code; use + prefix"
	}

	info, ok := countryData[countryCode]
	if !ok {
		v.Stats.Invalid++
		return false, "", "", "Unknown country code"
	}
	if restDigits == "" {
		v.Stats.Invalid++
		return false, "", info.Name, "Missing subscriber number"
	}
	if len(restDigits) < info.MinLen || len(restDigits) > info.MaxLen {
		v.Stats.Invalid++
		return false, "", info.Name, fmt.Sprintf("Invalid length: %d (expected %d-%d)", len(restDigits), info.MinLen, info.MaxLen)
	}
	if !info.Regex.MatchString(restDigits) {
		v.Stats.Invalid++
		return false, "", info.Name, "Invalid digit pattern"
	}
	normalized := "+" + countryCode + restDigits
	v.Stats.Valid++
	return true, normalized, info.Name, ""
}

func (v *PhoneValidator) batchValidate(numbers []string) []struct {
	Original   string
	Valid      bool
	Normalized string
	Country    string
	Error      string
} {
	var results []struct {
		Original   string
		Valid      bool
		Normalized string
		Country    string
		Error      string
	}
	for _, n := range numbers {
		n = strings.TrimSpace(n)
		if n == "" {
			continue
		}
		valid, normalized, country, err := v.validateNumber(n)
		results = append(results, struct {
			Original   string
			Valid      bool
			Normalized string
			Country    string
			Error      string
		}{n, valid, normalized, country, err})
	}
	return results
}

func (v *PhoneValidator) showStats() {
	fmt.Printf("\nStatistics: Total: %d, Valid: %d, Invalid: %d\n", v.Stats.Total, v.Stats.Valid, v.Stats.Invalid)
}

func main() {
	validator := NewPhoneValidator()
	scanner := bufio.NewScanner(os.Stdin)
	fmt.Println("=== Phone Number Validator ===")
	for {
		fmt.Println("\n1. Validate single number")
		fmt.Println("2. Validate from file")
		fmt.Println("3. Show statistics")
		fmt.Println("4. Exit")
		fmt.Print("Choose: ")
		scanner.Scan()
		choice := strings.TrimSpace(scanner.Text())
		switch choice {
		case "1":
			fmt.Print("Enter phone number: ")
			scanner.Scan()
			num := strings.TrimSpace(scanner.Text())
			valid, normalized, country, err := validator.validateNumber(num)
			fmt.Printf("Valid: %v\n", valid)
			if valid {
				fmt.Printf("Normalized: %s\n", normalized)
				fmt.Printf("Country: %s\n", country)
			} else {
				fmt.Printf("Error: %s\n", err)
			}
		case "2":
			fmt.Print("Enter file path: ")
			scanner.Scan()
			fname := strings.TrimSpace(scanner.Text())
			file, err := os.Open(fname)
			if err != nil {
				fmt.Println("File not found.")
				break
			}
			defer file.Close()
			var numbers []string
			fileScanner := bufio.NewScanner(file)
			for fileScanner.Scan() {
				numbers = append(numbers, fileScanner.Text())
			}
			results := validator.batchValidate(numbers)
			fmt.Println("\nBatch results:")
			for _, r := range results {
				status := "✓"
				if !r.Valid {
					status = "✗"
				}
				fmt.Printf("%s %s: %s\n", status, r.Original, r.Error)
				if r.Valid {
					fmt.Printf("   Normalized: %s, Country: %s\n", r.Normalized, r.Country)
				}
			}
		case "3":
			validator.showStats()
		case "4":
			fmt.Println("Goodbye!")
			return
		default:
			fmt.Println("Invalid choice.")
		}
	}
}
