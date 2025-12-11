#!/usr/bin/env perl
use 5.036;
use utf8;
use warnings 'all';
use autodie ':all';
use open qw/:std :utf8/;
utf8::decode($_) for @ARGV;

use List::Util qw/all/;

sub get_cpu_features ($model_name) {
    map { /target_feature="(.*?)"/; $1 }
    grep { /target_feature=/ }
    `rustc --print cfg -C 'target-cpu=$model_name'`
}

sub array_to_set (@vars) {
    scalar { map { $_ => undef } @vars }
}

sub set_union (@sets) {
    scalar { map { %$_ } @sets }
}

sub set_intersection (@sets) {
    my $all_keys = set_union @sets;
    array_to_set grep {
        my $key = $_;
        all { exists $_->{$key} } @sets;
    } keys %$all_keys;
}

sub set_difference ($a, $b) {
    array_to_set grep {
        ! exists $b->{$_}
    } keys %$a;
}

sub set_size ($x) {
    int(keys %$x)
}

sub get_edits ($baseline, $features) {
    my $required = set_difference($features, $baseline);
    my $redundant = set_difference($baseline, $features);
    [ (map { "+$_" } keys %$required), (map { "-$_" } keys %$redundant) ]
}

my $use_x86_versions = 0;

sub main (@argv) {
    @argv = 'native' unless int @argv;
    my @models = @argv;
    my %model_features = map { $_ => array_to_set(get_cpu_features $_) } @models;
    my $common_features = set_intersection values %model_features;

    my @x86_models = qw/x86-64 x86-64-v2 x86-64-v3 x86-64-v4/;
    my %x86_features = map { $_ => array_to_set(get_cpu_features $_) } @x86_models;

    my %baseline_model_features = do {
        if ($use_x86_versions) {
            (%x86_features);
        } else {
            (%model_features, %x86_features);
        }
    };

    delete $baseline_model_features{native};

    my @edits =
    sort { int(@{ $a->[1] }) <=> int(@{ $b->[1] }) }
    map { [ $_, get_edits($baseline_model_features{$_}, $common_features) ] }
    keys %baseline_model_features;

    my $winner = shift @edits;
    say $winner->[0];
    say join ",", $winner->[1]->@*;
}

main @ARGV unless caller;
