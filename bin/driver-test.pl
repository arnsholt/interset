#!/usr/bin/perl
# Tagset service functions.
# (c) 2007 Dan Zeman <zeman@ufal.mff.cuni.cz>
# Licence: GNU GPL

sub usage
{
    print STDERR ("Usage: driver-test.pl [-d] driver [driver2 [driver3...]]\n");
    print STDERR ("       driver-test.pl [-d] -a\n");
    print STDERR ("       driver-test.pl [-d] -A\n");
    print STDERR ("  driver name example: ar::conll\n");
    print STDERR ("  -a: test all known drivers but no pairs of drivers\n");
    print STDERR ("  -A: test all known drivers and all pairs of drivers\n");
    print STDERR ("  -d: debug mode (list tags being tested)\n");
}

use utf8;
use open ":utf8";
binmode(STDIN, ":utf8");
binmode(STDOUT, ":utf8");
binmode(STDERR, ":utf8");
use Getopt::Long qw(:config no_ignore_case bundling);
use Carp; # confess()
use tagset::common;

# Autoflush after every Perl statement.
$old_fh = select(STDOUT);
$| = 1;
select(STDERR);
$| = 1;
select($old_fh);
# Get options.
$all = 0;
$all_conversions = 0;
$debug = 0;
GetOptions('a' => \$all, 'A' => \$all_conversions, 'debug' => \$debug);
# Get the list of all drivers if needed.
if($all || $all_conversions)
{
    $drivers = tagset::common::find_drivers();
    $conversions = $all_conversions;
}
else
{
    $drivers = \@ARGV;
    $conversions = scalar(@{$drivers})>1;
}
# If the list of drivers is empty, show the list of available drivers and exit.
if(scalar(@{$drivers})==0)
{
    usage();
    my $drivers = tagset::common::find_drivers();
    if(scalar(@{$drivers}))
    {
        print STDERR ("\nThe following tagset drivers are available on this system:\n");
        print STDERR (join("", map {"$_\n"} sort @{$drivers}));
    }
    else
    {
        print STDERR ("\nNo tagset drivers have been found on this system.\n");
    }
}
else
{
    my $starttime = time();
    # Start with testing each driver separately (this is also a prerequisite to testing of pairs).
    foreach my $d (@{$drivers})
    {
        # If there were errors, interrupt testing so we do not overlook the errors.
        last if(test($d));
    }
    # Continue with testing conversions from one driver to another, if asked for it.
    if($conversions)
    {
        foreach my $d1 (@{$drivers})
        {
            foreach my $d2 (@{$drivers})
            {
                next if($d2 eq $d1);
                test_conversion($d1, $d2);
                print("\n");
            }
        }
    }
    print("Total duration ", duration($starttime), ".\n");
}



#------------------------------------------------------------------------------
# Tests that encode(decode(tag))=tag for all tags in list().
#------------------------------------------------------------------------------
sub test
{
    my $driver = shift; # e.g. "cs::pdt"
    my $starttime = time();
    print("Testing $driver ...");
    my $n_tags = 0;
    my $n_errors = 0;
    my $n_other = 0;
    # Note: We could also eval() just the "use" statement (and possibly the list(), decode() and encode() calls).
    # Enclosing the eval code in single quotes would prevent any "$" and "@" from being interpreted.
    # However, we still want the ${driver} to be interpreted.
    my $eval = <<_end_of_eval_
    {
        use tagset::${driver};
        my \$list = tagset::${driver}::list();
        foreach my \$tag (\@{\$list})
        {
            if(\$debug)
            {
                print STDERR ("Now testing tag \$tag\n");
            }
            my \$f = tagset::${driver}::decode(\$tag);
            \$n_other++ if(\$f->{other} ne "");
            my \$errors = is_known(\$f);
            if(scalar(\@{\$errors}))
            {
                print("Error: unknown features or values after decoding \\"\$tag\\"\n");
                foreach my \$e (\@{\$errors})
                {
                    print(" ", \$e);
                }
                print("\n");
                \$n_errors++;
            }
            my \$tag1 = tagset::${driver}::encode(\$f);
            if(\$tag1 ne \$tag)
            {
                print("\n\n") if(\$n_errors==0);
                print("Error: encode(decode(x)) != x\n");
                print(" src = \\"\$tag\\"\n");
                print(" tgt = \\"\$tag1\\"\n");
                print(" sfs = ", tagset::common::feature_structure_to_text(\$f), "\n");
                print("\n");
                \$n_errors++;
            }
            \$n_tags++;
        }
    }
_end_of_eval_
    ;
    if($debug)
    {
        print STDERR ($eval);
    }
    eval($eval);
    if($@)
    {
        confess("$@\nEval failed");
    }
    if($n_errors)
    {
        confess("Tested $n_tags tags, found $n_errors errors.\n");
    }
    else
    {
        print(" $n_tags tags OK\n");
        print("$n_other tags use the 'other' feature.\n");
    }
    print("Duration ", duration($starttime), ".\n");
    return $n_errors;
}



#------------------------------------------------------------------------------
# Converts all tags of tagset 1 to tagset 2. Checks whether the target tags are
# permitted in tagset 2.
#------------------------------------------------------------------------------
sub test_conversion
{
    my $driver1 = shift;
    my $driver2 = shift;
    my $starttime = time();
    print("Testing conversion from $driver1 to $driver2.\n");
    my $n_tags = 0;
    my $n_errors = 0;
    my $list1 = tagset::common::list($driver1);
    my $list2 = tagset::common::list($driver2);
    if(scalar(@{$list1})==0)
    {
        print("List of known tags of $driver1 is empty. Nothing to test.\n");
        return 0;
    }
    if(scalar(@{$list2})==0)
    {
        print("List of known tags of $driver2 is empty. Nothing to test.\n");
        return 0;
    }
    # Hash list 2 so that we can check which tags are permitted.
    my %tagset2;
    foreach my $t (@{$list2})
    {
        $tagset2{$t}++;
    }
    # Remember used target tags so that we can evaluate information loss.
    my %t2hits;
    # Convert all tagset 1 tags to tagset 2 and check whether the result is permitted.
    foreach my $src (@{$list1})
    {
        my $fs = tagset::common::decode($driver1, $src);
        my $tgt = tagset::common::encode($driver2, $fs);
        $t2hits{$tgt}++;
        if($debug)
        {
            my $fs1 = correct($driver2, $fs);
            print("Source tag = $src\n");
            print("Features   = ", tagset::common::feature_structure_to_text($fs), "\n");
            print("Corrected  = ", tagset::common::feature_structure_to_text($fs1), "\n");
            print("Target tag = $tgt\n");
            print("\n");
        }
        if(!exists($tagset2{$tgt}))
        {
            my $fs1 = correct($driver2, $fs);
            print("\n\n") if($n_errors==0);
            print("Source tag = $src\n");
            print("Features   = ", tagset::common::structure_to_string($fs), "\n");
            print("Features   = ", tagset::common::feature_structure_to_text($fs), "\n");
            print("Corrected  = ", tagset::common::feature_structure_to_text($fs1), "\n");
            print("Example    = ", get_tag_example($driver2, $fs1), "\n");
            print("Target tag = $tgt\n");
            print("The target tag is not known in the target tagset.\n\n");
#            die();
            $n_errors++;
        }
        $n_tags++;
    }
    if($n_errors)
    {
        # Repeat the initial message. It may not be visible now after all the error messages
        # and we may not know what conversion test this was.
        print("Tested conversion from $driver1 to $driver2.\n");
        print("Tested $n_tags tags, found $n_errors errors.\n");
        confess();
    }
    else
    {
        my $n_hits = scalar(keys(%t2hits));
        # Tagset of only one tag bears zero information.
        my $src_inf = $n_tags-1;
        my $tgt_inf = $n_hits-1;
        unless($tgt_inf)
        {
            print("The converted tags bear no information (all source tags were converted to the same target tag)!\n");
            confess();
        }
        print("$n_tags source tags mapped to $n_hits of total ", scalar(@{$list2}), " target tags.\n");
        if($src_inf)
        {
            my $inf_loss = ($src_inf-$tgt_inf)/$src_inf;
            printf("Information loss %d %%.\n", $inf_loss*100+0.5);
        }
        # For each used target tag, show how many source tags have been mapped to it.
        if($n_hits<=20)
        {
            foreach my $key (sort(keys(%t2hits)))
            {
                print("Target tag $key hit by $t2hits{$key} source tags.\n");
            }
        }
    }
    print("Duration ", duration($starttime), ".\n");
}



#------------------------------------------------------------------------------
# Check whether a feature structure contains only known features and values.
#------------------------------------------------------------------------------
sub is_known
{
    my $fs = shift; # feature structure (hash reference)
    my @errors;
    # Does the structure contain only known features?
    foreach my $f (keys(%{$fs}))
    {
        if(!exists($tagset::common::known{$f}))
        {
            push(@errors, "Unknown feature $f.\n");
        }
        else
        {
            # Do the features have only known values?
            # Empty value is always known and tagset and other can have any value.
            my @values;
            if(ref($fs->{$f}) eq "ARRAY")
            {
                @values = @{$fs->{$f}};
            }
            else
            {
                @values = ($fs->{$f});
            }
            foreach my $v (@values)
            {
                if(!exists($tagset::common::known{$f}{$v}) && $v ne "" && $f ne "tagset" && $f ne "other")
                {
                    push(@errors, "Unknown value $v of feature $f.\n");
                }
            }
        }
    }
    return \@errors;
}



#------------------------------------------------------------------------------
# Corrects a feature structure to comply with a driver's expectations. Mimics
# what drivers usually do to perform strict encoding. Works only with drivers
# that BEGIN with collecting the permitted structures.
#------------------------------------------------------------------------------
sub correct
{
    my $driver = shift; # e.g. "cs::pdt"
    my $fs0 = shift; # hash reference (feature structure)
    my $fs1;
    my $eval = <<_end_of_eval_
    {
        use tagset::${driver};
        my \$permitted = \$tagset::${driver}::permitted;
        if(scalar(keys(\%{\$permitted})))
        {
            \$fs1 = tagset::common::enforce_permitted_joint(\$fs0, \$tagset::${driver}::permitted);
        }
        else
        {
            \$fs1 = tagset::common::duplicate(\$fs0);
        }
    }
_end_of_eval_
    ;
    print("$eval\n") if($debug && 0);
    my %fs = eval($eval);
    if($@)
    {
        confess("$@\nEval failed");
    }
    return $fs1;
}



#------------------------------------------------------------------------------
# Retrieves a tag example for a feature structure permitted by a driver.
# Works only with drivers that BEGIN with collecting the permitted structures.
#------------------------------------------------------------------------------
sub get_tag_example
{
    my $driver = shift; # e.g. "cs::pdt"
    my $fs = shift; # hash reference (feature structure)
    my $tag;
    my $eval = <<_end_of_eval_
    {
        use tagset::${driver};
        my \$permitted = \$tagset::${driver}::permitted;
        if(scalar(keys(\%{\$permitted})))
        {
            \$tag = tagset::common::get_tag_example(\$fs, \$permitted);
        }
        else
        {
            \$tag = "Empty list of permitted feature structures.";
        }
    }
_end_of_eval_
    ;
    print("$eval\n") if($debug && 0);
    eval($eval);
    if($@)
    {
        confess("$@\nEval failed");
    }
    return $tag;
}



#------------------------------------------------------------------------------
# Measures time. Gets start time, asks system for current time. Generates
# formatted message about the duration that can be printed out.
#------------------------------------------------------------------------------
sub duration
{
    my $starttime = shift;
    my $stoptime = time();
    my $cas = $stoptime-$starttime;
    my $hod = int($cas/3600);
    my $min = int(($cas%3600)/60);
    my $sek = $cas%60;
    my $hlaseni;
    if($hod==0)
    {
        if($min==0)
        {
            $hlaseni = sprintf("$sek second%s", $sek==1 ? "" : "s");
        }
        else
        {
            $hlaseni = sprintf("%d:%02d minutes", $min, $sek);
        }
    }
    else
    {
        $hlaseni = sprintf("%2d:%02d:%02d hours", $hod, $min, $sek);
    }
    return $hlaseni;
}



1;
