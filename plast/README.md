# README.md

- Last modified: fre mar 19, 2021  07:13
- Sign: nylander

## Description

Test using [plast](https://plast.inria.fr/) instead of blast.

Start with our case with nt assemblies and aa baits, hence using `tplastn`:

    $ plast -p tplastn -i my_query -d my_databank -o my_results


Commands would be

    # Clean up previous runs
    $ rm -rf plast_results \
        blast_results \
        plast_alibaseq_out \
        blast_alibaseq_out \
        list_of_files_to_seach_against.txt
    $ find assemblies -type f -not -name '*.fasta' -exec rm {} \;

    # List assemblies
    $ find assemblies -type f -name '*.fasta' -exec basename {} \; > list_of_files_to_seach_against.txt

    # Create blast (plast) db's
    $ find assemblies -type f | \
        parallel 'makeblastdb -in {} -dbtype nucl -parse_seqids'

    # Start plast
    $ time bash plast_wrapper.sh \
        ./baits \
        ./assemblies \
        1e-10 \
        tplastn \
        4 \
        n \
        ./list_of_files_to_seach_against.txt

    # real	1m3,887s
    # user	2m55,024s
    # sys	0m3,608s


    $ mkdir -p plast_results
    $ mv *.blast plast_results

    $ python ../alibaseqPy3.py \
        -x a \
        -f M \
        -b ./plast_results/ \
        -t ./assemblies/ \
        -e 1e-10 \
        --is \
        --amalgamate-hits \
        --ac tdna-tdna \
        --translate

    $ mv *.log *.tab alibaseq_out
    $ mv alibaseq_out plast_alibaseq_out

    # Start blast
    $ time bash ../blast_wrapper.sh \
        ./baits \
        ./assemblies \
        1e-10 \
        tblastn \
        4 \
        n \
        ./list_of_files_to_seach_against.txt

    # real	0m3,051s
    # user	0m11,183s
    # sys	0m0,095s

    $ mkdir -p blast_results
    $ mv *.blast blast_results

    $ python ../alibaseqPy3.py \
        -x a \
        -f M \
        -b ./blast_results/ \
        -t ./assemblies/ \
        -e 1e-10 \
        --is \
        --amalgamate-hits \
        --ac tdna-tdna \
        --translate

    $ mv *.log *.tab alibaseq_out
    $ mv alibaseq_out blast_alibaseq_out


## RESULTS

#### Timing

plast:

    real	1m3,887s
    user	2m55,024s
    sys	0m3,608s

blast:

    real	0m3,051s
    user	0m11,183s
    sys	0m0,095s

#### Genes

plast:

    $ get_fasta_info plast_alibaseq_out/*.fas
    Nseqs	Min.len	Max.len	Avg.len	File
    1	47	47	47	EOG7428S5.fas
    Nseqs	Min.len	Max.len	Avg.len	File
    1	221	221	221	EOG789Q0W.fas

blast:

    $ get_fasta_info blast_alibaseq_out/*.fas
    Nseqs	Min.len	Max.len	Avg.len	File
    2	47	156	102	EOG7428S5.fas
    Nseqs	Min.len	Max.len	Avg.len	File
    2	98	206	152	EOG789Q0W.fas
    Nseqs	Min.len	Max.len	Avg.len	File
    1	153	153	153	EOG7DCCVT.fas

# Summary

plast was slower(!) and didn't return hits for all queries for all genomes!


