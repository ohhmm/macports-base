# et:ts=4
# portdestroot.tcl
#
# Copyright (c) 2002 - 2003 Apple Computer, Inc.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
# 3. Neither the name of Apple Computer, Inc. nor the names of its contributors
#    may be used to endorse or promote products derived from this software
#    without specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#

package provide portdestroot 1.0
package require portutil 1.0

set com.apple.destroot [target_new com.apple.destroot destroot_main]
target_provides ${com.apple.destroot} destroot
target_requires ${com.apple.destroot} main fetch extract checksum patch configure build
target_prerun ${com.apple.destroot} destroot_start
target_postrun ${com.apple.destroot} destroot_finish

# define options
options destroot.target destroot.destdir destroot.clean
commands destroot

# Set defaults
default destroot.dir {${build.dir}}
default destroot.cmd {${build.cmd}}
default destroot.pre_args {${destroot.target}}
default destroot.target install
default destroot.post_args {${destroot.destdir}}
default destroot.destdir {DESTDIR=${destroot}}
default destroot.clean no

set_ui_prefix

proc destroot_start {args} {
    global UI_PREFIX prefix portname destroot portresourcepath os.platform destroot.clean
    
    ui_msg "$UI_PREFIX [format [msgcat::mc "Staging %s into destroot"] ${portname}]"
    
    if { ${destroot.clean} == "yes" } {
	system "rm -Rf \"${destroot}\""
    }
    
    file mkdir "${destroot}"
    if { ${os.platform} == "darwin" } {
	system "cd \"${destroot}\" && mtree -e -U -f ${portresourcepath}/install/macosx.mtree"
    }
    file mkdir "${destroot}/${prefix}"
    system "cd \"${destroot}/${prefix}\" && mtree -e -U -f ${portresourcepath}/install/prefix.mtree"
}

proc destroot_main {args} {
    system "[command destroot]"
    return 0
}

proc destroot_finish {args} {
    global UI_PREFIX destroot prefix portname

    # Prune empty directories in ${destroot}
    catch {system "find \"${destroot}\" -depth -type d -exec rmdir -- \{\} \\; 2>/dev/null"}

	# Compress all manpages with gzip (instead)
	set manpath "${destroot}${prefix}/share/man"
	if {[file isdirectory ${manpath}]} {
		ui_info "$UI_PREFIX [format [msgcat::mc "Compressing man pages for %s"] ${portname}]"
		set found 0
		foreach mandir [readdir "${manpath}"] {
			if {![regexp {^man(.)$} ${mandir} match manindex]} { continue }
			ui_debug "Scanning ${mandir}"
			foreach manfile [readdir "${manpath}/${mandir}"] {
				if {[regexp "^(.*\[.\]${manindex}\[a-z\]*)\[.\]gz\$" ${manfile} gzfile manfile]} {
					set found 1
					system "cd ${manpath} && gunzip ${mandir}/${gzfile} && gzip -9v ${mandir}/${manfile}"
				} elseif {[regexp "^(.*\[.\]${manindex}\[a-z\]*)\[.\]bz2\$" ${manfile} bz2file manfile]} {
					set found 1
					system "cd ${manpath} && bunzip2 ${mandir}/${bz2file} && gzip -9v ${mandir}/${manfile}"
				} elseif {[regexp "\[.\]${manindex}\[a-z\]*\$" ${manfile}]} {
					set found 1
					system "cd ${manpath} && gzip -9v ${mandir}/${manfile}"
				}
			}
		}
		if {$found == 0} { ui_debug "No man pages found to compress." }
	}

    file delete "${destroot}/${prefix}/share/info/dir"
    return 0
}
