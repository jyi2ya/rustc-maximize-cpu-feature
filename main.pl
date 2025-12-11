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

sub main (@argv) {
    my @models = @argv;
    my %model_features = map { $_ => array_to_set(get_cpu_features $_) } @models;
    my $common_features = set_intersection values %model_features;

    my @baseline_models = qw/x86-64 x86-64-v2 x86-64-v3 x86-64-v4/;
    my %baseline_features = map { $_ => array_to_set(get_cpu_features $_) } @baseline_models;
    my @baseline_candidates = grep {
        set_size(set_intersection($baseline_features{$_}, $common_features)) == set_size($baseline_features{$_})
        and set_size(set_union($baseline_features{$_}, $common_features)) == set_size($common_features)
    } @baseline_models;

    my $baseline = pop @baseline_candidates;
    my $additional = set_difference($common_features, $baseline_features{$baseline});
    say join ',', $baseline, sort { $a cmp $b } map { "+$_" } keys %$additional;
}

main @ARGV unless caller;
