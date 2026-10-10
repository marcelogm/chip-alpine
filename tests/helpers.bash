assert_fragment_applied() {
	local fragment=$1 config=$2 missing=""
	while IFS= read -r line; do
		[ -z "$line" ] && continue
		grep -qxF -- "$line" "$config" || missing="$missing
$line"
	done < "$fragment"
	if [ -n "$missing" ]; then
		echo "missing from $config:$missing"
		return 1
	fi
}
