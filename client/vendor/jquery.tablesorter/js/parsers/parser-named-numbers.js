/*! Named Numbers Parser - 10/26/2014 (v2.18.0)
 * code modified from http://stackoverflow.com/a/12014376/145346
 */
/*jshint jquery:true */
;(function($){
"use strict";

	// Change language of the named numbers as needed
	var named = {
		negative: [ 'negative', 'minus' ],
		numbers : {
			'zero' : 0,
			'one' : 1,
			'two' : 2,
			'three' : 3,
			'four' : 4,
			'five' : 5,
			'six' : 6,
			'seven' : 7,
			'eight' : 8,
			'nine' : 9,
			'ten' : 10,
			'eleven' : 11,
			'twelve' : 12,
			'thirteen' : 13,
			'fourteen' : 14,
			'fifteen' : 15,
			'sixteen' : 16,
			'seventeen' : 17,
			'eighteen' : 18,
			'nineteen' : 19,
			'twenty' : 20,
			'thirty' : 30,
			'forty' : 40,
			'fourty' : 40, // common misspelling
			'fifty' : 50,
			'sixty' : 60,
			'seventy' : 70,
			'eighty' : 80,
			'ninety' : 90
		},
		// special case
		hundred : 'hundred',
		// multiples
		powers : {
			'thousand' : 1e3,
			'million' : 1e6,
			'billion' : 1e9,
			'trillion' : 1e12,
			'quadrillion' : 1e15,
			'quintillion' : 1e18,
			'sextillion' : 1e21,
			'septillion' : 1e24,
			'octillion' : 1e27,
			'nonillion' : 1e30,
			'decillion' : 1e33,
			'undecillion' : 1e36,
			'duodecillion' : 1e39,
			'tredecillion' : 1e42,
			'quattuordecillion' : 1e45,
			'quindecillion' : 1e48,
			'sexdecillion' : 1e51,
			'septendecillion' : 1e54,
			'octodecillion' : 1e57,
			'novemdecillion' : 1e60,
			'vigintillion' : 1e63,
			'unvigintillion' : 1e66,
			'duovigintillion' : 1e69,
			'trevigintillion' : 1e72,
			'quattuorvigintillion' : 1e75,
			'quinvigintillion' : 1e78,
			'sexvigintillion' : 1e81,
			'septenvigintillion' : 1e84,
			'octovigintillion' : 1e87,
			'novemvigintillion' : 1e90,
			'trigintillion' : 1e93,
			'untrigintillion' : 1e96,
			'duotrigintillion' : 1e99,
			'googl' : 1e100
		}
	},
	result, group,
	negativeRegex = new RegExp('(' + named.negative.join('|') + ')'),
	calc = function ( word, table ) {
		var num = named.numbers.hasOwnProperty( word ) ? named.numbers[ word ] : null,
			power = named.powers.hasOwnProperty( word ) ? named.powers[ word ] : null;
		if ( !num && !isNaN( word ) ) {
			num = $.tablesorter.formatFloat( word || '', table );
		}
		if ( num !== null ) {
			group += num;
		} else if ( word === named.hundred ) {
			group *= 100;
		} else if ( power !== null ) {
			result += group * power;
			group = 0;
		}
	};

	$.tablesorter.addParser({
		id: "namedNumbers",
		is: function () {
			return false;
		},
		format: function ( str, table ) {
			result = 0;
			group = 0;
			var indx,
				arry = ( str || '' ).split( /[\s-]+/ ),
				len = arry.length;
			for ( indx = 0; indx < len; indx++ ) {
				calc( arry[ indx ].toLowerCase(), table );
			}
			result = ( result + group ) * ( str.match( negativeRegex ) ? -1 : 1 );
			// make sure to let zero get parsed, so check hasOwnProperty
			return result || named.numbers.hasOwnProperty( str ) ? result : $.tablesorter.formatFloat( str || '', table );
		},
		type: "numeric"
	});

})( jQuery );
