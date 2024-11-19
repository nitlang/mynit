[0;33mtest_keep_going.nit:15,11--14[0m: Error: class `Fail` not found in module `test_keep_going`.
	fun plop: [1;31mFail[0m
	          ^
[0;33mtest_keep_going.nit:26,2--5[0m: Error: method or variable `fail` unknown in `Sys`.
		[1;31mfail[0m
		^
[0;33mtest_keep_going.nit:30,14--17[0m: Error: class `Fail` not found in module `test_keep_going`.
		var x = new [1;31mFail[0m
		            ^
[0;33mtest_keep_going.nit:35,5[0m: Type Error: expected `Bool`, got `Int`.
		if [1;31m1[0m then abort
		   ^
[0;33mtest_keep_going.nit:40,2--11[0m: Warning: unreachable statement. (unreachable)
		[1;31m999.output[0m
		^
[0;33mtest_keep_going.nit:44,18--21[0m: Error: method `fail` does not exists in `Sys`.
		var a = new Sys.[1;31mfail[0m
		                ^
Errors: 5. Warnings: 1.
1
2
3
4
5
6
7
