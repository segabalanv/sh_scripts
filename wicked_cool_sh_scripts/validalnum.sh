#!/bin/bash
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

# BEGIN MAIN SCRIPT--DELETE OR COMMENT OUT EVERYTHING BELOW THIS LINE IF
#   YOU WANT TO INCLUDE THIS IN OTHER SCRIPTS.
# =================
/bin/echo -n "Enter input: "
read -r input

#Input validation
if ! validAlphaNum "$input" ; then
  echo "Please enter only letters and numbers you fucking moron." >&2
  exit 1
else
  echo "Input is valid."
fi

exit 0
