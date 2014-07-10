# ABSTRACT: Driver for the Czech tagset of the Prague Spoken Corpus (Pražský mluvený korpus).
# Copyright © 2009, 2010, 2014 Dan Zeman <zeman@ufal.mff.cuni.cz>

package Lingua::Interset::Tagset::CS::Pmk;
use strict;
use warnings;
# VERSION: generated by DZP::OurPkgVersion

use utf8;
use open ':utf8';
use namespace::autoclean;
use Moose;
extends 'Lingua::Interset::Tagset';



has 'atoms' => ( isa => 'HashRef', is => 'ro', builder => '_create_atoms', lazy => 1 );



#------------------------------------------------------------------------------
# Creates atomic drivers for 11 surface features.
#------------------------------------------------------------------------------
sub _create_atoms
{
    my $self = shift;
    my %atoms;
    # GENDER ####################
    # Encoding of gender varies depending on context (part of speech).
    ###!!! Map differing number codes to one set first.
    #my %map =
    #(
    #    '1' => {'1'=>'M', '2'=>'I', '3'=>'F', '4'=>'N', '9'=>'X'},
    #    '2' => {'1'=>'M', '2'=>'I', '3'=>'F', '4'=>'N', '9'=>'X'},
    #    '3' => {'1'=>'M', '2'=>'I', '3'=>'F', '4'=>'N', '5'=>'B', '9'=>'X'},
    #    '4' => {'1'=>'M', '2'=>'I', '3'=>'F', '4'=>'N', '5'=>'B', '9'=>'X'},
    #    'P' => {'1'=>'M', '2'=>'I', '3'=>'F', '4'=>'N', '5'=>'X'}
    #);
    $atoms{gender} = $self->create_atom
    (
        'surfeature' => 'gender',
        'decode_map' =>
        {
            'M' => ['gender' => 'masc', 'animateness' => 'anim'],
            'I' => ['gender' => 'masc', 'animateness' => 'inan'],
            'F' => ['gender' => 'fem'],
            'N' => ['gender' => 'neut'],
            # Some pronouns ('já', 'ty') do not distinguish grammatical gender and have this value.
            # Note that this value ('B') is not identical to the general "unknown gender" ('X').
            'B' => ['other' => 'bezrodé'],
            'X' => []
        },
        'encode_map' =>

            { 'gender' => { 'masc' => { 'animateness' => { 'inan' => 'I',
                                                           '@'    => 'M' }},
                            'fem'  => 'F',
                            'neut' => 'N',
                            '@'    => { 'other' => { 'bezrodé' => 'B',
                                                     '@'       => 'X' }}}}
    );
    # NUMBER ####################
    # Encoding of number varies depending on context (part of speech).
    ###!!! Map differing number codes to one set first.
    #my %map =
    #(
    #    '1' => {'1'=>'S', '2'=>'P', '3'=>'T', '4'=>'D', '5'=>'C', '9'=>'X'},
    #    '2' => {'1'=>'S', '2'=>'P', '3'=>'D', '4'=>'C', '9'=>'X'},
    #    '3' => {'1'=>'S', '2'=>'P', '3'=>'D', '4'=>'V', '9'=>'X'},
    #    '4' => {'1'=>'S', '2'=>'P', '3'=>'D', '4'=>'C', '9'=>'X'},
    #    'P' => {'1'=>'S', '2'=>'P', '3'=>'T', '4'=>'X'}
    #);
    $atoms{number} = $self->create_atom
    (
        'surfeature' => 'number',
        'decode_map' =>
        {
            'S' => ['number' => 'sing'],
            'P' => ['number' => 'plu'],
            'T' => ['number' => 'ptan'],
            'D' => ['number' => 'dual'],
            'C' => ['number' => 'coll'],
            # "Vykání": using plural to address a single person in a polite manner.
            'V' => ['number' => 'plu', 'politeness' => 'pol'],
            'X' => []
        },
        'encode_map' =>

            { 'number' => { 'sing' => 'S',
                            'dual' => 'D',
                            'plu'  => { 'politeness' => { 'pol' => 'V',
                                                          '@'   => 'P' }},
                            'ptan' => 'T',
                            'coll' => 'C',
                            '@'    => 'X' }}
    );
    # GENDER AND NUMBER OF PARTICIPLES ####################
    $atoms{participle_gender_number} = $self->create_atom
    (
        'surfeature' => 'participle_gender_number',
        'decode_map' =>
        {
            '1' => ['gender' => 'masc', 'animateness' => 'anim', 'number' => 'sing'],
            '2' => ['gender' => 'masc', 'animateness' => 'inan', 'number' => 'sing'],
            '3' => ['gender' => 'fem', 'number' => 'sing'],
            '4' => ['gender' => 'neut', 'number' => 'sing'],
            '5' => ['gender' => 'masc', 'animateness' => 'anim', 'number' => 'plu'],
            '6' => ['gender' => 'masc', 'animateness' => 'inan', 'number' => 'plu'],
            '7' => ['gender' => 'fem', 'number' => 'plu'],
            '8' => ['gender' => 'neut', 'number' => 'plu'],
            # - -> neurčuje se / not specified => empty value
            # 9 => nelze určit / cannot specify => empty value
            # If this is not a participle number may still be specified but will be encoded elsewhere; gender will be '-'.
            # It can also happen that person+number is 3rd+singular (5=3) and gender+number is unknown (9=9). Example: "nařízíno"
            '9' => ['other' => 'gender=9'],
            '-' => ['other' => 'gender=-']
        },
        'encode_map' =>

            { 'other' => { 'gender=9' => '9',
                           'gender=-' => '-',
                           '@'        => { 'number' => { 'sing' => { 'gender' => { 'masc' => { 'animateness' => { 'inan' => '2',
                                                                                                                  '@'    => '1' }},
                                                                                   'fem'  => '3',
                                                                                   '@'    => '4' }},
                                                         'plu'  => { 'gender' => { 'masc' => { 'animateness' => { 'inan' => '6',
                                                                                                                  '@'    => '5' }},
                                                                                   'fem'  => '7',
                                                                                   '@'    => '8' }},
                                                         '@'    => '9' }}}}
    );
    # PERSON AND NUMBER OF VERBS ####################
    $atoms{person_number} = $self->create_atom
    (
        'surfeature' => 'person_number',
        'decode_map' =>
        {
            '1' => ['person' => '1', 'number' => 'sing'],
            '2' => ['person' => '2', 'number' => 'sing'],
            '3' => ['person' => '3', 'number' => 'sing'],
            '4' => ['person' => '1', 'number' => 'plu'],
            '5' => ['person' => '2', 'number' => 'plu'],
            '6' => ['person' => '3', 'number' => 'plu'],
            '7' => ['verbform' => 'inf', 'voice' => 'act'],
            '8' => ['verbform' => 'inf', 'voice' => 'pass'],
            # "non-personal" (neosobní) usage of the third person
            # "říkalo se", "říká se": subject "ono" (it) is a filler that does not denote any semantic object
            '9' => ['person' => '3', 'number' => 'sing', 'other' => 'nonpers'],
            # non-personal plural
            # only two occurrences in the whole corpus: "řikali", "hlásaj"
            '0' => ['person' => '3', 'number' => 'plu', 'other' => 'nonpers'],
            # - -> neurčuje se / not specified => empty value
            # can conflict with participle gender+number
            '-' => ['other' => 'person=-']
        },
        'encode_map' =>

            { 'other' => { 'person=-' => '-',
                           '@'        => { 'verbform' => { 'inf' => { 'voice' => { 'pass' => '8',
                                                                                   '@'    => '7' }},
                                                           '@'   => { 'number' => { 'plu'  => { 'person' => { '1' => '4',
                                                                                                              '2' => '5',
                                                                                                              '@' => { 'other' => { 'nonpers' => '0',
                                                                                                                                    '@'       => '6' }}}},
                                                                                    'sing' => { 'person' => { '1' => '1',
                                                                                                              '2' => '2',
                                                                                                              '@' => { 'other' => { 'nonpers' => '9',
                                                                                                                                    '@'       => '3' }}}},
                                                                                    '@'    => '-' }}}}}}
    );
    # CASE ####################
    $atoms{case} = $self->create_simple_atom
    (
        'intfeature' => 'case',
        'simple_decode_map' =>
        {
            '1' => 'nom',
            '2' => 'gen',
            '3' => 'dat',
            '4' => 'acc',
            '5' => 'voc',
            '6' => 'loc',
            '7' => 'ins'
            ###!!!
            # valency-based case of prepositions: "other" = 8
            # case of nouns, adjectives etc.: "cannot specify or indeclinable" = 9
        }
    );
    # COUNTED CASE ####################
    # (pád počítané jmenné fráze)
    $atoms{counted_case} = $self->create_simple_atom
    (
        'intfeature' => 'other',
        'simple_decode_map' =>
        {
            '1' => 'ccase=nom',
            '2' => 'ccase=gen',
            '3' => 'ccase=dat',
            '4' => 'ccase=acc',
            '5' => 'ccase=voc',
            '6' => 'ccase=loc',
            '7' => 'ccase=ins'
        },
        'encode_default' => '9'
    );
    # DEGREE OF COMPARISON ####################
    $atoms{degree} = $self->create_simple_atom
    (
        'intfeature' => 'degree',
        'simple_decode_map' =>
        {
            '-' => 'pos',
            '2' => 'comp',
            '3' => 'sup'
        }
    );
    # MOOD, TENSE AND VOICE ####################
    $atoms{mood_tense_voice} = $self->create_atom
    (
        'surfeature' => 'mood_tense_voice',
        'decode_map' =>
        {
            '1' => ['verbform' => 'fin', 'mood' => 'ind', 'tense' => 'pres', 'voice' => 'act'],  # dělá
            '2' => ['verbform' => 'fin', 'mood' => 'ind', 'tense' => 'pres', 'voice' => 'pass'], # je dělán
            '3' => ['verbform' => 'fin', 'mood' => 'cnd', 'tense' => 'pres', 'voice' => 'act'],  # dělal by
            '4' => ['verbform' => 'fin', 'mood' => 'cnd', 'tense' => 'pres', 'voice' => 'pass'], # byl by dělán
            '5' => ['verbform' => 'fin', 'mood' => 'ind', 'tense' => 'past', 'voice' => 'act'],  # dělal
            '6' => ['verbform' => 'fin', 'mood' => 'ind', 'tense' => 'past', 'voice' => 'pass'], # byl dělán
            '7' => ['verbform' => 'fin', 'mood' => 'cnd', 'tense' => 'past', 'voice' => 'act'],  # byl by dělal
            '8' => ['verbform' => 'fin', 'mood' => 'cnd', 'tense' => 'past', 'voice' => 'pass'], # byl by byl dělán
            '9' => ['verbform' => 'fin', 'mood' => 'ind', 'tense' => 'fut',  'voice' => 'act'],  # bude dělat
            '0' => ['verbform' => 'fin', 'mood' => 'ind', 'tense' => 'fut',  'voice' => 'pass']  # bude dělán
        },
        'encode_map' =>

            { 'verbform' => { 'trans' => '-',
                              '@'     => { 'mood' => { 'cnd' => { 'tense' => { 'past' => { 'voice' => { 'pass' => '8',
                                                                                                        '@'    => '7' }},
                                                                               '@'    => { 'voice' => { 'pass' => '4',
                                                                                                        '@'    => '3' }}}},
                                                       '@'   => { 'tense' => { 'fut'  => { 'voice' => { 'pass' => '0',
                                                                                                        '@'    => '9' }},
                                                                               'past' => { 'voice' => { 'pass' => '6',
                                                                                                        '@'    => '5' }},
                                                                               'pres' => { 'voice' => { 'pass' => '2',
                                                                                                        '@'    => '1' }},
                                                                               '@'    => '-' }}}}}}
    );
    # IMPERATIVE OR NON-FINITE VERB FORM ####################
    $atoms{nonfinite_verb_form} = $self->create_atom
    (
        'surfeature' => 'nonfinite_verb_form',
        'decode_map' =>
        {
            '1' => ['verbform' => 'fin', 'mood' => 'imp', 'voice' => 'act'],      # dělej
            '2' => ['verbform' => 'fin', 'mood' => 'imp', 'voice' => 'pass'],     # buď dělán
            '3' => ['verbform' => 'part', 'voice' => 'pass'],                     # dělán
            '4' => ['verbform' => 'trans', 'tense' => 'pres', 'voice' => 'act'],  # dělaje
            '5' => ['verbform' => 'trans', 'tense' => 'pres', 'voice' => 'pass'], # jsa dělán
            '6' => ['verbform' => 'trans', 'tense' => 'past', 'voice' => 'act'],  # udělav
            '7' => ['verbform' => 'trans', 'tense' => 'past', 'voice' => 'pass']  # byv udělán
        },
        'encode_map' =>

            { 'mood' => { 'imp' => { 'voice' => { 'pass' => '2',
                                                  '@'    => '1' }},
                          '@'   => { 'verbform' => { 'trans' => { 'tense' => { 'past' => { 'voice' => { 'pass' => '7',
                                                                                                        '@'    => '6' }},
                                                                               '@'    => { 'voice' => { 'pass' => '5',
                                                                                                        '@'    => '4' }}}},
                                                     'part'  => { 'voice' => { 'pass' => '3',
                                                                               '@'    => '-' }},
                                                     '@'     => '-' }}}}
    );
    # NEGATIVENESS ####################
    $atoms{negativeness} = $self->create_simple_atom
    (
        'intfeature' => 'negativeness',
        'simple_decode_map' =>
        {
            '1' => 'pos',
            '2' => 'neg'
        }
    );
    # STYLE ####################
    $atoms{style} = $self->create_simple_atom
    (
        'intfeature' => 'style',
        'simple_decode_map' =>
        {
            # základní, mluvený, neformální
            '1' => 'coll',
            # neutrální, mluvený, psaný
            '2' => 'norm',
            # knižní
            '3' => 'form',
            # vulgární
            '4' => 'vulg'
        },
        'encode_default' => '2'
    );
    # NOUN TYPE ####################
    # Noun types in PMK mostly reflect how (from what part of speech) the noun was derived.
    $atoms{noun_type} = $self->create_atom
    (
        'surfeature' => 'noun_type',
        'decode_map' =>
        {
            # běžné: konstruktér, rodina, auto
            '1' => [],
            # adjektivní: ženská, vedoucí, nadřízenej
            '2' => ['other' => 'nountype=adj'],
            # zájmenné: naši, vaši
            '3' => ['other' => 'nountype=pron'],
            # číslovkové: dvojka, devítka, šestsettřináctka
            '4' => ['other' => 'nountype=num'],
            # slovesné: postavení, bití, chování
            '5' => ['other' => 'nountype=verb'],
            # slovesné zvratné: věnování se; note: the tag is assigned to "věnování" while "se" has an empty tag
            '6' => ['other' => 'nountype=verb', 'reflex' => 'reflex'],
            # zkratkové slovo: ó dé eska; note: the tag is assigned to "ó" while "dé" and "eska" have empty tags
            # This is not the same as an abbreviated noun.
            '7' => ['other' => 'nountype=abbr'],
            # nesklonné: apartmá, interview, gró
            '9' => ['other' => 'nountype=indecl']
        },
        'encode_map' =>

            { 'reflex' => { 'reflex' => '6',
                            '@'      => { 'other' => { 'nountype=adj'    => '2',
                                                       'nountype=pron'   => '3',
                                                       'nountype=num'    => '4',
                                                       'nountype=verb'   => '5',
                                                       'nountype=abbr'   => '7',
                                                       'nountype=indecl' => '9',
                                                       '@'               => '1' }}}}
    );
    # ADJECTIVE TYPE ####################
    $atoms{adjective_type} = $self->create_atom
    (
        'surfeature' => 'adjective_type',
        'decode_map' =>
        {
            # nespecifické: jiný, prázdnej, řádová
            '1' => [],
            # slovesné: ovlivněný, skličující, vyspělý
            '2' => ['other' => 'adjtype=verb'],
            # přivlastňovací: Martinův, tátový, Klárčiny
            '3' => ['poss' => 'poss']
        },
        'encode_map' =>

            { 'poss' => { 'poss' => '3',
                          '@'    => { 'other' => { 'adjtype=verb' => '2',
                                                   '@'            => '1' }}}}
    );
    # ADJECTIVE SUBTYPE ####################
    $atoms{adjective_subtype} = $self->create_atom
    (
        'surfeature' => 'adjective_subtype',
        'decode_map' =>
        {
            # departicipiální prosté: přeloženej, shořelej, naloženej
            '1' => ['verbform' => 'part'],
            # zvratné: blížícím se, se živícim, drolící se
            '2' => ['reflex' => 'reflex'],
            # jmenná forma sg neutra: (chybná anotace???) prioritní, vytížený, obligátní
            '3' => ['variant' => 'short', 'gender' => 'neut', 'number' => 'sing'],
            # jmenná forma jiná: schopni, ochotni, unaven
            '4' => ['variant' => 'short'],
            # zvratná jmenná forma: si vědom
            '5' => ['variant' => 'short', 'reflex' => 'reflex'],
            # ostatní: chybnejch, normální, hovorový
            '0' => []
        },
        'encode_map' =>

            { 'variant' => { 'short' => { 'reflex' => { 'reflex' => '5',
                                                        '@' => { 'gender' => { 'neut' => { 'number' => { 'sing' => '3',
                                                                                                         '@'    => '4' }},
                                                                               '@'    => '4' }}}},
                             '@'     => { 'reflex' => { 'reflex' => '2',
                                                        '@'      => { 'verbform' => { 'part' => '1',
                                                                                      '@'    => '0' }}}}}}
    );
    # PRONOUN TYPE ####################
    $atoms{pronoun_type} = $self->create_atom
    (
        'surfeature' => 'pronoun_type',
        'decode_map' =>
        {
            # osobní: já, ty, on, ona, ono, my, vy, oni, ony
            '1' => ['prontype' => 'prs'],
            # neurčité: všem, všechno, nějakou, ňáká, něco, některé, každý
            '2' => ['prontype' => 'ind'],
            # osobní zvratné: sebe, sobě, se, si, sebou
            '3' => ['prontype' => 'prs', 'reflex' => 'reflex'],
            # ukazovací: to, takový, tu, ten, tamto, té, tech
            '4' => ['prontype' => 'dem'],
            # tázací: co, jaký, kdo, čim, komu, která
            '5' => ['prontype' => 'int'],
            # vztažné: což, který, která, čeho, čehož, jakým
            '6' => ['prontype' => 'rel'],
            # záporné: žádná, nic, žádný, žádnej, nikdo, nikomu
            '7' => ['prontype' => 'neg'],
            # přivlastňovací: můj, tvůj, jeho, její, náš, váš, jejich
            '8' => ['prontype' => 'prs', 'poss' => 'poss'],
            # přivlastňovací zvratné: své, svýmu, svými, svoje
            '9' => ['prontype' => 'prs', 'poss' => 'poss', 'reflex' => 'reflex'],
            # víceslovné: nějaký takový, takový ňáký, nějaký ty, takovym tim
            '0' => ['prontype' => 'ind', 'other' => 'prontype=víceslovné'],
            # víceslovné vztažné: to co, "to, co", něco co, "ten, kdo"
            '-' => ['prontype' => 'rel', 'other' => 'prontype=víceslovné']
        },
        'encode_map' =>

            { 'prontype' => { 'prs' => { 'poss' => { 'poss' => { 'reflex' => { 'reflex' => '9',
                                                                               '@'      => '8' }},
                                                     '@'    => { 'reflex' => { 'reflex' => '3',
                                                                               '@'      => '1' }}}},
                              'ind' => { 'other' => { 'prontype=víceslovné' => '0',
                                                      '@'                   => '2' }},
                              'dem' => '4',
                              'int' => '5',
                              'rel' => { 'other' => { 'prontype=víceslovné' => '-',
                                                      '@'                   => '6' }},
                              'neg' => '7' }}
    );
    # NUMERAL TYPE ####################
    $atoms{numeral_type} = $self->create_atom
    (
        'surfeature' => 'numeral_type',
        'decode_map' =>
        {
            # základní: jeden, pět, jedný, deset, vosum
            '1' => ['pos' => 'num', 'numtype' => 'card'],
            # řadová: druhej, prvnímu, poprvé, sedumdesátým
            '2' => ['pos' => 'adj|adv', 'numtype' => 'ord'],
            # druhová: oboje, troje, vosmery, jedny, dvojího
            '3' => ['pos' => 'adj', 'numtype' => 'gen'],
            # násobná: dvakrát, mockrát, jednou, mnohokrát, čtyřikrát
            '4' => ['pos' => 'adv', 'numtype' => 'mult'],
            # neurčitá: několik, kolik, pár, tolik, několikrát
            '5' => ['prontype' => 'ind'],
            # víceslovná základní: dvě stě, tři tisíce, deset tisíc, sedum set, čtyři sta
            '6' => ['pos' => 'num', 'numtype' => 'card', 'other' => 'numtype=víceslovná'],
            # víceslovná řadová: sedumdesátym druhym, šedesátej vosmej, osmdesátém devátém
            '7' => ['pos' => 'adj', 'numtype' => 'ord', 'other' => 'numtype=víceslovná'],
            # víceslovná druhová
            '8' => ['pos' => 'adj', 'numtype' => 'gen', 'other' => 'numtype=víceslovná'],
            # víceslovná násobná
            '9' => ['pos' => 'adv', 'numtype' => 'mult', 'other' => 'numtype=víceslovná'],
            # víceslovná neurčitá: "tolik, kolik", "tolik (ženskejch), kolik"
            '0' => ['prontype' => 'ind', 'other' => 'numtype=víceslovná']
        },
        'encode_map' =>

            { 'other' => { 'numtype=víceslovná' => { 'prontype' => { 'ind' => '0',
                                                                     '@'   => { 'numtype' => { 'mult' => '9',
                                                                                               'gen'  => '8',
                                                                                               'ord'  => '7',
                                                                                               '@'    => '6' }}}},
                           '@'                  => { 'prontype' => { 'ind' => '5',
                                                                     '@'   => { 'numtype' => { 'mult' => '4',
                                                                                               'gen'  => '3',
                                                                                               'ord'  => '2',
                                                                                               '@'    => '1' }}}}}}
    );
    # ASPECT ####################
    $atoms{aspect} = $self->create_simple_atom
    (
        'intfeature' => 'aspect',
        'simple_decode_map' =>
        {
            # imperfektivum: neměl, myslim, je, má, existují
            '1' => 'imp',
            # perfektivum: uživí, udělat, zlepšit, rozvíst, vynechat
            '2' => 'perf',
            # obouvidové: stačilo, absolvovali, algoritmizovat, analyzujou, nedokáží
            '9' => 'imp|perf'
        }
    );
    # ADVERB TYPE ####################
    $atoms{adverb_type} = $self->create_atom
    (
        'surfeature' => 'adverb_type',
        'decode_map' =>
        {
            # běžné nespecifické: materiálně, pak, finančně, moc, hrozně
            '1' => [],
            # predikativum: nelze, smutno, blízko, zima, horko
            '2' => ['advtype' => 'mod|sta'],
            # zájmenné nespojovací: tady, jak, tak, tehdy, teď, vždycky, kde, vodkaď, tam, tu, vodtaď, potom, přitom, někde
            # In fact, this category contains several types of pronominal adverbs: indefinite, demonstrative, interrogative etc.
            # The main point is to set prontype to anything non-empty here to distinguish them from adjectival adverbs.
            '3' => ['prontype' => 'ind'],
            # spojovací výraz jednoslovný: proč, kdy, kde, kam
            '4' => ['prontype' => 'rel'],
            # spojovací výraz víceslovný: "tak, jak", "tak, že", "tak, aby", "tak jako", "tak (velký), aby"
            # Typically, this is a pair of a demonstrative adverb ("tak") and a relative adverb ("jak") or conjunction ("že").
            # The tag appears at the demonstrative adverb while the rest has empty tag.
            '5' => ['prontype' => 'dem']
        },
        'encode_map' =>

            { 'advtype' => { 'mod|sta' => '2',
                             '@'       => { 'prontype' => { 'ind' => '3',
                                                            'rel' => '4',
                                                            'dem' => '5',
                                                            '@'   => '1' }}}}
    );
    # PREPOSITION TYPE ####################
    $atoms{preposition_type} = $self->create_atom
    (
        'surfeature' => 'preposition_type',
        'decode_map' =>
        {
            # běžná vlastní: v, vod, na, z, se
            '1' => [],
            # nevlastní homonymní: vokolo, vedle, včetně, pomocí, během
            '2' => ['other' => 'preptype=nevlastní'],
            # víceslovná: z pohledů, na základě, na začátku, za účelem, v rámci
            '3' => ['other' => 'preptype=víceslovná']
        },
        'encode_map' =>

            { 'other' => { 'preptype=nevlastní'  => '2',
                           'preptype=víceslovná' => '3',
                           '@'                   => '1' }}
    );
    # CONJUNCTION TYPE ####################
    $atoms{conjunction_type} = $self->create_atom
    (
        'surfeature' => 'conjunction_type',
        'decode_map' =>
        {
            # souřadící jednoslovná: a, ale, nebo, jenomže, či
            '1' => ['conjtype' => 'coor'],
            # podřadící jednoslovná: jesli, protože, že, jako, než
            '2' => ['conjtype' => 'sub'],
            # souřadící víceslovná: buďto-anebo, i-i, ať už-anebo, buď-nebo, ať-nebo
            '3' => ['conjtype' => 'coor', 'other' => 'multitoken'],
            # podřadící víceslovná: jesli-tak, "na to, že", i když, i dyž, proto-že
            '4' => ['conjtype' => 'sub', 'other' => 'multitoken'],
            # jiná jednoslovná: v korpusu se nevyskytuje
            '5' => ['other' => 'conjtype=other'],
            # jiná víceslovná: v korpusu se nevyskytuje
            '6' => ['other' => 'conjtype=other-multitoken'],
            # nelze určit: buď, jak, sice, jednak, buďto
            '9' => []
        },
        'encode_map' =>

            { 'other' => { 'conjtype=other'            => '5',
                           'conjtype=other-multitoken' => '6',
                           'multitoken'                => { 'conjtype' => { 'sub'  => '4',
                                                                            '@'    => '3' }},
                           '@'                         => { 'conjtype' => { 'sub'  => '2',
                                                                            'coor' => '1',
                                                                            '@'    => '9' }}}}
    );
    # INTERJECTION TYPE ####################
    $atoms{interjection_type} = $self->create_atom
    (
        'surfeature' => 'interjection_type',
        'decode_map' =>
        {
            # běžné původní: hm, nó, no jo, jé, aha
            '1' => [],
            # substantivní: škoda, čoveče, mami, bóže, hovno
            '2' => ['other' => 'intertype=noun'],
            # adjektivní: hotovo, bezva
            '3' => ['other' => 'intertype=adj'],
            # zájmenné: jo, ne, jó, né
            '4' => ['other' => 'intertype=pron'],
            # slovesné: neboj, sím, podivejte, hele, počkej
            '5' => ['other' => 'intertype=verb'],
            # adverbiální: vážně, jistě, takle, depak, rozhodně
            '6' => ['other' => 'intertype=adv'],
            # jiné: jaktože, pardón, zaplať pámbu, ahój, vůbec
            '7' => ['other' => 'intertype=other'],
            # víceslovné = frazém: v korpusu se nevyskytlo, resp. možná se vyskytlo a bylo označkováno jako frazém
            '0' => ['other' => 'intertype=multitoken']
        },
        'encode_map' =>

            { 'other' => { 'intertype=noun'       => '2',
                           'intertype=adj'        => '3',
                           'intertype=pron'       => '4',
                           'intertype=verb'       => '5',
                           'intertype=adv'        => '6',
                           'intertype=other'      => '7',
                           'intertype=multitoken' => '0',
                           '@'                    => '1' }}
    );
    # PARTICLE TYPE ####################
    $atoms{particle_type} = $self->create_atom
    (
        'surfeature' => 'particle_type',
        'decode_map' =>
        {
            # vlastní nehomonymní: asi, právě, také, spíš, přece
            '1' => [],
            # adverbiální: prostě, hnedle, naopak, třeba, tak
            '2' => ['other' => 'parttype=adv'],
            # spojkové: teda, ani, jako, až, ale
            '3' => ['other' => 'parttype=conj'],
            # jiné: nó, zrovna, jo, vlastně, to
            '4' => ['other' => 'parttype=other'],
            # víceslovné nevětné: no tak, tak ňák, že jo, nebo co, jen tak
            '5' => ['other' => 'parttype=multitoken]
        },
        'encode_map' =>

            { 'other' => { 'parttype=adv'        => '2',
                           'parttype=conj'       => '3',
                           'parttype=other'      => '4',
                           'parttype=multitoken' => '5',
                           '@'                   => '1' }}
    );
    # IDIOM TYPE ####################
    ###!!! Perhaps we could reverse the priorities. Idiom type would be (mostly) decoded
    ###!!! as $fs->{pos}, and $fs->{other} would record that this is an idiom.
    $atoms{idiom_type} = $self->create_atom
    (
        'surfeature' => 'idiom_type',
        'decode_map' =>
        {
            # verbální: vyprdnout se na to, mít dojem, mít smysl, měli rádi, jít vzorem
            '1' => ['other' => 'idiomtype=verb'],
            # substantivní: hlava rodiny, žebříček hodnot, říjnový revoluci, diamantovou svatbou, českej člověk
            '2' => ['other' => 'idiomtype=noun'],
            # adjektivní: ten a ten, každym druhym, toho a toho, jako takovou, výše postavených
            '3' => ['other' => 'idiomtype=adj'],
            # adverbiální: u nás, v naší době, tak ňák, za chvíli, podle mýho názoru
            '4' => ['other' => 'idiomtype=adv'],
            # propoziční včetně interjekčních: to stálo vodříkání, to snad není možný, je to tím že, největší štěstí je
            '5' => ['other' => 'idiomtype=prop'],
            # jiné: samy za sebe, všechno možný, jak který, všech možnejch, jednoho vůči druhýmu
            '6' => ['other' => 'idiomtype=other']
        },
        'encode_map' =>

            { 'other' => { 'idiomtype=verb' => '1',
                           'idiomtype=noun' => '2',
                           'idiomtype=adj'  => '3',
                           'idiomtype=adv'  => '4',
                           'idiomtype=prop' => '5',
                           '@'              => '6' }}
    );
    # OTHER REAL TYPE ####################
    # (skutečný druh)
    $atoms{other_real_type} = $self->create_atom
    (
        'surfeature' => 'other_real_type',
        'decode_map' =>
        {
            # citátové výrazy cizojazyčné, zvláště víceslovné: go, skinheads, non plus ultra, madame, cleaner polish
            'C' => ['foreign' => 'foreign'],
            # zkratky neslovní: ý, í, x, ČKD, EEG
            'Z' => ['abbr' => 'abbr'],
            # propria: Kunratickou, Hrádek, Mirek, Roháčích, Vinnetou
            'P' => ['pos' => 'noun', 'nountype' => 'prop']
        },
        'encode_map' =>

            { 'foreign' => { 'foreign' => 'C',
                             '@'       => { 'abbr' => { 'abbr' => 'Z',
                                                        '@'    => { 'nountype' => { 'prop' => 'P' }}}}}}
    );
    # PROPER NOUN TYPE ####################
    $atoms{proper_noun_type} = $self->create_atom
    (
        'surfeature' => 'proper_noun_type',
        'decode_map' =>
        {
            # jednoslovné: Vinnetou, Rybanu, Tujunga, Brně, Praze
            '1' => [],
            # víceslovné: Zahradním Městě, u Andělů, Staroměstského náměstí, Český Štenberk, Lucinka Tomíčková
            '2' => ['other' => 'multitoken']
        },
        'encode_map' =>

            { 'other' => { 'multitoken' => '2',
                           '@'          => '1' }}
    );
    return \%atoms;
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
    $fs->set_tagset('cs::pdt');
    my $atoms = $self->atoms();
    my @chars = split(//, $tag);
    $atoms->{pos}->decode_and_merge_hard($chars[0].$chars[1], $fs);
    $atoms->{gender}->decode_and_merge_hard($chars[2], $fs);
    $atoms->{number}->decode_and_merge_hard($chars[3], $fs);
    $atoms->{case}->decode_and_merge_hard($chars[4], $fs);
    $atoms->{possgender}->decode_and_merge_hard($chars[5], $fs);
    $atoms->{possnumber}->decode_and_merge_hard($chars[6], $fs);
    $atoms->{person}->decode_and_merge_hard($chars[7], $fs);
    $atoms->{tense}->decode_and_merge_hard($chars[8], $fs);
    $atoms->{degree}->decode_and_merge_hard($chars[9], $fs);
    $atoms->{negativeness}->decode_and_merge_hard($chars[10], $fs);
    $atoms->{voice}->decode_and_merge_hard($chars[11], $fs);
    $atoms->{variant}->decode_and_merge_hard($chars[14], $fs);
    return $fs;
}



#------------------------------------------------------------------------------
# Takes feature structure and returns the corresponding physical tag (string).
#------------------------------------------------------------------------------
sub encode
{
    my $self = shift;
    my $fs = shift; # Lingua::Interset::FeatureStructure
    my $tag = '';
    # pos and subpos
    # Numerals and pronouns must come first because they can be at the same time also nouns or adjectives.
    if($fs->is_numeral())
    {
    # Now encode the features.
    # The PDT tagset distinguishes unknown values ("X") and irrelevant features ("-").
    # Interset does not do this distinction but we have prepared the defaults for empty values above.
    my @tag = split(//, $tag);
    my @features = ('pos', 'subpos', 'gender', 'number', 'case', 'possgender', 'possnumber', 'person', 'tense', 'degree', 'negativeness', 'voice', undef, undef, 'variant');
    my $atoms = $self->atoms();
    for(my $i = 2; $i<15; $i++)
    {
        next if($i==12 || $i==13);
        my $atag = $atoms->{$features[$i]}->encode($fs);
        # If we got undef, there is something wrong with our encoding tables.
        if(!defined($atag))
        {
            print STDERR ("\n", $fs->as_string(), "\n");
            confess("Cannot encode '$features[$i]'");
        }
        if($atag ne '')
        {
            $tag[$i] = $atag;
        }
    }
    $tag = join('', @tag);
    return $tag;
}



#------------------------------------------------------------------------------
# Returns reference to list of known tags.
# The list was taken from the b2800a.o2f file (Hajič's Czech Morphology).
# 4288
#------------------------------------------------------------------------------
sub list
{
    my $self = shift;
    my $list = <<end_of_list
A.-------------
A2--------A----
Vt-S---3P-NA--2
X\@-------------
X\@------------0
X\@------------1
Xx-------------
XX-------------
XX------------8
Z:-------------
Z#-------------
end_of_list
    ;
    # Protect from editors that replace tabs by spaces.
    $list =~ s/ \s+/\t/sg;
    my @list = split(/\r?\n/, $list);
    pop(@list) if($list[$#list] eq "");
    return \@list;
}



1;

=head1 SYNOPSIS

  use Lingua::Interset::Tagset::CS::Pdt;
  my $driver = Lingua::Interset::Tagset::CS::Pdt->new();
  my $fs = $driver->decode('NNMS1-----A----');

or

  use Lingua::Interset qw(decode);
  my $fs = decode('cs::pdt', 'NNMS1-----A----');

=head1 DESCRIPTION

Interset driver for the part-of-speech tagset of the Prague Dependency Treebank.

=head1 SEE ALSO

L<Lingua::Interset>,
L<Lingua::Interset::Tagset>,
L<Lingua::Interset::FeatureStructure>

=cut
