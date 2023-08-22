#include <regex.h>
#include <stdio.h>

int main() {
    regex_t regex;
    int reti;
    char msgbuf[100];

    /* 编译正则表达式 */
    reti = regcomp(&regex, "^[1-9][0-9]*[^[:digit:]]", 0);
    if (reti) {
        fprintf(stderr, "Could not compile regex\n");
        return 1;
    }

    /* 匹配字符串 */
    regmatch_t pmatch;
    reti = regexec(&regex, "43-18", 1 , &pmatch, 0);
    if (!reti) {
        printf("%d, %d\n", pmatch.rm_so, pmatch.rm_eo);
    } else if (reti == REG_NOMATCH) {
        puts("No match");
    } else {
        regerror(reti, &regex, msgbuf, sizeof(msgbuf));
        fprintf(stderr, "Regex match failed: %s\n", msgbuf);
        return 1;
    }

    /* 释放编译的正则表达式 */
    regfree(&regex);

    return -1;
}
