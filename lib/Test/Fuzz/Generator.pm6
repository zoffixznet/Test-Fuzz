unit class Test::Fuzz::Generator;

method generate(Str \type, Mu:D $constraints, Int $size) {
	my Mu @ret;
	my Mu @undefined;
	my $type = type ~~ /^^
		$<type>	= (\w+)
		[
			':'
			$<def>	= (<[UD]>)
		]?
	$$/;
	my \test-type		= ::(~$type<type>);
	my $loaded-types	= set |::.values.grep(not *.defined);
	my $builtin-types	= set |%?RESOURCES<classes>.IO.lines.map({::($_)});
	my $types			= $loaded-types ∪ $builtin-types;
	#my $types			= $builtin-types;
	my @types			= $types.keys.grep(sub (Mu \item) {
		my Mu:U \i = item;
		return so i ~~ test-type;
		CATCH {return False}
	});
	@undefined = @types.grep(sub (Mu \item) {
		my Mu:U \i = item;
		return so i ~~ $constraints;
		CATCH {return False}
	}) if not $type<def>.defined or ~$type<def> eq "U";

	my %generator
		<== map({.^name => .generate-samples})
		<== grep({try {.?generate-samples}})
		#<== grep({.^can("generate-samples") && .?generate-samples})
		<== @types
	;

	my %indexes := BagHash.new;
	my %gens := @types.map(*.^name) ∩ %generator.keys;
	while @ret.elems < $size {
		for %gens.keys -> $sub {
			my $item = %generator{$sub}[%indexes{$sub}++];
			@ret.push: $item if $item ~~ test-type & $constraints;
		}
	}
	@ret.unshift: |@undefined if @undefined;
	@ret
}

