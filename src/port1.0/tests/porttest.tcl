package require tcltest 2
namespace import tcltest::*

set pwd [file normalize $argv0]
set pwd [eval file join {*}[lrange [file split $pwd] 0 end-1]]

#source ../../macports1.0/macports_fastload.tcl
set portdbpath /opt/local/var/macports

package require macports 1.0

array set ui_options {}
#set ui_options(ports_debug)   yes
#set ui_options(ports_verbose) yes
mportinit ui_options

source ./library.tcl
macports_worker_init

package require port 1.0
package require registry 1.0


# test test_start

test test_main {
    Test main unit test.
} -constraints {
    root
} -setup {
    set destpath $pwd/work/destroot
    set portbuildpath $pwd
    set portdbpath $pwd/dbpath
    set portpath $pwd

    set mport [mportopen file://.]

    # set $version var
    set workername [ditem_key $mport workername]

    # portinstall setup
    interp alias {} _cd {} cd

    # hide all output. Deactivate this for debugging!
    set oldchannels [array get macports::channels]
    set macports::channels(msg)    {}
    set macports::channels(notice) {}

    if {[$workername eval eval_targets install] != 0} {
	return "FAIL: port install failed"
    }

} -body {
    if {[$workername eval eval_targets test] != 0} {
	return "FAIL: test target failed"
    }

    return "Test main successful."

} -cleanup {
    if {[$workername eval eval_targets uninstall] != 0} {
    	return "FAIL: uninstall failed"
    }
    if {[$workername eval eval_targets clean] != 0} {
    	return "FAIL: clean failed"
    }
    file delete -force $pwd/work

} -result "Test main successful."


cleanupTests
