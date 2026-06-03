#!/usr/bin/perl
use strict;
use warnings;

my $study     = "OncoArray";
my $pop       = "europeans";
my $user      = $ENV{USER};

# Paths
my $pwd       = "/scratch/${USER}/onco";
my $gp_dir    = "/scratch/1000GP_Phase3";

my @chr_list  = map { "chr$_" } (23);


my %chr_int = ( 
    chr23 => [
        "2699555 7700000",   "7700001 12700001",   "12700002 17700002",
        "17700003 22700003",  "22700004 27700004",  "27700005 32700005",
        "32700006 37700006",  "37700007 42700007",  "42700008 47700008",
        "47700009 52700009",  "52700010 57700010",  "57700011 62700011",
        "62700012 66021550",  "68021551 72700013",  "72700014 77700014",
        "77700015 82700015",  "82700016 87700016",  "87700017 92700017",
        "92700018 97700018",  "97700019 102700019", "102700020 107700020",
        "107700021 112700021", "112700022 117700022", "117700023 122700023",
        "122700024 127700024", "127700025 132700025", "132700026 137700026",
        "137700027 142700027", "142700028 147700028", "147700029 152700029",
        "152700030 154930230", "66021551 68021550"
    ]
);


foreach my $chr (@chr_list) {
    next unless exists $chr_int{$chr};
    
    my @todo = @{ $chr_int{$chr} };
    
    my $out_dir   = "${pwd}/imputation";
    my $work_dir  = "${pwd}/imputation/${chr}";
    my $batch     = "${chr}_phased_imputation";
    my $cmd_file  = "${work_dir}/${batch}_cmdlist.sh";

    open my $submit, '>', $cmd_file
        or die "Could not open $cmd_file for writing: $!";
        
    foreach my $range (@todo) {
        my ($from, $to) = split(m{ }, $range);
        
        if ($from >= $to) {
            die "Error: 'From' position ($from) is greater than or equal to 'To' position ($to) in range: $range\n";
        }
        
        my @param = (
            "impute2",
            "-use_prephased_g",
            "-m ${gp_dir}/genetic_map_${chr}_combined_b37.txt",
            "-h ${gp_dir}/1000GP_Phase3_${chr}.hap.gz",
            "-l ${gp_dir}/legend_files/1000GP_Phase3_${chr}.legend",
            "-strand_g ${gp_dir}/strands/strand_${chr}.txt",
            "-known_haps_g ${pwd}/shapeit/onco_${chr}_prephased.haps",
            "-impute_excluded",
            "-int ${from} ${to}",
            "-Ne 20000",
            "-pgs_miss",
            "-o_gz",
            "-filt_rules_l 'filter==0'",
            "-exclude_snps_g ${gp_dir}/OncoArray_exclude_bcac/OncoArray_exclude_bcac_updated.txt",
            "-allow_large_regions",
            "-k_hap 800",
            "-buffer 500",
            "-o ${work_dir}/onco_${chr}_phased_${from}_${to}.txt"
        );

        print $submit join(" ", @param) . "\n";
    }
    close $submit;
    print "$batch commands in: $cmd_file\n";
}
