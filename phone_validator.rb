# phone_validator.rb
class PhoneValidator
  COUNTRY_DATA = {
    '1'   => { name: 'United States/Canada', min_len: 10, max_len: 10, regex: /^[2-9]\d{9}$/ },
    '44'  => { name: 'United Kingdom', min_len: 10, max_len: 10, regex: /^[1-9]\d{9}$/ },
    '49'  => { name: 'Germany', min_len: 10, max_len: 11, regex: /^[1-9]\d{9,10}$/ },
    '33'  => { name: 'France', min_len: 9, max_len: 10, regex: /^[1-9]\d{8,9}$/ },
    '7'   => { name: 'Russia/Kazakhstan', min_len: 10, max_len: 10, regex: /^[78]\d{9}$/ },
    '380' => { name: 'Ukraine', min_len: 9, max_len: 9, regex: /^[0-9]{9}$/ },
    '61'  => { name: 'Australia', min_len: 9, max_len: 10, regex: /^[0-9]{9,10}$/ },
    '91'  => { name: 'India', min_len: 10, max_len: 10, regex: /^[6-9]\d{9}$/ },
    '55'  => { name: 'Brazil', min_len: 10, max_len: 11, regex: /^[1-9]\d{9,10}$/ },
    '86'  => { name: 'China', min_len: 11, max_len: 11, regex: /^1\d{10}$/ },
    '81'  => { name: 'Japan', min_len: 10, max_len: 10, regex: /^[0-9]{10}$/ },
    '82'  => { name: 'South Korea', min_len: 10, max_len: 11, regex: /^[0-9]{10,11}$/ }
  }

  def initialize
    @stats = { total: 0, valid: 0, invalid: 0 }
  end

  attr_reader :stats

  def validate_number(raw)
    @stats[:total] += 1
    raw = raw.strip
    if raw.empty?
      @stats[:invalid] += 1
      return { valid: false, normalized: nil, country: nil, error: "Empty input" }
    end
    cleaned = raw.gsub(/[^\d+]/, '')
    if cleaned.empty?
      @stats[:invalid] += 1
      return { valid: false, normalized: nil, country: nil, error: "No digits found" }
    end
    country_code = nil
    rest_digits = nil
    if cleaned.start_with?('+')
      (1..3).each do |i|
        break if i >= cleaned.length
        cc = cleaned[1..i]
        if COUNTRY_DATA.key?(cc)
          country_code = cc
          rest_digits = cleaned[i+1..-1]
          break
        end
      end
      if country_code.nil?
        @stats[:invalid] += 1
        return { valid: false, normalized: nil, country: nil, error: "Unknown country code" }
      end
    else
      digits = raw.gsub(/\D/, '')
      if digits.length == 10 && digits =~ /^[2-9]\d{9}$/
        normalized = '+1' + digits
        @stats[:valid] += 1
        return { valid: true, normalized: normalized, country: 'United States/Canada', error: nil }
      end
      @stats[:invalid] += 1
      return { valid: false, normalized: nil, country: nil, error: "Could not determine country code; use + prefix" }
    end

    info = COUNTRY_DATA[country_code]
    if info.nil?
      @stats[:invalid] += 1
      return { valid: false, normalized: nil, country: nil, error: "Unknown country code" }
    end
    if rest_digits.nil? || rest_digits.empty?
      @stats[:invalid] += 1
      return { valid: false, normalized: nil, country: info[:name], error: "Missing subscriber number" }
    end
    if rest_digits.length < info[:min_len] || rest_digits.length > info[:max_len]
      @stats[:invalid] += 1
      return { valid: false, normalized: nil, country: info[:name], error: "Invalid length: #{rest_digits.length} (expected #{info[:min_len]}-#{info[:max_len]})" }
    end
    unless rest_digits =~ info[:regex]
      @stats[:invalid] += 1
      return { valid: false, normalized: nil, country: info[:name], error: "Invalid digit pattern" }
    end
    normalized = '+' + country_code + rest_digits
    @stats[:valid] += 1
    { valid: true, normalized: normalized, country: info[:name], error: nil }
  end

  def batch_validate(numbers)
    results = []
    numbers.each do |n|
      raw = n.strip
      next if raw.empty?
      result = validate_number(raw)
      result[:original] = raw
      results << result
    end
    results
  end

  def show_stats
    puts "\nStatistics: Total: #{@stats[:total]}, Valid: #{@stats[:valid]}, Invalid: #{@stats[:invalid]}"
  end
end

def main
  validator = PhoneValidator.new
  puts "=== Phone Number Validator ==="
  loop do
    puts "\n1. Validate single number"
    puts "2. Validate from file"
    puts "3. Show statistics"
    puts "4. Exit"
    print "Choose: "
    choice = gets.chomp.strip
    case choice
    when '1'
      print "Enter phone number: "
      num = gets.chomp.strip
      result = validator.validate_number(num)
      puts "Valid: #{result[:valid]}"
      if result[:valid]
        puts "Normalized: #{result[:normalized]}"
        puts "Country: #{result[:country]}"
      else
        puts "Error: #{result[:error]}"
      end
    when '2'
      print "Enter file path: "
      fname = gets.chomp.strip
      unless File.exist?(fname)
        puts "File not found."
        next
      end
      lines = File.readlines(fname).map(&:chomp)
      results = validator.batch_validate(lines)
      puts "\nBatch results:"
      results.each do |r|
        status = r[:valid] ? '✓' : '✗'
        puts "#{status} #{r[:original]}: #{r[:error] || 'OK'}"
        if r[:valid]
          puts "   Normalized: #{r[:normalized]}, Country: #{r[:country]}"
        end
      end
    when '3'
      validator.show_stats
    when '4'
      puts "Goodbye!"
      break
    else
      puts "Invalid choice."
    end
  end
end

main if __FILE__ == $0
