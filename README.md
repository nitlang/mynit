Nit is a statically typed object-oriented programming language.
The goal of Nit is to propose a statically typed programming language where structure is not a pain.

Nit has a simple straightforward style and can usually be picked up quickly, particularly by anyone who has programmed before.
While object-oriented, it allows procedural styles.

The Nit Compiler (nitc) produces efficient machine language binaries.

Some Nit features:

 * Pure Object-Oriented.
 * Multiple Inheritance.
 * Realist typing policy.
 * Light and clear syntax.


Requirement:

	* gcc		http://gcc.gnu.org/
	* pkg-config	http://www.freedesktop.org/wiki/Software/pkg-config/
	* ccache	http://ccache.samba.org/	to improve recompilation
	* libgc-dev	http://www.hpl.hp.com/personal/Hans_Boehm/gc/
	* graphviz	http://www.graphviz.org/	to enable graphes with the nitdoc tool
	* libunwind	http://nongnu.org/libunwind

Those are available in most Linux distributions

    # sudo apt-get install build-essential ccache libgc-dev graphviz libunwind pkg-config
    or
    # make prepare (This command is available for Debian and Ubuntu for the moment)

Important files and directory:

	benchmarks/	Script to bench the compilers
	bin/		The Nit tools
	bin/nitc	The Nit compiler
	bin/nit		The Nit interpreter
	bin/nitdoc	The Nit autodoc
	c_src/		C code of nitc (needed to bootstrap)
	clib/		C code needed by nitc to compile programs
	Changelog	List of change between versions
	contrib/	Various Nit programs (may or may not be useful)
	doc/		Documentation
	examples/	Program examples written in Nit
	LICENCE		License of the software
	misc/		Some additional file for commons text editors and tools
	tests/		Non-regression test-suite
	lib/		Nit standard library
	Makefile	Bootstrap the Nit tools
	NOTICE		List of the authors
	README		This file
	src/		The Nit tool sources (written in Nit)


How to start:

    $ make
    $ bin/nitc examples/hello_world.nit
    $ ./hello_world

You can put the `bin/` directory in your PATH

Using bash completion with Nit tools:

    $ echo source /absolute/path/to/misc/bash_completion/nit >> ~/.bash_completion
    $ source ~/.bash_completion

More information:

	http://www.nitlanguage.org
