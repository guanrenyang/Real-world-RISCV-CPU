gen-expr: gen-expr.c
	gcc -g -O0 gen-expr.c -o gen-expr
test_catch_throw: test_catch_throw.c
	gcc -Wno-div-by-zero -o $@ $^

clean: 
	@rm gen-expr test_catch_throw
