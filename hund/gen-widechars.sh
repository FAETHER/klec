#!/usr/bin/sh

# This stript downloads and parses these files:
# http://www.unicode.org/Public/UCD/latest/ucd/EastAsianWidth.txt
# http://www.unicode.org/Public/UCD/latest/ucd/UnicodeData.txt
# in order to generate tables of zero-width, and double-width characters.

# Files listed above belong to Unicode. You can find the license here:
# http://www.unicode.org/copyright.html
# or here:
# http://www.unicode.org/terms_of_use.html

# To generate new 'widechars.h':
# $ ./gen-widechars.sh > widechars.h

echo "/*"
echo " * This file was generated by a script using these files:"
echo " * http://www.unicode.org/Public/UCD/latest/ucd/EastAsianWidth.txt"
echo " * http://www.unicode.org/Public/UCD/latest/ucd/UnicodeData.txt"
echo " * These files belong to Unicode. You can find the license here:"
echo " * http://www.unicode.org/copyright.html"
echo " * or here:"
echo " * http://www.unicode.org/terms_of_use.html"
echo " */"
echo
echo "#ifndef WIDECHARS_H"
echo "#define WIDECHARS_H"
echo
echo "// A sorted list of ranges of Unicode codepoints of double-width characters"
echo "static const unsigned int double_width[][2] = {"
IFS=$'\n'
for line in $(curl -s http://www.unicode.org/Public/UCD/latest/ucd/EastAsianWidth.txt)
do
	if [ "${line:0:1}" == "#" ]; then
		continue
	fi
	range=$(echo $line | cut -d ';' -f 1)
	a=$(echo $range | cut -d '.' -f 1)
	b=$(echo $range | cut -d '.' -f 3)
	category=$(echo $line | cut -d ';' -f 2 | cut -d ' ' -f 1)
	if [ "$category" == "F" ] || [ "$category" == "W" ]; then
		echo -e "\t{0x$a, 0x$b},"
	fi
done
echo "};"
echo "static const size_t double_width_len = sizeof(double_width)/sizeof(double_width[0]);"
echo
echo "// A sorted list of ranges of Unicode codepoints of zero-width characters"
echo "static const unsigned int zero_width[][2] = {"
ra=0
rb=0
IFS=$'\n'
for line in $(curl -s http://www.unicode.org/Public/UCD/latest/ucd/UnicodeData.txt)
do
	cp=$(printf '%d' "0x$(echo $line | cut -d ';' -f 1)")
	name=$(echo $line | cut -d ';' -f 2)
	category=$(echo $line | cut -d ';' -f 3)
	if [ "$category" == "Cf" ] \
	|| [ "$category" == "Mn" ] \
	|| [ "$category" == "Me" ] \
	|| [ "${name:0:16}" == "HANGUL JUNGSEONG" ] \
	|| [ "${name:0:16}" == "HANGUL JONGSEONG" ]; then
		if (( cp == rb+1 )); then
			rb=$cp
			continue
		else
			printf "\t{0x%X, 0x%X},\n" $ra $rb
			ra=$cp
			rb=$cp
		fi
	fi
done
echo "};"
echo "static const size_t zero_width_len = sizeof(zero_width)/sizeof(zero_width[0]);"
echo
echo "#endif"
