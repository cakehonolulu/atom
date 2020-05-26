.code32
.extern _bootstrap	# This just acts kind of a wrapper between the boot1 second stage bootloader
call _bootstrap		# and just calls another assembly file where we can do a bunch more things.
cli
hlt
