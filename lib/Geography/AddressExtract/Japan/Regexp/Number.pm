package Geography::AddressExtract::Japan::Regexp::Number;
use strict;
use warnings;
use utf8;

sub create {
    #generated by Regexp::Assemble
    my $re = '(?-xism:(?:(?:(?:(?:[一二三四五六七八九]?十)?[一二三四
五六七八九〇]+|\d+)(?:丁目|[-‐−のノ]))?(?:(?:[東西南北
左右上下]?(?:(?:[一二三四五六七八九]?十)?[一二三四五六七八九〇]+
|\d+)|[a-zA-Zａ-ｚＡ-Ｚ])(?:番地?(?:[-‐−のノ](?:
[東西南北左右上下]?(?:(?:[一二三四五六七八九]?十)?[一二三四五六七
八九〇]+|\d+)|[a-zA-Zａ-ｚＡ-Ｚ])号?|(?:[東西南北左右上
下]?(?:(?:[一二三四五六七八九]?十)?[一二三四五六七八九〇]+|\d
+)|[a-zA-Zａ-ｚＡ-Ｚ])号?)?|[-‐−のノ](?:[東西南北左右
上下]?(?:(?:[一二三四五六七八九]?十)?[一二三四五六七八九〇]+|\
d+)|[a-zA-Zａ-ｚＡ-Ｚ])号?|号)|\d+)|\d+))';
    $re =~ s/\n//g;
    $re;
}

1;

__END__

