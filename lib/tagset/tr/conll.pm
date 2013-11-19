#!/usr/bin/perl
# Interset driver for the CoNLL 2007 Turkish tags (derived from the METU Sabanci corpus)
# Copyright © 2011, 2013 Dan Zeman <zeman@ufal.mff.cuni.cz>, Loganathan Ramasamy <ramasamy@ufal.mff.cuni.cz>
# License: GNU GPL

package tagset::tr::conll;
use utf8;
use open ':utf8';



#------------------------------------------------------------------------------
# Takes tag string.
# Returns feature hash.
#------------------------------------------------------------------------------
sub decode
{
    my $tag = shift;
    my %f; # features
    $f{tagset} = 'tr::conll';
    # three components: coarse-grained pos, fine-grained pos, features
    my ($pos, $subpos, $features) = split(/\s+/, $tag);

    # nouns
    # Noun Noun A3sg|Pnon|Nom examples: şey (thing), gün (day), zaman (time), kadın (woman), yıl (year)
    if($pos eq 'Noun')
    {
        $f{pos} = "noun";

        if ($subpos eq "NFutPart") {
            $f{verbform} = "part";
            $f{tense} = "fut";
        }
        elsif ($subpos eq "NPastPart") {
            $f{verbform} = "part";
            $f{tense} = "past";
        }
        elsif ($subpos eq "NPresPart") {
            $f{verbform} = "part";
            $f{tense} = "pres";
        }
        elsif ($subpos eq "NInf") {
            $f{verbform} = "inf";
        }
        elsif ($subpos eq "Prop") {
            $f{subpos} = "prop";
        }

    }
    # Documentation (https://wiki.ufal.ms.mff.cuni.cz/_media/user:zeman:treebanks:ttbankkl.pdf page 25):
    # +Dup category contains onomatopoeia words (zvukomalebná slova) which only appear as duplications in a sentence.
    # Some of them could be considered interjections, some others (or in some contexts) not.
    # Syntactically they may probably act as various parts of speech. Adjectives? Adverbs? Verbs? Nouns?
    # There are only about ten examples in the corpus.
    elsif ($pos eq 'Dup') {
        $f{pos} = '';
        $f{echo} = 'rdp';
    }
    # Question particle "mi". It inflects for person, number and tense.
    elsif ($pos eq 'Ques') {
        $f{pos} = 'part';
        $f{prontype} = 'int';
    }

    # pronouns
    elsif ($pos eq 'Pron') {
        $f{pos} = 'noun';

        if ($subpos eq 'DemonsP') {
            $f{prontype} = 'dem';
        }
        elsif ($subpos eq 'PersP') {
            $f{prontype} = 'prs';
        }
        elsif ($subpos eq 'Pron') {
            # "Pron Pron" contains a heterogenous group of pronouns. Reciprocal pronouns seem to constitute a large part of it.
            # Example: birbirimizi (each other)
            $f{prontype} = 'rcp';
        }
        elsif ($subpos eq 'QuesP') {
            $f{prontype} = 'int';
        }
        elsif ($subpos eq 'ReflexP') {
            $f{reflex} = 'reflex';
        }
    }

    # adjectives
    elsif($pos eq 'Adj')
    {
        $f{pos} = "adj";

        if ($subpos eq "AFutPart") {
            $f{verbform} = "part";
            $f{tense} = "fut";
        }
        elsif ($subpos eq "APastPart") {
            $f{verbform} = "part";
            $f{tense} = "past";
        }
        elsif ($subpos eq "APresPart") {
            $f{verbform} = "part";
            $f{tense} = "pres";
        }
    }
    # determiners
    elsif ($pos eq 'Det') {
        $f{pos} = 'adj';
        $f{subpos} = 'det';
    }

    # numeral
    elsif($pos eq 'Num')
    {
        $f{pos} = "num";

        if ($subpos eq 'Card') {
            $f{numtype} = "card";
        }
        elsif ($subpos eq 'Distrib') {
            $f{numtype} = 'dist';
        }
        elsif ($subpos eq 'Ord') {
            $f{numtype} = "ord";
        }
        elsif ($subpos eq "Real") {
            $f{numform} = "digit";
        }
        elsif ($subpos eq "Range") {
            $f{numtype} = "range";
        }
    }

    # v = verb
    elsif ($pos eq 'Verb')
    {
        $f{pos} = 'verb';
        # Two possible subposes: Verb and Zero.
        # Documentation: "A +Zero appears after a zero morpheme derivation."
        # So it does not seem as something one would necessarily want to preserve.
        if($subpos eq 'Zero')
        {
            $f{other}{zero} = 1;
        }
    }

    # adverb
    elsif($pos eq "Adv")
    {
        $f{pos} = "adv";
    }

    # postposition
    elsif($pos eq 'Postp')
    {
        $f{pos} = "prep";
    }

    # conjunction
    elsif($pos eq "Conj")
    {
        $f{pos} = "conj";
    }

    # interjection
    elsif($pos eq "Interj")
    {
        $f{pos} = "int";
    }

    # punctuation
    elsif($pos eq "Punc")
    {
        $f{pos} = "punc";
    }


    # Decode feature values.
    my @features = split(/\|/, $features);
    foreach my $feature (@features)
    {
        # Adjectives
        # Adj Adj _ examples: büyük (big), yeni (new), iyi (good), aynı (same), çok (many)
        # Adj Adj Agt examples: üretici (manufacturing), ürkütücü (scary), rahatlatıcı (relaxing), yakıcı (burning), barışçı (pacific)
        # Adj Adj AsIf examples: böylece (so that), onca (all that), delice (insane), aptalca (stupid), çılgınca (wild)
        # Adj Adj FitFor examples: dolarlık (in dollars), yıllık (annual), saatlik (hourly), trilyonluk (trillions worth), liralık (in pounds)
        # Adj Adj InBetween example: uluslararası (international)
        # Adj Adj JustLike example: konyakımsı (just like brandy), redingotumsu (just like redingot)
        # Adj Adj Rel examples: önceki (previous), arasındaki (in-between), içindeki (intra-), üzerindeki (upper), öteki (other)
        # Adj Adj Related examples: ideolojik (ideological), teknolojik (technological), meteorolojik (meteorological), bilimsel (scientific), psikolojik (psychological)
        # Adj Adj With examples: önemli (important), ilgili (related), vadeli (forward), yaşlı (elderly), yararlı (helpful)
        # Adj Adj Without examples: sessiz (quiet), savunmasız (vulnerable), anlamsız (meaningless), gereksiz (unnecessary), rahatsız (uncomfortable)
        if($feature =~ m/^(Agt|AsIf|FitFor|InBetween|JustLike|Rel|Related|With|Without)$/)
        {
            # Merge adjtype and advtype into one feature so that we do not have to distinguish them later on encoding.
            $f{other}{advtype} = $feature;
        }

        # Adverbs
        # The non-"_" non-Ly non-Since adverbs seem to be derived from verbs, i.e. they could be called adverbial participles (transgressives).
        # Adv Adv _ examples: daha (more), çok (very), en (most), bile (even), hiç (never)
        # Adv Adv Ly examples: hafifçe (slightly), rahatça (easily), iyice (thoroughly), öylece (just), aptalca (stupidly)
        # Adv Adv Since examples: yıldır (for years), yıllardır (for years), saattir (for hours)
        # Adv Adv AfterDoingSo examples: gidip (having gone), gelip (having come), deyip (having said), kesip (having cut out), çıkıp (having gotten out)
        # Adv Adv As examples: istemedikçe (unless you want to), arttıkça (as increases), konuştukça (as you talk), oldukça (rather), gördükçe (as you see)
        # Adv Adv AsIf examples: güneşiymişçesine, okumuşçasına (as if reads), etmişçesine, taparcasına (as if worships), okşarcasına (as if strokes)
        # Adv Adv ByDoingSo examples: olarak (by being), diyerek (by saying), belirterek (by specifying), koşarak (by running), çekerek (by pulling)
        # Adv Adv SinceDoingSo examples: olalı (since being), geleli (since coming), dönüşeli (since returning), başlayalı (since starting), kapılalı
        # Adv Adv When examples: görünce (when/on seeing), deyince (when we say), olunca (when), açılınca (when opening), gelince (when coming)
        # Adv Adv While examples: giderken (en route), konuşurken (while talking), derken (while saying), çıkarken (on the way out), varken (when there is)
        # Adv Adv WithoutHavingDoneSo examples: olmadan (without being), düşünmeden (without thinking), geçirmeden (without passing), çıkarmadan (without removing), almadan (without taking)
        if($feature =~ m/^(AfterDoingSo|As|AsIf|ByDoingSo|SinceDoingSo|When|While|WithoutHavingDoneSo)$/)
        {
            $f{verbform} = 'trans';
            $f{other}{advtype} = $feature;
        }
        elsif($feature =~ m/^(Ly|Since)$/)
        {
            $f{other}{advtype} = $feature;
        }

        # gender
        $f{gender} = "masc" if $feature eq "Ma";
        $f{gender} = "fem" if $feature eq "Fe";
        $f{gender} = "neut" if $feature eq "Ne";

        # agreement
        # person
        $f{person} = "1" if ($feature =~ /^A1(sg|pl)$/);
        $f{person} = "2" if ($feature =~ /^A2(sg|pl)$/);
        $f{person} = "3" if ($feature =~ /^A3(sg|pl)$/);
        # number
        $f{number} = "sing" if ($feature =~ /^A(1|2|3)sg$/);
        $f{number} = "plu" if ($feature =~ /^A(1|2|3)pl$/);

        # possessive agreement
        # person
        $f{possperson} = "1" if ($feature =~ /^P1(sg|pl)$/);
        $f{possperson} = "2" if ($feature =~ /^P2(sg|pl)$/);
        $f{possperson} = "3" if ($feature =~ /^P3(sg|pl)$/);
        # number
        $f{possnumber} = "sing" if ($feature =~ /^P(1|2|3)sg$/);
        $f{possnumber} = "plu" if ($feature =~ /^P(1|2|3)pl$/);
        # Pnon = no overt agreement

        # case features
        $f{case} = "nom" if $feature =~ m/^(PC)?Nom$/;
        $f{case} = "gen" if $feature =~ m/^(PC)?Gen$/;
        $f{case} = "acc" if $feature =~ m/^(PC)?Acc$/;
        $f{case} = "abl" if $feature =~ m/^(PC)?Abl$/;
        $f{case} = "dat" if $feature =~ m/^(PC)?Dat$/;
        $f{case} = "loc" if $feature =~ m/^(PC)?Loc$/;
        $f{case} = "ins" if $feature =~ m/^(PC)?Ins$/;
        # There is also the 'Equ' feature. It seems to appear in place of case but it is not documented.
        # And descriptions of Turkish grammar that I have seen do not list other cases than the above.
        # Nevertheless, until further notice, I am going to use another case value to store the feature.
        $f{case} = 'com' if($feature eq 'Equ');

        $f{degree} = "comp" if $feature eq "Cp";
        $f{degree} = "sup" if $feature eq "Su";

        # Compounding and modality features (here explained on the English verb "to do"; Turkish examples are not translations of "to do"!)
        # +Able ... able to do ... examples: olabilirim, olabilirsin, olabilir ... bunu demis olabilirim = I may have said (demis = said)
        # +Repeat ... do repeatedly ... no occurrence
        # +Hastily ... do hastily ... examples: aliverdi, doluverdi, gidiverdi
        # +EverSince ... have been doing ever since ... no occurrence
        # +Almost ... almost did but did not ... no occurrence
        # +Stay ... stayed frozen whlie doing ... just two examples: şaşakalmıştık, uyuyakalmıştı (Google translates the latter as "fallen asleep")
        # +Start ... start doing immediately ... no occurrence
        ###!!! Loganathan's solution of marking the verbs as auxiliaries is not ideal. These are normal verb stems but with additional morphemes.
        $f{subpos} = "aux" if $feature eq "Able";
        $f{subpos} = "aux" if $feature eq "Repeat";
        $f{subpos} = "aux" if $feature eq "Start";
        $f{subpos} = "aux" if $feature eq "Hastily";
        $f{subpos} = "aux" if $feature eq "Stay";
        $f{subpos} = "aux" if $feature eq "EverSince";
        $f{subpos} = "aux" if $feature eq "Almost";
        # Verbs derived from nouns or adjectives:
        1 if($feature eq 'Acquire'); # to acquire the noun
        1 if($feature eq 'Become'); # to become the noun

        # The "Pres" tag is not frequent.
        # It occurs with "Verb Zero" more often than with "Verb Verb". It often occurs with copulae ("Cop").
        # According to documentation, it is intended for predicative nominals or adjectives.
        # Pres|Cop|A3sg examples: vardır (there are), yoktur (there is no), demektir (means), sebzedir, nedir (what is the)
        $f{tense} = "pres" if $feature eq "Pres";
        # The "Fut" tag can be combined with "Past" and occasionally with "Narr".
        # Pos|Fut|A3sg examples: olacak (will), verecek (will give), gelecek, sağlayacak, yapacak
        # Pos|Fut|Past|A3sg examples: olacaktı (would), öğrenecekti (would learn), yapacaktı (would make), ölecekti, sokacaktı
        $f{tense} = "fut" if $feature eq "Fut";
        # Pos|Past|A3sg examples: dedi (said), oldu (was), söyledi (said), geldi (came), sordu (asked)
        # Pos|Prog1|Past|A3sg examples: geliyordu (was coming), oturuyordu (was sitting), bakıyordu, oluyordu, titriyordu
        if($feature eq 'Past')
        {
            # Is it combined with another tense? At most two tenses can be combined together.
            if($f{tense} eq 'narr')
            {
                $f{tense} = ['narr', 'past'];
            }
            elsif($f{tense} eq 'fut')
            {
                $f{tense} = ['fut', 'past'];
            }
            else
            {
                $f{tense} = 'past';
            }
        }
        # Pos|Narr|A3sg examples: olmuş (was), demiş (said), bayılmış (fainted), gelmiş (came), çıkmış (emerged)
        # Pos|Narr|Past|A3sg examples: başlamıştı (started), demişti (said), gelmişti (was), geçmişti (passed), kalkmıştı (sailed)
        # Pos|Prog1|Narr|A3sg examples: oluyormuş (was happening), bakıyormuş (was staring), çırpınıyormuş, yaşıyormuş, istiyormuş
        # enwiki:
        # The definite past or di-past is used to assert that something did happen in the past.
        # The inferential past or miş-past can be understood as asserting that a past participle is applicable now;
        # hence it is used when the fact of a past event, as such, is not important;
        # in particular, the inferential past is used when one did not actually witness the past event.
        # A newspaper will generally use the di-past, because it is authoritative.
        if($feature eq 'Narr')
        {
            # Is it combined with another tense? At most two tenses can be combined together.
            if($f{tense} eq 'fut')
            {
                $f{tense} = ['fut', 'narr'];
            }
            else
            {
                $f{tense} = 'narr';
            }
        }
        # Pos|Aor|A3sg examples: olur (will), gerekir (must), yeter (is enough), alır (takes), gelir (income)
        # Pos|Aor|Narr|A3sg examples: olurmuş (bustled), inanırmış, severmiş (loved), yaşarmış (lived), bitermiş
        # Pos|Aor|Past|A3sg examples: olurdu (would), otururdu (sat), yapardı (would), bilirdi (knew), derdi (used to say)
        # enwiki:
        # In Turkish the aorist is a habitual aspect. (Geoffrey Lewis, Turkish Grammar (2nd ed, 2000, Oxford))
        # So it is not a tense (unlike e.g. Bulgarian aorist) and it can be combined with tenses.
        # Habitual aspect means repetitive actions (they take place "usually"). It is a type of imperfective aspect.
        # English has habitual past: "I used to visit him frequently."
        $f{subtense} = "aor" if $feature eq "Aor";
        # Documentation calls the following two tenses "present continuous".
        # Prog1 = "present continuous, process"
        # Prog2 = "present continuous, state"
        # However, there are also combinations with past tags, e.g. "Prog1|Past".
        # Pos|Prog1|A3sg examples: diyor (is saying), geliyor (is coming), oluyor (is being), yapıyor (is doing), biliyor (is knowing)
        # Pos|Prog1|Past|A3sg examples: geliyordu (was coming), oturuyordu (was sitting), bakıyordu, oluyordu, titriyordu
        # Pos|Prog1|Narr|A3sg examples: oluyormuş (was happening), bakıyormuş (was staring), çırpınıyormuş, yaşıyormuş, istiyormuş
        $f{aspect} = "prog" if $feature eq "Prog1";
        # Pos|Prog2|A3sg examples: oturmakta (is sitting), kapamakta (is closing), soymakta (is peeling), kullanmakta, taşımakta
        if($feature eq 'Prog2')
        {
            $f{aspect} = 'prog';
            $f{variant} = 2;
        }
        # mood: wish-must case (dilek-şart kipi)
        # Pos|Imp|A2sg examples: var (be), gerek (need), bak (look), kapa (expand), anlat (tell)
        $f{mood} = "imp" if $feature eq "Imp";
        # Pos|Neces|A3sg examples: olmalı (should be), almalı (should buy), sağlamalı (should provide), kapsamalı (should cover)
        $f{mood} = "nec" if $feature eq "Neces";
        # Optative mood (indicates a wish or hope). "May you have a long life! If only I were rich!"
        # Oflazer: "Let me/him/her do..." / "Kéž by ..."
        # Pos|Opt|A3sg examples: diye (if only said), sevine (if only exulted), güle (if only laughed), ola (if only were), otura (if only sat)
        $f{mood} = "opt" if $feature eq "Opt";
        ###!!! What's the difference between Desr and Cond?
        # Pos|Desr|A3sg examples: olsa (wants to be), ise, varsa, istese (if wanted), bıraksa (wants to leave)
        $f{mood} = "des" if $feature eq "Desr";
        # Pos|Aor|Cond|A3sg examples: verirse (if), isterse, kalırsa (if remains), başlarsa (if begins), derse
        # Pos|Fut|Cond|A3sg example: olacaksa (if will)
        # Pos|Narr|Cond|A3sg example: oturmuşsa
        # Pos|Past|Cond|A3sg example: olduysa (if (would have been)), uyuduysa
        # Pos|Prog1|Cond|A3sg examples: geliyorsa (would be coming), öpüyorsa, uyuşuyorsa, seviyorsa (would be loving)
        $f{mood} = "cnd" if $feature eq "Cond";

        # negativeness
        # Pos|Prog1|A3sg examples: diyor (is saying), geliyor (is coming), oluyor (is being), yapıyor (is doing), biliyor (is knowing)
        # Neg|Prog1|A3sg examples: olmuyor (is not), tutmuyor (does not match), bilmiyor (does not know), gerekmiyor, benzemiyor
        $f{negativeness} = "pos" if $feature eq "Pos";;
        $f{negativeness} = "neg" if $feature eq "Neg";;

        # voice
        # Pass|Pos|Past|A3sg examples: belirtildi (was said), söylendi (was told), istendi (was asked), öğrenildi (was learned), kaldırıldı
        $f{voice} = "pass" if $feature eq "Pass";
        # Reflex|Pos|Prog1|A3sg example: hazırlanıyor (is preparing itself)
        $f{reflex} = 'reflex' if($feature eq 'Reflex');
        # Recip|Pos|Past|A3sg example: karıştı (confused each other?)
        $f{voice} = 'rcp' if($feature eq 'Recip');
        # Caus ... causative
        # Oflazer's documentation classifies this as a value of the voice feature.
        # Caus|Pos|Narr|A3sg examples: bastırmış (suppressed), bitirmiş (completed), oluşturmuş (created), çoğaltmış (multiplied), çıkartmış (issued)
        # Caus|Pos|Past|A3sg examples: belirtti (said), bildirdi (reported), uzattı (extended), indirdi (reduced), sürdürdü (continued)
        # Caus|Pos|Prog1|A3sg examples: karıştırıyor (is confusing), korkutuyor (is scaring), geçiriyor (is taking), koparıyor (is breaking), döktürüyor
        # Caus|Pos|Prog1|Past|A3sg examples: karıştırıyordu (was scooping), geçiriyordu (was giving), dolduruyordu (was filling), sürdürüyordu (was continuing), azaltıyordu (was diminishing)
        $f{voice} = "cau" if $feature eq "Caus";

        # Copula in Turkish is not an independent word. It is a bound morpheme (tur/tır/tir/dur etc.)
        # It is not clear to me though, what meaning it adds when attached to a verb.
        # Pos|Narr|Cop|A3sg examples: olmuştur (has been), açmıştır (has led), ulaşmıştır (has reached), başlamıştır, gelmiştir
        # Pos|Prog1|Cop|A3sg examples: oturuyordur (is sitting), öpüyordur (is kissing), tanıyordur (knows)
        # Pos|Fut|Cop|A3sg examples: olacaktır (will), akacaktır (will flow), alacaktır (will take), çarpacaktır, görecektir
        $f{subpos} = 'cop' if($feature eq 'Cop');

    }
    return \%f;
}



#------------------------------------------------------------------------------
# Takes feature hash.
# Returns tag string.
#------------------------------------------------------------------------------
sub encode
{
    my $f0 = shift;
    my $nonstrict = shift; # strict is default
    $strict = !$nonstrict;
    # Modify the feature structure so that it contains values expected by this
    # driver.
    my $f = tagset::common::enforce_permitted_joint($f0, $permitted);
    my %f = %{$f}; # This is not a deep copy but $f already refers to a deep copy of the original %{$f0}.
    my $tag;
    # pos and subpos
    # There are the following values of CPOS. I suspect that Zero could be merged with Verb.
    # There are only two occurrences of CPOS=Zero in the corpus. Both have POS=Verb and FORM=yok.
    # There are 21 other occurrences of FORM=yok that have CPOS=Verb and POS=Zero. So swapped Zero Verb occurred just by mistake.
    # Adj Adv Conj Det Dup Interj Noun Num Postp Pron Punc Ques Verb Zero
    if($f{echo} eq 'rdp')
    {
        $tag = "Dup\tDup";
    }
    elsif($f{pos} eq 'adj')
    {
        if($f{subpos} eq 'det')
        {
            $tag = "Det\tDet";
        }
        elsif($f{verbform} eq 'part')
        {
            if($f{tense} eq 'fut')
            {
                $tag = "Adj\tAFutPart";
            }
            elsif($f{tense} eq 'past')
            {
                $tag = "Adj\tAPastPart";
            }
            else
            {
                $tag = "Adj\tAPresPart";
            }
        }
        else
        {
            $tag = "Adj\tAdj";
        }
    }
    elsif($f{pos} eq 'adv')
    {
        $tag = "Adv\tAdv";
    }
    elsif($f{pos} eq 'conj')
    {
        $tag = "Conj\tConj";
    }
    elsif($f{pos} eq 'int')
    {
        $tag = "Interj\tInterj";
    }
    elsif($f{pos} eq 'noun')
    {
        if($f{reflex} eq 'reflex')
        {
            $tag = "Pron\tReflexP";
        }
        elsif($f{prontype} eq 'prs')
        {
            $tag = "Pron\tPersP";
        }
        elsif($f{prontype} eq 'rcp')
        {
            $tag = "Pron\tPron";
        }
        elsif($f{prontype} eq 'dem')
        {
            $tag = "Pron\tDemonsP";
        }
        elsif($f{prontype} eq 'int')
        {
            $tag = "Pron\tQuesP";
        }
        elsif($f{subpos} eq 'prop')
        {
            $tag = "Noun\tProp";
        }
        elsif($f{verbform} eq 'part')
        {
            if($f{tense} eq 'fut')
            {
                $tag = "Noun\tNFutPart";
            }
            elsif($f{tense} eq 'past')
            {
                $tag = "Noun\tNPastPart";
            }
            else
            {
                $tag = "Noun\tNPresPart";
            }
        }
        elsif($f{verbform} eq 'inf')
        {
            $tag = "Noun\tNInf";
        }
        else
        {
            $tag = "Noun\tNoun";
        }
    }
    elsif($f{pos} eq 'num')
    {
        if($f{numform} eq 'digit')
        {
            $tag = "Num\tReal";
        }
        elsif($f{numtype} eq 'card')
        {
            $tag = "Num\tCard";
        }
        elsif($f{numtype} eq 'ord')
        {
            $tag = "Num\tOrd";
        }
        elsif($f{numtype} eq 'dist')
        {
            $tag = "Num\tDistrib";
        }
        elsif($f{numtype} eq 'range')
        {
            $tag = "Num\tRange";
        }
        else
        {
            $tag = "Num\tNum";
        }
    }
    elsif($f{pos} eq 'part')
    {
        $tag = "Ques\tQues";
    }
    elsif($f{pos} eq 'prep')
    {
        $tag = "Postp\tPostp";
    }
    elsif($f{pos} eq 'punc')
    {
        $tag = "Punc\tPunc";
    }
    elsif($f{pos} eq 'verb')
    {
        if($f{tagset} eq 'tr::conll' && $f{other}{zero})
        {
            $tag = "Verb\tZero";
        }
        else
        {
            $tag = "Verb\tVerb";
        }
    }
    else ###!!! What will be the default part of speech?
    {
    }
    # Add the features to the part of speech.
    my $features = encode_features(\%f);
    $tag .= "\t$features";
    return $tag;
}



my %enfeatable =
(
    'gender' =>
    {
        'masc' => 'Ma',
        'fem'  => 'Fe',
        'neut' => 'Ne'
    },
    'number' =>
    {
        'sing' => 'sg',
        'plu'  => 'pl'
    },
    'case' =>
    {
        'nom' => 'Nom',
        'gen' => 'Gen',
        'acc' => 'Acc',
        'abl' => 'Abl',
        'dat' => 'Dat',
        'loc' => 'Loc',
        'ins' => 'Ins',
        'com' => 'Equ'
    },
    'degree' =>
    {
        'comp' => 'Cp',
        'sup'  => 'Su'
    },
    'mood' =>
    {
        'cnd' => 'Cond',
        'imp' => 'Imp',
        'nec' => 'Neces',
        'des' => 'Desr',
        'opt' => 'Opt'
    },
    'tense' =>
    {
        'past' => 'Past',
        'narr' => 'Narr',
        'pres' => 'Pres',
        'fut'  => 'Fut'
    },
    'voice' =>
    {
        'pass' => 'Pass',
        'rcp'  => 'Recip',
        'cau'  => 'Caus'
    },
    'negativeness' =>
    {
        'pos' => 'Pos',
        'neg' => 'Neg'
    },
    'reflex' =>
    {
        'reflex' => 'Reflex'
    }
);



#------------------------------------------------------------------------------
# Takes feature hash.
# Returns feature string.
#------------------------------------------------------------------------------
sub encode_features
{
    my $f = shift;
    # Add the features to the part of speech.
    my @features;
    foreach my $feature ('voice', 'reflex', 'negativeness', 'aspect', 'mood', 'tense', 'copula', 'agreement', 'possagreement', 'case', 'advtype')
    {
        # There are reflexive pronouns and reflexive verbs. For pronouns, reflexivity is treated as POS, not FEAT.
        if($feature eq 'reflex' && $f->{pos} ne 'verb')
        {
            next;
        }
        elsif($feature eq 'tense')
        {
            next if($f->{pos} =~ m/^(noun|adj)$/);
            if($f->{subtense} eq 'aor')
            {
                push(@features, 'Aor');
            }
            # Aorist can be combined with Past or Narr.
            if(ref($f->{tense}) eq 'ARRAY' && $f->{tense}[0] =~ m/^(fut|narr)$/ && $f->{tense}[1] =~ m/^(narr|past)$/)
            {
                push(@features, $enfeatable{tense}{$f->{tense}[0]}, $enfeatable{tense}{$f->{tense}[1]});
            }
            elsif($f->{tense} =~ m/^(past|narr|pres|fut)$/)
            {
                push(@features, $enfeatable{tense}{$f->{tense}});
            }
        }
        elsif($feature eq 'aspect')
        {
            if($f->{aspect} eq 'prog')
            {
                if($f->{variant} eq '2')
                {
                    push(@features, 'Prog2');
                }
                else
                {
                    push(@features, 'Prog1');
                }
            }
        }
        elsif($feature eq 'copula')
        {
            if($f->{subpos} eq 'cop')
            {
                push(@features, 'Cop');
            }
        }
        elsif($feature eq 'agreement')
        {
            if($f->{person} =~ m/^[123]$/ && $f->{number} =~ m/^(sing|plu)$/)
            {
                my $agreement = "A$f->{person}$enfeatable{number}{$f->{number}}";
                push(@features, $agreement);
            }
        }
        elsif($feature eq 'possagreement')
        {
            if($f->{possperson} =~ m/^[123]$/ && $f->{possnumber} =~ m/^(sing|plu)$/)
            {
                my $agreement = "P$f->{possperson}$enfeatable{number}{$f->{possnumber}}";
                push(@features, $agreement);
            }
            elsif($f->{pos} eq 'noun' || $f->{pos} eq 'adj' && $f->{verbform} eq 'part' && $f->{tense} =~ m/^(fut|past)$/)
            {
                push(@features, 'Pnon');
            }
        }
        elsif($feature eq 'case')
        {
            my $value = $f->{$feature};
            if(exists($enfeatable{$feature}{$value}))
            {
                my $outfeature = $enfeatable{$feature}{$value};
                if($f->{pos} eq 'prep')
                {
                    $outfeature = 'PC'.$outfeature;
                }
                push(@features, $outfeature);
            }
        }
        elsif($feature eq 'advtype')
        {
            if(exists($f->{other}{advtype}))
            {
                push(@features, $f->{other}{advtype});
            }
        }
        else
        {
            my $value = $f->{$feature};
            if(exists($enfeatable{$feature}{$value}))
            {
                push(@features, $enfeatable{$feature}{$value});
            }
        }
    }
    my $features = join("|", @features);
    if($features eq "")
    {
        $features = "_";
    }
    return $features;
}



#------------------------------------------------------------------------------
# Returns reference to list of known tags.
# cat train.conll test.conll |\
#   perl -pe '@x = split(/\s+/, $_); $_ = "$x[3]\t$x[4]\t$x[5]\n"' |\
#   sort -u | wc -l
# 1074
# 1072 after cleaning ###!!!???and adding 'other'-resistant tags
#------------------------------------------------------------------------------
sub list
{
    my $list = <<end_of_list
Adj	Adj	_
Adj	Adj	Agt
Adj	Adj	AsIf
Adj	Adj	FitFor
Adj	Adj	InBetween
Adj	Adj	JustLike
Adj	Adj	Rel
Adj	Adj	Related
Adj	Adj	With
Adj	Adj	Without
Adj	AFutPart	P1pl
Adj	AFutPart	P1sg
Adj	AFutPart	P3pl
Adj	AFutPart	P3sg
Adj	AFutPart	Pnon
Adj	APastPart	P1pl
Adj	APastPart	P1sg
Adj	APastPart	P2pl
Adj	APastPart	P2sg
Adj	APastPart	P3pl
Adj	APastPart	P3sg
Adj	APastPart	Pnon
Adj	APresPart	_
Adj	Zero	_
Adv	Adv	_
Adv	Adv	AfterDoingSo
Adv	Adv	As
Adv	Adv	AsIf
Adv	Adv	ByDoingSo
Adv	Adv	Ly
Adv	Adv	Since
Adv	Adv	SinceDoingSo
Adv	Adv	When
Adv	Adv	While
Adv	Adv	WithoutHavingDoneSo
Conj	Conj	_
Det	Det	_
Dup	Dup	_
Interj	Interj	_
Noun	NFutPart	A3pl|P1sg|Nom
Noun	NFutPart	A3pl|P3pl|Acc
Noun	NFutPart	A3pl|P3pl|Dat
Noun	NFutPart	A3pl|P3pl|Nom
Noun	NFutPart	A3pl|P3sg|Acc
Noun	NFutPart	A3pl|P3sg|Nom
Noun	NFutPart	A3pl|Pnon|Acc
Noun	NFutPart	A3pl|Pnon|Gen
Noun	NFutPart	A3pl|Pnon|Nom
Noun	NFutPart	A3sg|P1pl|Abl
Noun	NFutPart	A3sg|P1pl|Acc
Noun	NFutPart	A3sg|P1pl|Dat
Noun	NFutPart	A3sg|P1pl|Nom
Noun	NFutPart	A3sg|P1sg|Acc
Noun	NFutPart	A3sg|P1sg|Dat
Noun	NFutPart	A3sg|P1sg|Nom
Noun	NFutPart	A3sg|P2pl|Dat
Noun	NFutPart	A3sg|P2sg|Abl
Noun	NFutPart	A3sg|P2sg|Acc
Noun	NFutPart	A3sg|P2sg|Nom
Noun	NFutPart	A3sg|P3pl|Abl
Noun	NFutPart	A3sg|P3pl|Acc
Noun	NFutPart	A3sg|P3pl|Nom
Noun	NFutPart	A3sg|P3sg|Abl
Noun	NFutPart	A3sg|P3sg|Acc
Noun	NFutPart	A3sg|P3sg|Dat
Noun	NFutPart	A3sg|P3sg|Gen
Noun	NFutPart	A3sg|P3sg|Nom
Noun	NInf	A3pl|P1sg|Dat
Noun	NInf	A3pl|P1sg|Loc
Noun	NInf	A3pl|P1sg|Nom
Noun	NInf	A3pl|P3pl|Acc
Noun	NInf	A3pl|P3pl|Dat
Noun	NInf	A3pl|P3pl|Ins
Noun	NInf	A3pl|P3pl|Nom
Noun	NInf	A3pl|P3sg|Abl
Noun	NInf	A3pl|P3sg|Acc
Noun	NInf	A3pl|P3sg|Dat
Noun	NInf	A3pl|P3sg|Gen
Noun	NInf	A3pl|P3sg|Ins
Noun	NInf	A3pl|P3sg|Loc
Noun	NInf	A3pl|P3sg|Nom
Noun	NInf	A3pl|Pnon|Abl
Noun	NInf	A3pl|Pnon|Acc
Noun	NInf	A3pl|Pnon|Dat
Noun	NInf	A3pl|Pnon|Gen
Noun	NInf	A3pl|Pnon|Ins
Noun	NInf	A3pl|Pnon|Loc
Noun	NInf	A3pl|Pnon|Nom
Noun	NInf	A3sg|P1pl|Abl
Noun	NInf	A3sg|P1pl|Acc
Noun	NInf	A3sg|P1pl|Loc
Noun	NInf	A3sg|P1pl|Nom
Noun	NInf	A3sg|P1sg|Abl
Noun	NInf	A3sg|P1sg|Acc
Noun	NInf	A3sg|P1sg|Dat
Noun	NInf	A3sg|P1sg|Gen
Noun	NInf	A3sg|P1sg|Nom
Noun	NInf	A3sg|P2pl|Acc
Noun	NInf	A3sg|P2pl|Dat
Noun	NInf	A3sg|P2pl|Nom
Noun	NInf	A3sg|P2sg|Acc
Noun	NInf	A3sg|P2sg|Nom
Noun	NInf	A3sg|P3pl|Dat
Noun	NInf	A3sg|P3pl|Gen
Noun	NInf	A3sg|P3pl|Ins
Noun	NInf	A3sg|P3pl|Nom
Noun	NInf	A3sg|P3sg|Abl
Noun	NInf	A3sg|P3sg|Acc
Noun	NInf	A3sg|P3sg|Dat
Noun	NInf	A3sg|P3sg|Gen
Noun	NInf	A3sg|P3sg|Ins
Noun	NInf	A3sg|P3sg|Loc
Noun	NInf	A3sg|P3sg|Nom
Noun	NInf	A3sg|Pnon|Abl
Noun	NInf	A3sg|Pnon|Acc
Noun	NInf	A3sg|Pnon|Dat
Noun	NInf	A3sg|Pnon|Gen
Noun	NInf	A3sg|Pnon|Ins
Noun	NInf	A3sg|Pnon|Loc
Noun	NInf	A3sg|Pnon|Nom
Noun	Noun	A1pl|P3sg|Nom
Noun	Noun	A3pl|P1pl|Abl
Noun	Noun	A3pl|P1pl|Acc
Noun	Noun	A3pl|P1pl|Dat
Noun	Noun	A3pl|P1pl|Gen
Noun	Noun	A3pl|P1pl|Ins
Noun	Noun	A3pl|P1pl|Loc
Noun	Noun	A3pl|P1pl|Nom
Noun	Noun	A3pl|P1sg|Abl
Noun	Noun	A3pl|P1sg|Acc
Noun	Noun	A3pl|P1sg|Dat
Noun	Noun	A3pl|P1sg|Gen
Noun	Noun	A3pl|P1sg|Ins
Noun	Noun	A3pl|P1sg|Loc
Noun	Noun	A3pl|P1sg|Nom
Noun	Noun	A3pl|P2pl|Abl
Noun	Noun	A3pl|P2pl|Acc
Noun	Noun	A3pl|P2pl|Dat
Noun	Noun	A3pl|P2pl|Gen
Noun	Noun	A3pl|P2pl|Loc
Noun	Noun	A3pl|P2pl|Nom
Noun	Noun	A3pl|P2sg|Abl
Noun	Noun	A3pl|P2sg|Acc
Noun	Noun	A3pl|P2sg|Dat
Noun	Noun	A3pl|P2sg|Gen
Noun	Noun	A3pl|P2sg|Ins
Noun	Noun	A3pl|P2sg|Nom
Noun	Noun	A3pl|P3pl|Abl
Noun	Noun	A3pl|P3pl|Acc
Noun	Noun	A3pl|P3pl|Dat
Noun	Noun	A3pl|P3pl|Gen
Noun	Noun	A3pl|P3pl|Ins
Noun	Noun	A3pl|P3pl|Loc
Noun	Noun	A3pl|P3pl|Nom
Noun	Noun	A3pl|P3sg|Abl
Noun	Noun	A3pl|P3sg|Acc
Noun	Noun	A3pl|P3sg|Dat
Noun	Noun	A3pl|P3sg|Equ
Noun	Noun	A3pl|P3sg|Gen
Noun	Noun	A3pl|P3sg|Ins
Noun	Noun	A3pl|P3sg|Loc
Noun	Noun	A3pl|P3sg|Nom
Noun	Noun	A3pl|Pnon|Abl
Noun	Noun	A3pl|Pnon|Acc
Noun	Noun	A3pl|Pnon|Dat
Noun	Noun	A3pl|Pnon|Equ
Noun	Noun	A3pl|Pnon|Gen
Noun	Noun	A3pl|Pnon|Ins
Noun	Noun	A3pl|Pnon|Loc
Noun	Noun	A3pl|Pnon|Nom
Noun	Noun	A3sg|P1pl|Abl
Noun	Noun	A3sg|P1pl|Acc
Noun	Noun	A3sg|P1pl|Dat
Noun	Noun	A3sg|P1pl|Gen
Noun	Noun	A3sg|P1pl|Ins
Noun	Noun	A3sg|P1pl|Loc
Noun	Noun	A3sg|P1pl|Nom
Noun	Noun	A3sg|P1sg|Abl
Noun	Noun	A3sg|P1sg|Acc
Noun	Noun	A3sg|P1sg|Dat
Noun	Noun	A3sg|P1sg|Gen
Noun	Noun	A3sg|P1sg|Ins
Noun	Noun	A3sg|P1sg|Loc
Noun	Noun	A3sg|P1sg|Nom
Noun	Noun	A3sg|P2pl|Abl
Noun	Noun	A3sg|P2pl|Acc
Noun	Noun	A3sg|P2pl|Dat
Noun	Noun	A3sg|P2pl|Gen
Noun	Noun	A3sg|P2pl|Ins
Noun	Noun	A3sg|P2pl|Loc
Noun	Noun	A3sg|P2pl|Nom
Noun	Noun	A3sg|P2sg|Abl
Noun	Noun	A3sg|P2sg|Acc
Noun	Noun	A3sg|P2sg|Dat
Noun	Noun	A3sg|P2sg|Equ
Noun	Noun	A3sg|P2sg|Gen
Noun	Noun	A3sg|P2sg|Ins
Noun	Noun	A3sg|P2sg|Loc
Noun	Noun	A3sg|P2sg|Nom
Noun	Noun	A3sg|P3pl|Abl
Noun	Noun	A3sg|P3pl|Acc
Noun	Noun	A3sg|P3pl|Dat
Noun	Noun	A3sg|P3pl|Gen
Noun	Noun	A3sg|P3pl|Ins
Noun	Noun	A3sg|P3pl|Loc
Noun	Noun	A3sg|P3pl|Nom
Noun	Noun	A3sg|P3sg|Abl
Noun	Noun	A3sg|P3sg|Acc
Noun	Noun	A3sg|P3sg|Dat
Noun	Noun	A3sg|P3sg|Equ
Noun	Noun	A3sg|P3sg|Gen
Noun	Noun	A3sg|P3sg|Ins
Noun	Noun	A3sg|P3sg|Loc
Noun	Noun	A3sg|P3sg|Nom
Noun	Noun	A3sg|Pnon|Abl
Noun	Noun	A3sg|Pnon|Acc
Noun	Noun	A3sg|Pnon|Dat
Noun	Noun	A3sg|Pnon|Equ
Noun	Noun	A3sg|Pnon|Gen
Noun	Noun	A3sg|Pnon|Ins
Noun	Noun	A3sg|Pnon|Loc
Noun	Noun	A3sg|Pnon|Nom
Noun	Noun	Agt|A3pl|P3pl|Dat
Noun	Noun	Agt|A3pl|P3sg|Abl
Noun	Noun	Agt|A3pl|P3sg|Gen
Noun	Noun	Agt|A3pl|P3sg|Loc
Noun	Noun	Agt|A3pl|P3sg|Nom
Noun	Noun	Agt|A3pl|Pnon|Abl
Noun	Noun	Agt|A3pl|Pnon|Acc
Noun	Noun	Agt|A3pl|Pnon|Dat
Noun	Noun	Agt|A3pl|Pnon|Gen
Noun	Noun	Agt|A3pl|Pnon|Ins
Noun	Noun	Agt|A3pl|Pnon|Nom
Noun	Noun	Agt|A3sg|P1pl|Nom
Noun	Noun	Agt|A3sg|P1sg|Nom
Noun	Noun	Agt|A3sg|P3pl|Abl
Noun	Noun	Agt|A3sg|P3sg|Nom
Noun	Noun	Agt|A3sg|Pnon|Abl
Noun	Noun	Agt|A3sg|Pnon|Acc
Noun	Noun	Agt|A3sg|Pnon|Dat
Noun	Noun	Agt|A3sg|Pnon|Gen
Noun	Noun	Agt|A3sg|Pnon|Ins
Noun	Noun	Agt|A3sg|Pnon|Nom
Noun	Noun	Dim|A3sg|Pnon|Dat
Noun	Noun	Dim|A3sg|Pnon|Nom
Noun	Noun	Inf2|A3sg|Pnon|Dat
Noun	Noun	Inf3|A3sg|Pnon|Dat
Noun	Noun	Ness|A3pl|P2pl|Loc
Noun	Noun	Ness|A3pl|P2sg|Dat
Noun	Noun	Ness|A3pl|P3pl|Acc
Noun	Noun	Ness|A3pl|P3pl|Dat
Noun	Noun	Ness|A3pl|P3pl|Gen
Noun	Noun	Ness|A3pl|P3sg|Abl
Noun	Noun	Ness|A3pl|P3sg|Acc
Noun	Noun	Ness|A3pl|P3sg|Gen
Noun	Noun	Ness|A3pl|P3sg|Ins
Noun	Noun	Ness|A3pl|P3sg|Nom
Noun	Noun	Ness|A3pl|Pnon|Abl
Noun	Noun	Ness|A3pl|Pnon|Acc
Noun	Noun	Ness|A3pl|Pnon|Dat
Noun	Noun	Ness|A3pl|Pnon|Gen
Noun	Noun	Ness|A3pl|Pnon|Ins
Noun	Noun	Ness|A3pl|Pnon|Nom
Noun	Noun	Ness|A3sg|P1pl|Dat
Noun	Noun	Ness|A3sg|P1pl|Nom
Noun	Noun	Ness|A3sg|P1sg|Acc
Noun	Noun	Ness|A3sg|P1sg|Dat
Noun	Noun	Ness|A3sg|P1sg|Gen
Noun	Noun	Ness|A3sg|P1sg|Ins
Noun	Noun	Ness|A3sg|P1sg|Loc
Noun	Noun	Ness|A3sg|P1sg|Nom
Noun	Noun	Ness|A3sg|P2pl|Nom
Noun	Noun	Ness|A3sg|P2sg|Nom
Noun	Noun	Ness|A3sg|P3pl|Dat
Noun	Noun	Ness|A3sg|P3pl|Gen
Noun	Noun	Ness|A3sg|P3pl|Ins
Noun	Noun	Ness|A3sg|P3sg|Abl
Noun	Noun	Ness|A3sg|P3sg|Acc
Noun	Noun	Ness|A3sg|P3sg|Dat
Noun	Noun	Ness|A3sg|P3sg|Gen
Noun	Noun	Ness|A3sg|P3sg|Ins
Noun	Noun	Ness|A3sg|P3sg|Loc
Noun	Noun	Ness|A3sg|P3sg|Nom
Noun	Noun	Ness|A3sg|Pnon|Abl
Noun	Noun	Ness|A3sg|Pnon|Acc
Noun	Noun	Ness|A3sg|Pnon|Dat
Noun	Noun	Ness|A3sg|Pnon|Gen
Noun	Noun	Ness|A3sg|Pnon|Ins
Noun	Noun	Ness|A3sg|Pnon|Loc
Noun	Noun	Ness|A3sg|Pnon|Nom
Noun	NPastPart	A3pl|P1sg|Abl
Noun	NPastPart	A3pl|P1sg|Acc
Noun	NPastPart	A3pl|P1sg|Dat
Noun	NPastPart	A3pl|P1sg|Gen
Noun	NPastPart	A3pl|P1sg|Ins
Noun	NPastPart	A3pl|P1sg|Loc
Noun	NPastPart	A3pl|P1sg|Nom
Noun	NPastPart	A3pl|P2pl|Acc
Noun	NPastPart	A3pl|P2pl|Ins
Noun	NPastPart	A3pl|P2pl|Nom
Noun	NPastPart	A3pl|P2sg|Acc
Noun	NPastPart	A3pl|P3pl|Abl
Noun	NPastPart	A3pl|P3pl|Acc
Noun	NPastPart	A3pl|P3pl|Dat
Noun	NPastPart	A3pl|P3pl|Loc
Noun	NPastPart	A3pl|P3pl|Nom
Noun	NPastPart	A3pl|P3sg|Abl
Noun	NPastPart	A3pl|P3sg|Acc
Noun	NPastPart	A3pl|P3sg|Dat
Noun	NPastPart	A3pl|P3sg|Loc
Noun	NPastPart	A3pl|P3sg|Nom
Noun	NPastPart	A3pl|Pnon|Acc
Noun	NPastPart	A3sg|P1pl|Acc
Noun	NPastPart	A3sg|P1pl|Loc
Noun	NPastPart	A3sg|P1pl|Nom
Noun	NPastPart	A3sg|P1sg|Abl
Noun	NPastPart	A3sg|P1sg|Acc
Noun	NPastPart	A3sg|P1sg|Dat
Noun	NPastPart	A3sg|P1sg|Gen
Noun	NPastPart	A3sg|P1sg|Loc
Noun	NPastPart	A3sg|P1sg|Nom
Noun	NPastPart	A3sg|P2pl|Abl
Noun	NPastPart	A3sg|P2pl|Acc
Noun	NPastPart	A3sg|P2pl|Loc
Noun	NPastPart	A3sg|P2pl|Nom
Noun	NPastPart	A3sg|P2sg|Abl
Noun	NPastPart	A3sg|P2sg|Loc
Noun	NPastPart	A3sg|P2sg|Nom
Noun	NPastPart	A3sg|P3pl|Acc
Noun	NPastPart	A3sg|P3pl|Dat
Noun	NPastPart	A3sg|P3pl|Loc
Noun	NPastPart	A3sg|P3pl|Nom
Noun	NPastPart	A3sg|P3sg|Abl
Noun	NPastPart	A3sg|P3sg|Acc
Noun	NPastPart	A3sg|P3sg|Dat
Noun	NPastPart	A3sg|P3sg|Equ
Noun	NPastPart	A3sg|P3sg|Gen
Noun	NPastPart	A3sg|P3sg|Loc
Noun	NPastPart	A3sg|P3sg|Nom
Noun	NPastPart	A3sg|Pnon|Abl
Noun	NPresPart	A3sg|P3sg|Nom
Noun	Prop	A3pl|P3sg|Dat
Noun	Prop	A3pl|P3sg|Gen
Noun	Prop	A3pl|P3sg|Loc
Noun	Prop	A3pl|Pnon|Abl
Noun	Prop	A3pl|Pnon|Acc
Noun	Prop	A3pl|Pnon|Dat
Noun	Prop	A3pl|Pnon|Gen
Noun	Prop	A3pl|Pnon|Loc
Noun	Prop	A3pl|Pnon|Nom
Noun	Prop	A3sg|P1sg|Nom
Noun	Prop	A3sg|P2sg|Nom
Noun	Prop	A3sg|P3sg|Abl
Noun	Prop	A3sg|P3sg|Acc
Noun	Prop	A3sg|P3sg|Dat
Noun	Prop	A3sg|P3sg|Equ
Noun	Prop	A3sg|P3sg|Gen
Noun	Prop	A3sg|P3sg|Ins
Noun	Prop	A3sg|P3sg|Loc
Noun	Prop	A3sg|P3sg|Nom
Noun	Prop	A3sg|Pnon|Abl
Noun	Prop	A3sg|Pnon|Acc
Noun	Prop	A3sg|Pnon|Dat
Noun	Prop	A3sg|Pnon|Gen
Noun	Prop	A3sg|Pnon|Ins
Noun	Prop	A3sg|Pnon|Loc
Noun	Prop	A3sg|Pnon|Nom
Noun	Zero	A3pl|P2sg|Equ
Noun	Zero	A3pl|P2sg|Gen
Noun	Zero	A3pl|P2sg|Nom
Noun	Zero	A3pl|P3pl|Acc
Noun	Zero	A3pl|P3pl|Gen
Noun	Zero	A3pl|P3pl|Loc
Noun	Zero	A3pl|P3pl|Nom
Noun	Zero	A3pl|P3sg|Abl
Noun	Zero	A3pl|P3sg|Acc
Noun	Zero	A3pl|P3sg|Dat
Noun	Zero	A3pl|P3sg|Gen
Noun	Zero	A3pl|P3sg|Ins
Noun	Zero	A3pl|P3sg|Loc
Noun	Zero	A3pl|P3sg|Nom
Noun	Zero	A3pl|Pnon|Abl
Noun	Zero	A3pl|Pnon|Acc
Noun	Zero	A3pl|Pnon|Dat
Noun	Zero	A3pl|Pnon|Equ
Noun	Zero	A3pl|Pnon|Gen
Noun	Zero	A3pl|Pnon|Ins
Noun	Zero	A3pl|Pnon|Loc
Noun	Zero	A3pl|Pnon|Nom
Noun	Zero	A3sg|P1pl|Abl
Noun	Zero	A3sg|P1pl|Acc
Noun	Zero	A3sg|P1pl|Gen
Noun	Zero	A3sg|P1pl|Nom
Noun	Zero	A3sg|P1sg|Nom
Noun	Zero	A3sg|P2pl|Loc
Noun	Zero	A3sg|P2sg|Abl
Noun	Zero	A3sg|P2sg|Acc
Noun	Zero	A3sg|P2sg|Dat
Noun	Zero	A3sg|P2sg|Loc
Noun	Zero	A3sg|P3pl|Acc
Noun	Zero	A3sg|P3pl|Nom
Noun	Zero	A3sg|P3sg|Abl
Noun	Zero	A3sg|P3sg|Acc
Noun	Zero	A3sg|P3sg|Dat
Noun	Zero	A3sg|P3sg|Gen
Noun	Zero	A3sg|P3sg|Ins
Noun	Zero	A3sg|P3sg|Loc
Noun	Zero	A3sg|P3sg|Nom
Noun	Zero	A3sg|Pnon|Abl
Noun	Zero	A3sg|Pnon|Acc
Noun	Zero	A3sg|Pnon|Dat
Noun	Zero	A3sg|Pnon|Gen
Noun	Zero	A3sg|Pnon|Ins
Noun	Zero	A3sg|Pnon|Loc
Noun	Zero	A3sg|Pnon|Nom
Num	Card	_
Num	Distrib	_
Num	Ord	_
Num	Range	_
Num	Real	_
Postp	Postp	PCAbl
Postp	Postp	PCAcc
Postp	Postp	PCDat
Postp	Postp	PCGen
Postp	Postp	PCIns
Postp	Postp	PCNom
Pron	DemonsP	A3pl|Pnon|Abl
Pron	DemonsP	A3pl|Pnon|Acc
Pron	DemonsP	A3pl|Pnon|Dat
Pron	DemonsP	A3pl|Pnon|Gen
Pron	DemonsP	A3pl|Pnon|Nom
Pron	DemonsP	A3sg|Pnon|Abl
Pron	DemonsP	A3sg|Pnon|Acc
Pron	DemonsP	A3sg|Pnon|Dat
Pron	DemonsP	A3sg|Pnon|Equ
Pron	DemonsP	A3sg|Pnon|Gen
Pron	DemonsP	A3sg|Pnon|Ins
Pron	DemonsP	A3sg|Pnon|Loc
Pron	DemonsP	A3sg|Pnon|Nom
Pron	PersP	A1pl|Pnon|Abl
Pron	PersP	A1pl|Pnon|Acc
Pron	PersP	A1pl|Pnon|Dat
Pron	PersP	A1pl|Pnon|Gen
Pron	PersP	A1pl|Pnon|Ins
Pron	PersP	A1pl|Pnon|Loc
Pron	PersP	A1pl|Pnon|Nom
Pron	PersP	A1sg|Pnon|Abl
Pron	PersP	A1sg|Pnon|Acc
Pron	PersP	A1sg|Pnon|Dat
Pron	PersP	A1sg|Pnon|Equ
Pron	PersP	A1sg|Pnon|Gen
Pron	PersP	A1sg|Pnon|Ins
Pron	PersP	A1sg|Pnon|Loc
Pron	PersP	A1sg|Pnon|Nom
Pron	PersP	A2pl|Pnon|Abl
Pron	PersP	A2pl|Pnon|Acc
Pron	PersP	A2pl|Pnon|Dat
Pron	PersP	A2pl|Pnon|Gen
Pron	PersP	A2pl|Pnon|Ins
Pron	PersP	A2pl|Pnon|Nom
Pron	PersP	A2sg|Pnon|Abl
Pron	PersP	A2sg|Pnon|Acc
Pron	PersP	A2sg|Pnon|Dat
Pron	PersP	A2sg|Pnon|Gen
Pron	PersP	A2sg|Pnon|Ins
Pron	PersP	A2sg|Pnon|Nom
Pron	PersP	A3pl|Pnon|Abl
Pron	PersP	A3pl|Pnon|Acc
Pron	PersP	A3pl|Pnon|Dat
Pron	PersP	A3pl|Pnon|Gen
Pron	PersP	A3pl|Pnon|Ins
Pron	PersP	A3pl|Pnon|Loc
Pron	PersP	A3pl|Pnon|Nom
Pron	PersP	A3sg|Pnon|Abl
Pron	PersP	A3sg|Pnon|Acc
Pron	PersP	A3sg|Pnon|Dat
Pron	PersP	A3sg|Pnon|Equ
Pron	PersP	A3sg|Pnon|Gen
Pron	PersP	A3sg|Pnon|Ins
Pron	PersP	A3sg|Pnon|Loc
Pron	PersP	A3sg|Pnon|Nom
Pron	Pron	A1pl|P1pl|Acc
Pron	Pron	A1pl|P1pl|Dat
Pron	Pron	A1pl|P1pl|Equ
Pron	Pron	A1pl|P1pl|Gen
Pron	Pron	A1pl|P1pl|Nom
Pron	Pron	A2pl|P2pl|Acc
Pron	Pron	A2pl|P2pl|Ins
Pron	Pron	A2pl|P2pl|Nom
Pron	Pron	A3pl|P3pl|Abl
Pron	Pron	A3pl|P3pl|Acc
Pron	Pron	A3pl|P3pl|Dat
Pron	Pron	A3pl|P3pl|Gen
Pron	Pron	A3pl|P3pl|Ins
Pron	Pron	A3pl|P3pl|Loc
Pron	Pron	A3pl|P3pl|Nom
Pron	Pron	A3pl|Pnon|Gen
Pron	Pron	A3pl|Pnon|Nom
Pron	Pron	A3sg|P3sg|Abl
Pron	Pron	A3sg|P3sg|Acc
Pron	Pron	A3sg|P3sg|Dat
Pron	Pron	A3sg|P3sg|Gen
Pron	Pron	A3sg|P3sg|Ins
Pron	Pron	A3sg|P3sg|Loc
Pron	Pron	A3sg|P3sg|Nom
Pron	Pron	A3sg|Pnon|Abl
Pron	Pron	A3sg|Pnon|Acc
Pron	Pron	A3sg|Pnon|Dat
Pron	Pron	A3sg|Pnon|Loc
Pron	Pron	A3sg|Pnon|Nom
Pron	QuesP	A3pl|Pnon|Abl
Pron	QuesP	A3pl|Pnon|Acc
Pron	QuesP	A3pl|Pnon|Dat
Pron	QuesP	A3pl|Pnon|Loc
Pron	QuesP	A3pl|Pnon|Nom
Pron	QuesP	A3sg|P1sg|Nom
Pron	QuesP	A3sg|P2sg|Nom
Pron	QuesP	A3sg|P3sg|Acc
Pron	QuesP	A3sg|P3sg|Gen
Pron	QuesP	A3sg|P3sg|Nom
Pron	QuesP	A3sg|Pnon|Abl
Pron	QuesP	A3sg|Pnon|Acc
Pron	QuesP	A3sg|Pnon|Dat
Pron	QuesP	A3sg|Pnon|Gen
Pron	QuesP	A3sg|Pnon|Loc
Pron	QuesP	A3sg|Pnon|Nom
Pron	ReflexP	A1pl|P1pl|Acc
Pron	ReflexP	A1pl|P1pl|Dat
Pron	ReflexP	A1sg|P1sg|Acc
Pron	ReflexP	A1sg|P1sg|Dat
Pron	ReflexP	A1sg|P1sg|Nom
Pron	ReflexP	A2pl|P2pl|Acc
Pron	ReflexP	A2pl|P2pl|Dat
Pron	ReflexP	A2pl|P2pl|Nom
Pron	ReflexP	A2sg|P2sg|Acc
Pron	ReflexP	A2sg|P2sg|Dat
Pron	ReflexP	A3pl|P3pl|Abl
Pron	ReflexP	A3pl|P3pl|Acc
Pron	ReflexP	A3pl|P3pl|Dat
Pron	ReflexP	A3pl|P3pl|Gen
Pron	ReflexP	A3pl|P3pl|Ins
Pron	ReflexP	A3pl|P3pl|Loc
Pron	ReflexP	A3pl|P3pl|Nom
Pron	ReflexP	A3sg|P3sg|Abl
Pron	ReflexP	A3sg|P3sg|Acc
Pron	ReflexP	A3sg|P3sg|Dat
Pron	ReflexP	A3sg|P3sg|Equ
Pron	ReflexP	A3sg|P3sg|Gen
Pron	ReflexP	A3sg|P3sg|Ins
Pron	ReflexP	A3sg|P3sg|Nom
Punc	Punc	_
Ques	Ques	Narr|A3sg
Ques	Ques	Past|A1sg
Ques	Ques	Past|A2sg
Ques	Ques	Past|A3sg
Ques	Ques	Pres|A1pl
Ques	Ques	Pres|A1sg
Ques	Ques	Pres|A2pl
Ques	Ques	Pres|A2sg
Ques	Ques	Pres|A3sg
Ques	Ques	Pres|Cop|A3sg
Verb	Verb	_
Verb	Verb	A1pl
Verb	Verb	A3sg
Verb	Verb	Able
Verb	Verb	Able|Aor
Verb	Verb	Able|Aor|A1pl
Verb	Verb	Able|Aor|A1sg
Verb	Verb	Able|Aor|A2pl
Verb	Verb	Able|Aor|A2sg
Verb	Verb	Able|Aor|A3pl
Verb	Verb	Able|Aor|Past|A3pl
Verb	Verb	Able|Aor|A3sg
Verb	Verb	Able|Cond|Aor|A3sg
Verb	Verb	Able|Aor|Narr|A3sg
Verb	Verb	Able|Aor|Past|A1pl
Verb	Verb	Able|Aor|Past|A1sg
Verb	Verb	Able|Aor|Past|A3sg
Verb	Verb	Able|Desr|A1pl
Verb	Verb	Able|Desr|A1sg
Verb	Verb	Able|Desr|Past|A3pl
Verb	Verb	Able|Desr|Past|A3sg
Verb	Verb	Able|Fut|A1sg
Verb	Verb	Able|Fut|A3pl
Verb	Verb	Able|Fut|Past|A3pl
Verb	Verb	Able|Fut|A3sg
Verb	Verb	Able|Fut|Cop|A3sg
Verb	Verb	Able|Fut|Past|A1pl
Verb	Verb	Able|Imp|A3sg
Verb	Verb	Able|Narr
Verb	Verb	Able|Narr|A3sg
Verb	Verb	Able|Narr|Cop|A3sg
Verb	Verb	Able|Neces|A3sg
Verb	Verb	Able|Neces|Cop|A3sg
Verb	Verb	Able|Neg
Verb	Verb	Able|Neg|Aor
Verb	Verb	Able|Neg|Aor|A1pl
Verb	Verb	Able|Neg|Aor|A1sg
Verb	Verb	Able|Neg|Aor|A2pl
Verb	Verb	Able|Neg|Aor|A2sg
Verb	Verb	Able|Neg|Aor|A3pl
Verb	Verb	Able|Neg|Aor|Past|A3pl
Verb	Verb	Able|Neg|Aor|A3sg
Verb	Verb	Able|Neg|Cond|Aor|A1sg
Verb	Verb	Able|Neg|Cond|Aor|A2pl
Verb	Verb	Able|Neg|Aor|Narr|A3sg
Verb	Verb	Able|Neg|Aor|Past|A1sg
Verb	Verb	Able|Neg|Aor|Past|A3sg
Verb	Verb	Able|Neg|Desr|A3sg
Verb	Verb	Able|Neg|Fut|A1sg
Verb	Verb	Able|Neg|Fut|A3sg
Verb	Verb	Able|Neg|Fut|Cond|A3sg
Verb	Verb	Able|Neg|Narr
Verb	Verb	Able|Neg|Narr|A1pl
Verb	Verb	Able|Neg|Narr|A1sg
Verb	Verb	Able|Neg|Narr|A2sg
Verb	Verb	Able|Neg|Narr|A3sg
Verb	Verb	Able|Neg|Narr|Past|A1pl
Verb	Verb	Able|Neg|Narr|Past|A1sg
Verb	Verb	Able|Neg|Narr|Past|A3sg
Verb	Verb	Able|Neg|Past|A1pl
Verb	Verb	Able|Neg|Past|A1sg
Verb	Verb	Able|Neg|Past|A2pl
Verb	Verb	Able|Neg|Past|A3pl
Verb	Verb	Able|Neg|Past|A3sg
Verb	Verb	Able|Neg|Prog1|A1pl
Verb	Verb	Able|Neg|Prog1|A1sg
Verb	Verb	Able|Neg|Prog1|A2pl
Verb	Verb	Able|Neg|Prog1|A2sg
Verb	Verb	Able|Neg|Prog1|A3pl
Verb	Verb	Able|Neg|Prog1|Past|A3pl
Verb	Verb	Able|Neg|Prog1|A3sg
Verb	Verb	Able|Neg|Prog1|Past|A1sg
Verb	Verb	Able|Neg|Prog1|Past|A3sg
Verb	Verb	Able|Past|A1pl
Verb	Verb	Able|Past|A1sg
Verb	Verb	Able|Past|A2pl
Verb	Verb	Able|Past|A3sg
Verb	Verb	Able|Prog1|A1sg
Verb	Verb	Able|Prog1|A2sg
Verb	Verb	Able|Prog1|A3pl
Verb	Verb	Able|Prog1|A3sg
Verb	Verb	Able|Prog1|Cond|A2pl
Verb	Verb	Able|Prog1|Past|A1sg
Verb	Verb	Able|Prog1|Past|A3sg
Verb	Verb	Acquire
Verb	Verb	Acquire|Neg|Aor|A3sg
Verb	Verb	Acquire|Neg|Fut|A1pl
Verb	Verb	Acquire|Neg|Imp|A2sg
Verb	Verb	Acquire|Neg|Narr
Verb	Verb	Acquire|Pos
Verb	Verb	Acquire|Pos|Aor
Verb	Verb	Acquire|Pos|Aor|A3pl
Verb	Verb	Acquire|Pos|Aor|A3sg
Verb	Verb	Acquire|Pos|Fut|Cond|A3sg
Verb	Verb	Acquire|Pos|Imp|A2sg
Verb	Verb	Acquire|Pos|Imp|A3sg
Verb	Verb	Acquire|Pos|Narr
Verb	Verb	Acquire|Pos|Narr|A3sg
Verb	Verb	Acquire|Pos|Narr|Cop|A3sg
Verb	Verb	Acquire|Pos|Narr|Past|A1sg
Verb	Verb	Acquire|Pos|Narr|Past|A3sg
Verb	Verb	Acquire|Pos|Opt|A3sg
Verb	Verb	Acquire|Pos|Past|A1sg
Verb	Verb	Acquire|Pos|Past|A3sg
Verb	Verb	Acquire|Pos|Prog1|A1pl
Verb	Verb	Acquire|Pos|Prog1|A1sg
Verb	Verb	Acquire|Pos|Prog1|A2sg
Verb	Verb	Acquire|Pos|Prog1|A3pl
Verb	Verb	Acquire|Pos|Prog1|A3sg
Verb	Verb	Acquire|Pos|Prog1|Past|A3sg
Verb	Verb	Acquire|Pos|Prog2|A3sg
Verb	Verb	Become
Verb	Verb	Become|Neg|Aor
Verb	Verb	Become|Neg|Aor|A3sg
Verb	Verb	Become|Neg|Imp|A2sg
Verb	Verb	Become|Pos
Verb	Verb	Become|Pos|Aor|Past|A3pl
Verb	Verb	Become|Pos|Aor|A3sg
Verb	Verb	Become|Pos|Desr|A3sg
Verb	Verb	Become|Pos|Narr|A3sg
Verb	Verb	Become|Pos|Narr|Cop|A3sg
Verb	Verb	Become|Pos|Narr|Past|A3sg
Verb	Verb	Become|Pos|Past|A2pl
Verb	Verb	Become|Pos|Past|A2sg
Verb	Verb	Become|Pos|Past|A3sg
Verb	Verb	Become|Pos|Prog1|A1pl
Verb	Verb	Become|Pos|Prog1|A2sg
Verb	Verb	Become|Pos|Prog1|Past|A3pl
Verb	Verb	Become|Pos|Prog1|A3sg
Verb	Verb	Become|Pos|Prog1|Past|A3sg
Verb	Verb	Caus
Verb	Verb	Caus|Neg
Verb	Verb	Caus|Neg|Aor|A1sg
Verb	Verb	Caus|Neg|Aor|A3sg
Verb	Verb	Caus|Neg|Aor|Past|A1sg
Verb	Verb	Caus|Neg|Desr|A3pl
Verb	Verb	Caus|Neg|Imp|A2sg
Verb	Verb	Caus|Neg|Past|A1pl
Verb	Verb	Caus|Neg|Past|A3sg
Verb	Verb	Caus|Pos
Verb	Verb	Caus|Pos|Aor
Verb	Verb	Caus|Pos|Aor|A1pl
Verb	Verb	Caus|Pos|Aor|A1sg
Verb	Verb	Caus|Pos|Aor|A2pl
Verb	Verb	Caus|Pos|Aor|A3pl
Verb	Verb	Caus|Pos|Cond|Aor|A3pl
Verb	Verb	Caus|Pos|Aor|A3sg
Verb	Verb	Caus|Pos|Aor|Past|A3sg
Verb	Verb	Caus|Pos|Desr|A1sg
Verb	Verb	Caus|Pos|Desr|A3sg
Verb	Verb	Caus|Pos|Fut|A1pl
Verb	Verb	Caus|Pos|Fut|A1sg
Verb	Verb	Caus|Pos|Fut|A2sg
Verb	Verb	Caus|Pos|Fut|A3pl
Verb	Verb	Caus|Pos|Fut|A3sg
Verb	Verb	Caus|Pos|Fut|Cop|A3sg
Verb	Verb	Caus|Pos|Fut|Past|A1sg
Verb	Verb	Caus|Pos|Imp|A2sg
Verb	Verb	Caus|Pos|Imp|A3sg
Verb	Verb	Caus|Pos|Narr
Verb	Verb	Caus|Pos|Narr|A1pl
Verb	Verb	Caus|Pos|Narr|A2sg
Verb	Verb	Caus|Pos|Narr|A3pl
Verb	Verb	Caus|Pos|Narr|Cop|A3pl
Verb	Verb	Caus|Pos|Narr|Past|A3pl
Verb	Verb	Caus|Pos|Narr|A3sg
Verb	Verb	Caus|Pos|Narr|Cop|A3sg
Verb	Verb	Caus|Pos|Narr|Past|A1pl
Verb	Verb	Caus|Pos|Narr|Past|A1sg
Verb	Verb	Caus|Pos|Narr|Past|A2sg
Verb	Verb	Caus|Pos|Narr|Past|A3sg
Verb	Verb	Caus|Pos|Neces|A3sg
Verb	Verb	Caus|Pos|Opt|A1pl
Verb	Verb	Caus|Pos|Opt|A3pl
Verb	Verb	Caus|Pos|Opt|A3sg
Verb	Verb	Caus|Pos|Past|A1pl
Verb	Verb	Caus|Pos|Past|A1sg
Verb	Verb	Caus|Pos|Past|A2pl
Verb	Verb	Caus|Pos|Past|A3pl
Verb	Verb	Caus|Pos|Past|A3sg
Verb	Verb	Caus|Pos|Prog1|A1sg
Verb	Verb	Caus|Pos|Prog1|A2sg
Verb	Verb	Caus|Pos|Prog1|A3pl
Verb	Verb	Caus|Pos|Prog1|Past|A3pl
Verb	Verb	Caus|Pos|Prog1|A3sg
Verb	Verb	Caus|Pos|Prog1|Narr|A3sg
Verb	Verb	Caus|Pos|Prog1|Past|A1sg
Verb	Verb	Caus|Pos|Prog1|Past|A2sg
Verb	Verb	Caus|Pos|Prog1|Past|A3sg
Verb	Verb	Caus|Pos|Prog2|A3sg
Verb	Verb	Caus|Pos|Prog2|Cop|A3sg
Verb	Verb	Cond|A3sg
Verb	Verb	Hastily
Verb	Verb	Hastily|Aor|A3sg
Verb	Verb	Hastily|Imp|A2sg
Verb	Verb	Hastily|Narr|Past|A2sg
Verb	Verb	Hastily|Narr|Past|A3sg
Verb	Verb	Hastily|Past|A3sg
Verb	Verb	Hastily|Prog1|A3sg
Verb	Verb	Narr|A3sg
Verb	Verb	Neg
Verb	Verb	Neg|Aor
Verb	Verb	Neg|Aor|A1pl
Verb	Verb	Neg|Aor|A1sg
Verb	Verb	Neg|Aor|A2pl
Verb	Verb	Neg|Aor|A2sg
Verb	Verb	Neg|Aor|A3pl
Verb	Verb	Neg|Aor|Past|A3pl
Verb	Verb	Neg|Aor|A3sg
Verb	Verb	Neg|Cond|Aor|A1pl
Verb	Verb	Neg|Cond|Aor|A1sg
Verb	Verb	Neg|Cond|Aor|A2pl
Verb	Verb	Neg|Cond|Aor|A3sg
Verb	Verb	Neg|Aor|Narr|A3sg
Verb	Verb	Neg|Aor|Past|A1sg
Verb	Verb	Neg|Aor|Past|A3sg
Verb	Verb	Neg|Desr|A1pl
Verb	Verb	Neg|Desr|A1sg
Verb	Verb	Neg|Desr|A2pl
Verb	Verb	Neg|Desr|A2sg
Verb	Verb	Neg|Desr|A3pl
Verb	Verb	Neg|Desr|A3sg
Verb	Verb	Neg|Desr|Past|A1sg
Verb	Verb	Neg|Desr|Past|A3sg
Verb	Verb	Neg|Fut|A1pl
Verb	Verb	Neg|Fut|A1sg
Verb	Verb	Neg|Fut|A2sg
Verb	Verb	Neg|Fut|A3sg
Verb	Verb	Neg|Fut|Cop|A3sg
Verb	Verb	Neg|Fut|Narr|A3sg
Verb	Verb	Neg|Fut|Past|A1sg
Verb	Verb	Neg|Fut|Past|A3sg
Verb	Verb	Neg|Imp|A2pl
Verb	Verb	Neg|Imp|A2sg
Verb	Verb	Neg|Imp|A3sg
Verb	Verb	Neg|Narr
Verb	Verb	Neg|Narr|A1sg
Verb	Verb	Neg|Narr|A3pl
Verb	Verb	Neg|Narr|Past|A3pl
Verb	Verb	Neg|Narr|A3sg
Verb	Verb	Neg|Narr|Cop|A3sg
Verb	Verb	Neg|Narr|Past|A1pl
Verb	Verb	Neg|Narr|Past|A1sg
Verb	Verb	Neg|Narr|Past|A3sg
Verb	Verb	Neg|Neces|Past|A2pl
Verb	Verb	Neg|Opt|A1pl
Verb	Verb	Neg|Opt|A1sg
Verb	Verb	Neg|Opt|A3sg
Verb	Verb	Neg|Past|A1pl
Verb	Verb	Neg|Past|A1sg
Verb	Verb	Neg|Past|A2pl
Verb	Verb	Neg|Cond|Past|A2pl
Verb	Verb	Neg|Past|A2sg
Verb	Verb	Neg|Past|A3pl
Verb	Verb	Neg|Past|A3sg
Verb	Verb	Neg|Prog1|A1pl
Verb	Verb	Neg|Prog1|A1sg
Verb	Verb	Neg|Prog1|A2pl
Verb	Verb	Neg|Prog1|A2sg
Verb	Verb	Neg|Prog1|A3pl
Verb	Verb	Neg|Prog1|Cond|A3pl
Verb	Verb	Neg|Prog1|Narr|A3pl
Verb	Verb	Neg|Prog1|Past|A3pl
Verb	Verb	Neg|Prog1|A3sg
Verb	Verb	Neg|Prog1|Cond|A1sg
Verb	Verb	Neg|Prog1|Cond|A2pl
Verb	Verb	Neg|Prog1|Cond|A3sg
Verb	Verb	Neg|Prog1|Cop|A3sg
Verb	Verb	Neg|Prog1|Past|A1sg
Verb	Verb	Neg|Prog1|Past|A2sg
Verb	Verb	Neg|Prog1|Past|A3sg
Verb	Verb	Neg|Prog2|Cop|A3sg
Verb	Verb	Pass
Verb	Verb	Pass|Neg
Verb	Verb	Pass|Neg|Aor
Verb	Verb	Pass|Neg|Aor|A3pl
Verb	Verb	Pass|Neg|Aor|A3sg
Verb	Verb	Pass|Neg|Aor|Past|A3sg
Verb	Verb	Pass|Neg|Fut|A3sg
Verb	Verb	Pass|Neg|Narr
Verb	Verb	Pass|Neg|Narr|A3sg
Verb	Verb	Pass|Neg|Narr|Cop|A3sg
Verb	Verb	Pass|Neg|Narr|Past|A3sg
Verb	Verb	Pass|Neg|Neces|A3sg
Verb	Verb	Pass|Neg|Past|A1sg
Verb	Verb	Pass|Neg|Past|A3sg
Verb	Verb	Pass|Neg|Prog1|A1sg
Verb	Verb	Pass|Neg|Prog1|A3sg
Verb	Verb	Pass|Neg|Prog1|Narr|A3sg
Verb	Verb	Pass|Neg|Prog1|Past|A3sg
Verb	Verb	Pass|Pos
Verb	Verb	Pass|Pos|A3sg
Verb	Verb	Pass|Pos|Aor
Verb	Verb	Pass|Pos|Aor|A1pl
Verb	Verb	Pass|Pos|Aor|A1sg
Verb	Verb	Pass|Pos|Aor|A2sg
Verb	Verb	Pass|Pos|Aor|A3pl
Verb	Verb	Pass|Pos|Aor|A3sg
Verb	Verb	Pass|Pos|Cond|Aor|A1sg
Verb	Verb	Pass|Pos|Cond|Aor|A3sg
Verb	Verb	Pass|Pos|Aor|Narr|A3sg
Verb	Verb	Pass|Pos|Aor|Past|A3sg
Verb	Verb	Pass|Pos|Desr|A3sg
Verb	Verb	Pass|Pos|Fut|A3pl
Verb	Verb	Pass|Pos|Fut|A3sg
Verb	Verb	Pass|Pos|Fut|Cop|A3sg
Verb	Verb	Pass|Pos|Fut|Past|A3sg
Verb	Verb	Pass|Pos|Imp|A3sg
Verb	Verb	Pass|Pos|Narr
Verb	Verb	Pass|Pos|Narr|A2sg
Verb	Verb	Pass|Pos|Narr|Past|A3pl
Verb	Verb	Pass|Pos|Narr|A3sg
Verb	Verb	Pass|Pos|Cond|Narr|A3sg
Verb	Verb	Pass|Pos|Narr|Cop|A3sg
Verb	Verb	Pass|Pos|Narr|Past|A3sg
Verb	Verb	Pass|Pos|Neces|A3sg
Verb	Verb	Pass|Pos|Neces|Cop|A3pl
Verb	Verb	Pass|Pos|Neces|Cop|A3sg
Verb	Verb	Pass|Pos|Neces|Past|A3sg
Verb	Verb	Pass|Pos|Opt|A3sg
Verb	Verb	Pass|Pos|Past|A1pl
Verb	Verb	Pass|Pos|Past|A1sg
Verb	Verb	Pass|Pos|Past|A3pl
Verb	Verb	Pass|Pos|Past|A3sg
Verb	Verb	Pass|Pos|Prog1|A1sg
Verb	Verb	Pass|Pos|Prog1|A2sg
Verb	Verb	Pass|Pos|Prog1|A3pl
Verb	Verb	Pass|Pos|Prog1|A3sg
Verb	Verb	Pass|Pos|Prog1|Narr|A3sg
Verb	Verb	Pass|Pos|Prog1|Past|A1sg
Verb	Verb	Pass|Pos|Prog1|Past|A3sg
Verb	Verb	Pass|Pos|Prog2|A3sg
Verb	Verb	Pass|Pos|Prog2|Cop|A3sg
Verb	Verb	Past|A1sg
Verb	Verb	Past|A2sg
Verb	Verb	Past|A3sg
Verb	Verb	Pos
Verb	Verb	Pos|Aor
Verb	Verb	Pos|Aor|A1pl
Verb	Verb	Pos|Aor|A1sg
Verb	Verb	Pos|Aor|A2pl
Verb	Verb	Pos|Aor|A2sg
Verb	Verb	Pos|Aor|A3pl
Verb	Verb	Pos|Cond|Aor|A3pl
Verb	Verb	Pos|Aor|Narr|A3pl
Verb	Verb	Pos|Aor|Past|A3pl
Verb	Verb	Pos|Aor|A3sg
Verb	Verb	Pos|Cond|Aor|A1pl
Verb	Verb	Pos|Cond|Aor|A1sg
Verb	Verb	Pos|Cond|Aor|A2pl
Verb	Verb	Pos|Cond|Aor|A2sg
Verb	Verb	Pos|Cond|Aor|A3sg
Verb	Verb	Pos|Aor|Narr|A1sg
Verb	Verb	Pos|Aor|Narr|A3sg
Verb	Verb	Pos|Aor|Past|A1pl
Verb	Verb	Pos|Aor|Past|A1sg
Verb	Verb	Pos|Aor|Past|A2sg
Verb	Verb	Pos|Aor|Past|A3sg
Verb	Verb	Pos|Cond|Fut|A2sg
Verb	Verb	Pos|Cond|Fut|A3sg
Verb	Verb	Pos|Cond|Past|A2sg
Verb	Verb	Pos|Cond|Past|A3sg
Verb	Verb	Pos|Desr|A1pl
Verb	Verb	Pos|Desr|A1sg
Verb	Verb	Pos|Desr|A2pl
Verb	Verb	Pos|Desr|A2sg
Verb	Verb	Pos|Desr|A3pl
Verb	Verb	Pos|Desr|Past|A3pl
Verb	Verb	Pos|Desr|A3sg
Verb	Verb	Pos|Desr|Past|A1sg
Verb	Verb	Pos|Desr|Past|A2pl
Verb	Verb	Pos|Desr|Past|A2sg
Verb	Verb	Pos|Desr|Past|A3sg
Verb	Verb	Pos|Fut|A1pl
Verb	Verb	Pos|Fut|A1sg
Verb	Verb	Pos|Fut|A2pl
Verb	Verb	Pos|Fut|A2sg
Verb	Verb	Pos|Fut|A3pl
Verb	Verb	Pos|Fut|Narr|A3pl
Verb	Verb	Pos|Fut|Past|A3pl
Verb	Verb	Pos|Fut|A3sg
Verb	Verb	Pos|Fut|Cop|A3sg
Verb	Verb	Pos|Fut|Narr|A3sg
Verb	Verb	Pos|Fut|Past|A1pl
Verb	Verb	Pos|Fut|Past|A1sg
Verb	Verb	Pos|Fut|Past|A2sg
Verb	Verb	Pos|Fut|Past|A3sg
Verb	Verb	Pos|Imp|A2pl
Verb	Verb	Pos|Imp|A2sg
Verb	Verb	Pos|Imp|A3pl
Verb	Verb	Pos|Imp|A3sg
Verb	Verb	Pos|Narr
Verb	Verb	Pos|Narr|A1pl
Verb	Verb	Pos|Narr|A1sg
Verb	Verb	Pos|Narr|Cop|A1sg
Verb	Verb	Pos|Narr|A2pl
Verb	Verb	Pos|Narr|A2sg
Verb	Verb	Pos|Narr|A3pl
Verb	Verb	Pos|Cond|Narr|A3pl
Verb	Verb	Pos|Narr|Cop|A3pl
Verb	Verb	Pos|Narr|Past|A3pl
Verb	Verb	Pos|Narr|A3sg
Verb	Verb	Pos|Cond|Narr|A3sg
Verb	Verb	Pos|Narr|Cop|A3sg
Verb	Verb	Pos|Narr|Past|A1pl
Verb	Verb	Pos|Narr|Past|A1sg
Verb	Verb	Pos|Narr|Past|A2pl
Verb	Verb	Pos|Narr|Past|A2sg
Verb	Verb	Pos|Narr|Past|A3sg
Verb	Verb	Pos|Neces|A1pl
Verb	Verb	Pos|Neces|A1sg
Verb	Verb	Pos|Neces|A2pl
Verb	Verb	Pos|Neces|A2sg
Verb	Verb	Pos|Neces|A3sg
Verb	Verb	Pos|Neces|Cop|A3sg
Verb	Verb	Pos|Neces|Past|A1sg
Verb	Verb	Pos|Neces|Past|A2pl
Verb	Verb	Pos|Neces|Past|A3sg
Verb	Verb	Pos|Opt|A1pl
Verb	Verb	Pos|Opt|A1sg
Verb	Verb	Pos|Opt|A3sg
Verb	Verb	Pos|Past|A1pl
Verb	Verb	Pos|Past|A1sg
Verb	Verb	Pos|Past|A2pl
Verb	Verb	Pos|Past|A2sg
Verb	Verb	Pos|Past|A3pl
Verb	Verb	Pos|Past|A3sg
Verb	Verb	Pos|Prog1|A1pl
Verb	Verb	Pos|Prog1|A1sg
Verb	Verb	Pos|Prog1|A2pl
Verb	Verb	Pos|Prog1|A2sg
Verb	Verb	Pos|Prog1|A3pl
Verb	Verb	Pos|Prog1|Narr|A3pl
Verb	Verb	Pos|Prog1|Past|A3pl
Verb	Verb	Pos|Prog1|A3sg
Verb	Verb	Pos|Prog1|Cond|A1pl
Verb	Verb	Pos|Prog1|Cond|A1sg
Verb	Verb	Pos|Prog1|Cond|A2sg
Verb	Verb	Pos|Prog1|Cond|A3sg
Verb	Verb	Pos|Prog1|Cop|A3sg
Verb	Verb	Pos|Prog1|Narr|A1sg
Verb	Verb	Pos|Prog1|Narr|A3sg
Verb	Verb	Pos|Prog1|Past|A1pl
Verb	Verb	Pos|Prog1|Past|A1sg
Verb	Verb	Pos|Prog1|Past|A2pl
Verb	Verb	Pos|Prog1|Past|A2sg
Verb	Verb	Pos|Prog1|Past|A3sg
Verb	Verb	Pos|Prog2|A3sg
Verb	Verb	Pos|Prog2|Cop|A3pl
Verb	Verb	Pos|Prog2|Cop|A3sg
Verb	Verb	Pres|A1pl
Verb	Verb	Pres|A1sg
Verb	Verb	Pres|A2sg
Verb	Verb	Pres|A3pl
Verb	Verb	Pres|A3sg
Verb	Verb	Pres|Cop|A3sg
Verb	Verb	Recip
Verb	Verb	Recip|Neg
Verb	Verb	Recip|Pos
Verb	Verb	Recip|Pos|Aor|A1pl
Verb	Verb	Recip|Pos|Imp|A2pl
Verb	Verb	Recip|Pos|Past|A1pl
Verb	Verb	Recip|Pos|Past|A3pl
Verb	Verb	Recip|Pos|Past|A3sg
Verb	Verb	Reflex
Verb	Verb	Reflex|Pos
Verb	Verb	Reflex|Pos|Narr|A3sg
Verb	Verb	Reflex|Pos|Past|A2pl
Verb	Verb	Reflex|Pos|Prog1|A3sg
Verb	Verb	Stay
Verb	Verb	Stay|Narr|A3sg
Verb	Verb	Stay|Narr|Past|A1pl
Verb	Verb	Stay|Narr|Past|A3sg
Verb	Zero	_
Verb	Zero	A3e
Verb	Zero	Narr|A3pl
Verb	Zero	Past|A3pl
Verb	Zero	A3sg
Verb	Zero	Cond|A1sg
Verb	Zero	Cond|A3sg
Verb	Zero	Narr|A1pl
Verb	Zero	Narr|A1sg
Verb	Zero	Narr|A2sg
Verb	Zero	Narr|A3sg
Verb	Zero	Past|A1pl
Verb	Zero	Past|A1sg
Verb	Zero	Past|A2pl
Verb	Zero	Past|A2sg
Verb	Zero	Past|A3pl
Verb	Zero	Past|A3sg
Verb	Zero	Pos|Imp|A2sg
Verb	Zero	Pres|A1pl
Verb	Zero	Pres|A1sg
Verb	Zero	Pres|A2pl
Verb	Zero	Pres|A2pl|Cop
Verb	Zero	Pres|A2sg
Verb	Zero	Pres|A3pl
Verb	Zero	Pres|Cop|A3pl
Verb	Zero	Pres|Cop|A3pl
Verb	Zero	Pres|Cop|A3sg
end_of_list
    ;
    # Protect from editors that replace tabs by spaces.
    $list =~ s/ \s+/\t/sg;
    my @list = split(/\r?\n/, $list);
    pop(@list) if($list[$#list] eq "");
    ###!!!
    # Temporarily exclude from tests tags that contain unsupported features.
    @list = grep {$_ !~ m/(Zero|Able|Hastily|Stay|Become|Acquire|Agt|Dim|Inf2|Inf3|Ness)/} (@list);
    ###!!!
    return \@list;
}



#------------------------------------------------------------------------------
# Create trie of permitted feature structures. This will be needed for strict
# encoding. This BEGIN block cannot appear before the definition of the list()
# function.
#------------------------------------------------------------------------------
BEGIN
{
    # Store the hash reference in a global variable.
    $permitted = tagset::common::get_permitted_structures_joint(list(), \&decode);
}



1;
