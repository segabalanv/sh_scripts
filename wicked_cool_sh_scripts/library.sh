#!/bin/bash

# inpath--Verifies that a specified program is either valid as is
#    or can be found in the PATH directory list

in_path() {
  # Given a command and the PATH, tries to find the command. Returns 0 if
  # found and executable, 1 if not. Note that this temporarily modifies
  # the IFS (internal field separator) but restores it upen completion.

  cmd=$1    ourpath=$2    result=1
  oldIFS=$IFS IFS=":"
  
  for directory in $ourpath
  do
    if [ -x "$directory/$cmd" ] ; then
      result=0    # If we're here, we found the command.
    fi
  done
  
  IFS=$oldIFS
  return $result
}

checkForCmdInPath() {
  var=$1
  if [ "$var" != "" ]; then
    if [ "${var%${var#?}}" = "/" ] ; then
      if [ ! -x "$var" ] ; then
        return 1
      fi
    elif ! in_path "$var" "$PATH" ; then
      return 2
    fi
  fi
}

# validAlphaNum--Ensures that input consists only of alphabetical
#   and numeric characters
validAlphaNum() {
  # Validate arg: returns 0 if all upper+lower+digits; 1 otherwise

  # remove all unacceptable characters
  validchars="$(echo "$1" | sed -e 's/[^[:alnum:]]//g')"

  if [ "$validchars" = "$1" ] ; then
    return 0
  else
    return 1
  fi
}


# nicenumber--Given a number, shows it in comma-separated form. Expects DD
#   (decimal point delimiter) and TD (thousands delimiter) to be instantiated.
#   Instantiates nicenum or, if a second args is specified, the output is
#   echoed to stdout.

nicenumber() {
  # Note that we assume that '.' is the decimal separator in the INPUT value
  #   to this script. The decimal separator in the output value is '.' unless
  #   specified by the user with the -d flag.
  
  integer=$(echo "$1" | cut -d. -f1)   # Left of the decimal
  decimal=$(echo "$1" | cut -d. -f2)   # Right of the decimal
  # Check if the number has more than the integer part.
  if [ "$decimal" != "$1" ]; then
    # There's a fractional part, so let's include it.
    result="${DD:= '.'}$decimal"
  fi
  
  thousands=$integer
  
  while [ "$thousands" -gt 999 ]; do
    remainder=$((thousands % 1000))   # Three least significant digits
    # We need 'remainder' to be three digits. Do we need to add zeros?
    while [ ${#remainder} -lt 3 ]; do  # Force leading zeros
      remainder="0$remainder"
    done
    
    result="${TD:=","}${remainder}${result}"   # Builds right to left
    thousands=$((thousands / 1000))   # To left of remainder, if any
  done
  
  nicenum="${thousands}${result}"
  if [ ! -z "$2" ]; then
    echo "$nicenum"
  fi
}

DD="."   # Decimal point delimiter, to separate whole and fractional values
TD=","   # Thousands delimiter, to separate every three digits


# normdate--Normalizes month field in date specification to three letters,
#   first letter capitalized. A helper function for Script #7, valid-date.
# Exits with 0 if no error.

monthNumToName() {
  # Sets the 'month' variable to the appropiate value
  case $1 in
    1 ) month="Jan"  ;;  2 ) month="Feb"  ;;
    3 ) month="Mar"  ;;  4 ) month="Apr"  ;;
    5 ) month="May"  ;;  6 ) month="Jun"  ;;
    7 ) month="Jul"  ;;  8 ) month="Aug"  ;;
    9 ) month="Sep"  ;;  10) month="Oct"  ;;
    11) month="Nov"  ;;  12) month="Dec"  ;;
    * ) echo "$0: Unknown month value $1" >&2
        exit 1
  esac
  return 0
}

# validint--Validates integer input, allowing negative integers too

validint() {
  # Validate first field and test that value against min value $2 and/or
  #    max value $3 if they are supplied. If the value isn't within range
  #    or it's not composed of just digits, fail.
  number="$1";    min="$2";    max="$3"

  if [ -z "$number" ] ; then
    echo "You didn't enter anything. Please enter a number." >&2
    return 1
  fi

  # If the first character a '-' sign?
  if [ "${number%${number#?}}" = "-" ] ; then
    testvalue="${number#?}"    # Grab all but the first character
  else
    testvalue="${number}"
  fi

  # Create a version of the number that has no digits for testing.
  nodigits="$(echo "$testvalue" | sed 's/[[:digit:]]//g')"
  # Check for nondigits characters.
  if [ ! -z "$nodigits" ] ; then
    echo "Invalid number format! Only digits, no commas, spaces, etc." >&2
    return 1
  fi

  if [ ! -z "$min" ] ; then
    if [ "$number" -lt "$min" ] ; then
      echo "Your value is too small: smallest acceptable value is $min." >&2
      return 1
    fi
  fi
  if [ ! -z "$max" ] ; then
    # Is the input greater that the maximum value?
    if [ "$number" -gt "$max" ] ; then
      echo "Your value is too big: largest acceptable value is $max." >&2
      return 1
    fi
  fi
  return 0
}

# validfloat--Tests whether a number is a valid floating-point value.
#   Note that this script cannot accept scientific (1.304e5) notation.

# To test whether an entered value is a valid floating-point number,
#   we need to split the valu into two parts: the integer portion
#   and the fractional portion. We test the first part to see whether
#   it's a valid integer, and then we test whether the second part is a
#   valid >=0 integer. So -30.5 evaluates as valid, but -30.-8 doesn't.
# To include another shell script as part of this one, use the "." source
#   notation. Easy enough.

validfloat() {
  fvalue="$1"
  # Check whether the input number has a decimal point.
  if [ ! -z "$(echo "$fvalue" | sed 's/[^.]//g')" ] ; then
    # Extract the part before the decimal point.
    decimalPart="$(echo "$fvalue" | cut -d. -f1)"
    # Extract the digits after the decimal point.
    fractionalPart="${fvalue#*\.}"
    # Start by testing the decimal part, which is everything
    # to the left of the decimal point.
    if [ ! -z "$decimalPart" ] ; then
      # "!" reverses test logic, so the following is
      # "if NOT a valid integer"
      if ! validint "$decimalPart" "" "" ; then
        return 1
      fi
    fi
    # Now let's test the fractional value.
    # To start, you can't have a negative sign after the decimal point
    #   like 33.-11, so let's test for the '-' sign in the decimal.
    if [ "${fractionalPart%${fractionalPart#?}}" = "-" ] ; then
      echo "Invalid floating-point number: '-' not allowed \
after decimal point." >&2
      return 1
    fi
    if [ "$fractionalPart" != "" ] ; then
      # If the fractional part is NOT a valid integer...
      if ! validint "$fractionalPart" "0" ""; then
        return 1
      fi
    fi
  else
    # If the entire value is just "-", that's not good either.
    if [ "$fvalue" = "-" ] ; then
      echo "Invalid floating-point format." >&2
      return 1
    fi
    # Finally, check that the remaining digits are actually
    # valid as integers.
    if ! validint "$fvalue" "" "" ; then
      return 1
    fi
  fi
  
  return 0
}

# valid-date--Validates a date, taking into account leap year rules
normdate="normdate.sh"

exceedsDaysInMonth() {
  # Given a month name and day number in that month, this function will
  #   return 0 if the specified day value is less than or equal to the
  #   max days of in the month; 1 otherwise.

  case $(echo $1|tr '[:upper:]' '[:lower:]') in
    jan* ) days=31  ;;  feb* ) days=28 ;;
    mar* ) days=31  ;;  apr* ) days=30 ;;
    may* ) days=31  ;;  jun* ) days=30 ;;
    jul* ) days=31  ;;  aug* ) days=31 ;;
    sep* ) days=30  ;;  oct* ) days=31 ;;
    nov* ) days=30  ;;  dec* ) days=31 ;;
       * ) echo "$0: Unknown month name $1" >&2
           exit 1
  esac
  if [ $2 -lt 1 -o $2 -gt $days ] ; then
    return 1
  else
    return 0   # The day number is valid.
  fi
}

isLeapYear() {
  # This function returns 0 if the specified year is a leap year;
  #   1 otherwise
  # The formula for checking whether a leap year is a leap year is
  #   1. Years not divisible by 4 are not leap years.
  #   2. Years divisible by 4 and 400 are leap years.
  #   3. Years divisible by 4, not divisible by 400, but divisible
  #      by 100 are not leap years.
  #   4. All other years divisible by 4 are leap years.

  year=$1
  if [ "$((year % 4))" -ne 0 ] ; then
    return 1   # Nope, not a leap year
  elif [ "$((year % 400))" -eq 0 ] ; then
    return 0   # Yes, it's a leap year
  elif [ "$((year % 100))" -eq 0 ] ; then
    return 1
  else
    return 0
  fi
}

validdate() {
  # expects three values, month, day and year. Returns 0 if success
  newdate="$($normdate "$@")"

  if [ $? -eq 1 ] ; then
    exit 1   # Error condition already reported by normdate
  fi

  # Split the normalized date format, where
  #   first word = month, second word = day, third word = year
  month="$(echo $newdate | cut -d\  -f1)"
  day="$(echo $newdate | cut -d\  -f2)"
  year="$(echo $newdate | cut -d\  -f3)"

  # Now that we have a normalized date, let's check whether the
  #   day value is legal and valid (e.g., not Jan 36)
  if ! exceedsDaysInMonth $month "$2" ; then
    if [ $month = "Feb" -a "$2" -eq "29" ] ; then
      if ! isLeapYear $3 ; then
        echo "$0: $3 is not a leap year, so Feb doesn't have 29 days." >&2
        exit 1
      fi
    else
      echo "$0: bad day value: $month doesn't have $2 days." >&2
      exit 1
    fi
  fi
  return 0
}

echon() {
  echo "$*" | awk '{ printf "%s", $0 }'
}

# ANSI color--Use these varibles to make output in different colors
#   and formats. Color names that end with 'f' are foreground colors,
#   and those ending with 'b' are background colors.

initializeANSI() {
  esc=""   # If this doesn't work, enter an ESC directly.

  # Foreground colors
  blackf="${esc}[30m";  redf="${esc}[31m";  greenf="${esc}[32m"
  yellowf="${esc}[33m"; bluef="${esc}[34m"; purplef="${esc}[35m"
  cyanf="${esc}[36m";   whitef="${esc}[37m"
  
  # Background colors
  blackb="${esc}[40m"  redb="${esc}[41m";   greenb="${esc}[42m"
  yellowb="${esc}[43m" blueb="${esc}[44m";  purpleb="${esc}[45m"
  cyanb="${esc}[46m";  whiteb="${esc}[47m"

  # Bold, italic, underline, and inverse style toggles
  boldon="${esc}[1m";      boldoff="${esc}[22m"
  italicson="${esc}[3m";   italicsoff="${esc}[23m"
  ulon="${esc}[4m";        uloff="${esc}[24m"
  invon="${esc}[7m";       invoff="${esc}[27m"

  reset="${esc}[0m"
}
