#!/usr/bin/env bash

version="1.0.0"

set -eu

base_dir="$(dirname $(realpath $0))"

echo2() {
echo "$*" 1>&2
}

usage() {
echo2 "Usage: $(basename $0) <input_ttf_file> <output_ttf_file_prefix> <type> <weight>"
exit 1
}

type fontforge > /dev/null 2>&1 || (echo2 "fontforge does not exists in the PATH." && exit 1)
[ $# -ne 4 ] && usage

input_ttf_file="$1"
output_ttf_file_prefix="$2"
type="$3"
weight="$4"

family="JPDocFont ${type}"
name="${family} ${weight}"
psname="JPDocFont-${type}-${weight}"

[ ! -f "$input_ttf_file" ] && usage

# convert to sfd
unset tmp_pe_file tmp_sfd_file
cleanup() {
rm "$tmp_pe_file" "$tmp_sfd_file"
}
trap cleanup EXIT

tmp_pe_file=$(mktemp)
tmp_sfd_file=$(mktemp)

# create a script that output intermediate file.
cat > "$tmp_pe_file" <<EOF
#!/usr/bin/env fontforge
Open("$input_ttf_file");
Save("$tmp_sfd_file");
Close();
Quit(0);
EOF

# execute the script.
chmod +x "$tmp_pe_file"
"$tmp_pe_file"

# correct the intermediate file.
gsed -i \
    -e 's/sfntRevision: .*$/sfntRevision: 0x00000000/' \
    -e 's/Copyright: \(.*\)$/Copyright: \1\\n\\n[JPDocFont]\\nCopyright(c) 2019 Develhack.com/' \
    "$tmp_sfd_file"

# create a script that output ttf file.
cat > "$tmp_pe_file" <<EOF
#!/usr/bin/env fontforge
Open("$tmp_sfd_file");

SetFontNames( \
    "${psname}", \
    "${family}", \
    "${name}", \
    "${weight}");

# English(US)
SetTTFName(0x409, 0, "Copyright(c) 2019 Develhack.com"); # Copyright
SetTTFName(0x409, 1, "${family}"); # Family
SetTTFName(0x409, 2, "${weight}"); # Styles (SubFamily)
SetTTFName(0x409, 3, "${psname};${version}"); # UniqueID
SetTTFName(0x409, 4, "${name}"); # Fullname
SetTTFName(0x409, 5, "${version}"); # Version
SetTTFName(0x409, 6, ""); # PSName
SetTTFName(0x409, 7, ""); # Trademark
SetTTFName(0x409, 8, ""); # Manufacturer
SetTTFName(0x409, 9, ""); # Designer
SetTTFName(0x409, 10, ""); # Description
SetTTFName(0x409, 11, ""); # Vendor URL
SetTTFName(0x409, 12, ""); # Designer URL
# SetTTFName(0x409, 13, ""); # License
# SetTTFName(0x409, 14, ""); # License URL
# SetTTFName(0x409, 15, ""); # Reserved
SetTTFName(0x409, 16, "${family}"); # Preferred Family
SetTTFName(0x409, 17, "${weight}"); # Preferred Styles
SetTTFName(0x409, 18, ""); # Compatible Full 
SetTTFName(0x409, 19, ""); # Sample text
SetTTFName(0x409, 20, ""); # PostScript CID findfont name
SetTTFName(0x409, 21, ""); # WWS Family Name
SetTTFName(0x409, 22, ""); # WWS Subfamily Name
# Japanease
SetTTFName(0x411, 1, "${family}"); # Family
SetTTFName(0x411, 2, "${weight}"); # Styles (SubFamily)
SetTTFName(0x411, 4, "${name}"); # Fullname
SetTTFName(0x411, 16, "${family}"); # Preferred Family
SetTTFName(0x411, 17, "${weight}"); # Preferred Styles

Generate("${output_ttf_file_prefix}-${type}-${weight}.ttf");

SelectAll();
Skew(15);

SetFontNames( \
    "${psname}-Oblique", \
    "${family} Oblique", \
    "${name} Oblique");

SetTTFName(0x409, 1, "${family} Oblique"); # Family
SetTTFName(0x409, 3, "${psname}-Oblique;${version}"); # UniqueID
SetTTFName(0x409, 4, "${name} Oblique"); # Fullname
SetTTFName(0x409, 5, "${version}"); # Version
SetTTFName(0x411, 1, "${family} Oblique"); # Family
SetTTFName(0x411, 4, "${name} Oblique"); # Fullname

Generate("${output_ttf_file_prefix}-${type}-${weight}-Oblique.ttf");

Close();
Quit(0);
EOF

"$tmp_pe_file"
