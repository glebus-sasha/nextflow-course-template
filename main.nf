#!/usr/bin/env nextflow
include { refindex } from './processes/refindex.nf'
include { qcontrol } from './processes/qcontrol.nf'
include { align    } from './processes/align.nf'
include { faindex  } from './processes/faindex.nf'
include { bamindex } from './processes/bamindex.nf'
include { varcall  } from './processes/varcall.nf'
include { flagstat } from './processes/flagstat.nf'
include { bcfstats } from './processes/bcfstats.nf'
include { report   } from './processes/report.nf'

reads = Channel.fromFilePairs(params.reads)
reference = Channel.fromPath(params.reference).collect()
workflow simple{
    refindex(reference)
    qcontrol(reads)
    align(reference, qcontrol.out[0], refindex.out)
    faindex(reference)
    bamindex(align.out)
    varcall(reference, align.out.join(bamindex.out), faindex.out)
    flagstat(align.out)
    bcfstats(varcall.out)
        
    report(
        qcontrol.out.json.
        mix(flagstat.out.map{it -> it[1]}).
        mix(bcfstats.out.map{it -> it[1]}).collect()
        )
}

workflow show_off{

    reference | 
        refindex & faindex
    reads | qcontrol
    
    align(reference, qcontrol.out[0], refindex.out) |
        bamindex & flagstat
    varcall(reference, align.out.join(bamindex.out), faindex.out) |
        bcfstats
        
    report(
        qcontrol.out.json                           |
        mix(flagstat.out.map{it -> it[1]})          |
        mix(bcfstats.out.map{it -> it[1]})          |
        collect
        )
}

workflow{
    show_off()
}
