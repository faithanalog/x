#!/bin/bash

# This script modifies /etc/apt/apt.conf.d/50unattended-upgrades in-place to enable Unattended-Upgrade::Remove-Unused-Kernel-Packages.
# Specifically, it will:
# - uncomment `Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";` in-place if it exists as a commented line in the file
# - append `Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";` to end of file if it was not found as an existing commented line
# - ensure that `Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";` does not appear more than once in the file
#   - this guarantees the script will produce the desired results even if the setting has already been enabled, regardless of how it was enabled.
#
# The motive for enabling Unattended-Upgrade::Remove-Unused-Kernel-Packages is to prevent unattended-upgrades from filling
# a small disk with kernel images, which can break the dpkg database and make maintenance frustrating.

sed -i '
    # replace existing commented config line if it exists.
    s/^.*Unattended-Upgrade::Remove-Unused-Kernel-Packages.*$/Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";/

    t if-changed-line
    b endif-changed-line
    : if-changed-line
        # first, check if we already matched a line. set this line to empty if so to dedup
        x
        s/^changed-line$/changed-line/

        t if-dedup
        b else-dedup
        : if-dedup
            # "changed-line" -> back to hold space, clear current line
            x
            s/^.*//
            b endif-dedup
    
        : else-dedup
            # "changed-line" -> hold space
            s/^.*$/changed-line/
            x

        : endif-dedup

    : endif-changed-line

    # end of file 
    $ {
        # if "changed-line" is not in hold space then append the config
        x
        s/changed-line//

        t endif-changed-line-is-unset
        : if-changed-line-is-unset
            s/^.*$/Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";/
            H

        : endif-changed-line-is-unset

        x
    }
' /etc/apt/apt.conf.d/50unattended-upgrades
