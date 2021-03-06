# Defines basic Tcl procs that must exist for OpenOCD scripts to work.
#
# Embedded into OpenOCD executable
#

# All commands are registered with an 'ocd_' prefix, while the "real"
# command is a wrapper that calls this function.  Its primary purpose is
# to discard 'handler' command output.
# Due to the two nested proc calls, this wrapper has to explicitly run
# the wrapped command in the stack frame two levels above.
proc ocd_bouncer {name args} {
	set cmd [format "ocd_%s" $name]
	set type [eval ocd_command type $cmd $args]
	set errcode error
	set skiplevel [expr [eval info level] > 1 ? 2 : 1]
	if {$type == "native"} {
		return [uplevel $skiplevel $cmd $args]
	} else {if {$type == "simple"} {
		set errcode [catch {uplevel $skiplevel $cmd $args}]
		if {$errcode == 0} {
			return ""
		} else {
			# 'classic' commands output error message as part of progress output
			set errmsg ""
		}
	} else {if {$type == "group"} {
		catch {eval ocd_usage $name $args}
		set errmsg [format "%s: command requires more arguments" \
			[concat $name " " $args]]
	} else {
		set errmsg [format "invalid subcommand \"%s\"" $args]
	}}}
	return -code $errcode $errmsg
}

# Try flipping / and \ to find file if the filename does not
# match the precise spelling
proc find {filename} {
	if {[catch {ocd_find $filename} t]==0} {
		return $t
	}
	if {[catch {ocd_find [string map {\ /} $filename} t]==0} {
		return $t
	}
	if {[catch {ocd_find [string map {/ \\} $filename} t]==0} {
		return $t
	}
	# make sure error message matches original input string
	return -code error "Can't find $filename"
}
add_usage_text find "<file>"
add_help_text find "print full path to file according to OpenOCD search rules"

# Find and run a script
proc script {filename} {
	uplevel #0 [list source [find $filename]]
}
add_help_text script "filename of OpenOCD script (tcl) to run"
add_usage_text script "<file>"

#########

