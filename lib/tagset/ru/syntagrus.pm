#!/usr/bin/perl
# Driver for Syntagrus (Russian Dependency Treebank) tags.
# Copyright © 2006, 2011 Dan Zeman <zeman@ufal.mff.cuni.cz>
# License: GNU GPL

package tagset::ru::syntagrus;
use utf8;
use open ":utf8";
binmode(STDIN, ":utf8");
binmode(STDOUT, ":utf8");
binmode(STDERR, ":utf8");



#------------------------------------------------------------------------------
# Takes tag string.
# Returns feature hash.
#------------------------------------------------------------------------------
sub decode
{
    my $tag = shift;
    my %f; # features
    $f{tagset} = 'ru::syntagrus';
    my @positions = split(/\s+/, $tag);
    foreach my $p (@positions)
    {
        # Part of speech
        if($p eq 'A')
        {
            $f{pos} = 'adj';
        }
        elsif($p eq 'ADV')
        {
            $f{pos} = 'adv';
        }
        elsif($p eq 'COM')
        {
            $f{hyph} = 'hyph';
        }
        elsif($p eq 'CONJ')
        {
            $f{pos} = 'conj';
        }
        elsif($p eq 'INTJ')
        {
            $f{pos} = 'int';
        }
        elsif($p eq 'NID')
        {
            # Unknown word. Nothing to set in Interset.
        }
        elsif($p eq 'NUM')
        {
            $f{pos} = 'num';
        }
        elsif($p =~ m/^P(ART)?$/)
        {
            $f{pos} = 'part';
        }
        elsif($p eq 'PR')
        {
            $f{pos} = 'prep';
        }
        elsif($p eq 'S')
        {
            $f{pos} = 'noun';
        }
        elsif($p eq 'V')
        {
            $f{pos} = 'verb';
        }
        # Short (nominal) variant of adjectives
        elsif($p eq 'КР')
        {
            $f{variant} = 'short';
        }
        # Compound part
        elsif($p eq 'СЛ')
        {
            $f{hyph} = 'hyph';
        }
        # For adjectives and adverbs: distinguishes forms with prefix по-
        # (поближе, поскорее, подальше) from normal forms (больше, меньше, быстрей, дальше, позже).
        elsif($p eq 'СМЯГ')
        {
            $f{other}{smjag}++;
        }
        # Number
        elsif($p eq 'ЕД')
        {
            $f{number} = 'sing';
        }
        elsif($p eq 'МН')
        {
            $f{number} = 'plu';
        }
        # Gender
        elsif($p eq 'ЖЕН')
        {
            $f{gender} = 'fem';
        }
        elsif($p eq 'МУЖ')
        {
            $f{gender} = 'masc';
        }
        elsif($p eq 'СРЕД')
        {
            $f{gender} = 'neut';
        }
        # Animateness
        elsif($p eq 'НЕОД')
        {
            $f{animateness} = 'inan';
        }
        elsif($p eq 'ОД')
        {
            $f{animateness} = 'anim';
        }
        # Case
        elsif($p eq 'ИМ') # Именительный / Номинатив (Nominative)
        {
            $f{case} = 'nom';
        }
        elsif($p eq 'РОД') # Родительный / Генитив (Genitive)
        {
            $f{case} = 'gen';
        }
        elsif($p eq 'ПАРТ') # Количественно-отделительный (партитив, или второй родительный) (Partitive) [not in Russian schools]
        {
            # Subcase of РОД. Occasionally the word form differs if the genitive
            # is used for the noun describing a whole in relation to parts;
            # these forms may also be preferred with mass nouns.
            # «нет сахара» vs. «положить сахару»
            $f{case} = 'gen';
        }
        elsif($p eq 'ДАТ') # Дательный / Датив (Dative)
        {
            $f{case} = 'dat';
        }
        elsif($p eq 'ВИН') # Винительный / Аккузатив (Accusative)
        {
            $f{case} = 'acc';
        }
        elsif($p eq 'ЗВ') # only one word type: "Господи" # Звательный (вокатив) (Vocative) [not in Russian schools]
        {
            $f{case} = 'voc';
        }
        elsif($p eq 'ПР') # Предложный / Препозитив (Prepositional) [in Russian schools taught as the last one after instrumental?]
        {
            $f{case} = 'loc';
        }
        elsif($p eq 'МЕСТН') # [not in Russian schools]
        {
            # Subcase of ПР. ПР is used for two meanings: 'about what?' (о чём?) and 'where?' (где?).
            # The word forms of the two meanings mostly overlap but there are about 100 words whose forms differ:
            # «о шкафе» — «в шкафу»
            $f{case} = 'loc';
        }
        elsif($p eq 'ТВОР') # Творительный / Аблатив (объединяет инструментатив [Instrumental], локатив и аблатив)
        {
            $f{case} = 'ins';
        }
        # Degree of comparison
        elsif($p eq 'СРАВ')
        {
            $f{degree} = 'comp';
        }
        elsif($p eq 'ПРЕВ')
        {
            $f{degree} = 'sup';
        }
        # Aspect
        elsif($p eq 'НЕСОВ')
        {
            $f{aspect} = 'imp';
        }
        elsif($p eq 'СОВ')
        {
            $f{aspect} = 'perf';
        }
        # Verb form
        elsif($p eq 'ДЕЕПР')
        {
            $f{verbform} = 'trans';
        }
        elsif($p eq 'ИЗЪЯВ')
        {
            $f{verbform} = 'fin';
            $f{mood} = 'ind';
        }
        elsif($p eq 'ИНФ')
        {
            $f{verbform} = 'inf';
        }
        elsif($p eq 'ПОВ')
        {
            $f{verbform} = 'fin';
            $f{mood} = 'imp';
        }
        elsif($p eq 'ПРИЧ')
        {
            $f{verbform} = 'part';
        }
        # Tense
        elsif($p eq 'НЕПРОШ')
        {
            $f{tense} = ['pres'|'fut'];
        }
        elsif($p eq 'ПРОШ')
        {
            $f{tense} = 'past';
        }
        elsif($p eq 'НАСТ')
        {
            $f{tense} = 'pres';
        }
        # Person
        elsif($p eq '1-Л')
        {
            $f{person} = 1;
        }
        elsif($p eq '2-Л')
        {
            $f{person} = 2;
        }
        elsif($p eq '3-Л')
        {
            $f{person} = 3;
        }
        # Voice: страдательный залог = passive voice
        elsif($p eq 'СТРАД')
        {
            $f{voice} = 'pass';
        }
        # Non-standard spelling
        elsif($p eq 'НЕСТАНД')
        {
            $f{typo} = typo;
        }
        # Obsolete tags
        elsif($p eq 'МЕТА')
        {
            # This tag has been encountered at one token only, without any obvious purpose.
            $f{other}{meta}++;
        }
        elsif($p eq 'НЕПРАВ')
        {
            # This tag has been encountered at two tokens only, without any obvious purpose.
            $f{other}{neprav}++;
        }
        else
        {
            print STDERR ("Unknown tag '$p'.\n");
        }
    }
    return \%f;
}



#------------------------------------------------------------------------------
# Takes feature hash.
# Returns tag string.
#------------------------------------------------------------------------------
sub encode
{
    my $fs = shift;
    # The Sem feature cannot be encoded in PDT tags (instead, it is encoded in lemma suffixes in PDT).
    my $sem;
    if($fs->{tagset} eq "cs::conll")
    {
        $fs->{tagset} = "cs::pdt";
        $sem = $fs->{other}{sem};
        $fs->{other} = $fs->{other}{cspdt};
    }
    elsif($fs->{subpos} eq "prop")
    {
        $sem = "m";
    }
    # The CoNLL tagset is derived from the PDT tagset.
    # Coarse-grained POS is the first character of the PDT tag.
    # Fine-grained POS is the second character of the PDT tag.
    # Features are the rest: Gen Num Cas PGe PNu Per Ten Gra Neg Voi Rs1 Rs2 Var
    # The Sem feature comes from PDT lemma, not tag.
    my $pdttag = tagset::cs::pdt::encode($fs);
    my $tag = pdt_to_conll($pdttag);
    if($sem ne '')
    {
        unless($tag =~ s/\t_$/\tSem=$sem/)
        {
            $tag .= "|Sem=$sem";
        }
    }
    return $tag;
}



#------------------------------------------------------------------------------
# Returns reference to list of known tags.
#------------------------------------------------------------------------------
sub list
{
    my $list = <<end_of_list
A
A ЕД ЖЕН ВИН
A ЕД ЖЕН ДАТ
A ЕД ЖЕН ИМ
A ЕД ЖЕН ИМ МЕТА
A ЕД ЖЕН ПР
A ЕД ЖЕН РОД
A ЕД ЖЕН ТВОР
A ЕД МУЖ ВИН НЕОД
A ЕД МУЖ ВИН ОД
A ЕД МУЖ ДАТ
A ЕД МУЖ ИМ
A ЕД МУЖ ПР
A ЕД МУЖ РОД
A ЕД МУЖ ТВОР
A ЕД СРЕД ВИН
A ЕД СРЕД ДАТ
A ЕД СРЕД ИМ
A ЕД СРЕД ПР
A ЕД СРЕД РОД
A ЕД СРЕД ТВОР
A КР ЕД ЖЕН
A КР ЕД МУЖ
A КР ЕД СРЕД
A КР МН
A МН ВИН НЕОД
A МН ВИН ОД
A МН ДАТ
A МН ИМ
A МН ПР
A МН РОД
A МН ТВОР
A ПРЕВ ЕД ЖЕН ИМ
A ПРЕВ ЕД ЖЕН РОД
A ПРЕВ ЕД ЖЕН ТВОР
A ПРЕВ ЕД МУЖ ИМ
A ПРЕВ ЕД МУЖ ПР
A ПРЕВ ЕД МУЖ РОД
A ПРЕВ ЕД СРЕД ИМ
A ПРЕВ МН ВИН НЕОД
A ПРЕВ МН ВИН ОД
A ПРЕВ МН ДАТ
A ПРЕВ МН ИМ
A ПРЕВ МН ПР
A ПРЕВ МН РОД
A СЛ
A СРАВ
A СРАВ СМЯГ
ADV
ADV НЕСТАНД
ADV СРАВ
ADV СРАВ СМЯГ
COM
COM СЛ
CONJ
INTJ
NID
NUM
NUM ВИН
NUM ВИН НЕОД
NUM ВИН ОД
NUM ДАТ
NUM ЕД ЖЕН ВИН
NUM ЕД ЖЕН ДАТ
NUM ЕД ЖЕН ИМ
NUM ЕД ЖЕН ПР
NUM ЕД ЖЕН РОД
NUM ЕД ЖЕН ТВОР
NUM ЕД МУЖ ВИН НЕОД
NUM ЕД МУЖ ВИН ОД
NUM ЕД МУЖ ДАТ
NUM ЕД МУЖ ИМ
NUM ЕД МУЖ ПР
NUM ЕД МУЖ РОД
NUM ЕД МУЖ ТВОР
NUM ЕД СРЕД ВИН
NUM ЕД СРЕД ИМ
NUM ЕД СРЕД ПР
NUM ЕД СРЕД РОД
NUM ЕД СРЕД ТВОР
NUM ЖЕН ВИН НЕОД
NUM ЖЕН ДАТ
NUM ЖЕН ИМ
NUM ЖЕН РОД
NUM ИМ
NUM МУЖ ВИН НЕОД
NUM МУЖ ВИН ОД
NUM МУЖ ДАТ
NUM МУЖ ИМ
NUM ПР
NUM РОД
NUM СЛ
NUM СРЕД ВИН
NUM СРЕД ИМ
NUM ТВОР
P
PART
PART НЕПРАВ
PR
S ЕД ЖЕН ВИН
S ЕД ЖЕН ВИН НЕОД
S ЕД ЖЕН ВИН ОД
S ЕД ЖЕН ДАТ
S ЕД ЖЕН ДАТ НЕОД
S ЕД ЖЕН ДАТ ОД
S ЕД ЖЕН ИМ
S ЕД ЖЕН ИМ НЕОД
S ЕД ЖЕН ИМ ОД
S ЕД ЖЕН МЕСТН НЕОД
S ЕД ЖЕН ПР
S ЕД ЖЕН ПР НЕОД
S ЕД ЖЕН ПР ОД
S ЕД ЖЕН РОД
S ЕД ЖЕН РОД НЕОД
S ЕД ЖЕН РОД НЕОД НЕСТАНД
S ЕД ЖЕН РОД ОД
S ЕД ЖЕН РОД ОД НЕСТАНД
S ЕД ЖЕН ТВОР НЕОД
S ЕД ЖЕН ТВОР ОД
S ЕД МУЖ ВИН НЕОД
S ЕД МУЖ ВИН ОД
S ЕД МУЖ ДАТ
S ЕД МУЖ ДАТ НЕОД
S ЕД МУЖ ДАТ ОД
S ЕД МУЖ ДАТ ОД НЕСТАНД
S ЕД МУЖ ЗВ ОД
S ЕД МУЖ ИМ
S ЕД МУЖ ИМ НЕОД
S ЕД МУЖ ИМ ОД
S ЕД МУЖ ИМ ОД НЕСТАНД
S ЕД МУЖ МЕСТН НЕОД
S ЕД МУЖ НЕОД
S ЕД МУЖ ПАРТ НЕОД
S ЕД МУЖ ПР
S ЕД МУЖ ПР НЕОД
S ЕД МУЖ ПР ОД
S ЕД МУЖ РОД
S ЕД МУЖ РОД НЕОД
S ЕД МУЖ РОД ОД
S ЕД МУЖ ТВОР
S ЕД МУЖ ТВОР НЕОД
S ЕД МУЖ ТВОР ОД
S ЕД МУЖ ТВОР ОД НЕСТАНД
S ЕД СРЕД ВИН
S ЕД СРЕД ВИН НЕОД
S ЕД СРЕД ВИН ОД
S ЕД СРЕД ДАТ
S ЕД СРЕД ДАТ НЕОД
S ЕД СРЕД ИМ
S ЕД СРЕД ИМ НЕОД
S ЕД СРЕД ИМ ОД
S ЕД СРЕД НЕОД
S ЕД СРЕД ПР
S ЕД СРЕД ПР НЕОД
S ЕД СРЕД РОД
S ЕД СРЕД РОД НЕОД
S ЕД СРЕД РОД ОД
S ЕД СРЕД ТВОР НЕОД
S ЕД СРЕД ТВОР ОД
S ЖЕН НЕОД СЛ
S МН ВИН НЕОД
S МН ВИН ОД
S МН ДАТ
S МН ДАТ НЕОД
S МН ДАТ ОД
S МН ЖЕН ВИН НЕОД
S МН ЖЕН ВИН ОД
S МН ЖЕН ДАТ НЕОД
S МН ЖЕН ДАТ ОД
S МН ЖЕН ИМ НЕОД
S МН ЖЕН ИМ ОД
S МН ЖЕН НЕОД
S МН ЖЕН ПР НЕОД
S МН ЖЕН РОД НЕОД
S МН ЖЕН РОД ОД
S МН ЖЕН ТВОР НЕОД
S МН ЖЕН ТВОР ОД
S МН ИМ
S МН ИМ НЕОД
S МН ИМ ОД
S МН МУЖ ВИН НЕОД
S МН МУЖ ВИН ОД
S МН МУЖ ДАТ НЕОД
S МН МУЖ ДАТ ОД
S МН МУЖ ИМ НЕОД
S МН МУЖ ИМ ОД
S МН МУЖ ИМ ОД НЕСТАНД
S МН МУЖ ПР НЕОД
S МН МУЖ ПР ОД
S МН МУЖ РОД НЕОД
S МН МУЖ РОД НЕОД НЕСТАНД
S МН МУЖ РОД ОД
S МН МУЖ РОД ОД НЕСТАНД
S МН МУЖ ТВОР НЕОД
S МН МУЖ ТВОР ОД
S МН ПР
S МН ПР НЕОД
S МН ПР ОД
S МН РОД
S МН РОД НЕОД
S МН РОД ОД
S МН СРЕД ВИН НЕОД
S МН СРЕД ВИН ОД
S МН СРЕД ДАТ НЕОД
S МН СРЕД ДАТ ОД
S МН СРЕД ИМ НЕОД
S МН СРЕД ИМ ОД
S МН СРЕД НЕОД
S МН СРЕД ПР НЕОД
S МН СРЕД ПР ОД
S МН СРЕД РОД НЕОД
S МН СРЕД РОД ОД
S МН СРЕД ТВОР НЕОД
S МН СРЕД ТВОР ОД
S МН ТВОР
S МН ТВОР НЕОД
S МН ТВОР ОД
S МУЖ НЕОД СЛ
S МУЖ ОД СЛ
S СРЕД НЕОД СЛ
V НЕСОВ ДЕЕПР НЕПРОШ
V НЕСОВ ДЕЕПР ПРОШ
V НЕСОВ ИЗЪЯВ НАСТ ЕД 2-Л
V НЕСОВ ИЗЪЯВ НАСТ ЕД 3-Л
V НЕСОВ ИЗЪЯВ НАСТ МН 3-Л
V НЕСОВ ИЗЪЯВ НЕПРОШ ЕД 1-Л
V НЕСОВ ИЗЪЯВ НЕПРОШ ЕД 2-Л
V НЕСОВ ИЗЪЯВ НЕПРОШ ЕД 3-Л
V НЕСОВ ИЗЪЯВ НЕПРОШ ЕД 3-Л НЕСТАНД
V НЕСОВ ИЗЪЯВ НЕПРОШ МН 1-Л
V НЕСОВ ИЗЪЯВ НЕПРОШ МН 2-Л
V НЕСОВ ИЗЪЯВ НЕПРОШ МН 3-Л
V НЕСОВ ИЗЪЯВ НЕПРОШ МН 3-Л НЕСТАНД
V НЕСОВ ИЗЪЯВ ПРОШ ЕД ЖЕН
V НЕСОВ ИЗЪЯВ ПРОШ ЕД МУЖ
V НЕСОВ ИЗЪЯВ ПРОШ ЕД СРЕД
V НЕСОВ ИЗЪЯВ ПРОШ МН
V НЕСОВ ИНФ
V НЕСОВ ПОВ ЕД 2-Л
V НЕСОВ ПОВ МН 2-Л
V НЕСОВ ПРИЧ НЕПРОШ ЕД ЖЕН ВИН
V НЕСОВ ПРИЧ НЕПРОШ ЕД ЖЕН ИМ
V НЕСОВ ПРИЧ НЕПРОШ ЕД ЖЕН ПР
V НЕСОВ ПРИЧ НЕПРОШ ЕД ЖЕН РОД
V НЕСОВ ПРИЧ НЕПРОШ ЕД ЖЕН ТВОР
V НЕСОВ ПРИЧ НЕПРОШ ЕД МУЖ ВИН НЕОД
V НЕСОВ ПРИЧ НЕПРОШ ЕД МУЖ ВИН ОД
V НЕСОВ ПРИЧ НЕПРОШ ЕД МУЖ ДАТ
V НЕСОВ ПРИЧ НЕПРОШ ЕД МУЖ ИМ
V НЕСОВ ПРИЧ НЕПРОШ ЕД МУЖ ПР
V НЕСОВ ПРИЧ НЕПРОШ ЕД МУЖ РОД
V НЕСОВ ПРИЧ НЕПРОШ ЕД МУЖ ТВОР
V НЕСОВ ПРИЧ НЕПРОШ ЕД СРЕД ВИН
V НЕСОВ ПРИЧ НЕПРОШ ЕД СРЕД ИМ
V НЕСОВ ПРИЧ НЕПРОШ ЕД СРЕД ПР
V НЕСОВ ПРИЧ НЕПРОШ ЕД СРЕД РОД
V НЕСОВ ПРИЧ НЕПРОШ ЕД СРЕД ТВОР
V НЕСОВ ПРИЧ НЕПРОШ МН ВИН НЕОД
V НЕСОВ ПРИЧ НЕПРОШ МН ВИН ОД
V НЕСОВ ПРИЧ НЕПРОШ МН ДАТ
V НЕСОВ ПРИЧ НЕПРОШ МН ИМ
V НЕСОВ ПРИЧ НЕПРОШ МН ПР
V НЕСОВ ПРИЧ НЕПРОШ МН РОД
V НЕСОВ ПРИЧ НЕПРОШ МН ТВОР
V НЕСОВ ПРИЧ ПРОШ ЕД ЖЕН ДАТ
V НЕСОВ ПРИЧ ПРОШ ЕД ЖЕН ИМ
V НЕСОВ ПРИЧ ПРОШ ЕД ЖЕН ПР
V НЕСОВ ПРИЧ ПРОШ ЕД ЖЕН ТВОР
V НЕСОВ ПРИЧ ПРОШ ЕД МУЖ ВИН НЕОД
V НЕСОВ ПРИЧ ПРОШ ЕД МУЖ ИМ
V НЕСОВ ПРИЧ ПРОШ ЕД МУЖ РОД
V НЕСОВ ПРИЧ ПРОШ ЕД МУЖ ТВОР
V НЕСОВ ПРИЧ ПРОШ ЕД СРЕД ВИН
V НЕСОВ ПРИЧ ПРОШ МН ВИН НЕОД
V НЕСОВ ПРИЧ ПРОШ МН ВИН ОД
V НЕСОВ ПРИЧ ПРОШ МН ДАТ
V НЕСОВ ПРИЧ ПРОШ МН ИМ
V НЕСОВ ПРИЧ ПРОШ МН РОД
V НЕСОВ ПРИЧ ПРОШ МН ТВОР
V НЕСОВ СТРАД ИЗЪЯВ НЕПРОШ ЕД 3-Л
V НЕСОВ СТРАД ИЗЪЯВ НЕПРОШ МН 3-Л
V НЕСОВ СТРАД ИЗЪЯВ ПРОШ ЕД ЖЕН
V НЕСОВ СТРАД ИЗЪЯВ ПРОШ ЕД МУЖ
V НЕСОВ СТРАД ИЗЪЯВ ПРОШ ЕД СРЕД
V НЕСОВ СТРАД ИЗЪЯВ ПРОШ МН
V НЕСОВ СТРАД ИНФ
V НЕСОВ СТРАД ПРИЧ НЕПРОШ ЕД ЖЕН ИМ
V НЕСОВ СТРАД ПРИЧ НЕПРОШ ЕД ЖЕН РОД
V НЕСОВ СТРАД ПРИЧ НЕПРОШ ЕД ЖЕН ТВОР
V НЕСОВ СТРАД ПРИЧ НЕПРОШ ЕД МУЖ ИМ
V НЕСОВ СТРАД ПРИЧ НЕПРОШ ЕД МУЖ РОД
V НЕСОВ СТРАД ПРИЧ НЕПРОШ ЕД МУЖ ТВОР
V НЕСОВ СТРАД ПРИЧ НЕПРОШ ЕД СРЕД ВИН
V НЕСОВ СТРАД ПРИЧ НЕПРОШ ЕД СРЕД ИМ
V НЕСОВ СТРАД ПРИЧ НЕПРОШ ЕД СРЕД РОД
V НЕСОВ СТРАД ПРИЧ НЕПРОШ МН ВИН НЕОД
V НЕСОВ СТРАД ПРИЧ НЕПРОШ МН ИМ
V НЕСОВ СТРАД ПРИЧ НЕПРОШ МН РОД
V НЕСОВ СТРАД ПРИЧ ПРОШ ЕД ЖЕН ВИН
V НЕСОВ СТРАД ПРИЧ ПРОШ ЕД МУЖ ВИН ОД
V НЕСОВ СТРАД ПРИЧ ПРОШ ЕД СРЕД ВИН
V НЕСОВ СТРАД ПРИЧ ПРОШ ЕД СРЕД ИМ
V НЕСОВ СТРАД ПРИЧ ПРОШ КР ЕД ЖЕН
V НЕСОВ СТРАД ПРИЧ ПРОШ КР ЕД СРЕД
V НЕСОВ СТРАД ПРИЧ ПРОШ КР МН
V НЕСОВ СТРАД ПРИЧ ПРОШ МН ИМ
V СОВ ДЕЕПР НЕПРОШ
V СОВ ДЕЕПР ПРОШ
V СОВ ДЕЕПР ПРОШ НЕПРАВ
V СОВ ИЗЪЯВ НЕПРОШ ЕД 1-Л
V СОВ ИЗЪЯВ НЕПРОШ ЕД 1-Л НЕСТАНД
V СОВ ИЗЪЯВ НЕПРОШ ЕД 2-Л
V СОВ ИЗЪЯВ НЕПРОШ ЕД 3-Л
V СОВ ИЗЪЯВ НЕПРОШ МН 1-Л
V СОВ ИЗЪЯВ НЕПРОШ МН 2-Л
V СОВ ИЗЪЯВ НЕПРОШ МН 3-Л
V СОВ ИЗЪЯВ ПРОШ ЕД ЖЕН
V СОВ ИЗЪЯВ ПРОШ ЕД МУЖ
V СОВ ИЗЪЯВ ПРОШ ЕД СРЕД
V СОВ ИЗЪЯВ ПРОШ МН
V СОВ ИНФ
V СОВ ПОВ ЕД 2-Л
V СОВ ПОВ ЕД 2-Л НЕСТАНД
V СОВ ПОВ МН 1-Л
V СОВ ПОВ МН 2-Л
V СОВ ПРИЧ ПРОШ ЕД ЖЕН ВИН
V СОВ ПРИЧ ПРОШ ЕД ЖЕН ДАТ
V СОВ ПРИЧ ПРОШ ЕД ЖЕН ИМ
V СОВ ПРИЧ ПРОШ ЕД ЖЕН ПР
V СОВ ПРИЧ ПРОШ ЕД ЖЕН ТВОР
V СОВ ПРИЧ ПРОШ ЕД МУЖ ВИН НЕОД
V СОВ ПРИЧ ПРОШ ЕД МУЖ ВИН ОД
V СОВ ПРИЧ ПРОШ ЕД МУЖ ДАТ
V СОВ ПРИЧ ПРОШ ЕД МУЖ ИМ
V СОВ ПРИЧ ПРОШ ЕД МУЖ ПР
V СОВ ПРИЧ ПРОШ ЕД МУЖ РОД
V СОВ ПРИЧ ПРОШ ЕД МУЖ ТВОР
V СОВ ПРИЧ ПРОШ ЕД СРЕД ВИН
V СОВ ПРИЧ ПРОШ ЕД СРЕД ИМ
V СОВ ПРИЧ ПРОШ ЕД СРЕД ПР
V СОВ ПРИЧ ПРОШ ЕД СРЕД РОД
V СОВ ПРИЧ ПРОШ ЕД СРЕД ТВОР
V СОВ ПРИЧ ПРОШ МН ВИН НЕОД
V СОВ ПРИЧ ПРОШ МН ВИН ОД
V СОВ ПРИЧ ПРОШ МН ИМ
V СОВ ПРИЧ ПРОШ МН ПР
V СОВ ПРИЧ ПРОШ МН РОД
V СОВ ПРИЧ ПРОШ МН ТВОР
V СОВ СТРАД ПРИЧ ПРОШ ЕД ЖЕН ВИН
V СОВ СТРАД ПРИЧ ПРОШ ЕД ЖЕН ДАТ
V СОВ СТРАД ПРИЧ ПРОШ ЕД ЖЕН ИМ
V СОВ СТРАД ПРИЧ ПРОШ ЕД ЖЕН ПР
V СОВ СТРАД ПРИЧ ПРОШ ЕД ЖЕН РОД
V СОВ СТРАД ПРИЧ ПРОШ ЕД ЖЕН ТВОР
V СОВ СТРАД ПРИЧ ПРОШ ЕД МУЖ ВИН НЕОД
V СОВ СТРАД ПРИЧ ПРОШ ЕД МУЖ ДАТ
V СОВ СТРАД ПРИЧ ПРОШ ЕД МУЖ ИМ
V СОВ СТРАД ПРИЧ ПРОШ ЕД МУЖ ПР
V СОВ СТРАД ПРИЧ ПРОШ ЕД МУЖ РОД
V СОВ СТРАД ПРИЧ ПРОШ ЕД МУЖ ТВОР
V СОВ СТРАД ПРИЧ ПРОШ ЕД СРЕД ВИН
V СОВ СТРАД ПРИЧ ПРОШ ЕД СРЕД ИМ
V СОВ СТРАД ПРИЧ ПРОШ ЕД СРЕД ПР
V СОВ СТРАД ПРИЧ ПРОШ ЕД СРЕД РОД
V СОВ СТРАД ПРИЧ ПРОШ ЕД СРЕД ТВОР
V СОВ СТРАД ПРИЧ ПРОШ КР ЕД ЖЕН
V СОВ СТРАД ПРИЧ ПРОШ КР ЕД МУЖ
V СОВ СТРАД ПРИЧ ПРОШ КР ЕД СРЕД
V СОВ СТРАД ПРИЧ ПРОШ КР МН
V СОВ СТРАД ПРИЧ ПРОШ МН ВИН НЕОД
V СОВ СТРАД ПРИЧ ПРОШ МН ВИН ОД
V СОВ СТРАД ПРИЧ ПРОШ МН ДАТ
V СОВ СТРАД ПРИЧ ПРОШ МН ИМ
V СОВ СТРАД ПРИЧ ПРОШ МН ПР
V СОВ СТРАД ПРИЧ ПРОШ МН РОД
V СОВ СТРАД ПРИЧ ПРОШ МН ТВОР
end_of_list
    ;
    # Protect from editors that replace tabs by spaces.
    $list =~ s/ \s+/\t/sg;
    my @list = split(/\r?\n/, $list);
    pop(@list) if($list[$#list] eq "");
    return \@list;
}



#------------------------------------------------------------------------------
# Create trie of permitted feature structures. This will be needed for strict
# encoding. This BEGIN block cannot appear before the definition of the list()
# function.
#------------------------------------------------------------------------------
BEGIN
{
    my $list = list();
    # Store the hash reference in a global variable.
    $permitted = tagset::common::get_permitted_structures_joint($list, \&decode);
}



1;
