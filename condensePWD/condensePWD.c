#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#define MAXLEN 255
// one byte reserved for null
char outbuf[MAXLEN + 1];

#define PWD_BUF_LEN 2048
char pwd_buf[PWD_BUF_LEN];

int main(int argc, char **argv) {
    char* pwd = pwd_buf;
    int outbuf_idx = 0;

    if (getcwd(pwd, PWD_BUF_LEN) == NULL) {
        return 1;
    }

    // Replace home prefix with tilde in outbuf
    char* home = getenv("HOME");
    if (home != NULL) {
        char* orig_pwd = pwd;
        for (;;) {
            char c_home = *home;
            char c_pwd = *pwd;
            // If we reached the end of home, home is a prefix. insert tilde as first char of outbuf
            if (c_home == '\0') {
                outbuf[outbuf_idx++] = '~';
                break;
            }

            // If we reached the end of pwd before home, home is not a prefix. restore pwd
            if (c_pwd == '\0') {
                pwd = orig_pwd;
                break;
            }

            // If the current characters differ, home is not a prefix. restore pwd
            if (c_pwd != c_home) {
                pwd = orig_pwd;
                break;
            }

            home++;
            pwd++;
        }
    }

    char* dir_start;

    // If the pwd starts with /, put a leading / into outbuf and set
    // dir_start & pwd to the first directory name after it.  If it doesn't
    // start with /, well that's kinda weird but we'll just print a relative
    // directory we guess
    if (*pwd == '/') {
        outbuf[outbuf_idx++] = '/';
        dir_start = pwd = pwd + 1;
    } else {
        dir_start = pwd;
    }

    for (;;) {
        char c = *pwd;

        // End of PWD
        if (c == '\0') {
            // Copy trailing path into outbuf, without the null byte
            while (dir_start < pwd && outbuf_idx < MAXLEN) {
                outbuf[outbuf_idx++] = *(dir_start++);
            }
            break;
        }

        
        // End of current directory
        if (c == '/') {
            // outbuf is full, break
            if (outbuf_idx + 3 > MAXLEN) {
                break;
            }

            // Insert the first char of current directory and then a slash
            outbuf[outbuf_idx++] = *dir_start;
            // If the first char is a `.` and the second char is not a
            // slash, insert the second character as well.
            if (*dir_start == '.' && *(dir_start + 1) != '/') {
                outbuf[outbuf_idx++] = *(dir_start + 1);
            }
            outbuf[outbuf_idx++] = '/';

            // New dir_start after the slash
            dir_start = pwd + 1;
        }

        pwd++;
    }

    // Insert trailing null-byte
    outbuf[outbuf_idx] = '\0';

    // Print it out!
    puts(outbuf);
    
    return 0;
}


