package App::PeriSeq;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;

$SPEC{seq} = {
    v => 1.1,
    summary => 'Rinci-/Perinci::CmdLine-based "seq"-like CLI utility',
    description => <<'_',

This utility is similar to Unix `seq` command, with a few differences: some
differences in option names, allow infinite stream (when `to` is not specified).

_
    args_rels => {
        dep_any => ['equal_width', ['to']], # can't specify equal_width without to
    },
    args => {
        from => {
            schema => 'float*',
            req => 1,
            pos => 0,
        },
        to => {
            schema => 'float*',
            pos => 1,
        },
        increment => {
            schema => 'float*',
            default => 1,
            cmdline_aliases => {i=>{}},
            pos => 2,
        },
        equal_width => {
            summary => 'Equalize width by padding with leading zeros',
            schema => ['bool*', is=>1],
            cmdline_aliases => {w=>{}},
        },
        limit => {
            summary => 'Only generate a certain amount of numbers',
            schema => ['int*', min=>1],
            cmdline_aliases => {n=>{}},
        },
        number_format => {
            summary => 'sprintf() format for each number',
            schema => ['str*'],
            cmdline_aliases => {f=>{}},
        },
    },
    examples => [
        {
            summary => 'Generate whole numbers from 1 to 10 (1, 2, ..., 10)',
            src => 'peri-seq 1 10',
            src_plang => 'bash',
        },
        {
            summary => 'Generate odd numbers from 1 to 10 (1, 3, 5, 7, 9)',
            src => 'peri-seq 1 10 2',
            src_plang => 'bash',
        },
        {
            summary => 'Generate 1, 1.5, 2, 2.5, ..., 10',
            src => 'peri-seq 1 10 -i 0.5',
            src_plang => 'bash',
        },
        {
            summary => 'Generate stream 1, 1.5, 2, 2.5, ...',
            src => 'peri-seq 1 -i 0.5',
            src_plang => 'bash',
        },
        {
            summary => 'Generate 01, 02, ..., 10',
            src => 'peri-seq 1 10 -w',
            src_plang => 'bash',
        },
        {
            summary => 'Generate 0001, 0002, ..., 0010',
            src => 'peri-seq 1 10 -f "%04s"',
            src_plang => 'bash',
        },
        {
            summary => 'Generate -10, -9, -8, -7, -6 (limit 5 numbers)',
            src => 'peri-seq --from -10 --to 0 -n 5',
            src_plang => 'bash',
        },
    ],
};
sub seq {
    my %args = @_;

    if (defined $args{to}) {
        my @res;
        my $i = $args{from};
        while ($i < $args{to}) {
            push @res, $i;
            last if defined($args{limit}) && @res >= $args{limit};
            $i += $args{increment};
        }
        return [200, "OK", \@res];
    } else {
        # stream
        my $i = $args{from};
        my $j = 0;
        #my $finish;
        my $func = sub {
            #return undef if $finish;
            $i = $next_i if $j++;
            $next_i = $i + $args{increment};
            #$finish = 1 if ...
            return $i;
        };
        return [200, "OK", $func, {stream=>1}];
    }
}

1;
# ABSTRACT:
