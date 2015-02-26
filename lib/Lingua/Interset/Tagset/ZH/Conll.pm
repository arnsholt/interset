# ABSTRACT: Driver for the Chinese tagset of the CoNLL 2006 & 2007 Shared Tasks (derived from the Academia Sinica Treebank).
# Documentation in Huang, Chen, Lin: Corpus on Web: Introducing the First Tagged and Balanced Chinese Corpus.
# Copyright © 2007, 2015 Dan Zeman <zeman@ufal.mff.cuni.cz>

package Lingua::Interset::Tagset::ZH::Conll;
use strict;
use warnings;
our $VERSION = '2.041';

use utf8;
use open ':utf8';
use namespace::autoclean;
use Moose;
extends 'Lingua::Interset::Tagset::Conll';



#------------------------------------------------------------------------------
# Returns the tagset id that should be set as the value of the 'tagset' feature
# during decoding. Every derived class must (re)define this method! The result
# should correspond to the last two parts in package name, lowercased.
# Specifically, it should be the ISO 639-2 language code, followed by '::' and
# a language-specific tagset id. Example: 'cs::multext'.
#------------------------------------------------------------------------------
sub get_tagset_id
{
    return 'zh::conll';
}



#------------------------------------------------------------------------------
# Creates atomic drivers for surface features.
#------------------------------------------------------------------------------
sub _create_atoms
{
    my $self = shift;
    my %atoms;
    # PART OF SPEECH ####################
    $atoms{pos} = $self->create_atom
    (
        'surfeature' => 'pos',
        'decode_map' =>
        {
            # noun or pronoun
            'Na' => ['pos' => 'noun', 'nountype' => 'com'],
            'Nb' => ['pos' => 'noun', 'nountype' => 'prop'],
            # location noun (including some proper nouns, e.g. Feizhou = Africa)
            'Nc' => ['pos' => 'noun', 'advtype' => 'loc'],
            # time noun
            'Nd' => ['pos' => 'noun', 'advtype' => 'tim'],
            # classifier (measure word)
            'Nf' => ['pos' => 'noun', 'nountype' => 'class'],
            # pronoun
            'Nh' => ['pos' => 'noun', 'prontype' => 'prn'],
            ###!!! ???
            'Nv' => ['pos' => 'noun', 'other' => {'subpos' => 'Nv'}],
            # adjective
            'A'  => ['pos' => 'adj'],
            # determiner
            # anaphoric determiner (this, that)
            'Nep' => ['pos' => 'adj', 'prontype' => 'dem'],
            # classifying determiner (much, half)
            'Neq' => ['pos' => 'adj', 'prontype' => 'prn'],
            # specific determiner (you, shang, ge = every)
            'Nes' => ['pos' => 'adj', 'prontype' => 'prn'],
            # numeric determiner (one, two, three)
            'Neu' => ['pos' => 'num', 'numtype' => 'card'],
            # verb
            'V'   => ['pos' => 'verb'],
            # adverb
            'D'   => ['pos' => 'adv'],
            # measure word, quantifier
            ###!!! There ought to be a better solution but from the examples from the corpus I seem unable to grasp the nature of these words.
            'DM'  => ['pos' => 'adv'],
            # postposition (qian = before)
            'Ng'  => ['pos' => 'adp', 'adpostype' => 'post'],
            # preposition (66 kinds, 66 different tags)
            'P'   => ['pos' => 'adp', 'adpostype' => 'prep'],
            # conjunction
            'C'   => ['pos' => 'conj'],
            # the "de" particle (two kinds)
            'DE'  => ['pos' => 'part'],
            # particle
            'T'   => ['pos' => 'part'],
            # interjection
            'I'   => ['pos' => 'int']
        },
        'encode_map' =>
        {
            'pos' => { 'noun' => 'Na',
                       'adj'  => 'A',
                       'num'  => 'Neu',
                       'verb' => 'V',
                       'adv'  => 'D',
                       'adp'  => { 'adpostype' => { 'prep' => 'P',
                                                    'post' => 'Ng' }},
                       'conj' => 'C',
                       'part' => 'T',
                       'int'  => 'I' }
        }
    );
    return \%atoms;
}



#------------------------------------------------------------------------------
# Creates the list of all surface CoNLL features that can appear in the FEATS
# column. This list will be used in decode().
#------------------------------------------------------------------------------
sub _create_features_all
{
    my $self = shift;
    my @features = ('pos', 'gender', 'agreement', 'possagreement', 'case', 'pccase', 'degree', 'adjvtype', 'tense', 'aspect', 'comod', 'mood', 'negativeness', 'voice', 'copula');
    return \@features;
}



#------------------------------------------------------------------------------
# Creates the list of surface CoNLL features that can appear in the FEATS
# column with particular parts of speech. This list will be used in encode().
#------------------------------------------------------------------------------
sub _create_features_pos
{
    my $self = shift;
    my %features =
    (
    );
    return \%features;
}



#------------------------------------------------------------------------------
# Decodes a physical tag (string) and returns the corresponding feature
# structure.
#------------------------------------------------------------------------------
sub decode
{
    my $self = shift;
    my $tag = shift;
    my $fs = Lingua::Interset::FeatureStructure->new();
    $fs->set_tagset('zh::conll');
    my $atoms = $self->atoms();
    # Three components: pos, subpos, features (always empty).
    # example: N\tNaa\t_
    my ($pos, $subpos, $features) = split(/\s+/, $tag);
    # The underscore character is used if there are no features.
    $features = '' if($features eq '_');
    my @features = split(/\|/, $features);
    $atoms->{pos}->decode_and_merge_hard("$pos $subpos", $fs);
    foreach my $feature (@features)
    {
        $atoms->{feature}->decode_and_merge_hard($feature, $fs);
    }
    return $fs;
}



#------------------------------------------------------------------------------
# Takes feature structure and returns the corresponding physical tag (string).
#------------------------------------------------------------------------------
sub encode
{
    my $self = shift;
    my $fs = shift; # Lingua::Interset::FeatureStructure
    my $atoms = $self->atoms();
    my $possubpos = $atoms->{pos}->encode($fs);
    my ($pos, $subpos) = split(/\s+/, $possubpos);
    my $fpos = $possubpos;
    my $feature_names = $self->get_feature_names($fpos);
    my $value_only = 1;
    my $tag = $self->encode_conll($fs, $pos, $subpos, $feature_names, $value_only);
    return $tag;
}



#------------------------------------------------------------------------------
# Returns reference to list of known tags.
# Tags were collected from the corpus, 294 distinct tags found.
#------------------------------------------------------------------------------
sub list
{
    my $self = shift;
    my $list = <<end_of_list
A\tA\t_
C\tCaa\t_
C\tCaa[P1]\t_
C\tCaa[P1}\t_
C\tCaa[+P2]\t_
C\tCaa[P2]\t_
C\tCaa[P2}\t_
C\tCab\t_
C\tCbaa\t_
C\tCbab\t_
C\tCbba\t_
C\tCbbb\t_
C\tCbca\t_
C\tCbcb\t_
D\tDaa\t_
D\tDab\t_
D\tDbaa\t_
D\tDbab\t_
D\tDbb\t_
D\tDbc\t_
D\tDc\t_
D\tDd\t_
D\tDfa\t_
D\tDfb\t_
D\tDg\t_
D\tDh\t_
D\tDj\t_
D\tDk\t_
DE\tDE\t_
DE\tDi\t_
DM\tDM\t_
Head\tHead\t_
I\tI\t_
Ne\tNep\t_
Ne\tNeqa\t_
Ne\tNeqb\t_
Ne\tNes\t_
Ne\tNeu\t_
Ng\tNg\t_
N\tNaa\t_
N\tNaa[+SPO]\t_
N\tNab\t_
N\tNab[+SPO]\t_
N\tNac\t_
N\tNac[+SPO]\t_
N\tNad\t_
N\tNad[+SPO]\t_
N\tNaea\t_
N\tNaeb\t_
N\tNba\t_
N\tNbc\t_
N\tNca\t_
N\tNcb\t_
N\tNcc\t_
N\tNcda\t_
N\tNcdb\t_
N\tNce\t_
N\tNdaaa\t_
N\tNdaab\t_
N\tNdaac\t_
N\tNdaad\t_
N\tNdaba\t_
N\tNdabb\t_
N\tNdabc\t_
N\tNdabd\t_
N\tNdabe\t_
N\tNdabf\t_
N\tNdbb\t_
N\tNdc\t_
N\tNdda\t_
N\tNddb\t_
N\tNddc\t_
N\tNfa\t_
N\tNfc\t_
N\tNfd\t_
N\tNfe\t_
N\tNfg\t_
N\tNfh\t_
N\tNfi\t_
N\tNhaa\t_
N\tNhab\t_
N\tNhac\t_
N\tNhb\t_
N\tNhc\t_
N\tNv1\t_
N\tNv2\t_
N\tNv3\t_
N\tNv4\t_
P\tP01\t_
P\tP02\t_
P\tP03\t_
P\tP04\t_
P\tP06\t_
P\tP06[P1]\t_
P\tP06[P2]\t_
P\tP06[+part]\t_
P\tP07\t_
P\tP08\t_
P\tP08[+part]\t_
P\tP09\t_
P\tP10\t_
P\tP11\t_
P\tP11[P1]\t_
P\tP11[P2]\t_
P\tP11[+part]\t_
P\tP12\t_
P\tP13\t_
P\tP14\t_
P\tP15\t_
P\tP16\t_
P\tP17\t_
P\tP18\t_
P\tP18[+part]\t_
P\tP19\t_
P\tP19[P1]\t_
P\tP19[P2]\t_
P\tP19[+part]\t_
P\tP20\t_
P\tP20[+part]\t_
P\tP21\t_
P\tP21[+part]\t_
P\tP22\t_
P\tP23\t_
P\tP24\t_
P\tP25\t_
P\tP26\t_
P\tP27\t_
P\tP28\t_
P\tP29\t_
P\tP30\t_
P\tP31\t_
P\tP31[+P1]\t_
P\tP31[P1]\t_
P\tP31[+P2]\t_
P\tP31[P2]\t_
P\tP31[+part]\t_
P\tP31[part]\t_
P\tP32\t_
P\tP32[+part]\t_
P\tP35\t_
P\tP35[+part]\t_
P\tP36\t_
P\tP37\t_
P\tP38\t_
P\tP39\t_
P\tP40\t_
P\tP41\t_
P\tP42\t_
P\tP42[+part]\t_
P\tP43\t_
P\tP44\t_
P\tP45\t_
P\tP46\t_
P\tP46[+part]\t_
P\tP47\t_
P\tP48\t_
P\tP48[+part]\t_
P\tP49\t_
P\tP50\t_
P\tP51\t_
P\tP52\t_
P\tP53\t_
P\tP54\t_
P\tP55\t_
P\tP55[+part]\t_
P\tP58\t_
P\tP59\t_
P\tP59[+part]\t_
P\tP60\t_
P\tP61\t_
P\tP62\t_
P\tP63\t_
P\tP64\t_
P\tP65\t_
P\tP66\t_
Str\tStr\t_
T\tTa\t_
T\tTb\t_
T\tTc\t_
T\tTd\t_
V\tV_11\t_
V\tV_12\t_
V\tV_2\t_
V\tVA\t_
V\tVA11\t_
V\tVA11[+ASP]\t_
V\tVA11[+NEG]\t_
V\tVA12\t_
V\tVA12[+NEG]\t_
V\tVA12[+SPV]\t_
V\tVA13\t_
V\tVA13[+ASP]\t_
V\tVA2\t_
V\tVA2[+ASP]\t_
V\tVA2[+SPV]\t_
V\tVA3\t_
V\tVA3[+ASP]\t_
V\tVA4\t_
V\tVA4[+ASP]\t_
V\tVA4[+NEG]\t_
V\tVA4[+NEG,+ASP]\t_
V\tVA4[+SPV]\t_
V\tVB11\t_
V\tVB11[+ASP]\t_
V\tVB11[+DE]\t_
V\tVB11[+NEG]\t_
V\tVB11[+SPV]\t_
V\tVB12\t_
V\tVB12[+ASP]\t_
V\tVB12[+NEG]\t_
V\tVB2\t_
V\tVB2[+ASP]\t_
V\tVB2[+NEG]\t_
V\tVC1\t_
V\tVC1[+NEG]\t_
V\tVC1[+SPV]\t_
V\tVC2\t_
V\tVC2[+ASP]\t_
V\tVC2[+DE]\t_
V\tVC2[+NEG]\t_
V\tVC2[+SPV]\t_
V\tVC31\t_
V\tVC31[+ASP]\t_
V\tVC31[+DE]\t_
V\tVC31[+DE,+ASP]\t_
V\tVC31[+NEG]\t_
V\tVC31[+SPV]\t_
V\tVC32\t_
V\tVC32[+DE]\t_
V\tVC32[+SPV]\t_
V\tVC33\t_
V\tVD1\t_
V\tVD2\t_
V\tVD2[+NEG]\t_
V\tVE11\t_
V\tVE12\t_
V\tVE2\t_
V\tVE2[+DE]\t_
V\tVE2[+NEG]\t_
V\tVE2[+SPV]\t_
V\tVF1\t_
V\tVF2\t_
V\tVG1\t_
V\tVG1[+NEG]\t_
V\tVG2\t_
V\tVG2[+DE]\t_
V\tVG2[+NEG]\t_
V\tVH11\t_
V\tVH11[+asp]\t_
V\tVH11[+ASP]\t_
V\tVH11[+DE]\t_
V\tVH11[+NEG]\t_
V\tVH11[+SPV]\t_
V\tVH12\t_
V\tVH12[+ASP]\t_
V\tVH13\t_
V\tVH14\t_
V\tVH15\t_
V\tVH15[+NEG]\t_
V\tVH16\t_
V\tVH16[+ASP]\t_
V\tVH16[+NEG]\t_
V\tVH16[+SPV]\t_
V\tVH17\t_
V\tVH21\t_
V\tVH21[+ASP]\t_
V\tVH21[+Dbab]\t_
V\tVH21[+DE]\t_
V\tVH21[+NEG]\t_
V\tVH22\t_
V\tVI1\t_
V\tVI2\t_
V\tVI2[+ASP]\t_
V\tVI3\t_
V\tVJ1\t_
V\tVJ1[+DE]\t_
V\tVJ1[+NEG]\t_
V\tVJ2\t_
V\tVJ2[+NEG]\t_
V\tVJ2[+SPV]\t_
V\tVJ3\t_
V\tVJ3[+DE]\t_
V\tVJ3[+NEG]\t_
V\tVK1\t_
V\tVK1[+ASP]\t_
V\tVK1[+DE]\t_
V\tVK1[+NEG]\t_
V\tVK2\t_
V\tVK2[+NEG]\t_
V\tVL1\t_
V\tVL2\t_
V\tVL3\t_
V\tVL4\t_
V\tVP\t_
end_of_list
    ;
    # Protect from editors that replace tabs by spaces.
    $list =~ s/ \s+/\t/sg;
    my @list = split(/\r?\n/, $list);
    return \@list;
}



1;

=head1 SYNOPSIS

  use Lingua::Interset::Tagset::ZH::Conll;
  my $driver = Lingua::Interset::Tagset::ZH::Conll->new();
  my $fs = $driver->decode("N\tNaa\t_");

or

  use Lingua::Interset qw(decode);
  my $fs = decode('zh::conll', "N\tNaa\t_");

=head1 DESCRIPTION

Interset driver for the Chinese tagset of the CoNLL 2006 and 2007 Shared Tasks.
CoNLL tagsets in Interset are traditionally three values separated by tabs.
The values come from the CoNLL columns CPOS, POS and FEAT. For Chinese,
these values are derived from the tagset of the Academia Sinica Treebank
and the FEAT column is always empty.

=head1 SEE ALSO

L<Lingua::Interset>,
L<Lingua::Interset::Tagset>,
L<Lingua::Interset::Tagset::Conll>,
L<Lingua::Interset::FeatureStructure>

=cut
