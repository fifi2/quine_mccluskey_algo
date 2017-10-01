
" sop = Sum of products
" pos = Product of sums
let s:qmc_mode = 'sop'

function! s:QMCSimplify(formula)
	if type(a:formula) == v:t_string
		return a:formula
	endif

	let l:terms = s:QMCTerms(a:formula)
	echo "TERMS" l:terms
	let l:truth_table = s:QMCTruthTable(a:formula, l:terms)
	echo "TRUTH TABLE"
	for l:t in l:truth_table
		echo l:t
	endfor
	let l:implicants_charts = s:QMCImplicantsCharts(l:truth_table)
	echo "IMPLICANTS CHARTS"
	let l:size = 1
	for l:ic in l:implicants_charts
		echo "SIZE" l:size
		for l:i in l:ic
			echo l:i
		endfor
		let l:size = l:size*2
	endfor
	let l:pic = s:QMCPrimeImplicantsChart(l:implicants_charts)
	echo "PRIME IMPLICANTS CHART"
	for l:pi in l:pic
		echo l:pi
	endfor

	let l:solution = s:QMCSolution(l:pic)
	let l:build_prepare = s:QMCFormulaBuildPrepare(l:solution, l:terms)

	return s:QMCFormulaBuild(l:build_prepare)
endfunction

function! s:QMCFormulaOperatorPrecedenceHelper(formula)
	let l:formula = substitute(a:formula, '^\s*\(.\{-}\)\s*$', '\1', '')
	let l:formula = substitute(l:formula, '\([()]\)', '\1\1\1', 'g')
	let l:formula = substitute(l:formula, '\s*+\s*', '))+((', 'g')
	let l:formula = substitute(l:formula, '\s\+', ') (', 'g')
	return '(('.l:formula.'))'
endfunction

function! s:QMCParser(formula)
	return s:QMCFormulaParser(
		\ s:QMCFormulaListConvert(
			\ s:QMCFormulaOperatorPrecedenceHelper(a:formula)
			\ )
		\ )
endfunction

function! s:QMCFormulaParser(formula)

	let [ l:c_idx, l:br_match, l:brackets ] = [ 0, 0, 0 ]
	let l:formula_len = len(a:formula)
	while l:c_idx < l:formula_len
		if a:formula[l:c_idx] == '('
			let l:br_match += 1
		elseif a:formula[l:c_idx] == ')'
			let l:br_match -= 1
		endif

		if l:br_match == 0
			break
		else
			let l:brackets = 1
		endif

		let l:c_idx += 1
	endwhile

	if l:brackets == 1
		if l:c_idx == l:formula_len-1
			return s:QMCFormulaParser(
				\ a:formula[1:l:c_idx-1]
				\ )
		else
			let l:operator = get(a:formula, l:c_idx+1)
			if l:operator == '+' || l:operator == ' '
				return [
					\ l:operator,
					\ s:QMCFormulaParser(
						\ a:formula[0:l:c_idx]
						\ ),
					\ s:QMCFormulaParser(
						\ a:formula[l:c_idx+2:]
						\ )
					\ ]
			endif
		endif
	else
		return get(a:formula, 0)
	endif

endfunction

function! s:QMCFormulaToString(formula)
	if type(a:formula) == v:t_string
		return a:formula
	else
		if a:formula[0] == '+'
			return s:QMCFormulaToString(a:formula[1])
				\ .' + '
				\ .s:QMCFormulaToString(a:formula[2])
		elseif a:formula[0] == ' '
			let [ l:brackets_left, l:brackets_right ] = [ 0, 0 ]

			if type(a:formula[1]) != v:t_string && a:formula[1][0] == '+'
				let l:brackets_left = 1
			endif

			if type(a:formula[2]) != v:t_string && a:formula[2][0] == '+'
				let l:brackets_right = 1
			endif

			let l:left = s:QMCFormulaToString(a:formula[1])
			if l:brackets_left == 1
				let l:left = '('.l:left.')'
			endif

			let l:right = s:QMCFormulaToString(a:formula[2])
			if l:brackets_right == 1
				let l:right = '('.l:right.')'
			endif

			return l:left.' '.l:right
		endif
	endif
endfunction

function! s:QMCFormulaListConvert(formula)
	let l:formula = substitute(a:formula, '\s*+\s*', '+', 'g')
	let [ l:formula_list, l:c_idx, l:atom_pending ] = [ [], 0, '' ]

	while l:c_idx < strlen(l:formula)
		if index([ '(', ')', '+', ' ' ], l:formula[l:c_idx]) >= 0
			if !empty(l:atom_pending)
				let l:formula_list += [ l:atom_pending ]
				let l:atom_pending = ''
			endif
			let l:formula_list += [ l:formula[l:c_idx] ]
		else
			let l:atom_pending .= l:formula[l:c_idx]
		endif
		let l:c_idx += 1
	endwhile

	if !empty(l:atom_pending)
		let l:formula_list += [ l:atom_pending ]
	endif

	return l:formula_list
endfunction

function! s:QMCTerms(formula)
	if type(a:formula) == v:t_string
		return [ substitute(a:formula, '^-', '', '') ]
	else
		return uniq(
			\ sort(
				\ s:QMCTerms(a:formula[1])
					\ + s:QMCTerms(a:formula[2])
					\ )
			\ )
	endif
endfunction

function! s:QMCTruthTable(formula, terms)
	let l:terms_count = len(a:terms)
	let l:mterms_count = pow(2, l:terms_count)
	let l:truth_table = []
	let l:i = 0
	while l:i < l:mterms_count
		let l:mterm = split(printf('%0'.l:terms_count.'b', l:i), '\zs')
		let l:truth_table += [ {
			\ 'mterm': l:mterm,
			\ 'result': s:QMCTruthTableSet(a:formula, a:terms, l:mterm)
			\ } ]
		let l:i += 1
	endwhile
	return l:truth_table
endfunction

function! s:QMCTruthTableSet(formula, terms, mterm)
	if type(a:formula) == v:t_string
		let [ l:term, l:negation ] = [ a:formula, 0 ]
		if strpart(a:formula, 0, 1) == '-'
			let l:term = strpart(a:formula, 1)
			let l:negation = 1
		endif
		let l:val = a:mterm[index(a:terms, l:term)]
		return l:negation ? !l:val : l:val
	elseif type(a:formula) == v:t_list
		if a:formula[0] == ' '
			return s:QMCTruthTableSet(a:formula[1], a:terms, a:mterm)
				\ && s:QMCTruthTableSet(a:formula[2], a:terms, a:mterm)
		elseif a:formula[0] == '+'
			return s:QMCTruthTableSet(a:formula[1], a:terms, a:mterm)
				\ || s:QMCTruthTableSet(a:formula[2], a:terms, a:mterm)
		endif
	endif
endfunction

function! s:QMCImplicantsCharts(truth_table)
	let l:implicants_charts = []
	call add(
		\ l:implicants_charts,
		\ s:QMCImplicantsChartsCreate(a:truth_table)
		\ )
	while s:QMCImplicantsChartsContinue(l:implicants_charts[-1])
		let l:new_ic = s:QMCImplicantsChartsNext(l:implicants_charts[-1])
		if !empty(l:new_ic)
			call add(
				\ l:implicants_charts,
				\ l:new_ic
				\ )
		endif
	endwhile
	return l:implicants_charts
endfunction

function! s:QMCImplicantsChartsCreate(truth_table)
	let l:i = 0
	let l:implicants = []
	for l:truth in a:truth_table
		if s:qmc_mode == 'sop' && l:truth['result']
			\ || s:qmc_mode == 'pos' && !l:truth['result']
			let l:implicants += [ {
				\ 'mterms': [ l:i ],
				\ 'terms': l:truth['mterm'],
				\ 'prime': -1
				\ } ]
		endif
		let l:i += 1
	endfor
	return l:implicants
endfunction

function! s:QMCImplicantsChartsContinue(last_ic)
	for l:i in a:last_ic
		if get(l:i, 'prime') == -1
			return 1
		endif
	endfor
	return 0
endfunction

function! s:QMCImplicantsChartsNext(last_ic)
	let l:implicants_new = []
	let l:i = 0
	let l:implicants_count = len(a:last_ic)
	let l:combined = []
	while l:i < l:implicants_count
		let l:a = l:i + 1
		while l:a < l:implicants_count
			let l:comp = s:QMCImplicantsCompare(
				\ a:last_ic[l:i]['terms'],
				\ a:last_ic[l:a]['terms']
				\ )
			if !empty(l:comp)
				let l:combined += [ l:i, l:a ]
				let l:new = {
					\ 'mterms': uniq(
							\ sort(
								\ a:last_ic[l:i]['mterms']
									\ + a:last_ic[l:a]['mterms'],
								\ 'n'
							\ )
						\ ),
					\ 'terms': l:comp,
					\ 'prime': -1
					\ }
				if index(l:implicants_new, l:new) == -1
					let l:implicants_new += [ l:new ]
				endif
			endif
			let l:a += 1
		endwhile
		let l:i += 1
	endwhile

	let l:i = 0
	while l:i < l:implicants_count
		if index(l:combined, l:i) != -1
			let a:last_ic[l:i]['prime'] = 0
		else
			let a:last_ic[l:i]['prime'] = 1
		endif
		let l:i += 1
	endwhile

	return l:implicants_new
endfunction

function! s:QMCImplicantsCompare(a, b)
	let l:compare = []
	let l:diff = 0
	let l:ka = 0
	let l:length = len(a:a)
	while l:ka < len(a:a)
		if a:a[l:ka] != a:b[l:ka]
			let l:compare += [ '-' ]
			let l:diff += 1
		else
			let l:compare += [ a:a[l:ka] ]
		endif
		let l:ka += 1
	endwhile
	return l:diff <= 1 ? l:compare : []
endfunction

function! s:QMCPrimeImplicantsChart(implicants_charts)
	let l:prime_implicants = []
	for l:c in a:implicants_charts
		for l:i in l:c
			if l:i['prime'] == 1
				let l:prime_implicants += [ {
					\ 'mterms': l:i['mterms'],
					\ 'terms': l:i['terms']
					\ } ]
			endif
		endfor
	endfor
	return s:QMCPrimeImplicantsEssential(l:prime_implicants)
endfunction

function! s:QMCPrimeImplicantsEssential(prime_implicants)
	let [ l:prime_implicants, l:pk ] = [ [], 0 ]
	let l:prime_count = len(a:prime_implicants)
	while l:pk < l:prime_count
		let l:p = a:prime_implicants[l:pk]
		for l:m in l:p['mterms']
			let [ l:found, l:ak ] = [ 0, 0 ]
			while l:ak < l:prime_count && !l:found
				if l:ak == l:pk
					let l:ak += 1
					continue
				endif
				let l:found = index(
					\ a:prime_implicants[l:ak]['mterms'],
					\ l:m
					\ ) != -1
				let l:ak += 1
			endwhile
			let l:p['essential'] = !l:found
			if !l:found
				break
			endif
		endfor
		let l:prime_implicants += [ l:p ]
		let l:pk += 1
	endwhile
	return l:prime_implicants
endfunction

function! s:QMCSolution(prime_implicants)

	let l:solution = []
	let l:pic_clean = []
	let l:mterms_essential = []
	let l:mterms_remaining = []
	for l:pi in a:prime_implicants
		if l:pi['essential']
			let l:solution += [ l:pi['terms'] ]
			let l:mterms_essential += l:pi['mterms']
		endif
	endfor
	let l:mterms_essential = uniq(sort(l:mterms_essential))
	for l:pi in a:prime_implicants
		if !l:pi['essential']
			let l:mterms_clean = []
			for l:m in l:pi['mterms']
				if index(l:mterms_essential, l:m) == -1
					let l:mterms_clean += [ l:m ]
				endif
			endfor
			if !empty(l:mterms_clean)
				let l:pi['mterms'] = l:mterms_clean
				let l:mterms_remaining += l:pi['mterms']
				let l:pic_clean += [ l:pi ]
			endif
		endif
	endfor
	let l:mterms_remaining = uniq(sort(l:mterms_remaining))

	let l:pi_count = len(l:pic_clean)
	let l:pi_groups_count = pow(2, l:pi_count)-1
	let l:pi_groups = []
	let l:i = 0
	while l:i < l:pi_groups_count
		let l:bin_i = printf('%0'.l:pi_count.'b', l:i+1)
		let l:b = 0
		let l:cover = []
		let l:pos_terms = 0
		let l:neg_terms = 0
		while l:b < len(l:bin_i)
			if l:bin_i[l:b] == 1
				let l:cover += l:pic_clean[l:b]['mterms']
				let l:t = 0
				let l:terms_count = len(l:pic_clean[l:b]['terms'])
				while l:t < l:terms_count
					if l:pic_clean[l:b]['terms'][l:t] == '0'
						let l:neg_terms += 1
					elseif l:pic_clean[l:b]['terms'][l:t] == '1'
						let l:pos_terms += 1
					endif
					let l:t += 1
				endwhile
			endif
			let l:b += 1
		endwhile
		if uniq(sort(l:cover)) == l:mterms_remaining
			let l:pi_groups += [ {
				\ 'group': l:bin_i,
				\ 'count': count(split(l:bin_i, '\zs'), '1'),
				\ 'positive_terms': l:pos_terms,
				\ 'negative_terms': l:neg_terms
				\ } ]
		endif
		let l:i += 1
	endwhile

	let l:candidates = []
	for l:candidate in l:pi_groups
		if empty(l:candidates)
			let l:candidates += [ l:candidate ]
			let l:min = l:candidate['count']
		elseif l:candidate['count'] <= l:min
			if l:candidate['count'] < l:min
				let l:candidates = [ l:candidate ]
				let l:min = l:candidate['count']
			else
				let l:candidates += [ l:candidate ]
			endif
		endif
	endfor

	if len(l:candidates) > 1

		let l:new_candidates = []
		for l:candidate in l:candidates
			if empty(l:new_candidates)
				let l:new_candidates += [ l:candidate ]
				let l:min_pos = l:candidate['positive_terms']
				let l:min_neg = l:candidate['negative_terms']
			elseif l:candidate['positive_terms'] + l:candidate['negative_terms'] <= l:min_pos + l:min_neg
				if l:candidate['positive_terms'] + l:candidate['negative_terms'] < l:min_pos + l:min_neg
					let l:new_candidates = [ l:candidate ]
					let l:min_pos = l:candidate['positive_terms']
					let l:min_neg = l:candidate['negative_terms']
				else
					if l:candidate['positive_terms'] <= l:min_pos
						if l:candidate['positive_terms'] < l:min_pos
							let l:new_candidates = [ l:candidate ]
							let l:min_pos = l:candidate['positive_terms']
							let l:min_neg = l:candidate['negative_terms']
						else
							let l:new_candidates += [ l:candidate ]
						endif
					endif
				endif
			endif
		endfor

	else
		let l:new_candidates = l:candidates
	endif

	if !empty(l:new_candidates)
		let l:i = 0
		while l:i < len(l:new_candidates[0]['group'])
			if l:new_candidates[0]['group'][l:i] == '1'
				let l:solution += [ l:pic_clean[l:i]['terms'] ]
			endif
			let l:i += 1
		endwhile
	endif

	return l:solution

endfunction

function! s:QMCFormulaBuildPrepare(solution, terms)
	let l:terms_count = len(a:terms)
	let l:solution_count = len(a:solution)
	let l:build = []

	for l:term in a:solution
		let l:t = 0
		let l:operands = []
		while l:t < len(l:term)
			if l:term[l:t] != '-'
				let l:sign = ''
				if l:term[l:t] == '1' && s:qmc_mode == 'pos'
					\ || l:term[l:t] == '0' && s:qmc_mode == 'sop'
					let l:sign = '-'
				endif
				let l:operands += [ l:sign.a:terms[l:t] ]
			endif
			let l:t += 1
		endwhile
		let l:build += [ l:operands ]
	endfor

	return l:build
endfunction

function! s:QMCFormulaBuild(solution)

	if type(a:solution) == v:t_string
		return a:solution
	else
		if type(a:solution[0]) == v:t_string
			let l:next = a:solution[1:]
			if empty(l:next)
				return a:solution[0]
			else
				if s:qmc_mode == 'sop'
					return [ ' ', a:solution[0], s:QMCFormulaBuild(l:next) ]
				elseif s:qmc_mode == 'pos'
					return [ '+', a:solution[0], s:QMCFormulaBuild(l:next) ]
				endif
			endif
		else
			let l:formula = ''

			for l:s in a:solution
				if empty(l:formula)
					let l:formula = s:QMCFormulaBuild(l:s)
				else
					if s:qmc_mode == 'sop'
						let l:op = '+'
					elseif s:qmc_mode == 'pos'
						let l:op = ' '
					endif
					let l:formula = [
						\ l:op,
						\ l:formula,
						\ s:QMCFormulaBuild(l:s)
						\ ]
				endif
			endfor
			return l:formula
		endif
	endif

endfunction

let demo = "-a b -c -d + a -b -c -d + a -b -c d + a -b c -d + a -b c d + a b -c -d + a b c -d + a b c d"
echo "INPUT" demo
let solution = s:QMCFormulaToString(s:QMCSimplify(s:QMCParser(demo)))
echo "SOLUTION" solution

