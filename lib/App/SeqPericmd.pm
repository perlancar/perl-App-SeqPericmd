package App::PeriSeq;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;

use List::Util qw(max);

our %SPEC;

$SPEC{seq} = {
    v => 1.1,
    summary => 'Rinci-/Perinci::CmdLine-based "seq"-like CLI utility',
    description => <<'_',

This utility is similar to Unix `seq` command, with a few differences: some
differences in option names, JSON output, allow infinite stream (when `to` is
not specified).

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
        header => {
            summary => 'Add a header row',
            schema => 'str*',
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
        {
            summary => 'Use with fsql',
            src => q[peri-seq 1 100 --header num | fsql --add-tsv - --add-csv data.csv 'SELECT num, data1 FROM stdin LEFT JOIN data ON stdin.num=data.num'],
            src_plang => 'bash',
        },
    ],
};
sub seq {
    my %args = @_;

    my $fmt = $args{number_format};
    if (!defined($fmt)) {
        if ($args{equal_width}) {
            my $neg = $args{from}<0 || $args{to}<0 || $args{increment}<0 ? 1:0;
            my $width_whole = max(
                length(int($args{from}     )),
                length(int($args{to}       )),
                length(int($args{increment})),
            );
            my $width_frac  = max(
                length($args{from}      - int($args{from}     )),
                length($args{to}        - int($args{to}       )),
                length($args{increment} - int($args{increment})),
            ) - 2;
            $width_frac = 0 if $width_frac < 0;
            $fmt = sprintf("%%0%d.%df",
                           $width_whole+$width_frac+($width_frac ? 1:0) + $neg,
                           $width_frac,
                       );
            #say "D:fmt=$fmt";
        } elsif ($args{from} != int($args{from}) ||
                     defined($args{to}) && $args{to} != int($args{to}) ||
                     $args{increment} || int($args{increment})) {
            # use fixed floating point to avoid showing round-off errors
            my $width_frac  = max(
                length($args{from}      - int($args{from}     )),
                length($args{increment} - int($args{increment})),
                (defined($args{to}) ?
                     (length($args{to}-int($args{to}))) : ()),
            ) - 2;
            $width_frac = 0 if $width_frac < 0;
            $fmt = sprintf("%%.%df", $width_frac);
        }
    }

    if (defined $args{to}) {
        my @res;
        push @res, $args{header} if $args{header};
        my $i = $args{from}+0;
        while ($i <= $args{to}) {
            push @res, defined($fmt) ? sprintf($fmt, $i) : $i;
            last if defined($args{limit}) && @res >= $args{limit};
            $i += $args{increment};
        }
        return [200, "OK", \@res];
    } else {
        # stream
        my $i = $args{from}+0;
        my $j = $args{header} ? -1 : 0;
        my $next_i;
        #my $finish;
        my $func = sub {
            #return undef if $finish;
            $i = $next_i if $j++ > 0;
            return $args{header} if $j == 0 && $args{header};
            $next_i = $i + $args{increment};
            #$finish = 1 if ...
            return defined($fmt) ? sprintf($fmt, $i) : $i;
        };
        return [200, "OK", $func, {stream=>1}];
    }
}

1;
# ABSTRACT:
