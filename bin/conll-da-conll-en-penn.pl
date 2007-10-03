#!/usr/bin/perl
# Reads CoNLL data from STDIN, converts Danish tags to Penn (adds Penn as new column), writes the result to STDOUT.
# (c) 2006 Dan Zeman <zeman@ufal.mff.cuni.cz>
# License: GNU GPL

use utf8;
use open ":utf8";
binmode(STDIN, ":utf8");
binmode(STDOUT, ":utf8");
binmode(STDERR, ":utf8");
use tagset::da::conll;
use tagset::en::penn;

while(<>)
{
    unless(m/^\s*$/)
    {
        # Get rid of the line break.
        s/\r?\n$//;
        # Split line into columns.
        my @columns = split(/\s+/, $_);
        # Join coarse-grained pos, fine-grained pos, and features into one tag.
        my $tag = "$columns[3]\t$columns[4]\t$columns[5]";
        # Get corresponding PDT tag.
        my $features = tagset::da::conll::decode($tag);
        my $penn = tagset::en::penn::encode($features);
        $_ .= "\t$penn\n";
    }
    print;
}
