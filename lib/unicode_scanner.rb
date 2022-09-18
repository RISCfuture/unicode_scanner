# UnicodeScanner provides for Unicode-aware lexical scanning operations on a
# `String`.  Here is an example of its usage:
#
# ```` ruby
# s = UnicodeScanner.new('This is an example string')
# s.eos?               # -> false
#
# p s.scan(/\w+/)      # -> "This"
# p s.scan(/\w+/)      # -> nil
# p s.scan(/\s+/)      # -> " "
# p s.scan(/\s+/)      # -> nil
# p s.scan(/\w+/)      # -> "is"
# s.eos?               # -> false
#
# p s.scan(/\s+/)      # -> " "
# p s.scan(/\w+/)      # -> "an"
# p s.scan(/\s+/)      # -> " "
# p s.scan(/\w+/)      # -> "example"
# p s.scan(/\s+/)      # -> " "
# p s.scan(/\w+/)      # -> "string"
# s.eos?               # -> true
#
# p s.scan(/\s+/)      # -> nil
# p s.scan(/\w+/)      # -> nil
# ````
#
# Scanning a string means remembering the position of a _scan pointer_, which is
# just an index.  The point of scanning is to move forward a bit at a time, so
# matches are sought after the scan pointer; usually immediately after it.
#
# Given the string "test string", here are the pertinent scan pointer positions:
#
# ````
#   t e s t   s t r i n g
# 0 1 2 ...             1
#                       0
# ````
#
# When you {#scan} for a pattern (a regular expression), the match must occur at
# the character after the scan pointer.  If you use {#scan_until}, then the
# match can occur anywhere after the scan pointer.  In both cases, the scan
# pointer moves _just beyond_ the last character of the match, ready to scan
# again from the next character onwards.  This is demonstrated by the example
# above.
#
# Method Categories
# -----------------
#
# There are other methods besides the plain scanners.  You can look ahead in the
# string without actually scanning.  You can access the most recent match. You
# can modify the string being scanned, reset or terminate the scanner, find out
# or change the position of the scan pointer, skip ahead, and so on.
#
# ### Advancing the Scan Pointer
#
# - {#getch}
# - {#scan}
# - {#scan_until}
# - {#skip}
# - {#skip_until}
#
# ### Looking Ahead
#
# - {#check}
# - {#check_until}
# - {#exist?}
# - {#match?}
# - {#peek}
#
# ### Finding Where we Are
#
# - {#beginning_of_line?} ({#bol?})
# - {#eos?}
# - {#rest_size}
# - {#pos}
#
# ### Setting Where we Are
#
# - {#reset}
# - {#terminate}
# - {#pos=}
#
# ### Match Data
#
# - {#matched}
# - {#matched?}
# - {#matched_size}
# - {#[]}
# - {#pre_match}
# - {#post_match}
#
# ### Miscellaneous
#
# - {#<<}
# - {#concat}
# - {#string}
# - {#string=}
# - {#unscan}
#
# There are aliases to several of the methods.

class UnicodeScanner
  INSPECT_LENGTH = 5

  # Creates a new UnicodeScanner object to scan over the given `string`.
  #
  # @param [String] string The string to iterate over.

  def initialize(string)
    @string   = string
    @matches  = nil
    @matched  = false
    @current  = 0
    @previous = 0
  end

  # Appends `str` to the string being scanned. This method does not affect scan
  # pointer.
  #
  # @param [String] str The string to append.
  #
  # @example
  #   s = UnicodeScanner.new("Fri Dec 12 1975 14:39")
  #   s.scan(/Fri /)
  #   s << " +1000 GMT"
  #   s.string            # -> "Fri Dec 12 1975 14:39 +1000 GMT"
  #   s.scan(/Dec/)       # -> "Dec"

  def concat(str)
    @string.concat str
  end

  alias << concat

  # Return the <i>n</i>th subgroup in the most recent match.
  #
  # @param [Fixnum] n The index of the subgroup to return.
  # @return [String, nil] The subgroup, if it exists.
  #
  # @example
  #   s = UnicodeScanner.new("Fri Dec 12 1975 14:39")
  #   s.scan(/(\w+) (\w+) (\d+) /)       # -> "Fri Dec 12 "
  #   s[0]                               # -> "Fri Dec 12 "
  #   s[1]                               # -> "Fri"
  #   s[2]                               # -> "Dec"
  #   s[3]                               # -> "12"
  #   s.post_match                       # -> "1975 14:39"
  #   s.pre_match                        # -> ""

  def [](n)
    @matched ? @matches[n] : nil
  end

  # @return [true, false] `true` iff the scan pointer is at the beginning of the
  #   line.
  #
  # @example
  #   s = UnicodeScanner.new("test\ntest\n")
  #   s.bol?           # => true
  #   s.scan(/te/)
  #   s.bol?           # => false
  #   s.scan(/st\n/)
  #   s.bol?           # => true
  #   s.terminate
  #   s.bol?           # => true

  def beginning_of_line?
    return nil if @current > @string.size
    return true if @current.zero?

    return @string[@current - 1] == "\n"
  end

  alias bol? beginning_of_line?

  # This returns the value that {#scan} would return, without advancing the scan
  # pointer. The match register is affected, though.
  #
  # Mnemonic: it "checks" to see whether a {#scan} will return a value.
  #
  # @param [Regexp] pattern The pattern to scan for.
  # @return [String, nil] The matched segment, if matched.
  #
  # @example
  #   s = UnicodeScanner.new("Fri Dec 12 1975 14:39")
  #   s.check /Fri/               # -> "Fri"
  #   s.pos                       # -> 0
  #   s.matched                   # -> "Fri"
  #   s.check /12/                # -> nil
  #   s.matched                   # -> nil

  def check(pattern)
    do_scan pattern, false, true, true
  end

  # This returns the value that {#scan_until} would return, without advancing
  # the scan pointer. The match register is affected, though.
  #
  # Mnemonic: it "checks" to see whether a {#scan_until} will return a value.
  #
  # @param [Regexp] pattern The pattern to scan until reaching.
  # @return [String, nil] The matched segment, if matched.
  #
  # @example
  #   s = UnicodeScanner.new("Fri Dec 12 1975 14:39")
  #   s.check_until /12/          # -> "Fri Dec 12"
  #   s.pos                       # -> 0
  #   s.matched                   # -> 12

  def check_until(pattern)
    do_scan pattern, false, true, false
  end

  # @return [true, false] `true` if the scan pointer is at the end of the string.
  #
  # @example
  #   s = UnicodeScanner.new('test string')
  #   p s.eos?          # => false
  #   s.scan(/test/)
  #   p s.eos?          # => false
  #   s.terminate
  #   p s.eos?          # => true

  def eos?
    @current >= @string.length
  end

  # Looks _ahead_ to see if the `pattern` exists _anywhere_ in the string,
  # without advancing the scan pointer. This predicates whether a {#scan_until}
  # will return a value.
  #
  # @param [Regexp] pattern The pattern to search for.
  # @return [true, false] Whether the pattern exists ahead.
  #
  # @example
  #   s = UnicodeScanner.new('test string')
  #   s.exist? /s/            # -> 3
  #   s.scan /test/           # -> "test"
  #   s.exist? /s/            # -> 2
  #   s.exist? /e/            # -> nil

  def exist?(pattern)
    do_scan pattern, false, false, false
  end

  # Scans one character and returns it.
  #
  # @return [String] The character.
  #
  # @example
  #   s = UnicodeScanner.new("ab")
  #   s.getch           # => "a"
  #   s.getch           # => "b"
  #   s.getch           # => nil
  #
  #   $KCODE = 'EUC'
  #   s = UnicodeScanner.new("\2244\2242")
  #   s.getch           # => "\244\242"   # Japanese hira-kana "A" in EUC-JP
  #   s.getch           # => nil

  def getch
    return nil if eos?

    do_scan(/./u, true, true, true)
  end

  # Returns a string that represents the UnicodeScanner object, showing:
  #
  # * the current position
  # * the size of the string
  # * the characters surrounding the scan pointer
  #
  # @return [String] A description of this object.
  #
  # @example
  #   s = ::new("Fri Dec 12 1975 14:39")
  #   s.inspect # -> '#<UnicodeScanner 0/21 @ "Fri D...">'
  #   s.scan_until /12/ # -> "Fri Dec 12"
  #   s.inspect # -> '#<UnicodeScanner 10/21 "...ec 12" @ " 1975...">'

  def inspect
    return "#<#{self.class} (uninitialized)>" if @string.nil?
    return "#<#{self.class} fin>" if eos?

    if @current.zero?
      return format("#<%{class} %<cur>d/%<len>d @ %{after}>",
                    class: self.class.to_s,
                    cur:   @current,
                    len:   @string.length,
                    after: inspect_after.inspect)
    end

    format("#<%{class} %<cur>d/%<len>d %{before} @ %{after}>",
           class:  self.class.to_s,
           cur:    @current,
           len:    @string.length,
           before: inspect_before.inspect,
           after:  inspect_after.inspect)
  end

  # Tests whether the given `pattern` is matched from the current scan pointer.
  # Returns the length of the match, or `nil`. The scan pointer is not advanced.
  #
  # @param [Regexp] pattern The pattern to match with.
  # @return [true, false] Whether the pattern is matched from the scan pointer.
  #
  # @example
  #   s = UnicodeScanner.new('test string')
  #   p s.match?(/\w+/)   # -> 4
  #   p s.match?(/\w+/)   # -> 4
  #   p s.match?(/\s+/)   # -> nil

  def match?(pattern)
    do_scan pattern, false, false, true
  end

  # @return [String, nil] The last matched string.
  # @example
  #   s = UnicodeScanner.new('test string')
  #   s.match?(/\w+/)     # -> 4
  #   s.matched           # -> "test"

  def matched
    return nil unless @matched

    @matches[0]
  end

  # @return [true, false] `true` iff the last match was successful.
  # @example
  #   s = UnicodeScanner.new('test string')
  #   s.match?(/\w+/)     # => 4
  #   s.matched?          # => true
  #   s.match?(/\d+/)     # => nil
  #   s.matched?          # => false

  def matched?() @matched end

  # @return [Fixnum, nil] The size of the most recent match (see {#matched}), or
  #   `nil` if there was no recent match.
  # @example
  #   s = UnicodeScanner.new('test string')
  #   s.check /\w+/           # -> "test"
  #   s.matched_size          # -> 4
  #   s.check /\d+/           # -> nil
  #   s.matched_size          # -> nil

  def matched_size
    return nil unless @matched

    @matches.end(0) - @matches.begin(0)
  end

  # Extracts a string corresponding to `string[pos,len]`, without advancing the
  # scan pointer.
  #
  # @param [Fixnum] len The number of characters ahead to peek.
  # @return [String] The string after the current position.
  #
  # @example
  #   s = UnicodeScanner.new('test string')
  #   s.peek(7)          # => "test st"
  #   s.peek(7)          # => "test st"

  def peek(len)
    return '' if eos?

    @string[@current, len]
  end

  # Returns the byte position of the scan pointer. In the 'reset' position, this
  # value is zero. In the 'terminated' position (i.e. the string is exhausted),
  # this value is the bytesize of the string.
  #
  # In short, it's a 0-based index into the string.
  #
  # @return [Fixnum] The current scan position.
  #
  # @example
  #   s = UnicodeScanner.new('test string')
  #   s.pos               # -> 0
  #   s.scan_until /str/  # -> "test str"
  #   s.pos               # -> 8
  #   s.terminate         # -> #<UnicodeScanner fin>
  #   s.pos               # -> 11

  def pos() @current end

  alias pointer pos

  # Set the byte position of the scan pointer.
  #
  # @param [Fixnum] n The new position.
  #
  # @example
  #   s = UnicodeScanner.new('test string')
  #   s.pos = 7            # -> 7
  #   s.rest               # -> "ring"

  def pos=(n)
    n += @string.length if n.negative?
    raise RangeError, "index out of range" if n.negative?
    raise RangeError, "index out of range" if n > @string.length

    @current = n
  end

  # @return [String] The _**post**-match_ (in the regular expression sense) of
  #   the last scan.
  # @example
  #   s = UnicodeScanner.new('test string')
  #   s.scan(/\w+/)           # -> "test"
  #   s.scan(/\s+/)           # -> " "
  #   s.pre_match             # -> "test"
  #   s.post_match            # -> "string"

  def post_match
    return nil unless @matched

    @string[@previous + @matches.end(0), @string.length]
  end

  # @return [String] The _**pre**-match_ (in the regular expression sense) of
  #   the last scan.
  # @example
  #   s = UnicodeScanner.new('test string')
  #   s.scan(/\w+/)           # -> "test"
  #   s.scan(/\s+/)           # -> " "
  #   s.pre_match             # -> "test"
  #   s.post_match            # -> "string"

  def pre_match
    return nil unless @matched

    @string[0, @previous + @matches.begin(0)]
  end

  # Reset the scan pointer (index 0) and clear matching data.

  def reset
    @current = 0
    @matched = false
  end

  # @return [String] The "rest" of the string (i.e. everything after the scan
  #   pointer). If there is no more data (`eos? = true`), it returns `""`.

  def rest
    return '' if eos?

    return @string[@current, @string.length]
  end

  # @return [Fixnum] The value returned by `s.rest.size`.

  def rest_size
    return 0 if eos?

    @string.length - @current
  end

  # Tries to match with `pattern` at the current position. If there's a match,
  # the scanner advances the "scan pointer" and returns the matched string.
  # Otherwise, the scanner returns `nil`.
  #
  # @param [Regexp] pattern The pattern to match.
  # @return [String, nil] The string that was matched, if a match was found.
  #
  # @example
  #   s = UnicodeScanner.new('test string')
  #   p s.scan(/\w+/)   # -> "test"
  #   p s.scan(/\w+/)   # -> nil
  #   p s.scan(/\s+/)   # -> " "
  #   p s.scan(/\w+/)   # -> "string"
  #   p s.scan(/./)     # -> nil

  def scan(pattern)
    do_scan pattern, true, true, true
  end

  # Tests whether the given `pattern` is matched from the current scan pointer.
  # Advances the scan pointer if `advance_pointer` is `true`. Returns the
  # matched string if `return_string` is true. The match register is affected.
  #
  # "full" means "scan with full parameters".
  #
  # @param [Regexp] pattern The pattern to scan.
  # @param [true, false] advance_pointer Whether to advance the scan pointer if
  #   a match is found.
  # @param [true, false] return_string Whether to return the matched segment.
  # @return [String, Fixnum, nil] The matched segment if `return_string` is
  #   `true`, otherwise the number of characters advanced. `nil` if nothing
  #   matched.

  def scan_full(pattern, advance_pointer, return_string)
    do_scan pattern, advance_pointer, return_string, true
  end

  # Scans the string _until_ the `pattern` is matched. Returns the substring up
  # to and including the end of the match, advancing the scan pointer to that
  # location. If there is no match, `nil` is returned.
  #
  # @param [Regexp] pattern The pattern to match.
  # @return [String, nil] The segment that matched.
  #
  # @example
  #   s = UnicodeScanner.new("Fri Dec 12 1975 14:39")
  #   s.scan_until(/1/)        # -> "Fri Dec 1"
  #   s.pre_match              # -> "Fri Dec "
  #   s.scan_until(/XYZ/)      # -> nil

  def scan_until(pattern)
    do_scan pattern, true, true, false
  end

  # Scans the string `until` the pattern is matched. Advances the scan pointer
  # if `advance_pointer`, otherwise not. Returns the matched string if
  # `return_string` is `true`, otherwise returns the number of characters
  # advanced. This method does affect the match register.
  #
  # @param [Regexp] pattern The pattern to scan.
  # @param [true, false] advance_pointer Whether to advance the scan pointer if
  #   a match is found.
  # @param [true, false] return_string Whether to return the matched segment.
  # @return [String, Fixnum, nil] The matched segment if `return_string` is
  #   `true`, otherwise the number of characters advanced. `nil` if nothing
  #   matched.

  def search_full(pattern, advance_pointer, return_string)
    do_scan pattern, advance_pointer, return_string, false
  end

  # Attempts to skip over the given `pattern` beginning with the scan pointer.
  # If it matches, the scan pointer is advanced to the end of the match, and the
  # length of the match is returned. Otherwise, `nil` is returned.
  #
  # It's similar to {#scan}, but without returning the matched string.
  #
  # @param [Regexp] pattern The pattern to match.
  # @return [Fixnum, nil] The number of characters advanced, if matched.
  #
  # @example
  #   s = UnicodeScanner.new('test string')
  #   p s.skip(/\w+/)   # -> 4
  #   p s.skip(/\w+/)   # -> nil
  #   p s.skip(/\s+/)   # -> 1
  #   p s.skip(/\w+/)   # -> 6
  #   p s.skip(/./)     # -> nil

  def skip(pattern)
    do_scan pattern, true, false, true
  end

  # Advances the scan pointer until `pattern` is matched and consumed. Returns
  # the number of characters advanced, or `nil` if no match was found.
  #
  # Look ahead to match `pattern`, and advance the scan pointer to the _end_ of
  # the match. Return the number of characters advanced, or `nil` if the match
  # was unsuccessful.
  #
  # It's similar to {#scan_until}, but without returning the intervening string.
  #
  # @param [Regexp] pattern The pattern to match.
  # @return [Fixnum, nil] The number of characters advanced, if matched.

  def skip_until(pattern)
    do_scan pattern, true, false, false
  end

  # @return [String] The string being scanned.

  attr_reader :string

  # Changes the string being scanned to `str` and resets the scanner.
  #
  # @param [String] str The new string to scan.
  # @return [String] `str`

  def string=(str)
    @string  = str
    @matched = false
    @current = 0
  end

  # Set the scan pointer to the end of the string and clear matching data.

  def terminate
    @current = @string.length
    @matched = false
    self
  end
  alias clear terminate

  # Set the scan pointer to the previous position. Only one previous position is
  # remembered, and it changes with each scanning operation.
  #
  # @example
  #   s = UnicodeScanner.new('test string')
  #   s.scan(/\w+/)        # => "test"
  #   s.unscan
  #   s.scan(/../)         # => "te"
  #   s.scan(/\d/)         # => nil
  #   s.unscan             # ScanError: unscan failed: previous match record not exist

  def unscan
    raise ScanError, "unscan failed: previous match record not exist" unless @matched

    @current = @previous
    @matched = false
    self
  end

  private

  def do_scan(regex, advance_pointer, return_string, head_only)
    raise ArgumentError unless regex.kind_of?(Regexp)

    @matched = false
    return nil if eos?

    @matches = regex.match(@string[@current, @string.length])
    return nil unless @matches

    if head_only && @matches.begin(0).positive?
      @matches = nil
      return nil
    end

    @matched = true

    @previous = @current
    @current += @matches.end(0) if advance_pointer
    if return_string
      return @string[@previous, @matches.end(0)]
    else
      return @matches.end(0)
    end
  end

  def inspect_before
    return '' if @current.zero?

    str = String.new
    len = 0

    if @current > INSPECT_LENGTH
      str << '...'
      len = INSPECT_LENGTH
    else
      len = @current
    end

    str << @string[@current - len, len]
    return str
  end

  def inspect_after
    return '' if eos?

    str = String.new
    len = @string.length - @current
    if len > INSPECT_LENGTH
      len = INSPECT_LENGTH
      str << @string[@current, len]
      str << '...'
    else
      str << @string[@current, len]
    end

    return str
  end
end

class ScanError < StandardError; end
