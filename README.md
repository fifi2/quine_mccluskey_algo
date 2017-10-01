# Quine McCluskey algorithm

## What is that?

The [Quine McCluskey algorithm][1] is a method to minimize a boolean function
into a canonical POS (product of sums) or SOP (sum of products) function.

I had a try with this algorithm for a specific need in a Vim plugin but it is
too slow when there are too many different terms in the function.

[1]: https://en.wikipedia.org/wiki/Quine–McCluskey_algorithm

## Demo

	$ vim qmc.vim
	$ source %

	INPUT -a b -c -d + a -b -c -d + a -b -c d + a -b c -d + a -b c d + a b -c -d + a b c -d + a b c d
	TERMS ['a', 'b', 'c', 'd']
	TRUTH TABLE
	{'result': 0, 'mterm': ['0', '0', '0', '0']}
	{'result': 0, 'mterm': ['0', '0', '0', '1']}
	{'result': 0, 'mterm': ['0', '0', '1', '0']}
	{'result': 0, 'mterm': ['0', '0', '1', '1']}
	{'result': 1, 'mterm': ['0', '1', '0', '0']}
	{'result': 0, 'mterm': ['0', '1', '0', '1']}
	{'result': 0, 'mterm': ['0', '1', '1', '0']}
	{'result': 0, 'mterm': ['0', '1', '1', '1']}
	{'result': 1, 'mterm': ['1', '0', '0', '0']}
	{'result': 1, 'mterm': ['1', '0', '0', '1']}
	{'result': 1, 'mterm': ['1', '0', '1', '0']}
	{'result': 1, 'mterm': ['1', '0', '1', '1']}
	{'result': 1, 'mterm': ['1', '1', '0', '0']}
	{'result': 0, 'mterm': ['1', '1', '0', '1']}
	{'result': 1, 'mterm': ['1', '1', '1', '0']}
	{'result': 1, 'mterm': ['1', '1', '1', '1']}
	IMPLICANTS CHARTS
	SIZE 1
	{'prime': 0, 'terms': ['0', '1', '0', '0'], 'mterms': [4]}
	{'prime': 0, 'terms': ['1', '0', '0', '0'], 'mterms': [8]}
	{'prime': 0, 'terms': ['1', '0', '0', '1'], 'mterms': [9]}
	{'prime': 0, 'terms': ['1', '0', '1', '0'], 'mterms': [10]}
	{'prime': 0, 'terms': ['1', '0', '1', '1'], 'mterms': [11]}
	{'prime': 0, 'terms': ['1', '1', '0', '0'], 'mterms': [12]}
	{'prime': 0, 'terms': ['1', '1', '1', '0'], 'mterms': [14]}
	{'prime': 0, 'terms': ['1', '1', '1', '1'], 'mterms': [15]}
	SIZE 2
	{'prime': 1, 'terms': ['-', '1', '0', '0'], 'mterms': [4, 12]}
	{'prime': 0, 'terms': ['1', '0', '0', '-'], 'mterms': [8, 9]}
	{'prime': 0, 'terms': ['1', '0', '-', '0'], 'mterms': [8, 10]}
	{'prime': 0, 'terms': ['1', '-', '0', '0'], 'mterms': [8, 12]}
	{'prime': 0, 'terms': ['1', '0', '-', '1'], 'mterms': [9, 11]}
	{'prime': 0, 'terms': ['1', '0', '1', '-'], 'mterms': [10, 11]}
	{'prime': 0, 'terms': ['1', '-', '1', '0'], 'mterms': [10, 14]}
	{'prime': 0, 'terms': ['1', '-', '1', '1'], 'mterms': [11, 15]}
	{'prime': 0, 'terms': ['1', '1', '-', '0'], 'mterms': [12, 14]}
	{'prime': 0, 'terms': ['1', '1', '1', '-'], 'mterms': [14, 15]}
	SIZE 4
	{'prime': 1, 'terms': ['1', '0', '-', '-'], 'mterms': [8, 9, 10, 11]}
	{'prime': 1, 'terms': ['1', '-', '-', '0'], 'mterms': [8, 10, 12, 14]}
	{'prime': 1, 'terms': ['1', '-', '1', '-'], 'mterms': [10, 11, 14, 15]}
	PRIME IMPLICANTS CHART
	{'essential': 1, 'terms': ['-', '1', '0', '0'], 'mterms': [4, 12]}
	{'essential': 1, 'terms': ['1', '0', '-', '-'], 'mterms': [8, 9, 10, 11]}
	{'essential': 0, 'terms': ['1', '-', '-', '0'], 'mterms': [8, 10, 12, 14]}
	{'essential': 1, 'terms': ['1', '-', '1', '-'], 'mterms': [10, 11, 14, 15]}
	SOLUTION b -c -d + a -b + a c

