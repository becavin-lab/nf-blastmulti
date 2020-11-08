#!/usr/bin/env nextflow
 
/*
 * Defines the pipeline inputs parameters (giving a default value for each for them)
 * Each of the following parameters can be specified as command line options
 */
params.query = "$baseDir/data/"
params.db = "$baseDir/blast-db/pdb/tiny"
params.out = "$baseDir/result.txt"
params.chunkSize = 100
 
db_name = file(params.db).name
db_dir = file(params.db).parent
 
/*
* Create a channel to get all fasta files
*/

/*
 * Given the query parameter creates a channel emitting the query fasta file(s),
 * the file is split in chunks containing as many sequences as defined by the parameter 'chunkSize'.
 * Finally assign the result channel to the variable 'fasta_ch'
 */
Channel
    .fromPath("$baseDir/data/*.fa")
    .splitFasta(by: params.chunkSize, file:true)
    .set { fasta_ch }
 
/*
 * Executes a BLAST job for each chunk emitted by the 'fasta_ch' channel
 * and creates as output a channel named 'top_hits' emitting the resulting
 * BLAST matches 
 */
process blast {
    input:
    path 'query.fa' from fasta_ch
    path db from db_dir
 
    output:
    file 'sequences' into sequences_ch
 
    """
    blastp -db $db/$db_name -query query.fa -outfmt 6 > blast_result
    cat blast_result | head -n 10 > sequences
    """
}

 
/*
 * Collects all the sequences files into a single file
 * and prints the resulting file content when complete
 */
sequences_ch
    .collectFile(name: params.out)
    .view { file -> "matching sequences:\n ${file.text}" }

