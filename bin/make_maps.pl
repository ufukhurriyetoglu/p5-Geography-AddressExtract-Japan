use strict;
use warnings;
use encoding "euc-jp", STDOUT => "euc-jp";

use Data::Dumper;
use IO::File;
use Regexp::Assemble;
use Text::CSV_PP;

my $out;
my $ra_city = Regexp::Assemble->new;
my $ra_number = Regexp::Assemble->new;
my $ra_aza    = Regexp::Assemble->new;

my $dash   = '[-���ݤΥ�]';
my $number = '(?:(?:[���󻰻͸�ϻ��Ȭ��]?��)?[���󻰻͸�ϻ��Ȭ�塻]+|\d+)';
my $number_prefix = '[�������̺����岼]';
my $numbers = sprintf("(?:%s?%s|[a-zA-Z��-����-��])", $number_prefix, $number);
my $chome = sprintf("(?:%s(?:����|%s))?", $number, $dash);
my $ban = '����?';

if (1) {
my $csv = Text::CSV_PP->new({binary => 1});
my $io = IO::File->new('./ken_all.csv', '<:encoding(shiftjis)') or die $!;
my $map = {};
my %cache;
my $i;
while (! $io->eof and my $col = $csv->getline($io)) {
    my $data = $col->[6] . $col->[7];

    my @kana;
    if ($col->[6] ne '������' && $col->[8] !~ /^�ʲ��˷Ǥ�/ && ($col->[8] =~ /^[\p{Hiragana}\p{Katakana}]/ || $col->[8] =~ /��/)) {
        my $aza = $col->[8];
        $aza =~ s/��//;
        for my $str (split /��/, $aza) {
            if ($str =~ /^(\p{Hiragana}+)/ || $str =~ /^(\p{Katakana}+)/) {
                my $kana = $1;
                push @kana, $1;
            }
        }
    }

    next if $cache{$data}++;

    my $pref = $col->[6];
    my($city, $town);
    if ($col->[7] =~ /^(.+?��)(.+[¼Į])$/) {
        ($city, $town) = ($1, $2);
    } elsif ($col->[7] =~ /^(.+?��)(.+��)$/) {
        ($city, $town) = ($1, $2);
    } elsif ($col->[6] eq '�����' && $col->[7] =~ /^(.+?��)(.+[Į¼])$/) {
        ($city, $town) = ($1, $2);
    } else {
        ($city, $town) = ($col->[7], '');
    }

    $ra_city->add("$pref$city$town");
    $ra_city->add("$pref$city");
    $ra_city->add("$pref$town");
    $ra_city->add("$city$town");
    $ra_city->add("$city");
    $ra_city->add($town) if $town;
    for my $town2 (@kana) {
        $ra_city->add("$pref$city$town$town2");
        $ra_city->add("$pref$town$town2");
        $ra_city->add("$city$town$town2");
        $ra_city->add("$town$town2") if $town;
    }
    add_map($map, $col->[6], $city, $town);
}

my %dupe;
for my $city  (keys %$map ) {
    next if $city =~ /.+?��$/;
    $dupe{$city} = {} if $map->{$city} eq 'DUPE';
}

$io = IO::File->new('./ken_all.csv', '<:encoding(shiftjis)') or die $!;
while (! $io->eof and my $col = $csv->getline($io)) {

    my $town;
    if ($col->[7] =~ /^(.+?��)(.+[¼Į])$/) {
        $town = $2;
    } elsif ($col->[7] =~ /^(.+?��)(.+��)$/) {
        $town = $2;
    } elsif ($col->[7] =~ /^(.+?[�Զ�])$/) {
        $town = $1;
    } else {
        next;
    }
    next unless $dupe{$town};
    my $aza = $col->[8];
    $aza =~ s/��.+��?$//;
    next if $aza =~ /^�ʲ��˷Ǻܤ�/;

    if ($dupe{$town}->{$aza} && $dupe{$town}->{$aza} ne $col->[6] . $col->[7]) {
        $dupe{$town}->{$aza} = 'DUPE';
        next;
    }
    $dupe{$town}->{$aza} =  $col->[6] . $col->[7];
}

my %dupe_regexs;
for my $town ( keys %dupe ) {
    $dupe_regexs{$town} = {} unless $dupe_regexs{$town};

    for my $aza ( keys %{ $dupe{$town} } ) {
        my $city = $dupe{$town}->{$aza};
        next if $city eq 'DUPE';
        $dupe_regexs{$town}->{$city} = Regexp::Assemble->new unless ref($dupe_regexs{$town}->{$city});
        $dupe_regexs{$town}->{$city}->add($aza);
    }
}


#make Regexp/City
my $re_city = $ra_city->re;
$re_city =~ s/(.{1,40})/$1\n/g;
chop($re_city);
open $out, '>:encoding(utf8)', '../lib/Geography/AddressExtract/Japan/Regexp/City.pm';
print $out <<CODE;
package Geography::AddressExtract::Japan::Regexp::City;
use strict;
use warnings;
use utf8;

sub create {
    #generated by Regexp::Assemble
    my \$re =<<RE;
$re_city
RE
    \$re =~ s/\\n//g;
    \$re;
}

1;

__END__

=head1 SEE ALSO

L<http://www.post.japanpost.jp/zipcode/download.html>

=cut
CODE
close($out);

#make Map/City
open $out, '>:encoding(utf8)', '../lib/Geography/AddressExtract/Japan/Map/City.pm';
print $out <<CODE;
package Geography::AddressExtract::Japan::Map::City;
use strict;
use warnings;
use utf8;

sub create {
    #generated by Regexp::Assemble
    +{
CODE
for ( sort { $a cmp $b } keys %$map ) {
    print $out "        '$_' => '$map->{$_}',\n";
}
print $out <<CODE;
    };
}

1;

__END__

=head1 SEE ALSO

L<http://www.post.japanpost.jp/zipcode/download.html>

=cut

CODE
close($out);

#make Regexp/Dupe
open $out, '>:encoding(utf8)', '../lib/Geography/AddressExtract/Japan/Regexp/Dupe.pm';
print $out <<CODE;
package Geography::AddressExtract::Japan::Regexp::Dupe;
use strict;
use warnings;
use utf8;

sub create {
    #generated by Regexp::Assemble
    my \$re = +{
CODE
for my $town ( keys %dupe_regexs ) {
    print $out "        '$town' => {\n";
    for my $city ( keys %{ $dupe_regexs{$town} } ) {
        my $re = $dupe_regexs{$town}->{$city}->re;
        $re =~ s/(.{1,40})/$1\n/g;
        chop($re);
        print $out "            '$city' => '$re',\n";
    }
    print $out "        },\n";
}
print $out <<CODE;
    };

    for my \$town ( keys %{ \$re } ) {
        for my \$city ( keys %{ \$re->{\$town} } ) {
            \$re->{\$town}->{\$city} =~ s/\\n//g;
        }
    }
    \$re;
}

1;

__END__

=head1 SEE ALSO

L<http://www.post.japanpost.jp/zipcode/download.html>

=cut

CODE
close($out);

}

$ra_number->add('\d+');
$ra_number->add(sprintf("%s%s", $chome, '\d+'));
$ra_number->add(sprintf("%s%s%s%s", $chome, $numbers, $dash, $numbers));
$ra_number->add(sprintf("%s%s%s%s��", $chome, $numbers, $dash, $numbers));
$ra_number->add(sprintf("%s%s%s", $chome, $numbers, $ban));
$ra_number->add(sprintf("%s%s%s%s��", $chome, $numbers, $ban, $numbers));
$ra_number->add(sprintf("%s%s%s%s", $chome, $numbers, $ban, $numbers));
$ra_number->add(sprintf("%s%s%s%s%s", $chome, $numbers, $ban, $dash, $numbers));
$ra_number->add(sprintf("%s%s%s%s%s��", $chome, $numbers, $ban, $dash, $numbers));
$ra_number->add(sprintf("%s%s��", $chome, $numbers, $numbers));

my $jstr = '[\p{Hiragana}\p{Katakana}\p{Han}]';

$ra_aza->add('\p{Han}+����');
$ra_aza->add(sprintf('%s����', $number));
$ra_aza->add(sprintf('%s��%s�ϳ�', $jstr, $number));
$ra_aza->add(sprintf('%s%s�ϳ�', $jstr, $number));
$ra_aza->add(sprintf("%s*%s��", $jstr, $number));
$ra_aza->add(sprintf("%s*%s��", $jstr, $number));
$ra_aza->add(sprintf("%s*%s���̤�", $jstr, $number));
$ra_aza->add(sprintf("%s*%s����", $jstr, $number));
$ra_aza->add(sprintf("%s*%s�̤�", $jstr, $number));
$ra_aza->add(sprintf("%s*%s��", $jstr, $number));
$ra_aza->add(sprintf("���%s����%s", $jstr, $jstr));
$ra_aza->add(sprintf("���%s��%s", $jstr, $jstr));
$ra_aza->add(sprintf("���%s", $jstr, $jstr));
$ra_aza->add(sprintf("��%s����%s", $jstr, $jstr));
$ra_aza->add(sprintf("��%s", $jstr, $jstr));
$ra_aza->add(sprintf("%s��%s", $jstr, $jstr));
$ra_aza->add("$jstr*?");

#make Regexp/Number
my $re_number = $ra_number->re;
$re_number =~ s/(.{1,40})/$1\n/g;
chop($re_number);
open $out, '>:encoding(utf8)', '../lib/Geography/AddressExtract/Japan/Regexp/Number.pm';
print $out <<CODE;
package Geography::AddressExtract::Japan::Regexp::Number;
use strict;
use warnings;
use utf8;

sub create {
    #generated by Regexp::Assemble
    my \$re = '$re_number';
    \$re =~ s/\\n//g;
    \$re;
}

1;

__END__

CODE
close($out);

#make Regexp/Aza
my $re_aza = $ra_aza->re;
$re_aza =~ s/(.{1,40})/$1\n/g;
chop($re_aza);
open $out, '>:encoding(utf8)', '../lib/Geography/AddressExtract/Japan/Regexp/Aza.pm';
print $out <<CODE;
package Geography::AddressExtract::Japan::Regexp::Aza;
use strict;
use warnings;
use utf8;

sub create {
    #generated by Regexp::Assemble
    my \$re = '$re_aza';
    \$re =~ s/\\n//g;
    \$re;
}

1;

__END__

CODE
close($out);



exit;

sub add_map {
    my($map, $pref, $city, $town) = @_;
    $town = '' unless $town;

    _add_map($map, $city, $pref) unless $map->{$city} &&  $map->{$city} eq $pref;
    return unless $town;
    _add_map($map, "$city$town", $pref);
    _add_map($map, $town, "$pref$city");
}

sub _add_map {
    my($map, $key, $value) = @_;

    return if $map->{$key} && $map->{$key} eq 'DELETE';
    if ($map->{$key}) {
        #print "DUPE: $key -> $value: $map->{$key}\n";
        $map->{$key} = 'DUPE';
    } else {
        $map->{$key} = $value;
    }
}

