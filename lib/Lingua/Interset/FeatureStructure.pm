#!/usr/bin/env perl
# The main class of DZ Interset 2.0.
# It defines all morphosyntactic features and their values.
# Copyright © 2012 Dan Zeman <zeman@ufal.mff.cuni.cz>
# License: GNU GPL

package Lingua::Interset::FeatureStructure;
use utf8;
use open ':utf8';
use namespace::autoclean;
use Moose;
our $VERSION; BEGIN { $VERSION = "2.00" }



# Should the features have their own classes, too?
# Pluses:
# + We could bind all properties of one feature tighter (its name, its priority, list of values and their intuitive ordering, list of default value changes).
# + There would be more space for additional services such as documentation and examples of the feature values.
# Minuses:
# - It is good to have them all together here. Better overall picture, mutual relations checking etc. If they are spread across 30 files, the picture will be lost.
# - Handling classes might turn out to be more complicated than handling simple attributes?
# - Perhaps efficiency issues?

# We want to know the following about the features:
# 1. List of known feature names
# 1.1. Each feature named using the 'has' keyword of Moose
# 1.2. Print order of features, i.e. the order in which we want to sort a list of features when printed
# 1.3. Default priority order of features, to be used when restricting value combinations (can be overriden for particular tagsets)
# 2. For each feature, list of known values
# 2.1. Each value named using the 'enum' keyword of Moose to trigger Moose data validation
# 2.2. Print order of values, e.g. we want to print 'sing' before 'plu' although alphabetical order says otherwise
# 3. For each value, order in which the other values should be considered as replacements when value restrictions are in effect

# Solution: One big matrix of features, values and their properties follows.
# The Moose declarations will be simply derived from the matrix below.
# The order of the features and values in the matrix is their print order.
# Default priority order of features is defined by the 'priority' values, ascending.

# Help to the replacement arrays:

# What follows is an attempt to describe the system of value replacements
# in an easily readable and maintainable way. The algorithm to process it
# may be complicated but the human interpretation should (hopefully) be simple.

# Rule 1: Values of each feature are ordered. This is the order of priority
#         when searching for replacement of an empty value.
# Rule 2: A non-empty value is replaced by empty value in the first place.
#         If the empty value is not permitted, it is replaced according to
#         Rule 1.
# Rule 3: Some values of some features have customized replacement sequences.
#         They contain replacements that are used prior to the default empty value.
#         For instance, if we have pos=det (determiner), we want to try
#         pos=adj (adjective) first, and only if this value is not permitted,
#         we default to the empty value.
#         Customized replacement sequences, if present, are specified
#         immediately next to the value being replaced (in one array).
#         The last element is a link: if we pass this value, we proceed to
#         its own customized replacement sequence. If the value does not
#         have a customized replacement sequence or if the link constitutes
#         a loop, proceed as if replacing an empty value according to Rule 1.

# The empty value does not need to be specified in the main (top-down) list
# of values of a feature. However, should a customized replacement sequence
# (left-to-right list) contain an empty value, it must explicitely state it.

# The algorithm:
# $valord{$feature}[$first][$second]
# 1. Find the 2D array according to feature name.
# 2. Find the value to be replaced in the first dimension.
# 3. Try to find replacement in the second dimension (respect ordering).
# 4. If unsuccessful and the second dimension has more than one member, try to replace the last member (go back to step 2). Check loops!
# 5. In case of a loop go to next step and act as if there was only one member.
# 6. If unsuccessful and the second dimension has only one member (the value to replace), check empty value as replacement.
# 7. If unsuccessful, try to find replacement in the first dimension (respect ordering).

my @matrix =
(
    # Main part of speech
    ###!!! RENAME prep to adp (adposition)?
    'pos' =>
    {
        'priority' => 10,
        'values'   => ['noun', 'adj', 'num', 'verb', 'adv', 'prep', 'conj', 'part', 'int', ''],
        'replacements' =>
        [
            ['part'        ],
            ['noun', 'verb'],
            ['verb'        ],
            ['punc'        ],
            ['adj',  'noun'],
            ['num',  'adj' ],
            ['adv'         ],
            ['prep', 'adv' ],
            ['conj', 'prep'],
            ['int'         ]
        ],
    },
    # Subpart of speech.
    ###!!! This feature will probably be dissolved into several POS-specific features or something.
    'subpos' =>
    {
        'priority' => 20,
        'values' => ['mod', 'ex', 'voc', 'post', 'circ', 'preppron', 'comprep', 'emp', 'res', 'inf', 'vbp', ''],
        'replacements' =>
        [
            ['mod'],
            ['ex'],
            ['voc'],
            ['post'],
            ['circ'],
            ['preppron'],
            ['comprep'],
            ['emp'],
            ['res'],
            ['inf'],
            ['vbp']
        ],
    },
    # Special type of noun if applicable and if known.
    ###!!! NEW FEATURE (from subpos)
    'nountype' =>
    {
        'priority' => 30,
        'values' => ['com', 'prop', 'class', ''],
        'replacements' =>
        [
            ['com'],
            ['prop'],
            ['class'],
        ],
    },
    # Special type of adjective if applicable and if known.
    ###!!! NEW FEATURE (from subpos)
    'adjtype' =>
    {
        'priority' => 40,
        'values' => ['pdt', 'det', 'art', ''],
        'replacements' =>
        [
            ['pdt'],
            ['det'],
            ['art', 'det'],
        ],
    },
    # Pronominality and its type for nouns (pronouns), adjectives (determiners), numerals, adverbs etc.
    ###!!! NEW VALUE prn ... pronominal, without knowing the exact type
    'prontype' =>
    {
        'priority' => 50,
        'values' => ['prn', 'prs', 'rcp', 'int', 'rel', 'dem', 'neg', 'ind', 'tot', ''],
        'replacements' =>
        [
            ['prn'],
            ['ind'],
            ['dem'],
            ['prs'],
            ['rcp', 'prs'],
            ['int', 'rel'],
            ['rel', 'int'],
            ['neg', 'ind'],
            ['tot', 'ind'],
        ],
    },
    # Numeral types.
    ###!!! Note that it is currently not guaranteed that pos eq 'num'. (Nor do I find such cross-feature implications desirable.)
    ###!!! For instance, ordinal numbers are often classified as adjectives.
    ###!!! We may want to consider restricting pos = 'num' to cardinal numbers.
    'numtype' =>
    {
        'priority' => 60,
        'values' => ['card', 'ord', 'mult', 'frac', 'gen', 'dist', ''],
        'replacements' =>
        [
            ['card', '', 'ord'],
            ['ord', '', 'card'],
            ['mult', 'card'],
            ['frac', 'card'],
            ['gen', 'card'],
            ['dist', 'card']
        ],
    },
    # Presentation form of numerals.
    'numform' =>
    {
        'priority' => 70,
        'values' => ['word', 'digit', 'roman', ''],
        'replacements' =>
        [
            ['word'],
            ['digit', 'roman'],
            ['roman', 'digit']
        ],
    },
    # Numeric value (class of values) of numerals.
    # Some low-value numerals in some languages behave differently.
    'numvalue' =>
    {
        'priority' => 80,
        'values' => ['1', '2', '3', ''],
        'replacements' =>
        [
            ['1'],
            ['2', '3'],
            ['3', '2']
        ],
    },
    # Special type of verb if applicable and if known.
    ###!!! NEW FEATURE (from subpos)
    'verbtype' =>
    {
        'priority' => 90,
        'values' => ['aux', 'cop', 'mod', 'verbconj', ''],
        'replacements' =>
        [
            ['aux'],
            ['cop', 'aux'],
            ['mod', 'aux'],
            ['verbconj'],
        ],
    },
    # Semantic type of adverb.
    'advtype' =>
    {
        'priority' => 100,
        'values' => ['man', 'loc', 'tim', 'deg', 'cau', ''],
        'replacements' =>
        [
            ['man'],
            ['loc'],
            ['tim'],
            ['deg'],
            ['cau']
        ],
    },
    # Conjunction type.
    ###!!! NEW FEATURE (from subpos)
    'conjtype' =>
    {
        'priority' => 110,
        'values' => ['coor', 'sub', 'comp', ''],
        'replacements' =>
        [
            ['coor'],
            ['sub'],
            ['comp'],
        ],
    },
    # Punctuation type.
    'punctype' =>
    {
        'priority' => 120,
        'values' => ['peri', 'qest', 'excl', 'quot', 'brck', 'comm', 'colo', 'semi', 'dash', 'symb', 'root', ''],
        'replacements' =>
        [
            ['colo'],
            ['comm', 'colo'],
            ['peri', 'colo'],
            ['qest', 'peri'],
            ['excl', 'peri'],
            ['quot', 'brck'],
            ['brck', 'quot'],
            ['semi', 'comm'],
            ['dash', 'colo'],
            ['symb'],
            ['root']
        ],
    },
    # Distinction between opening and closing brackets and other paired punctuation.
    'puncside' =>
    {
        'priority' => 130,
        'values' => ['ini', 'fin', ''],
        'replacements' =>
        [
            ['ini'],
            ['fin']
        ],
    },
    # Syntactic part of speech.
    ###!!! DO WE STILL NEED THIS?
    # It was originally used with pronouns and numerals that behaved syntactically as nouns, adjectives or even adverbs.
    # The problem of pronouns has been solved by making pronominality a separate feature.
    # If we do something similar with numerals (but what about cardinals?), the synpos feature will probably become superfluous.
    # Before removing the feature we should analyze all existing tagsets to see which tagsets set synpos and where.
    'synpos' =>
    {
        'priority' => 140,
        'values' => ['subst', 'attr', 'adv', 'pred', ''],
        'replacements' =>
        [
            ['subst'],
            ['attr'],
            ['adv'],
            ['pred']
        ],
    },
    #--------------------------------------------------------------------------
    # For the following group of almost-boolean attributes I am not sure what would be the best internal representation.
    # Many of them constitute a distinct part of speech in some tagsets but they are in principle orthogonal to the part-of-speach feature.
    # However, regardless the representation, I would like the setter (writer) method to accept boolean values (zero/nonzero), too.
    # Possessivity.
    'poss' =>
    {
        'priority' => 150,
        'values' => ['poss', ''], ###!!! OR yes-no-empty? But I do not think it would be practical.
        'replacements' =>
        [
            ['poss']
        ],
    },
    # Reflexivity.
    'reflex' =>
    {
        'priority' => 160,
        'values' => ['reflex', ''], ###!!! OR yes-no-empty? But I do not think it would be practical.
        'replacements' =>
        [
            ['reflex']
        ],
    },
    # Foreign word? (Not a loanword but a quotation from a foreign language.)
    'foreign' =>
    {
        'priority' => 170,
        'values' => ['foreign', ''], ###!!! OR yes-no-empty? But I do not think it would be practical.
        'replacements' =>
        [
            ['foreign']
        ],
    },
    # Abbreviation?
    'abbr' =>
    {
        'priority' => 180,
        'values' => ['abbr', ''], ###!!! OR yes-no-empty? But I do not think it would be practical.
        'replacements' =>
        [
            ['abbr']
        ],
    },
    # Is this a part of a hyphenated compound?
    # Typically one part gets a normal part of speech and the other gets this flag.
    # Whether this is the first or the second part depends on the original tagset and language.
    'hyph' =>
    {
        'priority' => 190,
        'values' => ['hyph', ''], ###!!! OR yes-no-empty? But I do not think it would be practical.
        'replacements' =>
        [
            ['hyph']
        ],
    },
    # Is this / does this word contain a typo?
    'typo' =>
    {
        'priority' => 200,
        'values' => ['typo', ''], ###!!! OR yes-no-empty? But I do not think it would be practical.
        'replacements' =>
        [
            ['typo']
        ],
    },
    # Is this a reduplicated or echo word?
    'echo' =>
    {
        'priority' => 210,
        'values' => ['rdp', 'ech', ''],
        'replacements' =>
        [
            ['rdp', 'ech'],
            ['ech', 'rdp']
        ],
    },
    # Negativeness (presence of negative morpheme in languages and word classes where applicable).
    'negativeness' =>
    {
        'priority' => 220,
        'values' => ['pos', 'neg', ''],
        'replacements' =>
        [
            ['pos'],
            ['neg']
        ],
    },
    # Definiteness (or state in Arabic).
    'definiteness' =>
    {
        'priority' => 230,
        'values' => ['ind', 'def', 'red', 'com', ''],
        'replacements' =>
        [
            ['ind'],
            ['def'],
            ['red', 'def'],
            ['com', 'red', 'def']
        ],
    },
    # Gender.
    'gender' =>
    {
        'priority' => 240,
        'values' => ['masc', 'fem', 'com', 'neut', ''],
        'replacements' =>
        [
            ['neut'],
            ['com', 'masc', 'fem'],
            ['masc', 'com'],
            ['fem', 'com']
        ],
    },
    # Animateness (considered part of gender in some tagsets, but still orthogonal).
    'animateness' =>
    {
        'priority' => 250,
        'values' => ['anim', 'nhum', 'inan', ''],
        'replacements' =>
        [
            ['anim'],
            ['nhum', 'anim'],
            ['inan']
        ],
    },
    # Grammatical number.
    'number' =>
    {
        'priority' => 260,
        'values' => ['sing', 'dual', 'plu', 'ptan', 'coll', ''],
        'replacements' =>
        [
            ['sing'],
            ['dual', 'plu'],
            ['plu'],
            ['ptan', 'plu'],
            ['coll', 'sing']
        ],
    },
    # Grammatical case.
    'case' =>
    {
        'priority' => 270,
        'values' => ['nom', 'gen', 'dat', 'acc', 'voc', 'loc', 'ins', 'ist',
                     'abl', 'del', 'par', 'dis', 'ess', 'tra', 'com', 'abe', 'ine', 'ela', 'ill', 'ade', 'all', 'sub', 'sup', 'lat',
                     'add', 'tem', 'ter', 'abs', 'erg', 'cau', 'ben', ''],
        'replacements' =>
        [
            ['nom'],
            ['acc'],
            ['dat', 'ben'],
            ['gen'],
            ['loc', 'ine', 'ade', 'sup', 'tem'],
            ['ins'],
            ['voc'],
            ['abl', 'del', 'lat', 'loc'],
            ['del', 'abl', 'lat', 'loc'],
            ['par', 'gen'],
            ['dis'],
            ['ess'],
            ['tra'],
            ['com', 'ins'],
            ['abe'],
            ['ine', 'loc'],
            ['ela', 'loc'],
            ['ill', 'lat', 'loc'],
            ['add', 'ill'],
            ['ade', 'sup', 'loc'],
            ['sup', 'ade', 'loc'],
            ['all', 'sub', 'lat', 'loc'],
            ['sub', 'all', 'lat', 'loc'],
            ['lat', 'all', 'sub', 'loc'],
            ['tem', 'loc'],
            ['ter', 'ill'],
            ['abs', 'nom', 'acc'],
            ['erg', 'nom'],
            ['cau'],
            ['ben', 'dat']
        ],
    },
    # Is this a special form (case) after a preposition?
    # Typically applies to personal pronouns, e.g. in Czech and Portuguese.
    'prepcase' =>
    {
        'priority' => 280,
        'values' => ['npr', 'pre', ''],
        'replacements' =>
        [
            ['npr'],
            ['pre']
        ],
    },
    # Degree of comparison.
    'degree' =>
    {
        'priority' => 290,
        'values' => ['pos', 'comp', 'sup', 'abs', ''],
        'replacements' =>
        [
            ['pos'],
            ['comp'],
            ['sup', 'comp'],
            ['abs', 'sup']
        ],
    },
    # Person.
    'person' =>
    {
        'priority' => 300,
        'values' => ['1', '2', '3', ''],
        'replacements' =>
        [
            ['3'],
            ['1'],
            ['2']
        ],
    },
    # Politeness, formal vs. informal word forms.
    'politeness' =>
    {
        'priority' => 310,
        'values' => ['inf', 'pol', ''],
        'replacements' =>
        [
            ['inf'],
            ['pol']
        ],
    },
    # Possessor's gender. (The gender feature typically holds the possession's gender in this case.)
    'possgender' =>
    {
        'priority' => 320,
        'values' => ['masc', 'fem', 'com', 'neut', ''],
        'replacements' =>
        [
            ['neut'],
            ['com', 'masc', 'fem'],
            ['masc', 'com'],
            ['fem', 'com']
        ],
    },
    # Possessor's person.
    # Used e.g. in Hungarian where possessive morphemes can be attached to possessed nouns ("apple-mine").
    'possperson' =>
    {
        'priority' => 330,
        'values' => ['1', '2', '3', ''],
        'replacements' =>
        [
            ['3'],
            ['1'],
            ['2']
        ],
    },
    # Possessor's number.
    'possnumber' =>
    {
        'priority' => 340,
        'values' => ['sing', 'dual', 'plu', ''],
        'replacements' =>
        [
            ['sing'],
            ['dual', 'plu'],
            ['plu']
        ],
    },
    # Possession's number.
    # In Hungarian, it is possible (though rare) that a noun has three numbers:
    # 1. its own grammatical number; 2. number of its possessor; 3. number of its possession.
    'possednumber' =>
    {
        'priority' => 350,
        'values' => ['sing', 'dual', 'plu', ''],
        'replacements' =>
        [
            ['sing'],
            ['dual', 'plu'],
            ['plu']
        ],
    },
    # Subcategorization.
    # So far this feature only keeps the transitive-intransitive distinction encoded in some tagsets.
    # However, real verb subcategorization is in fact much more complex.
    'subcat' =>
    {
        'priority' => 360,
        'values' => ['intr', 'tran', ''],
        'replacements' =>
        [
            ['intr'],
            ['tran']
        ],
    },
    # Verb form.
    ###!!! Combine this feature with mood? Non-empty mood seems to always imply verbform=fin.
    ###!!! On the other hand, we may want to make some verb forms self-standing parts of speech:
    # part (participle, properties of both verbs and adjectives)
    # ger (gerund, properties of both verbs and nouns)
    # trans (transgressive, properties of both verbs and adverbs)
    'verbform' =>
    {
        'priority' => 370,
        'values' => ['fin', 'inf', 'sup', 'part', 'trans', 'ger', ''],
        'replacements' =>
        [
            ['inf'],
            ['fin'],
            ['part'],
            ['ger'],
            ['sup'],
            ['trans']
        ],
    },
    # Mood.
    'mood' =>
    {
        'priority' => 380,
        'values' => ['ind', 'imp', 'cnd', 'pot', 'sub', 'jus', 'qot', ''],
        'replacements' =>
        [
            ['ind'],
            ['imp'],
            ['cnd', 'sub'],
            ['pot', 'cnd'],
            ['sub', 'cnd', 'jus'],
            ['jus', 'sub'],
            ['qot', 'ind']
        ],
    },
    # Tense.
    ###!!! In contrast to DZ Interset 1, the subtense feature is now incorporated here.
    ###!!! There are other hierarchical features anyway (case, number...)
    'tense' =>
    {
        'priority' => 390,
        'values' => ['pres', 'fut', 'past', 'aor', 'imp', 'pqp', ''],
        'replacements' =>
        [
            ['pres'],
            ['fut'],
            ['past', 'aor', 'imp'],
            ['aor', 'past'],
            ['imp', 'past'],
            ['pqp', 'past']
        ],
    },
    # Voice.
    'voice' =>
    {
        'priority' => 400,
        'values' => ['act', 'pass', ''],
        'replacements' =>
        [
            ['act'],
            ['pass']
        ],
    },
    # Aspect (lexical or grammatical; but see also the 'imp' tense).
    'aspect' =>
    {
        'priority' => 410,
        'values' => ['imp', 'perf', 'pro', ''],
        'replacements' =>
        [
            ['imp'],
            ['perf'],
            ['pro']
        ],
    },
    # Variant. Used in some tagsets to distinguish between forms of the same lemma that would otherwise get the same tag.
    # The meaning of the values is not and cannot be universal, not even within the scope of one tagset.
    # Aspect (lexical or grammatical; but see also the 'imp' tense).
    'variant' =>
    {
        'priority' => 420,
        'values' => ['short', 'long', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', ''],
        'replacements' =>
        [
            ['0'],
            ['1'],
            ['2'],
            ['3'],
            ['4'],
            ['5'],
            ['6'],
            ['7'],
            ['8'],
            ['9'],
            ['short'],
            ['long']
        ],
    },
    # Style.
    # Either lexical category of the lemma, or grammatical
    # (e.g. standard and colloquial suffix of the same lemma, cf. Czech "zelený" vs. "zelenej").
    'style' =>
    {
        'priority' => 430,
        'values' => ['arch', 'form', 'norm', 'coll', 'vrnc', 'slng', 'derg', 'vulg', ''],
        'replacements' =>
        [
            ['norm'],
            ['form'],
            ['arch', 'form'],
            ['coll'],
            ['vrnc'],
            ['slng'],
            ['derg', 'coll'],
            ['vulg', 'derg']
        ],
    },
    # Tagset identifier. Where does this feature structure come from? Used to interpret the 'other' feature.
    # The expected values can be checked by a regular expression but they cannot be enumerated.
    # isa => subtype as 'Str', where { m/^([a-z]+::[a-z]+)?$/ }, message { "'$_' does not look like a tagset identifier ('lang::corpus')." } );
    'tagset' =>
    {
        'priority' => 9998,
    },
    # Tagset-specific information that does not fit elsewhere.
    # Any value is permitted, even a hash reference.
    'other' =>
    {
        'priority' => 9999,
    }
);



# These are the features and values defined in DZ Interset:
has 'pos'          => ( is  => 'rw', default => '',
                        isa => enum ['noun', 'adj', 'num', 'verb', 'adv', 'prep', 'conj', 'part', 'int', ''] ); ###!!! RENAME prep to adp (adposition)?
has 'subpos'       => ( is  => 'rw', default => '',
                        isa => enum ['mod', 'ex', 'voc', 'post', 'circ', 'preppron', 'comprep', 'emp', 'res', 'inf', 'vbp', ''] );
has 'nountype'     => ( is  => 'rw', default => '',
                        isa => enum ['com', 'prop', 'class', ''] ); ###!!! NEW FEATURE (from subpos)
has 'adjtype'      => ( is  => 'rw', default => '',
                        isa => enum ['pdt', 'det', 'art', ''] ); ###!!! NEW FEATURE (from subpos)
has 'prontype'     => ( is  => 'rw', default => '',
                        isa => enum ['prn', 'prs', 'rcp', 'int', 'rel', 'dem', 'neg', 'ind', 'tot', ''] ); ###!!! NEW VALUE prn ... pronominal, without knowing the exact type
has 'numtype'      => ( is  => 'rw', default => '',
                        isa => enum ['card', 'ord', 'mult', 'frac', 'gen', 'dist', ''] );
has 'numform'      => ( is  => 'rw', default => ''
                        isa => enum ['word', 'digit', 'roman', ''] );
has 'numvalue'     => ( is  => 'rw', default => '',
                        isa => enum ['1', '2', '3', ''] );
has 'verbtype'     => ( is  => 'rw', default => '',
                        isa => enum ['aux', 'cop', 'mod', 'verbconj', ''] ); ###!!! NEW FEATURE (from subpos)
has 'advtype'      => ( is  => 'rw', default => '',
                        isa => enum ['man', 'loc', 'tim', 'deg', 'cau', ''] );
has 'conjtype'     => ( is  => 'rw', default => '',
                        isa => enum ['coor', 'sub', 'comp', ''] ); ###!!! NEW FEATURE (from subpos)
has 'punctype'     => ( is  => 'rw', default => '',
                        isa => enum ['peri', 'qest', 'excl', 'quot', 'brck', 'comm', 'colo', 'semi', 'dash', 'symb', 'root', ''] );
has 'puncside'     => ( is  => 'rw', default => '',
                        isa => enum ['ini', 'fin', ''] );
has 'synpos'       => ( is  => 'rw', default => '',
                        isa => enum ['subst', 'attr', 'adv', 'pred', ''] ); ###!!! DO WE STILL NEED THIS?
# For the following group of almost-boolean attributes I am not sure what would be the best internal representation.
# However, regardless the representation, I would like the setter (writer) method to accept boolean values (zero/nonzero), too.
has 'poss'         => ( is  => 'rw', default => '',
                        isa => enum ['poss', ''] ); ###!!! OR yes-no-empty? But I do not think it would be practical.
has 'reflex'       => ( is  => 'rw', default => '',
                        isa => enum ['reflex', ''] ); ###!!! OR yes-no-empty? But I do not think it would be practical.
has 'foreign'      => ( is  => 'rw', default => '',
                        isa => enum ['foreign', ''] ); ###!!! OR yes-no-empty? But I do not think it would be practical.
has 'abbr'         => ( is  => 'rw', default => '',
                        isa => enum ['abbr', ''] ); ###!!! OR yes-no-empty? But I do not think it would be practical.
has 'hyph'         => ( is  => 'rw', default => '',
                        isa => enum ['hyph', ''] ); ###!!! OR yes-no-empty? But I do not think it would be practical.
has 'typo'         => ( is  => 'rw', default => '',
                        isa => enum ['typo', ''] ); ###!!! OR yes-no-empty? But I do not think it would be practical.
has 'echo'         => ( is  => 'rw', default => '',
                        isa => enum ['rdp', 'ech', ''] );
has 'negativeness' => ( is  => 'rw', default => '',
                        isa => enum ['pos', 'neg', ''] );
has 'definiteness' => ( is  => 'rw', default => '',
                        isa => enum ['ind', 'def', 'red', 'com', ''] );
has 'gender'       => ( is  => 'rw', default => '',
                        isa => enum ['masc', 'fem', 'com', 'neut', ''] );
has 'animateness'  => ( is  => 'rw', default => '',
                        isa => enum ['anim', 'nhum', 'inan', ''] );
has 'number'       => ( is  => 'rw', default => '',
                        isa => enum ['sing', 'dual', 'plu', 'ptan', 'coll', ''] );
has 'case'         => ( is  => 'rw', default => '',
                        isa => enum ['nom', 'gen', 'dat', 'acc', 'voc', 'loc', 'ins', 'ist',
                                     'abl', 'del', 'par', 'dis', 'ess', 'tra', 'com', 'abe', 'ine', 'ela', 'ill', 'ade', 'all', 'sub', 'sup', 'lat',
                                     'add', 'tem', 'ter', 'abs', 'erg', 'cau', 'ben', ''] );
has 'prepcase'     => ( is  => 'rw', default => '',
                        isa => enum ['npr', 'pre', ''] );
has 'degree'       => ( is  => 'rw', default => '',
                        isa => enum ['pos', 'comp', 'sup', 'abs', ''] );
has 'person'       => ( is  => 'rw', default => '',
                        isa => enum ['1', '2', '3', ''] );
has 'politeness'   => ( is  => 'rw', default => '',
                        isa => enum ['inf', 'pol', ''] );
has 'possgender'   => ( is  => 'rw', default => '',
                        isa => enum ['masc', 'fem', 'com', 'neut', ''] );
has 'possperson'   => ( is  => 'rw', default => '',
                        isa => enum ['1', '2', '3', ''] );
has 'possnumber'   => ( is  => 'rw', default => '',
                        isa => enum ['sing', 'dual', 'plu', ''] );
has 'possednumber' => ( is  => 'rw', default => '',
                        isa => enum ['sing', 'dual', 'plu', ''] );
has 'subcat'       => ( is  => 'rw', default => '',
                        isa => enum ['intr', 'tran', ''] );
has 'verbform'     => ( is  => 'rw', default => '',
                        isa => enum ['fin', 'inf', 'sup', 'part', 'trans', 'ger', ''] ); ###!!! Combine this feature with mood? Mood always implies verbform=fin.
has 'mood'         => ( is  => 'rw', default => '',
                        isa => enum ['ind', 'imp', 'cnd', 'pot', 'sub', 'jus', 'qot', ''] );
has 'tense'        => ( is  => 'rw', default => '',
                        isa => enum ['past', 'pres', 'fut', ''] );
has 'subtense'     => ( is  => 'rw', default => '',
                        isa => enum ['aor', 'imp', 'pqp', ''] ); ###!!! Combine this feature with tense? There are other hierarchical features anyway (case, number...)
has 'voice'        => ( is  => 'rw', default => '',
                        isa => enum ['act', 'pass', ''] );
has 'aspect'       => ( is  => 'rw', default => '',
                        isa => enum ['imp', 'perf', 'pro', ''] );
has 'variant'      => ( is  => 'rw', default => '',
                        isa => enum ['short', 'long', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', ''] );
has 'style'        => ( is  => 'rw', default => '',
                        isa => enum ['arch', 'form', 'norm', 'coll', 'vrnc', 'slng', 'derg', 'vulg', ''] );
has 'tagset'       => ( is  => 'rw', default => '',
                        isa => subtype as 'Str', where { m/^([a-z]+::[a-z]+)?$/ }, message { "'$_' does not look like a tagset identifier ('lang::corpus')." } );
has 'other'        => ( is  => 'rw', default => '' );



#---------------------------------------------------------------------------------
# Create a hash of ordering values to assist sorting feature values "intuitively".
# For example, singular is intuitively before but alphabetically after plural.
# Intuitive sorting will be useful when displaying a list of values.
#---------------------------------------------------------------------------------
my %order_values;
BUILD
{
    # Taken from DZ Interset 1: The intuitive ordering is defined by the array of
    # known values. This is a bad solution because we have to maintain the list of
    # values in at least two places: here and in the Moose enums above.
    my %known_values =
    (
        "pos"          => ["noun", "adj", "num", "verb", "adv", "prep", "conj", "part", "int", "punc"],
        "subpos"       => ["prop", "class", "pdt", "det", "art",
                           "aux", "cop", "mod", "verbconj", "mod", "ex", "voc", "post", "circ", "preppron", "comprep",
                           "coor", "sub", "comp", "emp", "res", "inf", "vbp"],
        "prontype"     => ["prs", "rcp", "int", "rel", "dem", "neg", "ind", "tot"],
        "numtype"      => ["card", "ord", "mult", "frac", "gen", "dist"],
        "numform"      => ["word", "digit", "roman"],
        "numvalue"     => ["1", "2", "3"],
        "advtype"      => ["man", "loc", "tim", "deg", "cau"],
        "punctype"     => ["peri", "qest", "excl", "quot", "brck", "comm", "colo", "semi", "dash", "symb", "root"],
        "puncside"     => ["ini", "fin"],
        "synpos"       => ["subst", "attr", "adv", "pred"],
        "poss"         => ["poss"],
        "reflex"       => ["reflex"],
        "negativeness" => ["pos", "neg"],
        "definiteness" => ["ind", "def", "red", "com"],
        "gender"       => ["masc", "fem", "com", "neut"],
        "animateness"  => ["anim", "nhum", "inan"],
        "number"       => ["sing", "dual", "plu", "ptan", "coll"],
        "case"         => ["nom", "gen", "dat", "acc", "voc", "loc", "ins", "ist",
                           "abl", "del", "par", "dis", "ess", "tra", "com", "abe", "ine", "ela", "ill", "ade", "all", "sub", "sup", "lat",
                           "add", "tem", "ter", "abs", "erg", "cau", "ben"],
        "prepcase"     => ["npr", "pre"],
        "degree"       => ["pos", "comp", "sup", "abs"],
        "person"       => [1, 2, 3],
        "politeness"   => ["inf", "pol"],
        "possgender"   => ["masc", "fem", "com", "neut"],
        "possperson"   => [1, 2, 3],
        "possnumber"   => ["sing", "dual", "plu"],
        "possednumber" => ["sing", "dual", "plu"],
        "subcat"       => ["intr", "tran"],
        "verbform"     => ["fin", "inf", "sup", "part", "trans", "ger"],
        "mood"         => ["ind", "imp", "cnd", "pot", "sub", "jus", "qot"],
        "tense"        => ["past", "pres", "fut"],
        "subtense"     => ["aor", "imp", "pqp"],
        "aspect"       => ["imp", "perf", "pro"],
        "voice"        => ["act", "pass"],
        "foreign"      => ["foreign"],
        "abbr"         => ["abbr"],
        "hyph"         => ["hyph"],
        "echo"         => ["rdp", "ech"],
        "style"        => ["arch", "form", "norm", "coll", "vrnc", "slng", "derg", "vulg"],
        "typo"         => ["typo"],
        "variant"      => ["short", "long", 0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
        "tagset"       => [""],
        "other"        => [""],
    );
    for(my $i = 0; $i<=$#known_features; $i++)
    {
        my $feature = $known_features[$i];
        $order_values{$feature}{''} = ($i+1)*1000;
        my @values = @{$known_values{$feature}};
        for(my $j = 0; $j<=$#values; $j++)
        {
            my $value = $values[$j];
            $order_values{$feature}{$value} = ($i+1)*1000+($j+1);
        }
    }
}



1;

=over

=item Lingua::Interset::FeatureStructure

DZ Interset is a universal framework for reading, writing, converting and
interpreting part-of-speech and morphosyntactic tags from multiple tagsets
of many different natural languages.

The C<FeatureStructure> class defines all morphosyntactic features and their values used
in DZ Interset.

=back

=cut

# Copyright © 2012 Dan Zeman <zeman@ufal.mff.cuni.cz>
# This file is distributed under the GNU General Public License v3. See doc/COPYING.txt.
