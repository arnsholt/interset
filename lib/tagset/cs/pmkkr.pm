#!/usr/bin/perl
# Driver for the short version of the tagset of the Pražský mluvený korpus (Prague Spoken Corpus) of Czech.
# Copyright © 2009, 2010 Dan Zeman <zeman@ufal.mff.cuni.cz>
# License: GNU GPL

package tagset::cs::pmkkr;
use utf8;
use tagset::common;
use tagset::cs::pmk;



# We take as one tag the section of XML where features of one word are described.
# It is a string without whitespace characters.
# It begins with '<i1>'. It typically ends with '</i11>' (the '_dl' part of the
# corpus) or '</i4>' (the '_kr' part of the corpus). Every <iN> element contains
# a value of one feature; the values are mostly numbers, sometimes also letters.
# Example: '<i1>1</i1><i2>1</i2><i3>1</i3><i4>1</i4>' means "noun, common, person,
# no valency".



#------------------------------------------------------------------------------
# Takes tag string.
# Returns feature hash.
#------------------------------------------------------------------------------
sub decode
{
    my $tag = shift;
    my %f; # features
    $f{tagset} = 'cs::pmk';
    # Convert the tag to an array of values.
    my $tag1 = $tag;
    my @values;
    while($tag1 =~ s/^<i(\d+)>(.*?)<\/i\1>//)
    {
        my $position = $1;
        my $value = $2;
        $values[$position] = $value;
    }
    # pos
    my $pos = $values[1];
    # substantivum = noun
    if($pos==1)
    {
        $f{pos} = 'noun';
        # 2. druh
        tagset::cs::pmk::decode_noun_type($values[2], \%f);
        # 3. rod
        tagset::cs::pmk::decode_gender($pos, $values[3], \%f);
        # 4. styl
        tagset::cs::pmk::decode_style($values[4], \%f);
    }
    # adjektivum = adjective
    elsif($pos==2)
    {
        $f{pos} = 'adj';
        # 2. druh
        tagset::cs::pmk::decode_adjective_type($values[2], \%f);
        # 3. poddruh
        tagset::cs::pmk::decode_adjective_subtype($values[3], \%f);
        # 4. styl
        tagset::cs::pmk::decode_style($values[4], \%f);
    }
    # zájmeno = pronoun
    elsif($pos==3)
    {
        $f{pos} = 'noun';
        $f{prontype} = 'prs';
        # 2. druh
        tagset::cs::pmk::decode_pronoun_type($values[2], \%f);
        # 3. _
        # 4. styl
        tagset::cs::pmk::decode_style($values[4], \%f);
    }
    # číslovka = numeral
    elsif($pos==4)
    {
        $f{pos} = 'num';
        # 2. druh
        tagset::cs::pmk::decode_numeral_type($values[2], \%f);
        # 3. _
        # 4. styl
        tagset::cs::pmk::decode_style($values[4], \%f);
    }
    # sloveso = verb
    elsif($pos==5)
    {
        $f{pos} = 'verb';
        # 2. víceslovnost a rezultativnost
        tagset::cs::pmk::decode_multiwordness_and_resultativeness($values[2], \%f);
        # 3. zápor
        tagset::cs::pmk::decode_negativeness($values[3], \%f);
        # 4. styl
        tagset::cs::pmk::decode_style($values[4], \%f);
    }
    # adverbium = adverb
    elsif($pos==6)
    {
        $f{pos} = 'adv';
        # 2. druh
        tagset::cs::pmk::decode_adverb_type($values[2], \%f);
        # 3. _
        # 4. styl
        tagset::cs::pmk::decode_style($values[4], \%f);
    }
    # předložka = preposition
    elsif($pos==7)
    {
        $f{pos} = 'prep';
        # 2. druh
        tagset::cs::pmk::decode_preposition_type($values[2], \%f);
        # 3. _
        # 4. styl
        tagset::cs::pmk::decode_style($values[4], \%f);
    }
    # spojka = conjunction
    elsif($pos==8)
    {
        $f{pos} = 'conj';
        # 2. druh
        tagset::cs::pmk::decode_conjunction_type($values[2], \%f);
        # 3. _
        # 4. styl
        tagset::cs::pmk::decode_style($values[4], \%f);
    }
    # citoslovce = interjection
    elsif($pos==9)
    {
        $f{pos} = 'int';
        # 2. druh
        tagset::cs::pmk::decode_interjection_type($values[2], \%f);
        # 3. _
        # 4. styl
        tagset::cs::pmk::decode_style($values[4], \%f);
    }
    # částice = particle
    elsif($pos eq '0')
    {
        $f{pos} = 'part';
        # 2. druh
        tagset::cs::pmk::decode_particle_type($values[2], \%f);
        # 3. _
        # 4. styl
        tagset::cs::pmk::decode_style($values[4], \%f);
    }
    # idiom a frazém = idiom and set phrase
    elsif($pos eq 'F')
    {
        $f{other}{pos} = 'F';
        # 2. druh
        tagset::cs::pmk::decode_idiom_type($values[2], \%f);
        # 3. _
        # 4. styl
        tagset::cs::pmk::decode_style($values[4], \%f);
    }
    # jiné = other
    elsif($pos eq 'J') # $pos eq 'J'
    {
        $f{other}{pos} = 'J';
        # 2. skutečný druh: CZP
        tagset::cs::pmk::decode_other_real_type($values[2], \%f);
        # 3. for 'JP' druh, otherwise '_'
        if($values[2] eq 'P')
        {
            tagset::cs::pmk::decode_proper_noun_type($values[3], \%f);
        }
        # 4. styl
        tagset::cs::pmk::decode_style($values[4], \%f);
    }
    # untagged tokens in multi-word expressions have empty tags like this:
    # <i1></i1><i2></i2><i3></i3><i4></i4>
    else
    {
        $f{other}{pos} = 'untagged';
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
    # Modify the feature structure so that it contains values expected by this
    # driver. Do not do that if this was also the source tagset (because the
    # modification would damage tags using 'other'). However, in any case
    # create a deep copy of the original feature structure so that it is
    # protected from changes during encoding.
    my $f;
    if($f0->{tagset} eq 'cs::pmk')
    {
        $f = tagset::common::duplicate($f0);
    }
    else
    {
        $f = tagset::common::enforce_permitted_joint($f0, $permitted);
    }
    my %f = %{$f};
    my $nonstrict = shift; # strict is default
    $strict = !$nonstrict;
    # Features are numbered from 1; the 0th element of the array will remain empty.
    my @values;
    # Part of speech (the first letter of the tag) specifies which features follow.
    my $pos = $f{pos};
    # substantivum = noun
    if($pos eq 'noun')
    {
        # zájmeno = pronoun
        if($f{prontype} ne '')
        {
            $values[1] = 3;
            # 2! druh
            $values[2] = tagset::cs::pmk::encode_pronoun_type($f);
            # 3. valence
            $values[3] = tagset::cs::pmk::encode_valency(3, $f);
            # 4. rod
            $values[4] = tagset::cs::pmk::encode_gender(3, $f);
            # 5. číslo
            $values[5] = tagset::cs::pmk::encode_number(3, $f);
            # 6. pád
            $values[6] = tagset::cs::pmk::encode_case($f);
            # 7. funkce
            $values[7] = tagset::cs::pmk::encode_function(3, $f);
            # 8. styl
            $values[8] = tagset::cs::pmk::encode_style($f);
        }
        # substantivum = noun
        else
        {
            $values[1] = 1;
            # 2! druh
            $values[2] = tagset::cs::pmk::encode_noun_type($f);
            # 3. třída
            $values[3] = tagset::cs::pmk::encode_noun_class($f);
            # 4. valence
            $values[4] = tagset::cs::pmk::encode_valency(1, $f);
            # 5! rod
            $values[5] = tagset::cs::pmk::encode_gender(1, $f);
            # 6. číslo
            $values[6] = tagset::cs::pmk::encode_number(1, $f);
            # 7. pád
            $values[7] = tagset::cs::pmk::encode_case($f);
            # 8. funkce
            $values[8] = tagset::cs::pmk::encode_function(1, $f);
            # 9! styl
            $values[9] = tagset::cs::pmk::encode_style($f);
        }
    }
    # adjektivum = adjective
    elsif($pos eq 'adj')
    {
        $values[1] = 2;
        # 2! druh
        $values[2] = tagset::cs::pmk::encode_adjective_type($f);
        # 3! poddruh
        $values[3] = tagset::cs::pmk::encode_adjective_subtype($f);
        # 4. třída
        $values[4] = tagset::cs::pmk::encode_adjective_class($f);
        # 5. valence
        $values[5] = tagset::cs::pmk::encode_valency(2, $f);
        # 6. rod
        $values[6] = tagset::cs::pmk::encode_gender(2, $f);
        # 7. číslo
        $values[7] = tagset::cs::pmk::encode_number(2, $f);
        # 8. pád
        $values[8] = tagset::cs::pmk::encode_case($f);
        # 9. stupeň
        $values[9] = tagset::cs::pmk::encode_degree($f);
        # 10. funkce
        $values[10] = tagset::cs::pmk::encode_function(2, $f);
        # 11! styl
        $values[11] = tagset::cs::pmk::encode_style($f);
    }
    # číslovka = numeral
    elsif($pos eq 'num')
    {
        $values[1] = 4;
        # 2! druh
        $values[2] = tagset::cs::pmk::encode_numeral_type($f);
        # 3. valence
        $values[3] = tagset::cs::pmk::encode_valency(4, $f);
        # 4. rod
        $values[4] = tagset::cs::pmk::encode_gender(4, $f);
        # 5. číslo
        $values[5] = tagset::cs::pmk::encode_number(4, $f);
        # 6. pád
        $values[6] = tagset::cs::pmk::encode_case($f);
        # 7. pád subst./pron.
        ###!!! Hodnoty jsou stejné jako u pádu, ale je potřeba to uložit jinam, takže nemůžeme použít stejnou funkci tagset::cs::pmk::decode_case()!
        ###!!! tagset::cs::pmk::decode_case($values[7], \%f);
        # 8. funkce
        $values[8] = tagset::cs::pmk::encode_function(4, $f);
        # 9. styl
        $values[9] = tagset::cs::pmk::encode_style($f);
    }
    # sloveso = verb
    elsif($pos eq 'verb')
    {
        $values[1] = 5;
        # 2. druh
        $values[2] = tagset::cs::pmk::encode_aspect($f);
        # 3. valence subjektová
        # 4. valence
        my @cd = split(//, tagset::cs::pmk::encode_valency(5, $f));
        $values[3] = $cd[0];
        $values[4] = $cd[1];
        # 5. osoba/číslo
        $values[5] = tagset::cs::pmk::encode_person_number($f);
        # 6. způsob/čas/slovesný rod
        $values[6] = tagset::cs::pmk::encode_mood_tense_voice($f);
        # 7. imper./neurč. tvary
        $values[7] = tagset::cs::pmk::encode_nonfinite_verb_form($f);
        # 8! víceslovnost a rezultativnost
        $values[8] = tagset::cs::pmk::encode_multiwordness_and_resultativeness($f);
        # 9. jmenný rod
        $values[9] = tagset::cs::pmk::encode_participle_gender_number($f);
        # 10! zápor
        $values[10] = tagset::cs::pmk::encode_negativeness($f);
        # 11! styl
        $values[11] = tagset::cs::pmk::encode_style($f);
    }
    # adverbium = adverb
    elsif($pos eq 'adv')
    {
        $values[1] = 6;
        # 2! druh
        $values[2] = tagset::cs::pmk::encode_adverb_type($f);
        # 3. třída
        $values[3] = tagset::cs::pmk::encode_adverb_class($f);
        # 4. valence/funkce
        $values[4] = tagset::cs::pmk::encode_valency(6, $f);
        # 5. stupeň
        $values[5] = tagset::cs::pmk::encode_degree($f);
        # 6! styl
        $values[6] = tagset::cs::pmk::encode_style($f);
    }
    # předložka = preposition
    elsif($pos eq 'prep')
    {
        $values[1] = 7;
        # 2! druh
        $values[2] = tagset::cs::pmk::encode_preposition_type($f);
        # 3. třída
        $values[3] = tagset::cs::pmk::encode_preposition_class($f);
        # 4. valenční pád
        $values[4] = tagset::cs::pmk::encode_case($f);
        # 5. funkční závislost levá
        $values[5] = tagset::cs::pmk::encode_function(7, $f);
        # 6! styl
        $values[6] = tagset::cs::pmk::encode_style($f);
    }
    # spojka = conjunction
    elsif($pos eq 'conj')
    {
        $values[1] = 8;
        # 2! druh
        $values[2] = tagset::cs::pmk::encode_conjunction_type($f);
        # 3. třída
        $values[3] = tagset::cs::pmk::encode_conjunction_class($f);
        # 4. valence
        $values[4] = tagset::cs::pmk::encode_valency(8, $f);
        # 5! styl
        $values[5] = tagset::cs::pmk::encode_style($f);
    }
    # citoslovce = interjection
    elsif($pos eq 'int')
    {
        $values[1] = 9;
        # 2! druh
        $values[2] = tagset::cs::pmk::encode_interjection_type($f);
        # 3. třída
        $values[3] = tagset::cs::pmk::encode_interjection_class($f);
        # 4! styl
        $values[4] = tagset::cs::pmk::encode_style($f);
    }
    # částice = particle
    elsif($pos eq 'part')
    {
        $values[1] = 0;
        # 2! druh
        $values[2] = tagset::cs::pmk::encode_particle_type($f);
        # 3. třída
        $values[3] = tagset::cs::pmk::encode_particle_class($f);
        # 4. valence
        $values[4] = tagset::cs::pmk::encode_valency($f);
        # 5. modus věty
        $values[5] = tagset::cs::pmk::encode_sentmod($f);
        # 6! styl
        $values[6] = tagset::cs::pmk::encode_style($f);
    }
    # idiom a frazém = idiom and set phrase
    elsif($f{tagset} eq 'cs::pmk' && $f{other}{pos} eq 'F')
    {
        $values[1] = 'F';
        # 2! druh
        $values[2] = tagset::cs::pmk::encode_idiom_type($f);
        # 3. valence substantivní
        # 4. valence
        my @cd = split(//, tagset::cs::pmk::encode_valency('F'.$values[2], $f));
        $values[3] = $cd[0];
        $values[4] = $cd[1];
        # 6! styl
        $values[6] = tagset::cs::pmk::encode_style($f);
    }
    # untagged tokens in multi-word expressions have empty tags like this:
    # <i1></i1><i2></i2><i3></i3><i4></i4>
    elsif($f{tagset} eq 'cs::pmk' && $f{other}{pos} eq 'untagged')
    {
        # leave $values[1..4] empty
    }
    # jiné = other
    else
    {
        $values[1] = 'J';
        # 2. skutečný druh: CZP
        $values[2] = tagset::cs::pmk::encode_other_real_type($f);
        # 3. druh (JP only)
        if($values[2] eq 'P')
        {
            $values[3] = tagset::cs::pmk::encode_proper_noun_type($f);
        }
        else
        {
            $values[3] = '_';
        }
        # 4. styl
        $values[4] = tagset::cs::pmk::encode_style($f);
    }
    # Mapping of long descriptions to short descriptions (value of 1st number => indices of numbers to be output).
    my %long_to_short =
    (
        1 => [1, 2, 5, 9], # nouns
        2 => [1, 2, 3, 11], # adjectives
        3 => [1, 2, 0, 8], # pronouns
        4 => [1, 2, 0, 9], # numerals
        5 => [1, 8, 10, 11], # verbs
        6 => [1, 2, 0, 6], # adverbs
        7 => [1, 2, 0, 6], # prepositions
        8 => [1, 2, 0, 5], # conjunctions
        9 => [1, 2, 0, 4], # interjections
        0 => [1, 2, 0, 6], # particles
        'F' => [1, 2, 0, 6], # idioms
        'J' => [1, 2, 3, 4], # other
        '' => [1, 1, 1, 1], # untagged
    );
    # Convert the array of values to a tag in the XML format.
    my $tag;
    # We have to decide whether we want the long or the short version of the tagset.
    # We could not make the decision above because we were writing directly to absolutely indexed members of @values.
    # So now we would have to select the members to be printed again anyway.
    # Currently we only test the short one.
    if(1)
    {
        my @indices = @{$long_to_short{$values[1]}};
        for(my $i = 0; $i<=$#indices; $i++)
        {
            my $j = $i+1;
            my $value = $indices[$i]>0 ? $values[$indices[$i]] : '_';
            $tag .= "<i$j>$value</i$j>";
        }
    }
    else # long tags
    {
        for(my $i = 1; $i<=$#values; $i++)
        {
            $tag .= "<i$i>$values[$i]</i$i>";
        }
    }
    return $tag;
}



#------------------------------------------------------------------------------
# Returns reference to list of known tags.
# 236 (pmk_kr.xml)
# 10900 (pmk_dl.xml)
#------------------------------------------------------------------------------
sub list
{
    my $list = <<end_of_list
<i1>0</i1><i2>1</i2><i3>_</i3><i4>1</i4>
<i1>0</i1><i2>1</i2><i3>_</i3><i4>2</i4>
<i1>0</i1><i2>1</i2><i3>_</i3><i4>3</i4>
<i1>0</i1><i2>2</i2><i3>_</i3><i4>1</i4>
<i1>0</i1><i2>2</i2><i3>_</i3><i4>2</i4>
<i1>0</i1><i2>2</i2><i3>_</i3><i4>3</i4>
<i1>0</i1><i2>3</i2><i3>_</i3><i4>1</i4>
<i1>0</i1><i2>3</i2><i3>_</i3><i4>2</i4>
<i1>0</i1><i2>4</i2><i3>_</i3><i4>1</i4>
<i1>0</i1><i2>4</i2><i3>_</i3><i4>2</i4>
<i1>0</i1><i2>4</i2><i3>_</i3><i4>3</i4>
<i1>0</i1><i2>5</i2><i3>_</i3><i4>1</i4>
<i1>0</i1><i2>5</i2><i3>_</i3><i4>2</i4>
<i1>1</i1><i2>1</i2><i3>1</i3><i4>1</i4>
<i1>1</i1><i2>1</i2><i3>1</i3><i4>2</i4>
<i1>1</i1><i2>1</i2><i3>1</i3><i4>4</i4>
<i1>1</i1><i2>1</i2><i3>2</i3><i4>1</i4>
<i1>1</i1><i2>1</i2><i3>2</i3><i4>2</i4>
<i1>1</i1><i2>1</i2><i3>2</i3><i4>4</i4>
<i1>1</i1><i2>1</i2><i3>3</i3><i4>1</i4>
<i1>1</i1><i2>1</i2><i3>3</i3><i4>2</i4>
<i1>1</i1><i2>1</i2><i3>3</i3><i4>4</i4>
<i1>1</i1><i2>1</i2><i3>4</i3><i4>1</i4>
<i1>1</i1><i2>1</i2><i3>4</i3><i4>2</i4>
<i1>1</i1><i2>1</i2><i3>4</i3><i4>4</i4>
<i1>1</i1><i2>2</i2><i3>1</i3><i4>1</i4>
<i1>1</i1><i2>2</i2><i3>1</i3><i4>2</i4>
<i1>1</i1><i2>2</i2><i3>2</i3><i4>1</i4>
<i1>1</i1><i2>2</i2><i3>3</i3><i4>1</i4>
<i1>1</i1><i2>2</i2><i3>3</i3><i4>2</i4>
<i1>1</i1><i2>2</i2><i3>4</i3><i4>1</i4>
<i1>1</i1><i2>3</i2><i3>1</i3><i4>1</i4>
<i1>1</i1><i2>4</i2><i3>1</i3><i4>1</i4>
<i1>1</i1><i2>4</i2><i3>2</i3><i4>1</i4>
<i1>1</i1><i2>4</i2><i3>3</i3><i4>1</i4>
<i1>1</i1><i2>4</i2><i3>3</i3><i4>2</i4>
<i1>1</i1><i2>4</i2><i3>4</i3><i4>1</i4>
<i1>1</i1><i2>4</i2><i3>4</i3><i4>2</i4>
<i1>1</i1><i2>5</i2><i3>2</i3><i4>1</i4>
<i1>1</i1><i2>5</i2><i3>4</i3><i4>1</i4>
<i1>1</i1><i2>5</i2><i3>4</i3><i4>2</i4>
<i1>1</i1><i2>6</i2><i3>4</i3><i4>1</i4>
<i1>1</i1><i2>6</i2><i3>4</i3><i4>2</i4>
<i1>1</i1><i2>7</i2><i3>1</i3><i4>1</i4>
<i1>1</i1><i2>7</i2><i3>2</i3><i4>1</i4>
<i1>1</i1><i2>7</i2><i3>3</i3><i4>1</i4>
<i1>1</i1><i2>7</i2><i3>4</i3><i4>1</i4>
<i1>1</i1><i2>9</i2><i3>2</i3><i4>1</i4>
<i1>1</i1><i2>9</i2><i3>3</i3><i4>1</i4>
<i1>1</i1><i2>9</i2><i3>4</i3><i4>1</i4>
<i1>1</i1><i2>9</i2><i3>4</i3><i4>2</i4>
<i1>2</i1><i2>1</i2><i3>0</i3><i4>1</i4>
<i1>2</i1><i2>1</i2><i3>0</i3><i4>2</i4>
<i1>2</i1><i2>1</i2><i3>0</i3><i4>3</i4>
<i1>2</i1><i2>1</i2><i3>1</i3><i4>1</i4>
<i1>2</i1><i2>1</i2><i3>2</i3><i4>1</i4>
<i1>2</i1><i2>1</i2><i3>3</i3><i4>1</i4>
<i1>2</i1><i2>1</i2><i3>4</i3><i4>1</i4>
<i1>2</i1><i2>1</i2><i3>4</i3><i4>2</i4>
<i1>2</i1><i2>1</i2><i3>4</i3><i4>3</i4>
<i1>2</i1><i2>2</i2><i3>1</i3><i4>1</i4>
<i1>2</i1><i2>2</i2><i3>1</i3><i4>2</i4>
<i1>2</i1><i2>2</i2><i3>1</i3><i4>4</i4>
<i1>2</i1><i2>2</i2><i3>2</i3><i4>1</i4>
<i1>2</i1><i2>2</i2><i3>2</i3><i4>2</i4>
<i1>2</i1><i2>2</i2><i3>3</i3><i4>2</i4>
<i1>2</i1><i2>2</i2><i3>4</i3><i4>1</i4>
<i1>2</i1><i2>2</i2><i3>4</i3><i4>2</i4>
<i1>2</i1><i2>2</i2><i3>4</i3><i4>3</i4>
<i1>2</i1><i2>2</i2><i3>5</i3><i4>2</i4>
<i1>2</i1><i2>3</i2><i3>0</i3><i4>1</i4>
<i1>2</i1><i2>3</i2><i3>3</i3><i4>1</i4>
<i1>2</i1><i2>3</i2><i3>4</i3><i4>1</i4>
<i1>2</i1><i2>3</i2><i3>4</i3><i4>2</i4>
<i1>3</i1><i2>-</i2><i3>_</i3><i4>1</i4>
<i1>3</i1><i2>-</i2><i3>_</i3><i4>2</i4>
<i1>3</i1><i2>0</i2><i3>_</i3><i4>1</i4>
<i1>3</i1><i2>0</i2><i3>_</i3><i4>2</i4>
<i1>3</i1><i2>1</i2><i3>_</i3><i4>1</i4>
<i1>3</i1><i2>1</i2><i3>_</i3><i4>2</i4>
<i1>3</i1><i2>2</i2><i3>_</i3><i4>1</i4>
<i1>3</i1><i2>2</i2><i3>_</i3><i4>2</i4>
<i1>3</i1><i2>2</i2><i3>_</i3><i4>3</i4>
<i1>3</i1><i2>3</i2><i3>_</i3><i4>1</i4>
<i1>3</i1><i2>3</i2><i3>_</i3><i4>2</i4>
<i1>3</i1><i2>4</i2><i3>_</i3><i4>1</i4>
<i1>3</i1><i2>4</i2><i3>_</i3><i4>2</i4>
<i1>3</i1><i2>5</i2><i3>_</i3><i4>1</i4>
<i1>3</i1><i2>5</i2><i3>_</i3><i4>2</i4>
<i1>3</i1><i2>6</i2><i3>_</i3><i4>1</i4>
<i1>3</i1><i2>6</i2><i3>_</i3><i4>2</i4>
<i1>3</i1><i2>7</i2><i3>_</i3><i4>1</i4>
<i1>3</i1><i2>7</i2><i3>_</i3><i4>2</i4>
<i1>3</i1><i2>8</i2><i3>_</i3><i4>1</i4>
<i1>3</i1><i2>8</i2><i3>_</i3><i4>2</i4>
<i1>3</i1><i2>9</i2><i3>_</i3><i4>1</i4>
<i1>3</i1><i2>9</i2><i3>_</i3><i4>2</i4>
<i1>4</i1><i2>0</i2><i3>_</i3><i4>1</i4>
<i1>4</i1><i2>1</i2><i3>_</i3><i4>1</i4>
<i1>4</i1><i2>1</i2><i3>_</i3><i4>2</i4>
<i1>4</i1><i2>2</i2><i3>_</i3><i4>1</i4>
<i1>4</i1><i2>2</i2><i3>_</i3><i4>2</i4>
<i1>4</i1><i2>3</i2><i3>_</i3><i4>1</i4>
<i1>4</i1><i2>3</i2><i3>_</i3><i4>2</i4>
<i1>4</i1><i2>4</i2><i3>_</i3><i4>1</i4>
<i1>4</i1><i2>4</i2><i3>_</i3><i4>2</i4>
<i1>4</i1><i2>5</i2><i3>_</i3><i4>1</i4>
<i1>4</i1><i2>5</i2><i3>_</i3><i4>2</i4>
<i1>4</i1><i2>6</i2><i3>_</i3><i4>1</i4>
<i1>4</i1><i2>6</i2><i3>_</i3><i4>2</i4>
<i1>4</i1><i2>7</i2><i3>_</i3><i4>1</i4>
<i1>5</i1><i2>1</i2><i3>1</i3><i4>1</i4>
<i1>5</i1><i2>1</i2><i3>1</i3><i4>2</i4>
<i1>5</i1><i2>1</i2><i3>1</i3><i4>3</i4>
<i1>5</i1><i2>1</i2><i3>1</i3><i4>4</i4>
<i1>5</i1><i2>1</i2><i3>2</i3><i4>1</i4>
<i1>5</i1><i2>1</i2><i3>2</i3><i4>2</i4>
<i1>5</i1><i2>1</i2><i3>2</i3><i4>3</i4>
<i1>5</i1><i2>1</i2><i3>2</i3><i4>4</i4>
<i1>5</i1><i2>2</i2><i3>1</i3><i4>1</i4>
<i1>5</i1><i2>2</i2><i3>1</i3><i4>2</i4>
<i1>5</i1><i2>2</i2><i3>1</i3><i4>3</i4>
<i1>5</i1><i2>2</i2><i3>1</i3><i4>4</i4>
<i1>5</i1><i2>2</i2><i3>2</i3><i4>1</i4>
<i1>5</i1><i2>2</i2><i3>2</i3><i4>2</i4>
<i1>5</i1><i2>2</i2><i3>2</i3><i4>3</i4>
<i1>5</i1><i2>3</i2><i3>1</i3><i4>1</i4>
<i1>5</i1><i2>3</i2><i3>1</i3><i4>2</i4>
<i1>5</i1><i2>3</i2><i3>1</i3><i4>3</i4>
<i1>5</i1><i2>3</i2><i3>1</i3><i4>4</i4>
<i1>5</i1><i2>3</i2><i3>2</i3><i4>1</i4>
<i1>5</i1><i2>3</i2><i3>2</i3><i4>2</i4>
<i1>5</i1><i2>4</i2><i3>1</i3><i4>1</i4>
<i1>5</i1><i2>4</i2><i3>1</i3><i4>2</i4>
<i1>5</i1><i2>4</i2><i3>2</i3><i4>1</i4>
<i1>5</i1><i2>4</i2><i3>2</i3><i4>2</i4>
<i1>5</i1><i2>5</i2><i3>1</i3><i4>1</i4>
<i1>5</i1><i2>5</i2><i3>1</i3><i4>2</i4>
<i1>5</i1><i2>5</i2><i3>2</i3><i4>1</i4>
<i1>5</i1><i2>5</i2><i3>2</i3><i4>2</i4>
<i1>5</i1><i2>6</i2><i3>1</i3><i4>1</i4>
<i1>5</i1><i2>6</i2><i3>1</i3><i4>2</i4>
<i1>5</i1><i2>7</i2><i3>1</i3><i4>1</i4>
<i1>5</i1><i2>7</i2><i3>1</i3><i4>2</i4>
<i1>6</i1><i2>1</i2><i3>_</i3><i4>1</i4>
<i1>6</i1><i2>1</i2><i3>_</i3><i4>2</i4>
<i1>6</i1><i2>1</i2><i3>_</i3><i4>3</i4>
<i1>6</i1><i2>2</i2><i3>_</i3><i4>1</i4>
<i1>6</i1><i2>2</i2><i3>_</i3><i4>2</i4>
<i1>6</i1><i2>3</i2><i3>_</i3><i4>1</i4>
<i1>6</i1><i2>3</i2><i3>_</i3><i4>2</i4>
<i1>6</i1><i2>4</i2><i3>_</i3><i4>1</i4>
<i1>6</i1><i2>4</i2><i3>_</i3><i4>2</i4>
<i1>6</i1><i2>4</i2><i3>_</i3><i4>3</i4>
<i1>6</i1><i2>5</i2><i3>_</i3><i4>1</i4>
<i1>6</i1><i2>5</i2><i3>_</i3><i4>2</i4>
<i1>7</i1><i2>1</i2><i3>_</i3><i4>1</i4>
<i1>7</i1><i2>1</i2><i3>_</i3><i4>2</i4>
<i1>7</i1><i2>2</i2><i3>_</i3><i4>1</i4>
<i1>7</i1><i2>2</i2><i3>_</i3><i4>2</i4>
<i1>7</i1><i2>3</i2><i3>_</i3><i4>1</i4>
<i1>7</i1><i2>3</i2><i3>_</i3><i4>2</i4>
<i1>8</i1><i2>1</i2><i3>_</i3><i4>1</i4>
<i1>8</i1><i2>1</i2><i3>_</i3><i4>2</i4>
<i1>8</i1><i2>1</i2><i3>_</i3><i4>3</i4>
<i1>8</i1><i2>2</i2><i3>_</i3><i4>1</i4>
<i1>8</i1><i2>2</i2><i3>_</i3><i4>2</i4>
<i1>8</i1><i2>2</i2><i3>_</i3><i4>3</i4>
<i1>8</i1><i2>3</i2><i3>_</i3><i4>1</i4>
<i1>8</i1><i2>3</i2><i3>_</i3><i4>2</i4>
<i1>8</i1><i2>3</i2><i3>_</i3><i4>3</i4>
<i1>8</i1><i2>4</i2><i3>_</i3><i4>1</i4>
<i1>8</i1><i2>4</i2><i3>_</i3><i4>2</i4>
<i1>8</i1><i2>9</i2><i3>_</i3><i4>1</i4>
<i1>8</i1><i2>9</i2><i3>_</i3><i4>2</i4>
<i1>9</i1><i2>1</i2><i3>_</i3><i4>1</i4>
<i1>9</i1><i2>1</i2><i3>_</i3><i4>2</i4>
<i1>9</i1><i2>2</i2><i3>_</i3><i4>1</i4>
<i1>9</i1><i2>3</i2><i3>_</i3><i4>1</i4>
<i1>9</i1><i2>4</i2><i3>_</i3><i4>1</i4>
<i1>9</i1><i2>5</i2><i3>_</i3><i4>1</i4>
<i1>9</i1><i2>6</i2><i3>_</i3><i4>1</i4>
<i1>9</i1><i2>6</i2><i3>_</i3><i4>2</i4>
<i1>9</i1><i2>7</i2><i3>_</i3><i4>1</i4>
<i1></i1><i2></i2><i3></i3><i4></i4>
<i1>F</i1><i2>1</i2><i3>_</i3><i4>1</i4>
<i1>F</i1><i2>1</i2><i3>_</i3><i4>2</i4>
<i1>F</i1><i2>1</i2><i3>_</i3><i4>4</i4>
<i1>F</i1><i2>2</i2><i3>_</i3><i4>1</i4>
<i1>F</i1><i2>2</i2><i3>_</i3><i4>2</i4>
<i1>F</i1><i2>2</i2><i3>_</i3><i4>4</i4>
<i1>F</i1><i2>3</i2><i3>_</i3><i4>1</i4>
<i1>F</i1><i2>3</i2><i3>_</i3><i4>2</i4>
<i1>F</i1><i2>3</i2><i3>_</i3><i4>3</i4>
<i1>F</i1><i2>4</i2><i3>_</i3><i4>1</i4>
<i1>F</i1><i2>4</i2><i3>_</i3><i4>2</i4>
<i1>F</i1><i2>5</i2><i3>_</i3><i4>1</i4>
<i1>F</i1><i2>5</i2><i3>_</i3><i4>2</i4>
<i1>F</i1><i2>5</i2><i3>_</i3><i4>3</i4>
<i1>F</i1><i2>5</i2><i3>_</i3><i4>4</i4>
<i1>F</i1><i2>6</i2><i3>_</i3><i4>1</i4>
<i1>F</i1><i2>6</i2><i3>_</i3><i4>2</i4>
<i1>F</i1><i2>6</i2><i3>_</i3><i4>4</i4>
<i1>J</i1><i2>C</i2><i3>_</i3><i4>1</i4>
<i1>J</i1><i2>C</i2><i3>_</i3><i4>2</i4>
<i1>J</i1><i2>C</i2><i3>_</i3><i4>4</i4>
<i1>J</i1><i2>P</i2><i3>1</i3><i4>1</i4>
<i1>J</i1><i2>P</i2><i3>1</i3><i4>2</i4>
<i1>J</i1><i2>P</i2><i3>2</i3><i4>1</i4>
<i1>J</i1><i2>P</i2><i3>2</i3><i4>2</i4>
<i1>J</i1><i2>Z</i2><i3>_</i3><i4>1</i4>
<i1>J</i1><i2>Z</i2><i3>_</i3><i4>2</i4>
end_of_list
    ;
    my @list = split(/\r?\n/, $list);
    pop(@list) if($list[$#list] eq '');
    return \@list;
}



#------------------------------------------------------------------------------
# Create trie of permitted feature structures. This will be needed for strict
# encoding. This BEGIN block cannot appear before the definition of the list()
# function.
#------------------------------------------------------------------------------
BEGIN
{
    # When scanning tags for permitted feature structures, do not consider tags
    # that require setting the 'other' feature.
    my $no_other = 1;
    # Store the hash reference in a global variable.
    $permitted = tagset::common::get_permitted_structures_joint(list(), \&decode, $no_other);
}



1;
